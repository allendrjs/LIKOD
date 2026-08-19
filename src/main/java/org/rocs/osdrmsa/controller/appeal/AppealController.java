package org.rocs.osdrmsa.controller.appeal;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.domain.appeal.Appeal;
import org.rocs.osdrmsa.dto.request.AppealFileRequest;
import org.rocs.osdrmsa.dto.request.AppealRequest;
import org.rocs.osdrmsa.dto.summary.AiSuggestionSummary;
import org.rocs.osdrmsa.service.appeal.AppealService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/appeals")
@RequiredArgsConstructor
public class AppealController {

    private final AppealService appealService;

    @GetMapping
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_PREFECT')")
    public List<Appeal> getAppeals(@RequestParam String status) {
        return appealService.getAppealsByStatus(status);
    }

    @GetMapping("/student/{studentId}")
    @PreAuthorize("hasAnyRole('ADMIN','PREFECT','STAFF') "
            + "or (hasRole('USER') and @access.isSelfStudent(#studentId))")
    public List<Appeal> getAppealsForStudent(@PathVariable String studentId) {
        return appealService.getAppealsByStudentId(studentId);
    }

    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Appeal> submitAppeal(@RequestBody AppealFileRequest request) {
        Appeal appeal = appealService.submitAppeal(
                request.recordId(), request.enrollmentId(), request.message(), request.documentId());
        return ResponseEntity.ok(appeal);
    }

    @GetMapping("/{id}/suggestions")
    @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_PREFECT')")
    public ResponseEntity<AiSuggestionSummary> getSuggestions(@PathVariable Long id) {
        AiSuggestionSummary suggestion = appealService.getSuggestionsForAppeal(id);
        return suggestion != null ? ResponseEntity.ok(suggestion) : ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasAuthority('ROLE_PREFECT')")
    public ResponseEntity<Void> approve(@PathVariable Long id, @RequestBody AppealRequest request) {

        appealService.approveAppeal(id, request.remarks());
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/deny")
    @PreAuthorize("hasAuthority('ROLE_PREFECT')")
    public ResponseEntity<Void> deny(@PathVariable Long id, @RequestBody AppealRequest request) {

        appealService.denyAppeal(id, request.remarks());
        return ResponseEntity.ok().build();
    }
}