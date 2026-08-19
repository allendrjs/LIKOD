package org.rocs.osdrmsa.domain.suggestion;

import jakarta.persistence.*;
import lombok.Data;
import org.rocs.osdrmsa.domain.document.Document;

import java.time.LocalDateTime;

/**
 * The AI Support Module's output for a specific uploaded Document (Table 16,
 * Generated Suggestion Table in the thesis paper). `generatedText` holds the
 * case-specific write-up Ollama produced for this letter -- grounded in the
 * letter's own text, the student's real violation history, and the most
 * relevant entries from the Suggestion table (used as retrieval context, not
 * picked as-is). `suggestion` is kept nullable for backward compatibility
 * with the earlier fixed-template-matching design; new rows leave it null.
 */
@Entity
@Data
@Table(name = "GENERATEDSUGGESTION")
public class GeneratedSuggestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "GENERATEDSUGGESTIONID")
    private Long generatedSuggestionId;

    @ManyToOne
    @JoinColumn(name = "SUGGESTIONID")
    private Suggestion suggestion;

    @ManyToOne
    @JoinColumn(name = "DOCUMENTID")
    private Document document;

    @Lob
    @Column(name = "GENERATEDTEXT")
    private String generatedText;

    @Column(name = "GENERATEDAT")
    private LocalDateTime generatedAt;
}
