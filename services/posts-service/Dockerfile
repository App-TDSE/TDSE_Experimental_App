FROM public.ecr.aws/lambda/java:21

COPY target/posts-service.jar ${LAMBDA_TASK_ROOT}/

CMD ["org.eci.TdseApp.posts.PostsServiceLambdaHandler"]
