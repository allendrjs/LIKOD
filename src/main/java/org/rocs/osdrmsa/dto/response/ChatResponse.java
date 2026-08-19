package org.rocs.osdrmsa.dto.response;

import java.time.LocalDateTime;

public record ChatResponse(
        String reply,
        LocalDateTime timestamp
) {
}
