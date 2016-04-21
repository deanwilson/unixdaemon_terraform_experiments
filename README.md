## UnixDaemon Experiments Terraform Repo

### Introduction

While it's possible to experiment and learn parts of Terraform in
isolation sometimes it's handy to have a larger, more complete,
environment to run your tests in. For me
[unixdaemon_terraform_experiments](https://github.com/deanwilson/unixdaemon_terraform_experiments)
this is that repo. It will contain a number of different terraform based
projects that can be consistently deployed together. You can see some of
my thinking behind this in the
[Naive first steps with Terraform](http://www.unixdaemon.net/cloud/naive-first-steps-with-terraform/) post.

Terraform is a very powerful, but quite young, piece of software so
I'm making this repo open to encourage sharing and invite feedback on
better way to do things. There is no guarantee that anything in this repo
is the best or most current way to do anything.

### Bootstrap

The bootstrap phase requires you to have AWS account credentials. For
this repo it's recommended that you store them in `.aws/credentials`
under distinct profile names and leave `[default]` empty.

We'll do the initial terraform configuration out of bounds to avoid
making bootstrapping difficult. First we create the S3 bucket, which
must have a globally unique name, used to store the terraform state
files. Then we enable bucket versioning in case of anything going
hideously wrong.

The `AWS_REGION` and `DEPLOY_ENV` variables will help us when we later
need to have AWS resources in multiple regions or if you decide to have
separate test, staging and production environments for example.

    export AWS_PROFILE=test-admin
    export AWS_REGION=eu-west-1
    export DEPLOY_ENV=test

    export TERRAFORM_BUCKET="net.dean-wilson-terraform-state-${AWS_REGION}-${DEPLOY_ENV}"

    $ aws --region $AWS_REGION s3 mb "s3://${TERRAFORM_BUCKET}"
    make_bucket: s3://net.dean-wilson-terraform-state-eu-west-1-test/

    $ aws --region $AWS_REGION       \
        s3api put-bucket-versioning  \
        --bucket ${TERRAFORM_BUCKET} \
        --versioning-configuration Status=Enabled

You will also need to make a change to the projects `Rakefile` and tell
it your `BUCKET_NAME and `BUCKET_REGION`. These are (currently, and awkwardly) set
as constants at the top of the file and should match the values you exported above.

You should now install Terraform. This can be done by downloading the file from
the [Terraform website](https://www.terraform.io/downloads.html), or
possibly installing it using your package manager.

Once this is done we'll enable our `rake` terraform wrapper by
installing its dependencies.

    $ bundle install

You can then see the possible `rake` tasks with

    $ bundle exec rake -T
    ...
    rake plan                  # Show the terraform plan
    ...

### Setting up an environment

Before we add our first Terraform project we'll configure an
environment. I've decided to structure this repo and code to have three
environments, `test`, `staging` and `production`. Each of those will be
implemented as a distinct Amazon AWS Account and will have their own S3
distinct bucket for state. If you want to have your own environment names
then you'll need to change `ALLOWED_ENVIRONMENTS` in the `Rakefile`.

We then create our environment specific variable file.

    mkdir variables

    echo 'environment = "test"' > variables/test.tfvars

### Running an initial terraform project

Now we're past all the basic configuration we'll create a very simple
Terraform project and apply it to confirm everything is working. For our
initial project we'll create a security group and then delete it to show
the entire end to end process.

Our initial step is to create a directory under `projects` to hold our
new resources. Once this is done we'll add a single security group
resource.

    mkdir -p projects/simple-sg/resources/

    cat > projects/simple-sg/resources/security-group.tf <<EOF
    resource "aws_security_group" "test_sg" {
        name = "test-labs-sg"
        description = "A test-labs-sg example resource"
    }
    EOF

Now everything is configured and we have a simple test case we'll run Terraform
and see check if everything works.

    $ PROJECT_NAME=simple-sg bundle exec rake plan

    Remote state configured and pulled.
    ...
    + aws_security_group.test_sg
        description: "" => "A test-labs-sg resource"
        name:        "" => "test-labs-sg"
    ...
    Plan: 1 to add, 0 to change, 0 to destroy.

Everything is looking good so far. Terraform has now shown us what it will do
when we `apply` it to our infrastructure. Which we'll do now.


    # notice that the rake task changes from plan to apply
    $ PROJECT_NAME=simple-sg bundle exec rake apply

    aws_security_group.test_sg: Creating...
      description: "" => "A test-labs-sg resource
    ...
    aws_security_group.test_sg: Creation complete
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

You can now check for the security group using either the AWS console or
the `aws` command line tool. If you now check the S3 bucket we
configured and created earlier to store our Terraform statefiles you'll
also see an object named `terraform-simple-sg.tfstate`. This is where
Terraform stores its remote state.

If you re-run the `terraform apply` nothing will will change as Terraform has no more work to do.

    $ PROJECT_NAME=simple-sg bundle exec rake apply

    aws_security_group.test_sg: Refreshing state... (ID: sg-000000)
    Apply complete! Resources: 0 added, 0 changed, 0 destroyed

We'll now finish our testing and clean up after ourselves by having
Terraform `destroy` the resource we created.

    $ PROJECT_NAME=simple-sg bundle exec rake destroy

    Do you really want to destroy?
      Terraform will delete all your managed infrastructure.

      Enter a value: yes

    aws_security_group.test_sg: Refreshing state... (ID: sg-000000)
    aws_security_group.test_sg: Destroying...
    aws_security_group.test_sg: Destruction complete

    Apply complete! Resources: 0 added, 0 changed, 1 destroyed.

### Future Plans

In general most of the things under `projects` will start out as `tf`
files full of resources and will be extracted as modules when they're
generic enough to be useful on their own. I'm sure there is third party
code I could use to build most of this but as this repo is mostly for
learning it'd be a little counter productive to import too much
functionality.

I'll be expanding the repo with working examples as I hit new use cases
and hopefully having a larger, related, chunk of terraform code will be
useful to people new to Terraform.

Since you've made it all the way here another link to the repo might be in order:
[unixdaemon_terraform_experiments](https://github.com/deanwilson/unixdaemon_terraform_experiments)
