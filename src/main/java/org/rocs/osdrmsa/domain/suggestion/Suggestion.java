package org.rocs.osdrmsa.domain.suggestion;

import jakarta.persistence.*;
import lombok.Data;

/**
 * A predefined suggestion template (Table 15, Suggestion Table in the thesis
 * paper). These are seeded ahead of time -- the AI Support Module does not
 * generate new suggestion text on the fly, it only decides which existing
 * templates are relevant to a given uploaded document via keyword/policy
 * matching (spaCy + BM25).
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
