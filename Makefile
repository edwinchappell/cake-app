BUCKET_NAME=<bucket name> # For SAM deployment
STACK_NAME=cake-stack # For SAM deployment

start_dynamodb_local:
	pip3 install --no-cache-dir --upgrade -r ./app/requirements.txt
	docker stop dynamodb || true && docker rm dynamodb || true
	docker run -d -i --name dynamodb -p 8000:8000 amazon/dynamodb-local
	python3 dynamodb_local.py

start_app_local:
	cd ./app; uvicorn main:app --reload --port 8001

start_local: start_dynamodb_local start_app_local

start_aws_sam:
	sam build; sam package --output-template-file packaged.yaml --s3-bucket ${BUCKET_NAME}; \
	sam deploy --template-file packaged.yaml --stack-name ${STACK_NAME} --capabilities CAPABILITY_IAM

stop_aws_sam:
	sam delete --stack-name ${STACK_NAME} --no-prompts --region eu-west-2