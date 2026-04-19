package org.eci.TdseApp.stream.client;

import org.eci.TdseApp.stream.web.dto.PostDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Component
public class PostsServiceClient {
    private final RestTemplate restTemplate;
    private final String postsServiceUrl;

    public PostsServiceClient(RestTemplate restTemplate, @Value("${app.services.posts-service-url:http://localhost:8082}") String postsServiceUrl) {
        this.restTemplate = restTemplate;
        this.postsServiceUrl = postsServiceUrl;
    }

    public List<PostDto> getAllPosts() {
        try {
            PostDto[] posts = restTemplate.getForObject(postsServiceUrl + "/api/posts", PostDto[].class);
            return posts != null ? Arrays.asList(posts) : Collections.emptyList();
        } catch (RestClientException e) {
            throw new RuntimeException("Failed to fetch posts from Posts Service", e);
        }
    }
}
