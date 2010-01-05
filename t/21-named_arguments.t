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

sub new_app_with_args {
    my ($args) = @_;

    my $c = new_app();
    @ARGV = @$args;
    parse_input($c);

    return $c;
}

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#           Testing incorrect options             #
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#


# Lack of required option
##############################################
eval { new_app_with_args([ qw( cmd1 ) ]) };
like ( $@, qr{^option 'opt4' is required for command cmd1 at } );


# Lack of explicit argument in required option
##############################################
eval { new_app_with_args([ qw( cmd1 --opt4 ) ]) };
like ($@, qr{^missing 1 argument\(s\) for option 'opt4' at });


# wrong type in option opt7
##############################################
eval { new_app_with_args([ qw( cmd1 --opt4=42 --opt7=foo) ]) };
is( $@, "option 'opt7' requires a value of type 'num'\n" );


# Condition returned false
##############################################
eval { new_app_with_args([ qw( cmd1 --opt4=somestring --opt1=43 ) ]) };
is ($@, "incorrect value for option 'opt1': number must be below 42\n");


# Conflicting options
##############################################
eval { new_app_with_args([ qw( cmd1 --opt4=somestring --opt1=40 --opt2 ) ]) };
like ($@, qr{^options 'opt2' and 'opt1' conflict and can not be used together at });

# Condition returned false (using aliases)
##############################################
eval { new_app_with_args([ qw( cmd1 --opt4=somestring --a1=50 --opt2 ) ]) };
is ($@, "incorrect value for option 'opt1': number must be below 42\n");

# Conflicting options (using aliases)
##############################################
eval { new_app_with_args([ qw( cmd1 --opt4=somestring --a1=40 --opt2 ) ]) };
like ($@, qr{options 'opt2' and 'opt1' conflict and can not be used together at });

# test for conflicting aliases
##############################################
eval { new_app_with_args([ qw( cmd1 --opt4=somestring --a1=33 --a2=bar ) ]) };
like ($@, qr{options 'opt2' and 'opt1' conflict and can not be used together at });

# test invalid option
##############################################
eval { new_app_with_args([ qw(cmd1 --opt4=somestring --baz) ]) };
is( $@, "invalid option 'baz'\n" );


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#            Testing correct options              #
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

##############################################
new_app_with_args([ qw( cmd1 --opt4=foo ) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');

is ($c->options->{'opt3'}, 42, 'default value for opt3 was set');
is( $c->stash->{one},    42, 'opt3 set stash with default value (1)' );
is( $c->stash->{two},    42, 'opt3 set stash with default value (2)' );


##############################################
new_app_with_args([ qw( cmd1 -opt4=foo --opt3 ) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt3}, 42, 'opt3 got proper default value' );
is( $c->stash->{one},    42, 'opt3 set stash value (1)' );
is( $c->stash->{two},    42, 'opt3 set stash value (2)' );


##############################################
new_app_with_args([ qw( cmd1 --opt4=foo --opt3=meep ) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt3}, 'meep', 'opt3 got non-default value' );
is( $c->stash->{one},    'meep', 'opt3: override stash value(1)' );
is( $c->stash->{two},    'meep', 'opt3: override stash value(2)' );


##############################################
new_app_with_args([ qw( cmd1 --opt2=foo --opt4=foo ) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt2}, 'foo', 'option opt2 was set' );

##############################################
new_app_with_args([ qw( cmd1 --a2=foo --opt4=foo ) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt2}, 'foo', 'option opt2 set via alias' );
is( $c->options->{a2}, undef, 'a2 is just an alias');


##############################################
new_app_with_args([ qw( cmd1 --opt4=foo --opt5 ) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt5}, 1, 'opt5 default value test' );

##############################################
new_app_with_args([ qw( cmd1 --opt4=foo --opt5 --opt5 --opt5) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt5}, 3, 'opt5 default value test' );

##############################################
new_app_with_args([ qw( cmd1 --opt4=foo --opt6 ) ]);
is ($c->cmd, 'cmd1', 'command was set');
is ($c->options->{'opt4'}, 'foo', 'option opt4 was set');
is( $c->options->{opt6}, 1, 'opt6 default value test' );
is( $c->stash->{one}, 1, 'opt6 default value test' );

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
#parse_input($c);
#is_deeply(\@ARGV, []);
#
#@ARGV = qw(cmd1 --foo);
#parse_input($c);
#is($c->options->{foo}, 1);
#
#TODO: {
#    local $TODO = 'empty parameter not implemented yet';
#    @ARGV = qw(cmd1 --foo=);
#    parse_input($c);
#    is($c->options->{foo}, '');
#};
#
#@ARGV = qw(cmd1 --foo=bar);
#parse_input($c);
#is($c->options->{foo}, 'bar');
#
