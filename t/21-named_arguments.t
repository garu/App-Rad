use Test::More tests => 14;
use App::Rad::Tester;

sub foo { }
my $c = get_controller;

$c->register(
    'cmd1',
    \&foo,
    {
        'arg1' => {
            type      => 'num',
            condition => sub { $_ < 42 },
            error_msg => 'number must be below 42',
            aliases   => [ 'a1', 'a3' ],
            to_stash  => 'somearg',
            help      => 'help for --arg1',
        },
        'arg2' => {
            conflicts_with => 'arg1',
            aliases        => 'a2',
            type           => 'str'

              #arguments      => 2,
        },
        'arg3' => {
            default  => 42,
            to_stash => [ 'one', 'two' ],
        },
        'arg4' => {
            required => 1,
            type     => 'str',
        },
        'arg5' => 'standard argument with help',
        -help  => 'help for cmd2',
    }
);


@ARGV = qw( cmd1 );
eval { $c->parse_input; };
ok( !$@,
   "Test: command 'cmd1' no argument?\n"
);


@ARGV = qw( cmd1 --arg4 );
eval { $c->parse_input };
ok( !$@,
    "Test: command 'cmd1' argument 'arg4' no explicit value, defaults to 1?\n"
);

@ARGV = qw( cmd1 --arg2=42 );
eval { $c->parse_input };
ok( $@,
    "Test: command 'cmd1' argument 'arg2' requires a value of type 'str'?\n"
);

@ARGV = qw( cmd1 --arg2=foo );
$c->parse_input;
is_deeply( \@ARGV, ['--arg2=foo'],
    "Test: command 'cmd1' argument 'arg2' parameters mismatched?\n"
);

is( $c->options->{arg2}, 'foo',
    "Test: command 'cmd1' argument 'arg2' value mismatch(isn't 'foo')?\n"
);

# NOTE: AL NEWKIRK - STOPPED HERE - Test below dont work, functions have not been
# implemented.

# we didn't die, so it's safe to test for arg3's default behavior
@ARGV = qw( cmd1 --arg3 );
$c->parse_input;
is( $c->options->{arg3}, 42,
    "Test: command 'cmd1' argument 'arg3' has proper default value?"
);
is( $c->stash->{one}, 42,
    "Test: command 'cmd1' argument 'arg3' set stash value stash(1)"
);
is( $c->stash->{two}, 42,
    "Test: command 'cmd1' argument 'arg3' set stash value stash(2)"
);


@ARGV = qw( cmd1 --arg4=foo --arg3=meep );
$c->parse_input;
#ok ()
is ($c->options->{arg3}, 'meep', 'arg3 should have set a proper default value');
is ($c->stash->{one}   , 'meep', 'arg3 stash value should be overriden(1)');
is ($c->stash->{two}   , 'meep', 'arg3 stash value should be overriden(2)');

@ARGV = qw( cmd1 --arg4=foo --arg5 );
$c->parse_input;
is ($c->options->{arg5}, 1);

@ARGV = qw( cmd1 --arg4=foo --arg5=bar );
$c->parse_input;
is ($c->options->{arg5}, 'bar');


@ARGV = qw(cmd1 --baz);
eval { $c->parse_input };
is ($@, "Error: argument 'baz' not accepted by command 'cmd1'\n");

# EOF

######################################
#TODO: move these commented tests to their rightful file
#my $c = get_controller;
#$c->register('cmd1', \&foo, { foo => 'sets foo', bar => 'sets bar' } );
#sub foo {}
#
#
#local @ARGV = qw(cmd1);
#$c->parse_input;
#is_deeply(\@ARGV, []);
#
#@ARGV = qw(cmd1 --foo);
#$c->parse_input;
#is($c->options->{foo}, 1);
#
#TODO: {
#    local $TODO = 'empty parameter not implemented yet';
#    @ARGV = qw(cmd1 --foo=);
#    $c->parse_input;
#    is($c->options->{foo}, '');
#};
#
#@ARGV = qw(cmd1 --foo=bar);
#$c->parse_input;
#is($c->options->{foo}, 'bar');
#