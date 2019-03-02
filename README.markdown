# Grammar::Debugger [![Build Status](https://travis-ci.org/jnthn/grammar-debugger.svg?branch=master)](https://travis-ci.org/jnthn/grammar-debugger)
This module provides a simple debugger for grammars. Just `use` it:

    use Grammar::Debugger;

And any grammar in the lexical scope of the `use` statement will
automatically have debugging enabled. The debugger will break
execution when you first enter the grammar, and provide a prompt.
Type "h" for a list of commands.

If you are debugging a grammar and want to set up breakpoints in
code rather than entering them manually at the debug prompt, you
can apply the breakpoint trait to any rule:

    token name is breakpoint { \w+ [\h+ \w+]* }

If you want to conditionally break, you can also do something like:

    token name will break { $^m eq 'Russia' } { \w+ [\h+ \w+]* }

Which will only break after the name rule has matched "Russia".

# Grammar::Tracer
This gives similar output to Grammar::Debugger, but just runs through
the whole grammar without stopping until it is successful or fails.
Once again, after a use:

    use Grammar::Tracer;

It will apply to any grammars in the lexical scope of the use statement.

The default behavior of this module is to output traces for all grammars as they are parsed.  The function GrammarTraceMode() is exported to allow this behavior to be changed at runtime.

    GrammarTraceMode(Always) # Default, always output full traces
    GrammarTraceMode(Never)  # Disable all Grammar Tracing

# Bugs? Ideas?
Please file them in [GitHub issues](https://github.com/jnthn/grammar-debugger/issues).
