# Grammar::Debugger
This module provides a simple debugger for grammars. Just use it:

    use Grammar::Debugger;

And any grammar in the lexical scope of the use satement will
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

----
#### A note on Windows:
On Windows you might find yourself annoyed by some gibberish like
```
←[1mTOP←[0m
|  ←[1mfoo←[0m
|  * ←[37;42mMATCH←[0m←[37m "x"←[0m
* ←[37;42mMATCH←[0m←[37m "x"←[0m
```
That's because the plain ol' cmd.exe doesn't understand ANSI escape codes which are to colour the output.
In that case your options are:
- Accept it and try to become Neo, he who "sees through"...
- Wait for a perl6 equivalent of Win32::Console::ANSI
- Wait for "colour-stripped" versions of Debugger and Tracer
- Or, instead of ol' cmd.exe, use a console that understands the codes (ref #6)
    * [Console2](http://www.hanselman.com/blog/Console2ABetterWindowsCommandPrompt.aspx)
    * [AnsiCon](https://github.com/adoxa/ansicon)
    
- Or you can use perl5 to get proper output, with
    * either `perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"`
      (have perl5's Win32::Console::ANSI handle it)
    * or `perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"`
      (just strip 'em off)
 
----

# Bugs? Ideas?
Please [file them in GitHub issues](https://github.com/jnthn/grammar-debugger/issues/new).
