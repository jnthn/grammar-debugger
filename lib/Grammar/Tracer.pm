use v6;

use Term::ANSIColor;
use Grammar::InterceptedGrammarHOW;


my class TracedGrammarHOW is InterceptedGrammarHOW is export {

    method onRegexEnter(Str $name, Int $indent) {
        say ('|  ' x $indent) ~ BOLD() ~ $name ~ RESET();
    }

    method onRegexExit(Str $name, Int $indent, Match $match) {
        say ('|  ' x $indent) ~ '* ' ~
            ($match ??
                colored('MATCH', 'white on_green') ~ self.summary($indent, $match) !!
                colored('FAIL', 'white on_red'));
    }

    method summary(Int $indent, Match $match) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = TracedGrammarHOW;
