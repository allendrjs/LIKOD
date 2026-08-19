package org.rocs.osdrmsa.service.chat;

import org.rocs.osdrmsa.dto.request.ChatRequest;
import org.rocs.osdrmsa.dto.response.ChatResponse;

public interface ChatService {

    /**
     * Answers a chat message on behalf of the currently authenticated student.
     * The response is grounded only in that student's own enrollment, records,
     * and appeals -- never another student's data.
     *
     * @param username the authenticated principal's login username (not the studentId)
     * @param request  the incoming message plus any prior turns for context
     */
    ChatResponse ask(String username, ChatRequest request);
}
