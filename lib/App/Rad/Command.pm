package App::Rad::Command;
use strict;
use warnings;

use Carp ();

# yeah, I know, I know, this package needs some serious refactoring
my %TYPES = (
    'num' => sub { require Scalar::Util; 
                return Scalar::Util::looks_like_number(shift)
             }, 
    'str' => sub { require Scalar::Util;
                return !Scalar::Util::looks_like_number(shift)
             },
    'any' => sub { return 1 },
);


#TODO: improve this so it can be defined
# as a standalone command?
sub new {
    my ($class, $options) = (@_);

    my $self = {
        name => ($options->{name} || ''     ),
        code => ($options->{code} || sub {} ),
    };
    bless $self, $class;

    if ($options->{help} ) {
        $self->{help} = $options->{help};
    }
    # if help for the command is not given, we try to
    # get it from the :Help() attribute
    elsif ($self->{name} ne '') {
        require App::Rad::Help;
        $self->{help} = App::Rad::Help->get_help_attr_for($self->{name});
    }

    $self->set_arguments($options->{args}) 
        if $options->{args};

    return $self;
}


# - "I gotta get a job that pays me to do this -- it's just too much fun"
# (SmokeMachine on Rad)
sub set_arguments {
    my ($self, $arguments) = (@_);
    return unless ref $arguments;
    
    foreach my $arg (keys %{ $arguments }) {
        $self->set_arg($arg, $arguments->{$arg});
    }
}

sub set_arg {
    my ($self, $arg, $options) = (@_);

    my $opt_type = ref $options;
    if ($opt_type) {
        Carp::croak "arguments can only receive HASH references"
            unless $opt_type eq 'HASH';

        my %accepted = (
            type           => 1,
            help           => 1,
            condition      => 1, 
            aliases        => 1,
            to_stash       => 1,
            required       => 1,
            default        => 1,
            error_msg      => 1,
            conflicts_with => 1,
        );
        foreach my $value (keys %{$options}) {
            Carp::croak "unknown attribute '$value' for argument '$arg'\n"
                unless $accepted{$value};
                
            # stupid error checking
            my $opt_ref = ref $options->{$value};
            if ($value eq 'type') {
                Carp::croak "Invalid type (should be 'num', 'str' or 'any')\n"
                    unless $opt_ref or $TYPES{ lc $options->{$value} };
            }
            elsif ($value eq 'condition' and (!$opt_ref or $opt_ref ne 'CODE')) {
                Carp::croak "'condition' attribute must be a CODE reference\n"
            }
            elsif ($value eq 'help' and $opt_ref) {
                Carp::croak "'help' attribute must be a string\n"
            }
            elsif ($value eq 'aliases' and ($opt_ref and $opt_ref ne 'ARRAY')) {
                Carp::croak "'aliases' attribute must be a string or an ARRAY ref\n";
            }
            elsif ($value eq 'to_stash' and ($opt_ref and $opt_ref ne 'ARRAY')) {
                Carp::croak "'to_stash' attribute must be a scalar or an ARRAY ref\n";
            }
            elsif($value eq 'required') {
                if ($accepted{'default'}) {
                    $accepted{'required'} = 0;
                }
                else {
                    Carp::croak "'required' and 'default' attributes cannot be used at the same time\n";
                }
            }
            elsif($value eq 'default') {
                if ($accepted{'required'}) {
                    $accepted{'default'} = 0;
                }
                else {
                    Carp::croak "'required' and 'default' attributes cannot be used at the same time\n";
                }
            }
            elsif ($value eq 'error_msg' and $opt_ref) {
                Carp::croak "'error_msg' attribute must be a string\n"
            }
            elsif ($value eq 'conflicts_with' and ($opt_ref and $opt_ref ne 'ARRAY')) {
                Carp::croak "'conflicts_with' attribute must be a scalar or an ARRAY ref\n";
            }
            $self->{args}->{$arg}->{$value} = $options->{$value};
        }
    }
    # got a string. Set it as the help for the argument
    else {
        $self->{args}->{$arg}->{help} = $options;
    }
}

sub _set_default_values {
    my ($self, $options_ref, $stash_ref) = (@_);
    
    foreach my $arg ( keys %{$self->{args}} ) {
        if (my $default = $self->{args}->{$arg}->{default}) {
            
            unless (defined $options_ref->{$arg}) {
                $options_ref->{$arg} = $default;
            
                # if the argument has a to_stash value or hashref,
                # we fill the stash.
                if (my $stashed = $self->{args}->{$arg}->{to_stash}) {
                    push my @keys, ref $stashed ? @{$stashed} : $arg;
                    foreach (@keys) {
                        $stash_ref->{$_} = $default;
                    }
                }
            }
        }
    }
}

sub _validate_arg {
    my ($self, $opt, $val) = (@_);
    return $opt;
}

