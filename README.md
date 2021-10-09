# cake-app

A simple FastAPI application exposing 3 operations on Cake resources: create, list and delete. 

DynamoDB is used for persistence.

The application can be either run locally or deployed to AWS using SAM CLI

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

### Cloning the repository

Clone the repository with:

``` bash
git clone https://github.com/edwinchappell/cake-app.git
```

```bash
cd cake-api
```
`Make` is used to provide all commands to run the application

### Running the API locally

Run `make start_local` to start the application locally for development. This will spin up a local dynamodb container 
(see https://hub.docker.com/r/amazon/dynamodb-local)

### Running the API on AWS using SAM CLI

Run `make start_aws_sam` to deploy the FlaskAPI cake API as a serverless application on AWS

The deployed resources are part of SAM stack name 'cake-stack'

This will create an API gateway endpoint to proxy all requests through to the FastAPI application running as a Lambda
A DynamoDB 'cake' table is created as part of deployment

(Note that the BUCKET_NAME variable must be assigned to a valid bucket name - see prerequisites)

The URI for the deployed API spec will be visible in the deployment logs

Run `make stop_aws_sam` to remove all deployed resources using the SAM CLI



