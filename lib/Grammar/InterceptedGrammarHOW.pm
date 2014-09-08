use v6;

use Term::ANSIColor;


role InterceptedGrammarHOW {

    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }

    method summary(Match $match, Int $indent) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
    }

    # this is a crutch: can't seem to override and use callsame in Debugger...
    method announceRegexEnter(Str $name, Int $indent) {
        say ('|  ' x $indent) ~ BOLD() ~ $name ~ RESET();
    }

    method onRegexEnter(Str $name, Int $indent) {
        self.announceRegexEnter($name, $indent); # Issue the rule's/token's/regex's name
    }

}

