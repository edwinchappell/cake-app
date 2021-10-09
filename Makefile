start_dynamodb_local:
	pip3 install --no-cache-dir --upgrade -r requirements.txt
	docker stop dynamodb || true && docker rm dynamodb || true
	docker run -d -i --name dynamodb -p 8000:8000 amazon/dynamodb-local
	python3 ./scripts/dynamodb_local.py

start_app_local:
	cd ./app; uvicorn main:app --reload --port 8001

run_local: start_dynamodb_local start_app_local
