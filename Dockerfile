FROM python:3.9-slim
WORKDIR /code
COPY ../requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt
COPY .. /code/app
ENV REGION=eu-west-2
EXPOSE 8001
CMD ["uvicorn", "app.main:app","--host", "0.0.0.0","--port", "8001"]
