# Localstack example of running Lambda + s3 + DynamoDB locally using terraform
LocalStack is a cloud service emulator that runs in a single container on your laptop or in your CI environment. With LocalStack, you can run your AWS applications or Lambdas entirely on your local machine without connecting to a remote cloud provider!

Terraform code for updateRoundels lambda placed in `dcx-cee-promotions/lambdas/dcx-roundels-updateRoundels/terraform-local`

WIP: handler has not been completely reworked yet

Ensure that your machine has a functional docker environment installed before proceeding.

# Usage

### Install Docker:

for Mac https://docs.docker.com/desktop/install/mac-install/

for Linux https://docs.docker.com/engine/install/ubuntu/

add user to docker group on Linux https://docs.docker.com/engine/install/linux-postinstall/  

### Install localstack (https://github.com/localstack/localstack):

Linux/MacOS:
`pip install localstack`

or

Linux/MacOS:
`brew install localstack/tap/localstack-cli`


### Install terraform-local (https://github.com/localstack/terraform-local):

`pip install terraform-local`

### How to run

Use command every time after your code change to test it locally: `npm run localstack`

Every time it will restart container, clean up temporary terraform files and apply the newest lambda code to container.
For current example it takes 70 sec.

If you don't want to have elimination every time - just use `npm run tf-run-local`, it takes 55 sec. Choosing this approach don't forgot to clear `builds` folder, it's just a temporary directory.

In order to have access to real time resources dashboard and interact with them - you should register on the official website.

Dashboard: https://app.localstack.cloud/inst/default/status

# Possible errors or problems
`The AWS Access Key Id you provided does not exist in our records` the reason is warnings during `npm run build` which stem from `package-lock.json`. Don't forget to remove node_modules after fixing them.

`KVM permissions`: https://docs.docker.com/desktop/install/linux-install/#kvm-virtualization-support
