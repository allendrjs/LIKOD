package org.rocs.osdrmsa.repository.suggestion;

import org.rocs.osdrmsa.domain.suggestion.GeneratedSuggestion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GeneratedSuggestionRepository extends JpaRepository<GeneratedSuggestion, Long> {

    List<GeneratedSuggestion> findByDocumentDocumentId(Long documentId);
}
