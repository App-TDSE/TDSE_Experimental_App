package org.eci.TdseApp.stream.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.eci.TdseApp.stream.service.StreamService;
import org.eci.TdseApp.stream.web.dto.PostDto;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/stream")
@RequiredArgsConstructor
@Tag(name = "Stream", description = "Global public feed of posts")
public class StreamController {
    private final StreamService streamService;

    @GetMapping
    @Operation(summary = "Get the global public feed", description = "Public endpoint. Posts newest first.")
    @ApiResponse(responseCode = "200", description = "Stream returned")
    public List<PostDto> getStream() {
        return streamService.getGlobalStream();
    }
}
