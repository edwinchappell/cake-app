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

if os.environ.get("REGION", False):
    logger.info("Connect to DB using region")
    client = boto3.resource('dynamodb', region_name="eu-west-2")
else:
    logger.info("Connect to DB using endpoint")
    client = boto3.resource('dynamodb', endpoint_url='http://localhost:8000')

table_name = 'cake'
table = client.Table(table_name)
logger.info(f"API spec availble at 'http://localhost:8001/docs'")

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


@app.post("/create", status_code=201, response_model=Cake, responses={409: {"message": CAKE_ERROR_DETAIL.get(409),
                                                                            500: {"message": CAKE_ERROR_DETAIL.get(
                                                                                500)}}})
async def create(cake_req: Cake):
    id_query_result = get_by_id(cake_req.id)
    if id_query_result is not None and id_query_result.get("Count") > 0:
        raise HTTPException(status_code=409, detail=CAKE_ERROR_DETAIL.get(409))

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
    logger.info(f"Got table scan result {response}")
    return response.get("Items")


@app.delete("/delete/{id}", responses={204: {"message": f"{CAKE_ERROR_DETAIL.get(204)} <id>"}, 500: {"message": CAKE_ERROR_DETAIL.get(500)}})
async def delete(id: int):
    table.delete_item(
        Key={
            'id': id,
        }
    )
    return {"message": f"{CAKE_ERROR_DETAIL.get(204)} {id}"}


def get_by_id(cake_id: int):
    query_result = table.query(
        KeyConditionExpression=Key('id').eq(Decimal(cake_id))
    )
    return query_result


handler = Mangum(app)
