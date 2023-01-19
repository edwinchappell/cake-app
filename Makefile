BUCKET_NAME=etcbucket20211006# For SAM deployment
ECR_URI=<ECR URI># For ECS deployment
APP_NAME=cake-app
STACK_NAME=cake-stack# For SAM deployment

start_local: _install_dependencies _start_dynamodb_local _start_app_local

test_local: _install_dependencies _start_dynamodb_local _run_tests

start_aws_sam:
	cp requirements.txt ./app/
	sam build
# 	sam package --output-template-file packaged.yaml --s3-bucket ${BUCKET_NAME}
	sam deploy --template-file packaged.yaml --stack-name ${STACK_NAME} --capabilities CAPABILITY_IAM

stop_aws_sam:
	sam delete --stack-name ${STACK_NAME} --no-prompts --region eu-west-2

start_aws_ecs: _docker_build_tag_push _create_ecs_infrastructure

stop_aws_ecs: _destroy_ecs_infrastructure


# These should not be called directly
_start_dynamodb_local:
	docker stop dynamodb || true && docker rm dynamodb || true
	docker network create -d bridge sam-network
	docker run -d -i --name dynamodb -p 8000:8000 --network=sam-network amazon/dynamodb-local
	python3 dynamodb_local.py

_docker_build_tag_push:
	cd ./app; docker build --tag ${APP_NAME} .
	aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${ECR_URI}/${APP_NAME}
	docker tag cake-app:latest ${ECR_URI}/${APP_NAME}:latest
	docker push ${ECR_URI}/${APP_NAME}:latest

_create_ecs_infrastructure:
	cd ./terraform; terraform init; terraform apply -auto-approve

_destroy_ecs_infrastructure:
	cd ./terraform; terraform destroy -auto-approve

_start_app_local:
	cd ./app; uvicorn app:app --reload --port 8001

_install_dependencies:
	pip3 install -r requirements.txt

_run_tests:
	pip3 install pytest moto requests
	pytest
	docker stop dynamodb || true && docker rm dynamodb || true

