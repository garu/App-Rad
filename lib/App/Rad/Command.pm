package App::Rad::Command;
use strict;
use warnings;

use Carp ();

# yeah, I know, I know, this package needs some serious refactoring
my %TYPES = (
    'num' => sub { require Scalar::Util; 
                return Scalar::Util::looks_like_number(shift)
             }, 
    'str' => sub { return 1 },
);


#TODO: improve this so it can be defined
# as a standalone command?
sub new {
    my ($class, $options) = (@_);

    my $self = {
        name => ($options->{name} || ''     ),
        code => ($options->{code} || sub {} ),
        options => {},
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

    $self->set_options($options->{opts}) 
        if $options->{opts};

    return $self;
}


# - "I gotta get a job that pays me to do this -- it's just too much fun"
# (SmokeMachine on Rad)
sub set_options {
    my ($self, $options) = (@_);
    return unless ref $options;
    
    foreach my $opt (keys %{ $options }) {
        $self->set_opt($opt, $options->{$opt});
    }
}


# TODO: rename this
sub set_opt {
    my ($self, $opt, $options) = (@_);

    my $opt_type = ref $options;
    if ($opt_type) {
        Carp::croak "options can only receive HASH references"
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
            arguments      => 1,
        );
        foreach my $value (keys %{$options}) {
            Carp::croak "unknown attribute '$value' for option '$opt'\n"
                unless $accepted{$value};
                
            # stupid error checking
            my $opt_ref = ref $options->{$value};
            if ($value eq 'type') {
                Carp::croak "Invalid type (should be 'num' or 'str')\n"
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
            $self->{opts}->{$opt}->{$value} = $options->{$value};
        }
    }
    # got a string. Set it as the help for the option
    else {
        $self->{opts}->{$opt}->{help} = $options;
    }
}

sub options {
    return $_[0]->{'options'};
}

# this function is here to replace _parser_opt
# we should find a better name for it, but...later.

# it returns the number of arguments left
sub setopt {
    my ($self, $opt_name, $opt_val) = (@_);
    my $arguments_left = 0;

    # if the app has custom options for that command, 
    # we check them now. Otherwise, just accept it.
    if ( keys ( %{$self->{opts}} ) > 0 ) {
        my $actual_opt_name = $self->_get_option_name($opt_name) 
            || die "invalid option '$opt_name'\n";

        $opt_name = $actual_opt_name;
        my $opt = $self->{opts}->{$opt_name};

        # if no value was given to the option, here's what we do:
        if ( not defined $opt_val ) {
            # first, if we have a default value to use, use it.
            if (defined $opt->{default} ) {
                $opt_val = $opt->{default}
            }
            # if a required number of arguments was set 
            # for the option, we will not use the auto-increment
            elsif ( defined $opt->{arguments} ) {
                return $opt->{arguments};
            }
            # otherwise, do an auto-increment
            else {
                # TODO: on the test below, do a looks_like_number ?
                $opt_val = defined $self->{options}->{$opt_name} 
                         ? $self->{options}->{$opt_name} + 1
                         : 1
                         ;
             }
         }

        # type check (TODO: it would be nice if we allowed pluggable types)
        if ( $opt->{type} and not $TYPES{$opt->{type}}->($opt_val) ) {
            die "option '$opt_name' requires a value of type '" . $opt->{type} . "'\n";
        }

        # condition check
        if ( $opt->{condition} and not $opt->{condition}->($opt_val) ) {
            die "incorrect value for option '$opt_name'" . 
                (defined $opt->{error_msg} ? ": " . $opt->{error_msg} : '') 
                . "\n";
        }
        
        #TODO: conflict check?
        
        #TODO: arguments left check
    }
    else {
        # no custom options, so we just make sure
        # there is a value to set.
        if (not defined $opt_val) {
            $opt_val = defined $self->{options}->{$opt_name} 
             ? $self->{options}->{$opt_name} + 1
             : 1
             ;
         }
    }
    $self->options->{$opt_name} = $opt_val;
    return $arguments_left;
}

# returns option name, or undef if it's not found
sub _get_option_name {
    my ($self, $opt) = (@_);
    
    return $opt if exists $self->{opts}->{$opt};
    
ALIAS_CHECK: # try to find whether we were given an alias instead
    foreach my $valid_opt (keys %{$self->{opts}}) {
            
        # get aliases list
        my $aliases = $self->{opts}->{$valid_opt}->{aliases};
        $aliases = [$aliases] unless ref $aliases;

        # get token if it's inside alias list,
        foreach my $alias ( @{$aliases} ) {
            return $valid_opt if $alias and $opt eq $alias;
        }
    }
    return;
}

sub is_option {
    my ($self, $opt) = (@_);
    
    # if there are no registered options, everything can be an option
    return 1 unless scalar keys %{$self->{opts}};
    
    return (exists $self->{opts}->{$opt}) ? 1 : 0;
}

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
#    return help . option_help # or something like that
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

=head2 Extended options registering

  $c->register(
        'foo' => {
             "length" => {
                     type      => "num",
                     condition => sub { $_ > 0 },
                     aliases   => [ 'len', 'l' ],
                     to_stash  => 'mylength',
                     required  => 1,
                     help      => 'help for the --length option',
              }
        }
  )
  