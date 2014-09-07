module Grammar::Test::Helper;

use Term::ANSIColor;

enum StdStream is export <IN OUT ERR>;


class RemoteControl is export {

    class Out-capture {
        has StdStream     $.stdStream;
        has RemoteControl $.rc;
        method print(*@args) { $.rc.record($.stdStream, 'print', @args) }
        method flush(*@args) { $.rc.record($.stdStream, 'flush', @args) }
    }

    class In-capture {
        has                 @.answers;
        has RemoteControl   $.rc;
        method get(*@args) {
            my $out = @.answers ?? shift @.answers !! '';
            $.rc.record(IN, 'get', :$out, @args);
            return $out;
        }
    }

    has @!calls = ().hash;

    method calls() {
        return @!calls;
    }

    method record(StdStream:D $stdStream, Str:D $which, :$out?, *@args) {
        my $entry = {
            when  => now,
            where => $stdStream,
            which => $which,
            args  => @args,
            out   => $out,
        };
        $entry does role {
            method Str(Bool :$colorstrip = False) {
                self.perl(:$colorstrip);
            }
            method perl(Bool :$colorstrip = False) {
                '$*' ~ self<where> ~ '.' ~ self<which>
                    ~ ( self<args>.elems
                        ?? '(' ~ self<args>.map({ ($colorstrip ?? colorstrip($_) !! $_).perl }) ~ ');' 
                        !! ';' )
                    ~ ( self<out>.defined 
                        ?? ' # ~> ' ~ self<out>.perl
                        !! '' )
                    ~ '        # @' ~ self<when>
                    ~ "\n"
            }
        };
        @!calls.push($entry);
    }

    has $!result;   # should not be set via constructor
    method result { $!result }

    method do (|args) {
        (self // RemoteControl.new)!do(|args);
    }

    method !do (&block, :@answers = ()) {
        my ($oldOUT, $oldERR, $oldIN) = ($*OUT, $*ERR, $*IN);
        ($*OUT, $*ERR, $*IN) = Out-capture.new(:stdStream(OUT), :rc(self)), Out-capture.new(:stdStream(ERR), :rc(self)), In-capture.new(:rc(self), :@answers);
        $!result = &block();
        ($*OUT, $*ERR, $*IN) = ($oldOUT, $oldERR, $oldIN);
        return self;
    }

    method log(Bool :$colorstrip = True) {
        @!calls.map({
            '$*' ~ "$_<where>.$_<which>"
                ~ ( $_<args>.elems
                    ?? '(' ~ $_<args>.map({ ($colorstrip ?? colorstrip($_) !! $_).perl }) ~ ');' 
                    !! ';' )
                ~ ( $_<out>.defined 
                    ?? '##<' ~ $_<out>.perl 
                    !! '' )
                ~ "\n"
            ;
        });
    }

    multi method lines(Bool :$colorstrip = True, :$prefix = '') {
        self!lines(@!calls, :$colorstrip, :$prefix)
    }

    multi method lines(StdStream:D $where, Bool :$colorstrip = True, :$prefix = '') {
        self!lines(
            @!calls.grep({ $_<where> == $where }),
            :$colorstrip,
            :$prefix
        );
    }

    method !lines(@calls, Bool :$colorstrip = True, :$prefix = '') {
        my @out = @calls.grep({
            $_<which> ne 'flush'
        }).map({
            $_<where> == IN
                ?? $_<out> ~ "\n"
                !! $_<args>.join('')
        }).map({
            $colorstrip ?? colorstrip($_) !! $_
        }).join('').split(/\n/).map({
            $prefix ~ $_ ~ "\n";
        });
        @out[*-1] = @out[*-1].substr(0, *-1);
        @out;
    }
}
