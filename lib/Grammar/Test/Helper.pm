module Grammar::Test::Helper;

use Term::ANSIColor;


class RemoteControl is export {

    my enum Where <IN OUT ERR>;

    class Out-capture {
        has Where         $.where;
        has RemoteControl $.rc;
        method print(*@args) { $.rc.record($.where, 'print', @args) }
        method flush(*@args) { $.rc.record($.where, 'flush', @args) }
    }

    class In-capture {
        has                 @.answers;
        has Bool            $.echo = False;
        has RemoteControl   $.rc;
        method get(*@args) {
            my $out = @.answers ?? shift @.answers !! '';
            $.rc.record(IN, 'get', :$out, @args);
            say $out if $.echo;
            return $out;
        }
    }

    has @!calls = ().hash;

    method record(Where:D $where, Str:D $which, :$out?, *@args) {
        @!calls.push({
            when  => now,
            where => $where,
            which => $which,
            args  => @args,
            out   => $out,
        });
    }

    has $!result;   # should not be set via constructor
    method result { $!result }

    method do (|args) {
        (self // RemoteControl.new)!do(|args);
    }

    method !do (&block, :@answers = ()) {
        my ($oldOUT, $oldERR, $oldIN) = ($*OUT, $*ERR, $*IN);
        ($*OUT, $*ERR, $*IN) = Out-capture.new(:where(OUT), :rc(self)), Out-capture.new(:where(ERR), :rc(self)), In-capture.new(:rc(self), :@answers);
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

    method lines(Bool :$colorstrip = True, :$prefix = '') {
        my @out = @!calls.grep({
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
