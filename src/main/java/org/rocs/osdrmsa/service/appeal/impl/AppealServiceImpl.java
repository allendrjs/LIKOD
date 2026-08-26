package org.rocs.osdrmsa.service.appeal.impl;

import org.rocs.osdrmsa.domain.appeal.Appeal;
import org.rocs.osdrmsa.domain.document.Document;
import org.rocs.osdrmsa.domain.enrollment.Enrollment;
import org.rocs.osdrmsa.domain.record.Record;
import org.rocs.osdrmsa.domain.record.RecordStatus;
import org.rocs.osdrmsa.domain.suggestion.GeneratedSuggestion;
import org.rocs.osdrmsa.dto.summary.AiSuggestionSummary;
import org.rocs.osdrmsa.repository.appeal.AppealRepository;
import org.rocs.osdrmsa.repository.document.DocumentRepository;
import org.rocs.osdrmsa.repository.enrollment.EnrollmentRepository;
import org.rocs.osdrmsa.repository.record.RecordRepository;
import org.rocs.osdrmsa.repository.suggestion.GeneratedSuggestionRepository;
import org.rocs.osdrmsa.service.appeal.AppealService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.NoSuchElementException;

@Service
public class AppealServiceImpl implements AppealService {

    private final AppealRepository appealRepository;
    private final RecordRepository recordRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final DocumentRepository documentRepository;
    private final GeneratedSuggestionRepository generatedSuggestionRepository;

    public AppealServiceImpl(AppealRepository appealRepository, RecordRepository recordRepository,
                              EnrollmentRepository enrollmentRepository, DocumentRepository documentRepository,
                              GeneratedSuggestionRepository generatedSuggestionRepository) {
        this.appealRepository = appealRepository;
        this.recordRepository = recordRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.documentRepository = documentRepository;
        this.generatedSuggestionRepository = generatedSuggestionRepository;
    }

    @Override
    public List<Appeal> getAppealsByStatus(String status) {
        return appealRepository.findByStatus(status);
    }

    @Override
    public List<Appeal> getAppealsByStudentId(String studentId) {
        return appealRepository.findByEnrollmentStudentStudentId(studentId);
    }

    @Override
    public Appeal submitAppeal(Long recordId, Long enrollmentId, String message, Long documentId) {
        Record record = recordRepository.findById(recordId)
                .orElseThrow(() -> new NoSuchElementException("Record not found."));
        Enrollment enrollment = enrollmentRepository.findById(enrollmentId)
                .orElseThrow(() -> new NoSuchElementException("Enrollment not found."));

        if (message == null || message.trim().isEmpty()) {
            throw new IllegalArgumentException("Appeal message is required.");
        }

        if (record.getStatus() != RecordStatus.PENDING) {
            throw new IllegalStateException("This offense has already been appealed and cannot be appealed again.");
        }

        if (appealRepository.existsByRecord_RecordId(recordId)) {
            throw new IllegalStateException("This offense has already been appealed and cannot be appealed again.");
        }

        Appeal appeal = new Appeal();
        appeal.setRecord(record);
        appeal.setEnrollment(enrollment);
        appeal.setMessage(message);
        appeal.setDateFiled(LocalDate.now());
        appeal.setStatus("PENDING");

        if (documentId != null) {
            Document document = documentRepository.findById(documentId)
                    .orElseThrow(() -> new NoSuchElementException("Uploaded document not found."));
            appeal.setDocument(document);
        }

        Appeal savedAppeal = appealRepository.save(appeal);

        record.setStatus(RecordStatus.APPEALED);
        recordRepository.save(record);

        return savedAppeal;
    }

    @Override
    public void approveAppeal(Long appealId, String remarks) {
        Appeal appeal = appealRepository.findById(appealId).orElseThrow(() -> new RuntimeException("Appeal not found."));

        appeal.setStatus("APPROVED");
        appeal.setRemarks(remarks);
        appeal.setDateProcessed(LocalDate.now());

        appealRepository.save(appeal);
    }

    @Override
    public void denyAppeal(Long appealId, String remarks) {
        if (remarks == null || remarks.trim().isEmpty()) {
            throw new IllegalArgumentException("Denial remarks are required.");
        }

        Appeal appeal = appealRepository.findById(appealId).orElseThrow(() -> new RuntimeException("Appeal not found."));

        appeal.setStatus("DENIED");
        appeal.setRemarks(remarks);
        appeal.setDateProcessed(LocalDate.now());

        appealRepository.save(appeal);
    }

    @Override
    public AiSuggestionSummary getSuggestionsForAppeal(Long appealId) {
        Appeal appeal = appealRepository.findById(appealId)
                .orElseThrow(() -> new NoSuchElementException("Appeal not found."));

        if (appeal.getDocument() == null) {
            return null;
        }

        List<GeneratedSuggestion> generated =
                generatedSuggestionRepository.findByDocumentDocumentId(appeal.getDocument().getDocumentId());

        // Ollama generates one case-specific note per upload, but this
        // takes the most recent in case generation is ever re-run for the
        // same document (e.g. a future "regenerate" action).
        return generated.stream()
                .filter(gs -> gs.getGeneratedText() != null)
                .max(Comparator.comparing(
                        GeneratedSuggestion::getGeneratedAt, Comparator.nullsFirst(Comparator.naturalOrder())))
                .map(gs -> new AiSuggestionSummary(gs.getGeneratedText(), gs.getGeneratedAt()))
                .orElse(null);
    }
}