package org.eci.TdseApp.stream.service;

import org.eci.TdseApp.stream.client.PostsServiceClient;
import org.eci.TdseApp.stream.web.dto.PostDto;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class StreamService {
    private final PostsServiceClient postsServiceClient;

    public StreamService(PostsServiceClient postsServiceClient) {
        this.postsServiceClient = postsServiceClient;
    }

    public List<PostDto> getGlobalStream() {
        return postsServiceClient.getAllPosts();
    }
}
