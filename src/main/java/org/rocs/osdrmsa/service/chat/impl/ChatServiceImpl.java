package org.rocs.osdrmsa.service.chat.impl;

import lombok.RequiredArgsConstructor;
import org.rocs.osdrmsa.domain.appeal.Appeal;
import org.rocs.osdrmsa.domain.department.Department;
import org.rocs.osdrmsa.domain.enrollment.Enrollment;
import org.rocs.osdrmsa.domain.handbook.HandbookSection;
import org.rocs.osdrmsa.domain.login.Login;
import org.rocs.osdrmsa.domain.person.student.Student;
import org.rocs.osdrmsa.domain.record.Record;
import org.rocs.osdrmsa.dto.request.ChatRequest;
import org.rocs.osdrmsa.dto.response.ChatResponse;
import org.rocs.osdrmsa.dto.summary.ChatMessageDto;
import org.rocs.osdrmsa.repository.appeal.AppealRepository;
import org.rocs.osdrmsa.repository.enrollment.EnrollmentRepository;
import org.rocs.osdrmsa.repository.handbook.HandbookSectionRepository;
import org.rocs.osdrmsa.repository.login.LoginRepository;
import org.rocs.osdrmsa.repository.record.RecordRepository;
import org.rocs.osdrmsa.repository.student.StudentRepository;
import org.rocs.osdrmsa.service.chat.ChatService;
import org.rocs.osdrmsa.utils.ai.AiAnalysisClient;
import org.rocs.osdrmsa.utils.ai.OllamaClient;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

    private static final int MAX_RECENT_ITEMS = 10;
    private static final int MAX_HANDBOOK_HINTS = 4;

    private static final String SYSTEM_PROMPT = """
            You are the RC-OSD Assistant, a support chatbot inside the Rogationist College Office for \
            Student Discipline mobile app. You help the currently logged-in student understand their own \
            disciplinary records, appeal history, how to file an appeal, and the rules in their own \
            department's Student Handbook.

            Rules you must follow:
            1. Only use the student information given to you in the CONTEXT block below. Never invent \
            offenses, dates, statuses, or details that are not explicitly present in CONTEXT.
            2. For questions about school rules or policy, only use the HANDBOOK CONTEXT block below. Never \
            invent a rule, fee, or procedure that isn't in it. When you use a HANDBOOK CONTEXT excerpt, name \
            the section it came from (e.g. "Under 'Dress Code and Grooming'..."). If HANDBOOK CONTEXT says \
            nothing matched the question, say plainly that it isn't covered in the handbook and suggest the \
            student contact the Office for Student Discipline -- do not guess.
            3. Do not give legal advice, and do not judge whether the student is guilty or innocent of an offense.
            4. A student can file an appeal on a PENDING offense from that offense's detail screen in the app.
            5. If asked about other students, or about a disciplinary decision that hasn't been made yet, say \
            you can't help with that and suggest the student contact the Office for Student Discipline directly.
            6. Keep answers short and easy to read on a phone screen.""";

    private final LoginRepository loginRepository;
    private final StudentRepository studentRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final RecordRepository recordRepository;
    private final AppealRepository appealRepository;
    private final HandbookSectionRepository handbookSectionRepository;
    private final AiAnalysisClient aiAnalysisClient;
    private final OllamaClient ollamaClient;

    @Override
    public ChatResponse ask(String username, ChatRequest request) {
        if (request == null || request.message() == null || request.message().isBlank()) {
            throw new IllegalArgumentException("Message is required.");
        }

        Student student = resolveStudent(username);
        String context = buildContext(student);
        String handbookContext = buildHandbookContext(resolveDepartment(student), request.message().trim());

        List<ChatMessageDto> messages = new ArrayList<>();
        messages.add(new ChatMessageDto("system", SYSTEM_PROMPT + "\n\n" + context + "\n\n" + handbookContext));

        if (request.history() != null) {
            messages.addAll(request.history());
        }
        messages.add(new ChatMessageDto("user", request.message().trim()));

        String reply = ollamaClient.chat(messages);

        return new ChatResponse(reply, LocalDateTime.now());
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
     * Looks up the student's own department (JHS/SHS/College) from their
     * latest enrollment, so handbook retrieval can be scoped to only their
     * own department's handbook -- a JHS student should never get SHS- or
     * College-specific rules back, and vice versa.
     */
    private Department resolveDepartment(Student student) {
        return enrollmentRepository
                .findTopByStudentStudentIdOrderBySchoolYearDesc(student.getStudentId())
                .map(Enrollment::getDepartment)
                .orElse(null);
    }

    /**
     * BM25-retrieves the top few Student Handbook sections -- scoped to the
     * student's own department only -- most relevant to their question, for
     * use as grounding context for the LLM. Reuses the same in-process BM25
     * matcher AiAnalysisClient already provides for Suggestion retrieval
     * (see its javadoc); this is the "real Student Handbook sections" swap
     * that DocumentServiceImpl's buildRetrievedHints anticipated.
     */
    private String buildHandbookContext(Department department, String query) {
        if (department == null) {
            return "HANDBOOK CONTEXT: no department is on file for this student, so no handbook sections could be retrieved.";
        }

        List<HandbookSection> sections = handbookSectionRepository.findByDepartment(department);
        if (sections.isEmpty()) {
            return "HANDBOOK CONTEXT: none available.";
        }

        List<AiAnalysisClient.Candidate> candidates = sections.stream()
                .map(s -> new AiAnalysisClient.Candidate(s.getHandbookSectionId(), s.getTitle() + "\n" + s.getBody()))
                .toList();

        AiAnalysisClient.AnalyzeResult result = aiAnalysisClient.analyze(query, candidates);

        Map<Long, HandbookSection> byId = sections.stream()
                .collect(Collectors.toMap(HandbookSection::getHandbookSectionId, s -> s, (a, b) -> a, HashMap::new));

        List<String> hints = new ArrayList<>();
        result.matches().stream()
                .limit(MAX_HANDBOOK_HINTS)
                .forEach(match -> {
                    HandbookSection section = byId.get(match.id());
                    if (section != null) {
                        hints.add("### " + section.getTitle() + "\n" + section.getBody());
                    }
                });

        if (hints.isEmpty()) {
            return "HANDBOOK CONTEXT: nothing in the " + department.getDisplayName()
                    + " Student Handbook matched this question closely enough to be useful.";
        }

        return "HANDBOOK CONTEXT (excerpts from the " + department.getDisplayName()
                + " Student Handbook -- cite the section name when you use one):\n\n" + String.join("\n\n", hints);
    }

    private String buildContext(Student student) {
        StringBuilder sb = new StringBuilder();
        sb.append("CONTEXT:\n");
        sb.append("Student ID: ").append(student.getStudentId()).append("\n");

        Enrollment enrollment = enrollmentRepository
                .findTopByStudentStudentIdOrderBySchoolYearDesc(student.getStudentId())
                .orElse(null);

        if (enrollment != null) {
            sb.append("Current Enrollment: ")
                    .append(enrollment.getSchoolYear()).append(", ")
                    .append(enrollment.getStudentLevel()).append(", Section ")
                    .append(enrollment.getSection()).append("\n");
            if (enrollment.getDisciplinaryStatus() != null) {
                sb.append("Disciplinary Status: ")
                        .append(enrollment.getDisciplinaryStatus().getStatus()).append("\n");
            }
        } else {
            sb.append("Current Enrollment: none on file\n");
        }

        List<Record> records = recordRepository.findByEnrollmentStudentStudentId(student.getStudentId());
        appendRecords(sb, records);

        List<Appeal> appeals = appealRepository.findByEnrollmentStudentStudentId(student.getStudentId());
        appendAppeals(sb, appeals);

        return sb.toString();
    }

    private void appendRecords(StringBuilder sb, List<Record> records) {
        sb.append("\nDisciplinary Records (").append(records.size()).append(" total");
        if (records.size() > MAX_RECENT_ITEMS) {
            sb.append(", showing ").append(MAX_RECENT_ITEMS).append(" most recent");
        }
        sb.append("):\n");

        if (records.isEmpty()) {
            sb.append("- No disciplinary records on file.\n");
            return;
        }

        records.stream()
                .sorted(Comparator.comparing(Record::getDateOfViolation, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(MAX_RECENT_ITEMS)
                .forEach(r -> sb.append("- Record #").append(r.getRecordId())
                        .append(": ").append(r.getOffense() != null ? r.getOffense().getOffense() : "Unknown offense")
                        .append(", filed ").append(r.getDateOfViolation())
                        .append(", status ").append(r.getStatus())
                        .append("\n"));
    }

    private void appendAppeals(StringBuilder sb, List<Appeal> appeals) {
        sb.append("\nAppeals (").append(appeals.size()).append(" total");
        if (appeals.size() > MAX_RECENT_ITEMS) {
            sb.append(", showing ").append(MAX_RECENT_ITEMS).append(" most recent");
        }
        sb.append("):\n");

        if (appeals.isEmpty()) {
            sb.append("- No appeals on file.\n");
            return;
        }

        appeals.stream()
                .sorted(Comparator.comparing(Appeal::getDateFiled, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(MAX_RECENT_ITEMS)
                .forEach(a -> sb.append("- Appeal #").append(a.getAppealId())
                        .append(" for ").append(a.getRecord() != null && a.getRecord().getOffense() != null
                                ? a.getRecord().getOffense().getOffense() : "an offense")
                        .append(", filed ").append(a.getDateFiled())
                        .append(", status ").append(a.getStatus())
                        .append("\n"));
    }
}
