package org.eci.TdseApp.user;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;

import java.util.HashMap;
import java.util.Map;

/**
 * Lambda handler for User Service.
 * When deployed to Lambda with container image, API Gateway routes requests to this handler.
 * The handler delegates to Spring Boot application context.
 */
public class UserServiceLambdaHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    private static ConfigurableApplicationContext applicationContext;

    static {
        applicationContext = SpringApplication.run(UserServiceApplication.class);
    }

    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent event, Context context) {
        // The actual request handling is done by Spring Boot's DispatcherServlet
        // This is a placeholder that indicates Spring Boot is running
        context.getLogger().log("User Service Lambda Handler - Request path: " + event.getPath());

        APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();
        response.setStatusCode(200);
        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");
        response.setHeaders(headers);
        response.setBody("{\"message\":\"User Service is running\"}");
        return response;
    }
}

