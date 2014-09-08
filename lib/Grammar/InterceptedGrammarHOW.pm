use v6;

role InterceptedGrammarHOW {

    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }

}

