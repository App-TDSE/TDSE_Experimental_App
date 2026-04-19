FROM public.ecr.aws/lambda/java:21

COPY target/stream-service.jar ${LAMBDA_TASK_ROOT}/

CMD ["org.eci.TdseApp.stream.StreamServiceLambdaHandler"]
