package org.rocs.osdrmsa.service.document.impl;

import lombok.RequiredArgsConstructor;
import org.apache.tika.Tika;
import org.rocs.osdrmsa.domain.document.Document;
import org.rocs.osdrmsa.domain.login.Login;
import org.rocs.osdrmsa.domain.person.student.Student;
import org.rocs.osdrmsa.domain.record.Record;
import org.rocs.osdrmsa.domain.suggestion.GeneratedSuggestion;
import org.rocs.osdrmsa.domain.suggestion.Suggestion;
import org.rocs.osdrmsa.dto.response.DocumentUploadResponse;
import org.rocs.osdrmsa.dto.summary.ChatMessageDto;
import org.rocs.osdrmsa.repository.document.DocumentRepository;
import org.rocs.osdrmsa.repository.login.LoginRepository;
import org.rocs.osdrmsa.repository.record.RecordRepository;
import org.rocs.osdrmsa.repository.student.StudentRepository;
import org.rocs.osdrmsa.repository.suggestion.GeneratedSuggestionRepository;
import org.rocs.osdrmsa.repository.suggestion.SuggestionRepository;
import org.rocs.osdrmsa.service.document.DocumentService;
import org.rocs.osdrmsa.utils.ai.AiAnalysisClient;
import org.rocs.osdrmsa.utils.ai.OllamaClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DocumentServiceImpl implements DocumentService {

    private static final Logger log = LoggerFactory.getLogger(DocumentServiceImpl.class);

    private static final List<String> IMAGE_EXTENSIONS =
            List.of("jpg", "jpeg", "png", "bmp", "tif", "tiff", "gif");

    private static final int MAX_RECENT_RECORDS = 10;
    private static final int MAX_RETRIEVED_HINTS = 3;

    private static final String SYSTEM_PROMPT = """
            You are the AI Support Module inside the Rogationist College Office for Student Discipline \
            system. Your job is to write a short, neutral, informational note that helps a Prefect review \
            an appeal letter a student just submitted -- you are NOT deciding the appeal and must never \
            state or imply what the outcome should be.

            Rules you must follow:
            1. Base your note only on the LETTER TEXT, CASE HISTORY, and POLICY HINTS given to you below. \
            Never invent offenses, dates, or facts that are not present in that information.
            2. Do not approve, deny, or recommend a specific disciplinary action. Do not use words like \
            "should be approved" or "should be denied."
            3. If the case history shows repeat violations, or the letter lacks supporting detail, you may \
            neutrally point that out as something worth the Prefect's attention -- but always as an \
            observation, not a conclusion.
            4. Keep the note to 2-4 sentences, plain language, no headers or bullet points.
            5. If the letter text is too short or unclear to say anything useful, say so plainly instead of \
            guessing.""";

    private final LoginRepository loginRepository;
    private final StudentRepository studentRepository;
    private final DocumentRepository documentRepository;
    private final RecordRepository recordRepository;
    private final SuggestionRepository suggestionRepository;
    private final GeneratedSuggestionRepository generatedSuggestionRepository;
    private final AiAnalysisClient aiAnalysisClient;
    private final OllamaClient ollamaClient;

    private final Tika tika = new Tika();

    @Override
    public DocumentUploadResponse processAppealUpload(String username, byte[] fileBytes, String filename) {
        if (fileBytes == null || fileBytes.length == 0) {
            throw new IllegalArgumentException("Uploaded file is empty.");
        }

        Student student = resolveStudent(username);

        String extractedText = extractText(fileBytes, filename);

        Document document = new Document();
        document.setStudent(student);
        document.setExtractedText(extractedText);
        document = documentRepository.save(document);

        String aiSuggestion = generateCaseSuggestion(document, student, extractedText);

        return new DocumentUploadResponse(document.getDocumentId(), extractedText, aiSuggestion);
    }

    private Student resolveStudent(String username) {
        Login login = loginRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalStateException("No account found for the current session."));

        if (login.getPerson() == null) {
            throw new IllegalStateException("This account isn't linked to a student profile.");
        }

        return studentRepository.findByPerson_PersonId(login.getPerson().getPersonId())
                .orElseThrow(() -> new IllegalStateException("No student profile found for the current session."));
    }

    /**
     * Generates a case-specific note via Ollama, grounded in the letter's own
     * text, this student's real violation history, and the most relevant
     * entries from the Suggestion table (used only as retrieval context --
     * a lightweight stand-in for real Student Handbook sections until those
     * are ingested). Deliberately never lets an AI failure block the upload
     * or appeal filing -- if Ollama is unreachable or errors, the document
     * still saves and the student can still file their appeal; they just
     * won't have a generated note for that upload.
     */
    private String generateCaseSuggestion(Document document, Student student, String extractedText) {
        if (extractedText == null || extractedText.isBlank()) {
            return null;
        }

        try {
            String caseHistory = buildCaseHistorySummary(student);
            String policyHints = buildRetrievedHints(extractedText);

            String userPrompt = "LETTER TEXT:\n" + extractedText.trim() +
                    "\n\n" + caseHistory +
                    "\n\n" + policyHints;

            List<ChatMessageDto> messages = List.of(
                    new ChatMessageDto("system", SYSTEM_PROMPT),
                    new ChatMessageDto("user", userPrompt)
            );

            String generatedText = ollamaClient.chat(messages);

            GeneratedSuggestion generated = new GeneratedSuggestion();
            generated.setDocument(document);
            generated.setGeneratedText(generatedText);
            generated.setGeneratedAt(LocalDateTime.now());
            generatedSuggestionRepository.save(generated);

            return generatedText;
        } catch (Exception e) {
            log.warn("AI Support Module suggestion generation failed for document {}: {}",
                    document.getDocumentId(), e.getMessage());
            return null;
        }
    }

    private String buildCaseHistorySummary(Student student) {
        List<Record> records = recordRepository.findByEnrollmentStudentStudentId(student.getStudentId());

        StringBuilder sb = new StringBuilder("CASE HISTORY (");
        sb.append(records.size()).append(" total violation");
        sb.append(records.size() == 1 ? "" : "s");
        if (records.size() > MAX_RECENT_RECORDS) {
            sb.append(", showing ").append(MAX_RECENT_RECORDS).append(" most recent");
        }
        sb.append(" on file):\n");

        if (records.isEmpty()) {
            sb.append("- No prior disciplinary records on file. This would be the student's first.\n");
            return sb.toString();
        }

        records.stream()
                .sorted(Comparator.comparing(Record::getDateOfViolation, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(MAX_RECENT_RECORDS)
                .forEach(r -> sb.append("- ")
                        .append(r.getOffense() != null ? r.getOffense().getOffense() : "Unknown offense")
                        .append(", filed ").append(r.getDateOfViolation())
                        .append(", status ").append(r.getStatus())
                        .append("\n"));

        return sb.toString();
    }

    /**
     * BM25-retrieves the top few Suggestion rows most relevant to the
     * letter's text, to use as grounding context for the LLM -- not
     * returned to anyone directly. This is the retrieval half of a small
     * retrieval-augmented-generation setup; swapping in real Student
     * Handbook sections here later (instead of the 10 seeded one-liners)
     * doesn't require touching anything else in this class.
     */
    private String buildRetrievedHints(String extractedText) {
        List<Suggestion> allSuggestions = suggestionRepository.findAll();
        if (allSuggestions.isEmpty()) {
            return "POLICY HINTS: none available.";
        }

        List<AiAnalysisClient.SuggestionCandidate> candidates = allSuggestions.stream()
                .map(s -> new AiAnalysisClient.SuggestionCandidate(s.getSuggestionId(), s.getSuggestionText()))
                .toList();

        AiAnalysisClient.AnalyzeResult result = aiAnalysisClient.analyze(extractedText, candidates);

        Map<Long, Suggestion> byId = allSuggestions.stream()
                .collect(Collectors.toMap(Suggestion::getSuggestionId, s -> s, (a, b) -> a, HashMap::new));

        List<String> hints = new ArrayList<>();
        result.matches().stream()
                .limit(MAX_RETRIEVED_HINTS)
                .forEach(match -> {
                    Suggestion suggestion = byId.get(match.suggestionId());
                    if (suggestion != null) {
                        hints.add("- " + suggestion.getSuggestionText());
                    }
                });

        if (hints.isEmpty()) {
            return "POLICY HINTS: none matched this letter closely enough to be useful.";
        }

        return "POLICY HINTS (general guidance, not the full Student Handbook):\n" + String.join("\n", hints);
    }

    private String extractText(byte[] fileBytes, String filename) {
        String extension = extension(filename);

        if (IMAGE_EXTENSIONS.contains(extension)) {
            return aiAnalysisClient.ocr(fileBytes, filename);
        }

        try {
            return tika.parseToString(new ByteArrayInputStream(fileBytes));
        } catch (Exception e) {
            throw new IllegalStateException("Could not extract text from the uploaded file.", e);
        }
    }

    private String extension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "";
        }
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
    }
}
