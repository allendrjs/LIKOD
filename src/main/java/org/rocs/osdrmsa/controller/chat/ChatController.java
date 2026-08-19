package org.rocs.osdrmsa.controller.chat;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.dto.request.ChatRequest;
import org.rocs.osdrmsa.dto.response.ChatResponse;
import org.rocs.osdrmsa.service.chat.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Student-facing chatbot. Deliberately has NO path variable / studentId parameter --
 * it always answers on behalf of whoever is authenticated, resolved server-side from
 * the JWT. This avoids the class of bug where a client could pass someone else's ID.
 */
@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<ChatResponse> ask(Authentication authentication, @RequestBody ChatRequest request) {
        ChatResponse response = chatService.ask(authentication.getName(), request);
        return ResponseEntity.ok(response);
    }
}
