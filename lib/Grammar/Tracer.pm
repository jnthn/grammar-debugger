use v6;
use Term::ANSIColor;
# On Windows you might see "gibberish" - that's because the plain ol' cmd.exe
# doesn't understand ANSI escape codes which are to colour the output.
# There's a few options that you have in that case:
# - instead of ol' cmd.exe use a console that understands the codes
#   * Console2: http://www.hanselman.com/blog/Console2ABetterWindowsCommandPrompt.aspx
#   * AnsiCon: https://github.com/adoxa/ansicon
#   (see https://github.com/jnthn/grammar-debugger/pull/6)
# - OR you can use perl 5 to get proper output, by
#   * sending it through Win32::Console::ANSI like this: perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"
#   * stripping off all the escape codes like this:      perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"

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
