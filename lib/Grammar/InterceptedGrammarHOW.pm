use v6;

use Term::ANSIColor;


role InterceptedGrammarHOW {

    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }

    method summary($match, $indent) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
    }

}

