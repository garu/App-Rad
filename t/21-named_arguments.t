use Test::More;# tests => 17;
use App::Rad::Tester;

sub foo { }

sub new_app {
    my $c = get_controller;

    $c->register(
        'cmd1',
        \&foo,
        {
            'opt1' => {
                type      => 'num',
                condition => sub { $_[0] < 42 },
                error_msg => 'number must be below 42',
                aliases   => [ 'a1', 'a3' ],
                to_stash  => ['someopt'],
                help      => 'help for --opt1',
            },
            'opt2' => {
                conflicts_with => 'opt1',
                aliases        => 'a2',
                type           => 'str'

                  #arguments      => 2,
            },
            'opt3' => {
                default  => 42,
                to_stash => [ 'one', 'two' ],
            },
            'opt4' => {
                required => 1,
                type     => 'str',
                arguments => 1,
            },
            'opt5' => 'standard option with help',
            'opt6' => { to_stash => 'one' },
            'opt7' => { type => 'num' },
            -help  => 'help for command 1',
        }
    );
#    use Data::Dumper;
#    diag (Dumper($c));
    return $c;
}
my $c;

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#           Testing incorrect options             #
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#


# Lack of required option
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 );
eval { $c->parse_input; };
is ($@, "option 'opt4' is required for command cmd1 at t/21-named_arguments.t line 58\n");


# Lack of explicit argument in required option
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4 );
eval { $c->parse_input };
is ($@, "missing 1 argument(s) for option 'opt4' at t/21-named_arguments.t line 66\n");


# wrong type in option opt7
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=42 --opt7=foo);
eval { $c->parse_input };
is( $@, "option 'opt7' requires a value of type 'num'\n" );


# Condition returned false
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=somestring --opt1=43 );
eval { $c->parse_input };
is ($@, "incorrect value for option 'opt1': number must be below 42\n");


# Conflicting options
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=somestring --opt1=40 --opt2 );
eval { $c->parse_input };
is ($@, "options 'opt2' and 'opt1' conflict and can not be used together at t/21-named_arguments.t line 90\n");

# Condition returned false (using aliases)
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=somestring --a1=50 --opt2 );
eval { $c->parse_input };
is ($@, "incorrect value for option 'opt1': number must be below 42\n");

# Conflicting options (using aliases)
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=somestring --a1=40 --opt2 );
eval { $c->parse_input };
is ($@, "options 'opt2' and 'opt1' conflict and can not be used together at t/21-named_arguments.t line 104\n");

# test for conflicting aliases
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=somestring --a1=33 --a2=bar );
eval { $c->parse_input };
is ($@, "options 'opt2' and 'opt1' conflict and can not be used together at t/21-named_arguments.t line 111\n");

# test invalid option
##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw(cmd1 --opt4=somestring --baz);
eval { $c->parse_input };
is( $@, "invalid option 'baz'\n" );


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#            Testing correct options              #
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

##############################################
$c = new_app();
@ARGV = qw( cmd1 --opt4=foo );
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');

is ($c->options->{'opt3'}, 42, 'default value for opt3 was set');
is( $c->stash->{one},    42, 'opt3 set stash with default value (1)' );
is( $c->stash->{two},    42, 'opt3 set stash with default value (2)' );


##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 -opt4=foo --opt3 );
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt3}, 42, 'opt3 got proper default value' );
is( $c->stash->{one},    42, 'opt3 set stash value (1)' );
is( $c->stash->{two},    42, 'opt3 set stash value (2)' );


##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=foo --opt3=meep );
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt3}, 'meep', 'opt3 got non-default value' );
is( $c->stash->{one},    'meep', 'opt3: override stash value(1)' );
is( $c->stash->{two},    'meep', 'opt3: override stash value(2)' );


##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt2=foo --opt4=foo );
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt2}, 'foo', 'option opt2 was set' );

##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --a2=foo --opt4=foo );
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt2}, 'foo', 'option opt2 set via alias' );
is( $c->options->{a2}, undef, 'a2 is just an alias');


##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=foo --opt5 );
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt5}, 1, 'opt5 default value test' );

##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=foo --opt5 --opt5 --opt5);
#TODO: should ->parse_input reset options values?
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt5}, 3, "opt5 default value test" );

##############################################
$c = new_app(); # reset context for re-parse
@ARGV = qw( cmd1 --opt4=foo --opt6 );
$c->parse_input;
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt6}, 1, "opt6 default value test" );
is( $c->stash->{one}, 1, "opt6 default value test" );

# TODO: repeat ALL tests using different styles of @ARGV (--foo bar instead of --foo=bar, etc)
# Note: currently, when the parser sees "--foo bar" it only tries "bar" to fill "--foo" if
# we explicitly set the "arguments" attribute for option "foo". We can fix this with some
# lookahead or something, assuming it's a bug

#TODO: make sure you test having two conflicting AND required options

# TODO: Conflicts with default values (how do you tell which one has been
# passed?) --estebanm 20090830

#TODO: test setting two aliases of the same command



done_testing;

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
