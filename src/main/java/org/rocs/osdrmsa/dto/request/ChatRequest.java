package org.rocs.osdrmsa.dto.request;

import org.rocs.osdrmsa.dto.summary.ChatMessageDto;

import java.util.List;

public record ChatRequest(
        String message,
        List<ChatMessageDto> history
) {
}
