# Lambda definition
module "ts_lambda_function" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "7.2.6"
  function_name = "dcx-roundels"
  lambda_role   = aws_iam_role.test_role.arn
  description   = "Lambda function written in TS"
  handler       = "main.default"
  runtime       = "nodejs18.x"
  memory_size   = 10240
  timeout       = 900
  source_path   = [
    {
      path     = "../"
      commands = [
        "npm run build",
        "cd dist",
        ":zip"
      ]
    }
  ]

  environment_variables = {
    ADDITIONAL_ATTRIBUTES_TABLE = "test-dcx-additional-attributes"
    ROUNDELS_ARRIVAL_BUCKET     = "test-roundels-arrival-bucket"
    ROUNDELS_PROCESSED_BUCKET   = "test-roundels-processed-bucket"
    ROUNDELS_ERRORED_BUCKET     = "test-roundels-errored-bucket"
  }
}

# Lambda role
resource "aws_iam_role" "test_role" {
  name               = "test_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# S3 bucket
resource "aws_s3_bucket" "roundels-arrival-bucket" {
  bucket = "test-roundels-arrival-bucket"
}
resource "aws_s3_bucket" "roundels-processed-bucket" {
  bucket = "test-roundels-processed-bucket"
}
resource "aws_s3_bucket" "roundels-errored-bucket" {
  bucket = "test-roundels-errored-bucket"
}

# Define trigger for S3
resource "aws_s3_bucket_notification" "demo_bucket_notification" {
  bucket = aws_s3_bucket.roundels-arrival-bucket.id
  lambda_function {
    lambda_function_arn = module.ts_lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# DynamoDB table creation
resource "aws_dynamodb_table" "dcx-additional-attributes-table" {
  name             = "test-dcx-additional-attributes"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "id"
  range_key        = "type"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  global_secondary_index {
    name            = "test-dcx-additional-attributes-index"
    hash_key        = "productId"
    range_key       = "type"
    projection_type = "ALL"
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "productId"
    type = "S"
  }

  attribute {
    name = "type"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}

# Populate the table
resource "aws_dynamodb_table_item" "dcx-additional-attributes" {
  for_each   = local.tf_data
  table_name = aws_dynamodb_table.dcx-additional-attributes-table.name
  hash_key   = "id"
  range_key  = "type"
  item       = jsonencode(each.value)
}

data "aws_iam_policy_document" "dcx_roundels_policy_document" {
  statement {
    actions = [
      "dynamodb:*",
    ]
    resources = [aws_dynamodb_table.dcx-additional-attributes-table.arn]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "${aws_s3_bucket.roundels-arrival-bucket.arn}/*", aws_s3_bucket.roundels-arrival-bucket.arn,
      "${aws_s3_bucket.roundels-errored-bucket.arn}/*", aws_s3_bucket.roundels-errored-bucket.arn,
      "${aws_s3_bucket.roundels-processed-bucket.arn}/*", aws_s3_bucket.roundels-processed-bucket.arn,
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "dcx_roundels_dynamo_and_s3_policy" {
  name   = "test_dcx_roundels_dynamo_policy"
  policy = data.aws_iam_policy_document.dcx_roundels_policy_document.json
}

# Attach policy to Lambda IAM execute role
resource "aws_iam_policy_attachment" "roundels_policy_attach" {
  name       = "${module.ts_lambda_function.lambda_function_name}-roundels-policy-attach"
  roles      = [aws_iam_role.test_role.name]
  policy_arn = aws_iam_policy.dcx_roundels_dynamo_and_s3_policy.arn
}
