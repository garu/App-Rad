package App::Rad::Command;

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

#TODO: improve this so it can be defined
# as a standalone command?
sub new {
    my ($class, $options) = (@_);
    my $self = {
        name => ($options->{name} || ''     ),
        code => ($options->{code} || sub {} ),
    };
    bless $self, $class;
    
    $self->set_arguments($options);
    return $self;
}

sub run { 
    my ($self, $c) = (@_);
    $self->{code}->($c, @_);
}

sub set_arguments {
    my ($self, $options) = (@_);
    
    # set (short) help string. It may have been passed
    # as a single parameter, or as a ->{help} option
    if (!ref($options)) {
        $self->{help} = $options;
        return; # if it's not a ref, our business is over.
    }
    elsif ($options->{help} ) {
        $self->{help} = $options->{help};
    }
    elsif ($self->{name} ne '') {
        require App::Rad::Help;
        $self->{help} = App::Rad::Help->get_help_attr_for($self->{name});
    }
}

sub help { return shift->{help} }

# a.k.a. long help - called with ./myapp help command
#sub description {
#    my $self = shift;
#    return help . argument_help # or something like that
#}

42;
__END__

=head1 DESCRIPTION

In a main App::Rad file, each sub you create turns into a command:

  use App::Rad;
  
  sub foo {
      my $c = shift;
      return q{ './myapp.pl foo' will get here };
  }
  
  sub bar {
      my $c = shift;
      return q{ './myapp.pl bar' will get here };
  }

...unless you specifically tell Rad to do otherwise:

  use App::Rad;
  
  sub setup {
      my $c = shift;
      $c->register( 'foo', \&baz );
  }
  
  sub baz {
      my $c = shift;
      return q{ './myapp.pl foo' will get here };
  }
  
  sub foo {
      return q{this cannot be called directly as an external command};
  }
  
You may also create each command as a single file inside you main app's "lib" folder:

  # this will automatically register "foo" (note the lowecase) as
  # a command of MyApp.
  package MyApp::Foo;
  use base 'App::Rad::Command';
  
  sub run {
  }
  
  