# _parse_arg should return the options' name
# and its "to_stash" values
# code here should probably be separated in different subs
# for better segregation and testing
sub _parse_arg {
    my ($self, $token, $val) = (@_);

    # short circuit
    return ($token, undef) 
        unless defined $self->{args};

    # first we see if it's a valid arg
    my $arg_ref = undef;
    my $arg_real_name = $token;
    if (defined $self->{args}->{$token}) {
        $arg_ref = $self->{args}->{$token};
    }
    else {
ALIAS_CHECK: # try to find if user given an alias instead
        foreach my $valid_arg (keys %{$self->{args}}) {
            
            # get aliases list
            my $aliases = $self->{args}->{$valid_arg}->{aliases};
            $aliases = [$aliases] unless ref $aliases;

            foreach my $alias (@{$aliases}) {
                # get token if it's inside alias list,
                if ($alias and $token eq $alias) {
                    $arg_ref = $self->{args}->{$valid_arg};
                    $arg_real_name = $valid_arg;
                    last ALIAS_CHECK;
                }
            }
        }
    }
    return (undef, "argument '$token' not accepted by command '" . $self->{name} . "'\n")
        unless defined $arg_ref;
    
    # now that we have the argument name,
    # we need to validate it.
    if (defined $arg_ref->{type} ) {
        if (not defined $val or not $TYPES{$arg_ref->{type}}->($val)) {
            return (undef, "argument '$token' expects a (" . $arg_ref->{type} . ") value\n");
        }
    }
    
    # return argument and stash list ref
    return ($arg_real_name, undef);
}


sub _parse_argument {
    my ($self, $c, $arg) = (@_);
    
    # single option (could be grouped)
    if ( $arg =~ m/^\-([^\-\=]+)$/o) {
        my @args = split //, $1;
        foreach (@args) {
            if ($c->options->{$_}) {
                $c->options->{$_}++;
            }
            else {
                $c->options->{$_} = 1;
            }
        }
    }
    # long option: --name or --name=value
    elsif ( $arg =~ m/^\-\-([^\-\=]+)(?:\=(.+))?$/o) {
        $c->options->{$1} = defined $2 ? $2 
                          : 1
                          ;
    }
    else {
        push @{$c->argv}, $arg;
    }
}

# returns 0 if argument spawned an error
# returns 1 if argument was not parsed into $opt_ref
# returns 2 if argument was parsed into $opt_ref
#sub _parse_argument {
#    my ($self, $opt_ref, $arg) = (@_);
#    
#    if ($self->args) {
#        return 0; # TODO
#    }
#
#    # always accept if we don't have any args specs.
#    return $self->_tinygetopt($opt_ref, $arg);
#}
#
#sub _tinygetopt {
#    my ($self, $opt_ref, $arg) = (@_);
#    
#    # single option (could be grouped)
#    if ( $arg =~ m{^\-([^\-\=]+)$}o) {
#        my @args = split //, $1;
#        foreach (@args) {
#            if ($opt_ref->{$_}) {
#                $opt_ref->{$_}++;
#            }
#            else {
#                $opt_ref->{$_} = 1;
#            }
#        }
#    }
#    # long option: --name or --name=value
#    elsif (m{^\-\-([^\-\=]+)(?:\=(.+))?$}o) {
#        $opt_ref->{$1} = defined $2 ? $2 
#                          : 1
#                          ;
#    }
#    # unrecognized option, forwards to $c->argv
#    else {
#        return 1;
#    }
#    return 2;
#}
#
#TODO: add arguments ***********************************************
#$c->register_commands( {
#              command1 => {
#                             "length" => {
#                                     type => "num",
#                                     condition => sub { $_ > 0 },
#                                     aliases   => [ 'len', 'l' ],
#                                     to_stash => 'mylength',
#                                     required  => 1,
#                                     help       => 'help for the
#--length argument of command1',
#                                     error_message => 'this will be
#printed if "condition" returns false',
#                             }
#                             "foo" => 'other arguments can still just
#have simple help',
#                             "bar" => {
#                                     conflicts_with => 'foo',
#                             },
#                             "baz" => {
#                                     default => 42,
#                             },
#              },
#              command2 => {
#                             ....
#              },
#});
#


sub name { return shift->{name} }
sub help { return shift->{help} }

sub run { 
    my $self = shift;
    my $c    = shift;
    $self->{code}->($c, @_);
}


#TODO: a.k.a. long help - called with ./myapp help command
#sub description {
#    my $self = shift;
#    return help . argument_help # or something like that
#}

42;
__END__

=head1 DESCRIPTION

You can register a command in App::Rad in three diferent ways:

=head2 Simple register:

  $c->register('foo');            # "./myapp foo" goes to \&foo
  $c->register('foo', \&bar);     # "./myapp foo" goes to \&bar


=head2 Register with help text

  $c->register('foo', \&bar, 'this is the help for command foo');

=head2 Extended arguments registering

  $c->register(
        'foo' => {
             "length" => {
                     type      => "num",
                     condition => sub { $_ > 0 },
                     aliases   => [ 'len', 'l' ],
                     to_stash  => 'mylength',
                     required  => 1,
                     help      => 'help for the lenght attribute',
              }
        }
  )
  
  