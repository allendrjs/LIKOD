package org.rocs.osdrmsa.utils.ai;

import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * In-process AI Support Module helper -- OCR and keyword/BM25 matching both
 * run inside this JVM. No HTTP calls, no Python sidecar.
 *
 * Tesseract's native binary + tessdata are still required on the machine
 * running the backend (see the tesseract.* properties below); Tess4j is a
 * JNA wrapper that calls that binary directly instead of over HTTP to a
 * separate service.
 *
 * Keyword tokenization/normalization and BM25 scoring are hand-written
 * below (no OpenNLP/Lucene dependency, no trained models to download).
 * The actual requirement -- tokenize the appeal letter text, drop stopwords,
 * lightly normalize word endings, then rank a small bank of suggestion
 * templates by relevance -- doesn't need a full NLP pipeline to do well.
 */
@Component
public class AiAnalysisClient {

    private static final double BM25_K1 = 1.5;
    private static final double BM25_B = 0.75;
    private static final int MAX_MATCHES = 5;
    private static final int MAX_KEYWORDS = 15;

    private static final Set<String> STOPWORDS = Set.of(
            "the", "a", "an", "is", "was", "were", "be", "been", "being", "have", "has", "had",
            "do", "does", "did", "will", "would", "should", "could", "of", "in", "on", "at", "to",
            "for", "with", "by", "from", "as", "that", "this", "these", "those", "it", "its", "i",
            "you", "he", "she", "we", "they", "my", "your", "his", "her", "our", "their", "and",
            "or", "but", "if", "because", "so", "not", "no", "nor", "than", "then", "there", "here",
            "when", "where", "how", "what", "which", "who", "whom", "am", "are", "all", "any",
            "both", "each", "few", "more", "most", "other", "some", "such", "only", "own", "same",
            "also", "just", "very", "can", "about"
    );

    @Value("${tesseract.tessdata-path:}")
    private String tessdataPath;

    @Value("${tesseract.language:eng}")
    private String tesseractLanguage;

    public String ocr(byte[] fileBytes, String filename) {
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(fileBytes));
            if (image == null) {
                throw new IllegalStateException("The uploaded file (" + filename + ") isn't a readable image.");
            }

            Tesseract tesseract = new Tesseract();
            if (tessdataPath != null && !tessdataPath.isBlank()) {
                tesseract.setDatapath(tessdataPath);
            }
            tesseract.setLanguage(tesseractLanguage);

            return tesseract.doOCR(image);
        } catch (IOException e) {
            throw new IllegalStateException("Could not read the uploaded image for OCR.", e);
        } catch (TesseractException e) {
            throw new IllegalStateException(
                    "OCR failed. Make sure Tesseract is installed and tesseract.tessdata-path points at its tessdata folder.",
                    e);
        }
    }

    public AnalyzeResult analyze(String text, List<SuggestionCandidate> suggestions) {
        if (text == null || text.isBlank() || suggestions == null || suggestions.isEmpty()) {
            return new AnalyzeResult(List.of(), List.of());
        }

        List<String> queryTokens = tokenize(text);
        if (queryTokens.isEmpty()) {
            return new AnalyzeResult(List.of(), List.of());
        }

        Map<Long, List<String>> docTokensById = new LinkedHashMap<>();
        for (SuggestionCandidate candidate : suggestions) {
            docTokensById.put(candidate.suggestionId(), tokenize(candidate.text()));
        }

        double avgDocLen = docTokensById.values().stream()
                .mapToInt(List::size)
                .average()
                .orElse(0);

        Set<String> uniqueQueryTerms = new LinkedHashSet<>(queryTokens);

        Map<String, Integer> docFrequency = new HashMap<>();
        for (String term : uniqueQueryTerms) {
            long count = docTokensById.values().stream().filter(doc -> doc.contains(term)).count();
            docFrequency.put(term, (int) count);
        }

        int corpusSize = docTokensById.size();

        List<SuggestionMatch> matches = new ArrayList<>();
        for (SuggestionCandidate candidate : suggestions) {
            List<String> docTokens = docTokensById.get(candidate.suggestionId());
            double score = bm25Score(uniqueQueryTerms, docTokens, docFrequency, corpusSize, avgDocLen);
            if (score > 0) {
                matches.add(new SuggestionMatch(candidate.suggestionId(), score));
            }
        }

        matches.sort((a, b) -> Double.compare(b.score(), a.score()));
        List<SuggestionMatch> topMatches = matches.stream().limit(MAX_MATCHES).toList();

        List<String> keywords = queryTokens.stream()
                .distinct()
                .limit(MAX_KEYWORDS)
                .toList();

        return new AnalyzeResult(keywords, topMatches);
    }

    private double bm25Score(Set<String> queryTerms, List<String> docTokens, Map<String, Integer> docFrequency,
                              int corpusSize, double avgDocLen) {
        if (docTokens.isEmpty()) {
            return 0;
        }

        Map<String, Long> termFrequency = docTokens.stream()
                .collect(Collectors.groupingBy(t -> t, Collectors.counting()));

        double score = 0;
        int docLen = docTokens.size();

        for (String term : queryTerms) {
            long tf = termFrequency.getOrDefault(term, 0L);
            if (tf == 0) {
                continue;
            }

            int n = docFrequency.getOrDefault(term, 0);
            double idf = Math.log(1 + (corpusSize - n + 0.5) / (n + 0.5));

            double numerator = tf * (BM25_K1 + 1);
            double denominator = tf + BM25_K1 * (1 - BM25_B + BM25_B * (docLen / avgDocLen));

            score += idf * (numerator / denominator);
        }

        return score;
    }

    private List<String> tokenize(String text) {
        String[] rawWords = text.toLowerCase(Locale.ROOT).split("[^a-z]+");
        List<String> tokens = new ArrayList<>();
        for (String word : rawWords) {
            if (word.length() < 3 || STOPWORDS.contains(word)) {
                continue;
            }
            tokens.add(LightStemmer.stem(word));
        }
        return tokens;
    }

    public record SuggestionCandidate(Long suggestionId, String text) {
    }

    public record SuggestionMatch(Long suggestionId, double score) {
    }

    public record AnalyzeResult(List<String> keywords, List<SuggestionMatch> matches) {
    }
}
