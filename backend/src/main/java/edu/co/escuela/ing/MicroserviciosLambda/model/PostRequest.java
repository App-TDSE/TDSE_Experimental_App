package edu.co.escuela.ing.MicroserviciosLambda.model;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Request body for creating a new post")
public class PostRequest {

    @Schema(description = "Content of the post (max 140 characters)", example = "Hello World!", maxLength = 140, requiredMode = Schema.RequiredMode.REQUIRED)
    private String content;

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
