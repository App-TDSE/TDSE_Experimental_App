FROM public.ecr.aws/lambda/java:21

COPY target/user-service.jar ${LAMBDA_TASK_ROOT}/

CMD ["org.eci.TdseApp.user.UserServiceLambdaHandler"]
