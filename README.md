# cake-app

A simple FastAPI application exposing 3 operations on Cake resources: create, list and delete. 

DynamoDB is used for persistence.

Make targets are included to:

i. Run the application locally, 
ii. Deploy as a serverless application to AWS using SAM CLI or
iii. Deploy as a containerised application to AWS ECS using docker and terraform

## Getting Started

### Prerequisites and assumptions

- make
- python >=3.6
- pip
- docker
- Git CLI
- AWS CLI installed and configured with the credentials of an IAM user with permissions to create/destroy resources
  
- SAM CLI (https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- SAM CLI deployment requires a bucket whose name is added to Makefile (BUCKET_NAME)
- terraform (for ECS deployment)
  
- ECS deployment requires an existing ECR repository to host images. The repository URI should be added to:
  Makefile (ECR_URI) and terraform/variables.tf (ecs_image_url)
- ECS deployment requires terraform >= 0.14.8

### Cloning the repository

Clone the repository with:

``` bash
git clone https://github.com/edwinchappell/cake-app.git
```

```bash
cd cake-app
```
`Make` is used to provide all commands to run the application

### Running the API locally

Run `make start_local` to start the application locally for development. This will spin up a local dynamodb container 
(see https://hub.docker.com/r/amazon/dynamodb-local)

### Testing the API locally

Run `make test_local` to unit test the application locally

### Running the API on AWS using SAM CLI

(Note that the Makefile BUCKET_NAME variable must be assigned to a valid bucket name - see prerequisites)

Run `make start_aws_sam` to deploy the FlaskAPI cake API as a serverless application on AWS

The deployed resources are part of SAM stack name 'cake-stack'

This will create an API gateway endpoint to proxy all requests through to the FastAPI application running as a Lambda
A DynamoDB 'cake' table is created as part of deployment


The URI for the deployed API spec will be visible in the deployment logs

Run `make stop_aws_sam` to remove all deployed resources using the SAM CLI

### Running the API on AWS using ECS

(Note that the Makefile ECR_URI variable must be assigned to a ECR repository - see prerequisites)

Run `make start_aws_ecs` to deploy the FlaskAPI cake API as a containerised application on AWS

This will create a new image from the Dockerfile, push the image to the specified ECR repository and create the required
AWS resources. 

Once deployed the URI of the deployed API spec will be logged

Run `make stop_aws_ecs` to tear down the infrastructure





