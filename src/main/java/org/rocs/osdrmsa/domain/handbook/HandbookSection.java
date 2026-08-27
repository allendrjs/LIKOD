package org.rocs.osdrmsa.domain.handbook;

import jakarta.persistence.*;
import lombok.Data;
import org.rocs.osdrmsa.domain.department.Department;

/**
 * One chunk of the Student Handbook -- a single heading and the body text
 * under it, tagged with the department whose handbook it came from (JHS,
 * SHS, or COLLEGE). Each department's handbook is a self-contained document
 * (it has its own copy of the shared front matter -- founder bio, vision,
 * mission -- as well as its department-specific policies), so scoping
 * retrieval to a single department's sections is enough to avoid mixing up,
 * say, Junior High disciplinary rules with Senior High ones.
 *
 * Populated once at startup by HandbookSeeder from the markdown files in
 * src/main/resources/handbook/, and used as retrieval candidates by
 * ChatServiceImpl (via the same BM25 matcher AiAnalysisClient already uses
 * for Suggestion retrieval -- see AiAnalysisClient's javadoc).
 */
@Entity
@Data
@Table(name = "HANDBOOKSECTION")
public class HandbookSection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "HANDBOOKSECTIONID")
    private Long handbookSectionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "DEPARTMENT", nullable = false)
    private Department department;

    @Column(name = "TITLE")
    private String title;

    @Lob
    @Column(name = "BODY")
    private String body;

    @Column(name = "ORDERINDEX")
    private Integer orderIndex;
}
