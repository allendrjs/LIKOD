package org.rocs.osdrmsa.utils.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.rocs.osdrmsa.dto.summary.ChatMessageDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Thin wrapper around Ollama's local /api/chat endpoint (http://localhost:11434 by
 * default). This is the ONLY place in the backend that talks to Ollama -- the mobile
 * app never calls it directly, and it is not exposed on any public-facing port.
 */
@Component
public class OllamaClient {

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${ollama.base-url:http://localhost:11434}")
    private String baseUrl;

    @Value("${ollama.model:llama3.2}")
    private String model;

    @Value("${ollama.request-timeout-seconds:60}")
    private long requestTimeoutSeconds;

    public String chat(List<ChatMessageDto> messages) {
        try {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("model", model);
            body.put("messages", messages.stream()
                    .map(m -> Map.of("role", m.role(), "content", m.content()))
                    .toList());
            body.put("stream", false);

            String json = objectMapper.writeValueAsString(body);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/api/chat"))
                    .header("Content-Type", "application/json")
                    .timeout(Duration.ofSeconds(requestTimeoutSeconds))
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new IllegalStateException(
                        "Ollama returned HTTP " + response.statusCode() + ": " + response.body());
            }

            JsonNode root = objectMapper.readTree(response.body());
            String reply = root.path("message").path("content").asText(null);

            if (reply == null || reply.isBlank()) {
                throw new IllegalStateException("Ollama returned an empty response.");
            }

            return reply.trim();
        } catch (IOException e) {
            throw new IllegalStateException(
                    "Couldn't reach the local AI service. Make sure Ollama is running on " + baseUrl + ".", e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("The AI request was interrupted. Please try again.", e);
        }
    }
}
