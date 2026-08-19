package org.rocs.osdrmsa.controller.document;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.dto.response.DocumentUploadResponse;
import org.rocs.osdrmsa.service.document.DocumentService;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

/**
 * Handles appeal-letter uploads (scanned/handwritten image, PDF, or DOCX).
 * Deliberately has no studentId path variable -- like ChatController, it
 * always processes the upload on behalf of whoever is authenticated,
 * resolved server-side from the JWT.
 */
@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentService documentService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<DocumentUploadResponse> upload(
            Authentication authentication,
            @RequestParam("file") MultipartFile file
    ) throws IOException {
        DocumentUploadResponse response = documentService.processAppealUpload(
                authentication.getName(), file.getBytes(), file.getOriginalFilename());
        return ResponseEntity.ok(response);
    }
}
