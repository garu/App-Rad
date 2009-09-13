use Test::More tests => 17;
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
            to_stash  => ['somearg'],
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
        'arg6' => { to_stash => 'one' },
        -help  => 'help for cmd2',
    }
);


# Testing incorrect arguments --------------------------------------------------------
# Lack of required argument
@ARGV = qw( cmd1 );
eval { $c->parse_input; };
is ($@, "Error: command 'cmd1' needs argument 'arg4'\n");

# Lack of value in required argument
@ARGV = qw( cmd1 --arg4 );
eval { $c->parse_input };
is ($@, "Error: argument 'arg4' requires a value of type 'str'\n");

@ARGV = qw( cmd1 --arg2=42 );
eval { $c->parse_input };
ok( $@, "test: string value required" );

# Condition returned false
@ARGV = qw( cmd1 --arg4=somestring --arg1=43 );
eval { $c->parse_input };
is ($@, "Error: incorrect value for argument 'arg1': number must be below 42\n");

# Conflicting arguments
@ARGV = qw( cmd1 --arg4=somestring --arg1=40 --arg2 );
eval { $c->parse_input };
is ($@, "Error: you can't provide both 'arg1' and 'arg2'\n");

# Condition returned false (using aliases)
@ARGV = qw( cmd1 --arg4=somestring --a1=50 --arg2 );
eval { $c->parse_input };
is ($@, "Error: incorrect value for argument 'a1': number must be below 42\n");

# Conflicting arguments (using aliases)
@ARGV = qw( cmd1 --arg4=somestring --a1=40 --arg2 );
eval { $c->parse_input };
is ($@, "Error: you can't provide both 'arg1' and 'arg2'\n");

# TODO: Conflicts with default values (how do you tell which one has been
# passed?) --estebanm 20090830


# Testing correct arguments ----------------------------------------------------------
@ARGV = qw( cmd1 --arg2=foo );
$c->parse_input;
is_deeply( \@ARGV, ['--arg2=foo'], "test: mismatched parameters" );

is( $c->options->{arg2}, 'foo', "test: value mismatch (isn't 'foo')" );

# we didn't die, so it's safe to test for arg3's default behavior
@ARGV = qw( cmd1 --arg3 );
$c->parse_input;
is( $c->options->{arg3}, 42, "test: proper default value" );
is( $c->stash->{one},    42, "test: set stash value (1)" );
is( $c->stash->{two},    42, "test: set stash value (2)" );

@ARGV = qw( cmd1 --arg2=foo --arg3=meep );
$c->parse_input;
is( $c->options->{arg3}, 'meep', 'test: set a proper default value' );
is( $c->stash->{one},    'meep', 'test: override stash value(1)' );
is( $c->stash->{two},    'meep', 'test: override stash value(2)' );

@ARGV = qw( cmd1 --arg3=foo --arg5 );
$c->parse_input;
is( $c->options->{arg5}, "", "test: another default value test" );

# test for alias support and conflict support
@ARGV = qw( cmd1 --a1=33 --a2=bar );
eval { $c->parse_input };
ok( $@, "test: values that conflict" );
is( $c->options->{arg1}, 33,    "test: alias value (1)" );
is( $c->options->{arg2}, "bar", "test: alias value (2)" );

@ARGV = qw( cmd1 --arg6=99 );
eval { $c->parse_input };
ok( !$@, "test: invalid to_stash option" );

@ARGV = qw(cmd1 --baz);
eval { $c->parse_input };
ok( $@, "test: command not accepted" );


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
