from decimal import Decimal
from typing import List

from boto3.dynamodb.conditions import Key
from fastapi import FastAPI, HTTPException
import boto3
from pydantic import BaseModel, Field, AnyHttpUrl
from mangum import Mangum
import logging
import os

logging.basicConfig(format='%(asctime)s %(message)s')
logger = logging.getLogger("app")
logger.setLevel(logging.DEBUG)

stage = os.environ.get('STAGE', None)
root_path = f"/{stage}" if stage else "/"
app = FastAPI(title='CAKE API', root_path=root_path)

print(os.environ)
if os.environ.get("AWS_SAM_LOCAL"):
    logger.info("Running in SAM local")
    client = boto3.resource('dynamodb', endpoint_url='http://dynamodb:8000')
elif os.environ.get("REGION"):
    logger.info("Connect to DB using region")
    client = boto3.resource('dynamodb', region_name="eu-west-2")
else:
    logger.info("Running locally")
    client = boto3.resource('dynamodb', endpoint_url='http://localhost:8000')
    logger.info(f"API spec available at 'http://localhost:8001/docs'")

table_name = 'cake'
table = client.Table(table_name)


CAKE_ERROR_DETAIL = {204: "Deleted cake with ID",
                     409: "Conflict - cannot process cake request with provided ID",
                     500: "An unknown error occurred"}


class Cake(BaseModel):
    id: int
    name: str = Field(min_length=1, max_length=30)
    comment: str = Field(min_length=1, max_length=200)
    imageUrl: AnyHttpUrl = Field(default="https://www.example.com/")
    value: str
    yumFactor: int = Field(ge=1, le=5)


class Message(BaseModel):
    message: str


@app.get("/")
def health():
    return "OK"


@app.post("/create", status_code=201, response_model=Cake, responses={409: {"message": CAKE_ERROR_DETAIL.get(409),
                                                                            500: {"message": CAKE_ERROR_DETAIL.get(
                                                                                500)}}})
async def create(cake_req: Cake):
    id_query_result = get_by_id(cake_req.id)
    if id_query_result is not None and id_query_result.get("Count") > 0:
        raise HTTPException(status_code=409, detail=CAKE_ERROR_DETAIL.get(409))
    try:
        table.put_item(
            Item={
                'id': cake_req.id,
                'name': cake_req.name,
                'comment': cake_req.comment,
                'imageUrl': cake_req.imageUrl,
                'value': cake_req.value,
                'yumFactor': cake_req.yumFactor,
            }
        )
    except Exception as e:
        logger.error("Error writing to table", e)
        raise HTTPException(status_code=500, detail=CAKE_ERROR_DETAIL.get(500))

    return cake_req


@app.get("/list", status_code=200, response_model=List[Cake],
         responses={500: {"message": CAKE_ERROR_DETAIL.get(500)}})
async def list():
    response = []
    try:
        response = table.scan()
    except Exception as e:
        logger.error("Error scanning table", e)
        return response
    logger.info(f"Table scan result {response}")
    return response.get("Items")


@app.delete("/delete/{id}", status_code=204, responses={ 500: {"message": CAKE_ERROR_DETAIL.get(500)}})
async def delete(id: int):
    try:
        table.delete_item(
            Key={
                'id': id,
            }
        )
    except Exception as e:
        logger.error("Error deleting from table", e)
        raise HTTPException(status_code=500, detail=CAKE_ERROR_DETAIL.get(500))

    return


def get_by_id(cake_id: int):
    query_result = table.query(
        KeyConditionExpression=Key('id').eq(Decimal(cake_id))
    )
    return query_result


handler = Mangum(app)
