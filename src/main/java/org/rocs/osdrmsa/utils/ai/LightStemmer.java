package org.rocs.osdrmsa.utils.ai;

/**
 * Small, dependency-free suffix-stripping normalizer for English keyword
 * matching. This is not a full implementation of Porter's stemming
 * algorithm -- it only strips the handful of endings that matter for the
 * AI Support Module's use case (matching an appeal letter's wording against
 * a small bank of suggestion templates), which keeps it easy to read and
 * verify without pulling in an NLP library or downloading trained models.
 */
final class LightStemmer {

    private LightStemmer() {
    }

    static String stem(String word) {
        if (word.length() <= 3) {
            return word;
        }

        if (word.endsWith("ies") && word.length() > 4) {
            return word.substring(0, word.length() - 3) + "y";
        }
        if (word.endsWith("edly") && word.length() > 6) {
            return word.substring(0, word.length() - 4);
        }
        if (word.endsWith("ing") && word.length() > 5) {
            return word.substring(0, word.length() - 3);
        }
        if (word.endsWith("ment") && word.length() > 6) {
            return word.substring(0, word.length() - 4);
        }
        if (word.endsWith("ness") && word.length() > 6) {
            return word.substring(0, word.length() - 4);
        }
        if (word.endsWith("tion") && word.length() > 6) {
            return word.substring(0, word.length() - 4);
        }
        if (word.endsWith("ed") && word.length() > 4) {
            return word.substring(0, word.length() - 2);
        }
        if (word.endsWith("ly") && word.length() > 4) {
            return word.substring(0, word.length() - 2);
        }
        if (word.endsWith("es") && word.length() > 4) {
            return word.substring(0, word.length() - 2);
        }
        if (word.endsWith("s") && !word.endsWith("ss") && word.length() > 3) {
            return word.substring(0, word.length() - 1);
        }

        return word;
    }
}
