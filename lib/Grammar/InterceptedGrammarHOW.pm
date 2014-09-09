use v6;

use Term::ANSIColor;


class InterceptedGrammarHOW is Metamodel::GrammarHOW {

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

    method onRegexEnter(Str $name, Int $indent) {
        # Issue the rule's/token's/regex's name
        say ('|  ' x $indent) ~ BOLD() ~ $name ~ RESET();
    }

    method onRegexExit(Str $name, Int $indent, Match $match) {
        say ('|  ' x $indent) ~ '* ' ~
            ($match ??
                colored('MATCH', 'white on_green') ~ self.summary($match, $indent) !!
                colored('FAIL', 'white on_red'));
    }

}

