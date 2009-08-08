package App::Rad::Command;
use strict;
use warnings;

use Carp ();

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

sub run { 
    my ($self, $c) = (@_);
    $self->{code}->($c, @_);
}

# - "I gotta get a job that pays me to do this -- it's just too much fun"
# (SmokeMachine on Rad)
sub set_arguments {
    my ($self, $options) = (@_);
    
    return unless ref $options;
    
    # the command may have been set with a list of accepted arguments
    foreach my $argument (keys %{ $options->{args} }) {
        my $arg_ref = ref $options->{args}->{$argument};
        if ($arg_ref) {
            Carp::croak "arguments can only receive strings or HASH references\n"
                unless $arg_ref eq 'HASH';
            $self->set_arg($argument, $options->{args}->{$argument});
        }
    }
}

sub set_arg {
    my ($self, $arg, $options) = (@_);

    foreach my $value (keys %{$options}) {
        if ($value eq 'type') {
            my %types = ( 'num' => qr{\d+}, 'str' => qr{.+});
            Carp::croak "Invalid type\n"
                unless $types{ lc $options->{$value} };
        }
        else {
            Carp::croak "unknown argument attribute '$arg'\n";
        }
        $self->{args}->{$arg}->{$value} = $options->{$value};
    }
}
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



sub help { return shift->{help} }

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
  
  