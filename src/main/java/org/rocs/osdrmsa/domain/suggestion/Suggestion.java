package org.rocs.osdrmsa.domain.suggestion;

import jakarta.persistence.*;
import lombok.Data;

/**
 * A predefined suggestion template (Table 15, Suggestion Table in the thesis
 * paper). These are seeded ahead of time and used as retrieval hints: an
 * in-process BM25 keyword matcher picks the most relevant templates for a
 * given uploaded document, and those hints (plus the letter text and the
 * student's case history) are passed to Ollama, which generates the actual
 * case-specific suggestion text (see GeneratedSuggestion).
 */
@Entity
@Data
@Table(name = "SUGGESTION")
public class Suggestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SUGGESTIONID")
    private Long suggestionId;

    @Column(name = "TYPE")
    private String type;

    @Lob
    @Column(name = "SUGGESTIONTEXT")
    private String suggestionText;
}
