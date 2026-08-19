package org.rocs.osdrmsa.repository.suggestion;

import org.rocs.osdrmsa.domain.suggestion.Suggestion;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SuggestionRepository extends JpaRepository<Suggestion, Long> {
}
