package App::Rad::Parser;
use Carp ();
use strict;
use warnings;

# retrieves command line arguments
# to be executed by the main program
# 
#When the parser starts, it fetches tokens left to right, validating them agains Global options. At the first argument not specified by a previous Global option, or at the first token that doesn't start with a hyphen (i.e. the first non-option given), the parser will determine which command it is. If the token is not a valid command, the invalid command is called. If there is no token at all, then the default command is called instead.
#TODO: handle ARGV
sub parse_input {
    my $c = shift;
    my @input = @_ || @ARGV; #TODO: keep doing this?
    my $slurp = 0;
    my $invalid;

print STDERR ">>> starting parser\n";
    # we start with the global command
    #my $current_command = $c->{'_globals'};
    my $current_command = $c->{'_commands'}->{''};
    my ($option_name, $option_value, $arguments_left);
    
    while (my $token = shift @input) {
print STDERR ">>> token is '$token'\n";
        # '--' marks the end of options
        if ($token eq '--') {
print STDERR ">>> slurping...\n";
            $slurp = 1;
        }
        # option found
        elsif ( $token =~ s/^-// ) {
print STDERR ">>> option found\n";
            Carp::croak "Missing $arguments_left argument(s) for option $option_name"
                if $arguments_left;
            
            # -foo=bar, --foo, --foo=bar
            #if ( $token =~ m/^-?([^=]+)(?:=(.+))?/o ) {
            #TODO: regex improvement?
            #if ( $token =~ m/^(?:-([^=]+)(?:=(.+))?)|([^-=])+=(.+)$/o ) {
            if ( $token =~ m/^(?:-([^=]+)(?:=(.+))?|([^-=]+)=(.+))$/o ) {
                ($option_name, $option_value) = (defined $4 ? ($3, $4) : ($1, $2));
print STDERR ">>> -foo=bar, --foo, --foo=bar\n";
            }
            # -foo
            else {
print STDERR ">>> -foo\n";
                my @flags = split //, $token;
                # -f -o -o (if all elements are valid options, we push them back)
                if (@flags > 1
                 && @flags == (grep { $current_command->is_option($_) } @flags) ) {
print STDERR ">>> '@flags' are valid options, pushing them back\n";
                    unshift @input, map { '-' . $_ } @flags;
                    next;
                }
                # otherwise, -foo means the "foo" option
                else {
print STDERR ">>> '$token' means the '$token' option\n";
                    ($option_name, $option_value) = ($token, undef);
                }
            }
print STDERR ">>> setting option '$option_name' with value '$option_value'\n";
            $arguments_left = $current_command->setopt($option_name, $option_value);
print STDERR ">>> returned $arguments_left as the number of arguments left for that option\n";
        }
        # when in slurp mode, tokens are arguments
        elsif ($slurp or $arguments_left) {
print STDERR ">>> we are in slurp mode, or there are arguments left\n";
            if (defined $option_name) {
print STDERR ">>> pushing yet another argument to option '$option_name' (value: '$token')\n";
                $arguments_left = $current_command->setopt($option_name, $token);
print STDERR ">>> number of arguments left for option '$option_name': $arguments_left\n";
            }
            else {
print STDERR ">>> pushing token '$token' to c->argv queue\n";
                push @{$c->argv}, $token;
            }
        }
        # we already have a command, so it's a stand-alone argument
        # TODO: should we allow it in all cases?
        # TODO: parsing chained commands
        elsif ( defined $c->cmd or defined $invalid) {
print STDERR ">>> we already have a command, push token '$token' to c->argv queue\n";
            push @{$c->argv}, $token;
        }
        # it's a command, and no previous command was set
        elsif ( $c->is_command($token) ) {
            $current_command = $c->{'_commands'}->{$token};
            $c->cmd = $current_command->name;
print STDERR ">>> got command: '" . $c->cmd . "'\n";
        }
        # it's an invalid command
        else {
print STDERR ">>> TODO: invalid command\n";
            $invalid = $token; #TODO: pass it as something else, maybe?
            # return;
            # set as invalid and mark $c->cmd, but keep parsing the invalid
            # command as '' (global)
            #$invalid = 1;
        }
    }
    Carp::croak "missing $arguments_left argument(s) for option '$option_name'"
        if $arguments_left;

    # TODO: this should be done whenever a command is 'done', 
    # not when the input is over
    check_required($current_command);    # TODO: this goes into Parser.pm
    check_conflicts($current_command);   # TODO: this goes into Parser.pm
    set_defaults($current_command);      # TODO: this goes into Parser.pm
    push_to_stash($c, $current_command); # TODO: this goes into Parser.pm
    
    # let caller know if command was set or if we'll use the default
    $c->cmd = '' unless defined $c->cmd;
    return $invalid;
}

sub check_required {
    my $command = shift;
    foreach my $option (keys %{ $command->{opts} }) {
        if ( $command->{opts}->{$option}->{required} 
           and not exists $command->options->{$option} 
        ) {
            Carp::croak "option '$option' is required for command " . $command->name;
        }
    }
}

sub check_conflicts {
    my $command = shift;
    foreach my $option (sort keys %{ $command->{options} }) {
        my $conflicts = $command->{opts}->{$option}->{conflicts_with};
        if ( $conflicts ) {
            # TODO make sure we store it as a ref, so we don't have to do the below
            $conflicts = [ $conflicts ] unless ref $conflicts; 
            
            foreach my $conflict ( @{$conflicts} ) {
                if (defined $command->{options}->{$conflict}) {
                    Carp::croak "options '$option' and '$conflict' conflict and can not be used together";
                }
            }
        }
    }
}

sub set_defaults {
    my $command = shift;
    foreach my $option (keys %{ $command->{opts} }) {
        if ( $command->{opts}->{$option}->{default} 
           and not exists $command->options->{$option} 
        ) {
            $command->options->{$option} = $command->{opts}->{$option}->{default};
        }
    }
}

sub push_to_stash {
    my ($c, $command) = (@_);
    foreach my $option (keys %{ $command->{opts} }) {
        if ( $command->options->{$option} and (my $stash = $command->{opts}->{$option}->{to_stash} )) {
            $stash = [ $stash ] unless ref $stash; # TODO: always store to_stash under an array ref
            
            foreach my $elem ( @{$stash} ) {
                $c->stash->{$elem} = $command->options->{$option};
            }
        }
    }
}


42;
__END__
=head1 WARNING: INTERNAL SPEC DOCUMENT AHEAD!

This attempts to be a thorough explanation of the command line parsing done by L<< App::Rad >> in the purpose of explicit clarification, internal documentation and troubleshooting. If you are looking for how to create command line apps, please look into L<< App::Rad >>'s main documentation instead.

=head1 COMMAND-LINE PARSING

This documentation explains in detail how L<< App::Rad >> parses the command line. If you are familiar with command line applications, you most likely already know all of this. Please let us know if anything strikes you as odd or if you have any fixes/wishes.

App::Rad parses the command line options and arguments trying to follow the GNU Program Argument Syntax Conventions and the IEEE Std 1003.1 Guidelines.

=head2 Unspecified (generic) options setup

This is Rad's default behavior regarding command line options and arguments parsing, meaning this is what you get if you don't specify any options for your command:

=over 4

=item * Everything starting with one or two hyphens is an option. Everything else are standalone arguments.

=item * long arguments B<< must >> be passed with the long '--' format

   ./myapp --abc   # sets "abc" option
   ./myapp -abc    # sets options "a", "b" and "c"

=item * if an option takes an argument, it needs to be explicitly set with an '=' sign.

This means that, to pass arguments to an option, you B<< need >> to use the '=' construct

   ./myapp -a=2   # sets "a" option to "2"
   
   ./myapp -a 2   # toggles "a" option (in this case, with "1"), 
                  # leaving "2" as a stand-alone argument (unless "2" is a command)

=back


=head2 Given Options and Arguments

If, however, you B<< did >> specify options for your command, you also gain more granularity and control over the parser. In such cases, the following rules apply:

=over 4

=item * Invalid options are treated as errors.

=item * Arguments are options if they begin with a hyphen '-'

   ./myapp -a -b -c

=item * If options take no arguments, they can be grouped together

   ./myapp -abc

=item * Options may be supplied in any order, and appear multiple times. App::Rad automatically increments non-argument options every time they appear.

This means if you do this:

   ./myapp -vvv -a -v
   
Then the "v" option will have the value 4, while "a" will have 1.

=item * Long options may be preceded by one or two hyphens

   ./myapp --foo     # ok
   ./myapp -foo      # also ok

=item * Short options have priority over long ones

This means if options "f", "o" and "foo" are valid, then

  ./myapp -foo
  
will set "f" to 1 and "o" to 2, keeping the "foo" option undefined. To avoid ambiguity, use the long option format (C<< --foo >>) explicitly.

=item * If an option B<does> take an argument, it is set as the very next argument, separated by a whitespace or an equal sign.

For example, if "a" takes an argument, then all of the following pass "bc" as its argument:

   ./myapp -a bc
   ./myapp -a=bc

Similarly, if "foo" takes an argument, then all of the following pass "bar" as its argument:

   ./myapp --foo bar
   ./myapp --foo=bar

=item * Single-letter options that take an argument can have the argument set without any whitespace between them.

For example, if "a" takes an argument, then:

   ./myapp -abc

will also set "bc" as its argument. If you also wish to set options "b", "c" and "abc" while still passing "bc" as an argument to "a", you can do something like:

   ./myapp -b -c -a=bc --abc   
   ./myapp -bc -a bc --abc
   ./myapp -bc -abc --abc
   ./myapp -bcabc --abc

=item * users can abbreviate option names as long as abbreviations are unique.

For example, if "foo", "bar" and "f" are options and take no arguments, then

   ./myapp -b    # sets "bar"
   ./myapp -ba   # sets "bar"
   ./myapp -bar  # sets "bar"
   ./myapp -f    # sets "f"
   ./myapp -fo   # sets "foo"
   ./myapp -foo  # sets "foo"

But keep in mind that, if the "f" option takes an argument, only the long format will save you:

   ./myapp -f     # error: option "f" takes an argument
   ./myapp -fo    # sets "f" option to "o"
   ./myapp -foo   # sets "f" option to "oo"
   ./myapp --f=oo # sets "f" option to "oo"
   ./myapp --f oo # sets "f" option to "oo"   
   ./myapp --f    # error: option "f" takes an argument
   ./myapp --fo   # sets "foo"
   ./myapp --foo  # sets "foo"

=item * The argument '--' terminates all options. This means any and all following elements are treated as simple arguments, even if they start with a hyphen.

This means the following call:

   ./myapp -a arg -bc -- -def -g moo -h --bar=baz
   
will set the options "a" (with the value "arg"), "b" and "c", and no others. The elements "-def", "-g", "moo", "-h" and "--bar=baz" will be left alone, passed as-is to the program.

=back


=head2 Global options x Command options

App::Rad uses commands as its main form of control over CLI Applications. In fact, all available options are retrieved from the issued command.

When the parser starts, it fetches tokens left to right, validating them agains Global options. At the first argument not specified by a previous Global option, or at the first token that doesn't start with a hyphen (i.e. the first non-option given), the parser will determine which command it is. If the token is not a valid command, the invalid command is called. If there is no token at all, then the default command is called instead.

If, however, it B<< is >> a valid command, the parser updates its token list and rules with the current command's options, and keeps going, this time filling the commands's options and arguments list.

=head2 Command dispatching

When the parser is done, it has each to-be-called command set with its respective options and arguments, so it calls them in order.

=head2 Subcommands (a.k.a. Chaining commands together)

it is possible to create subcommands via the :Chained() attribute, or by making a C<< MyApp::Cmd >> package that inherits from L<< App::Rad::Command >>.

  sub foo :Chained(bar baz) {}

  sub bar {}
  sub baz {}
  
In the example above, the parser will look for the "foo" command if and only if it is already parsing the "bar" or "baz" commands. If there are still tokens left after the subcommand, they are parsed and given only to it.


=head1 REFERENCES

=over 4

=item * GNU Program Argument Syntax Conventions
L<< http://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html >>

=item * IEEE Std 1003.1
L<< http://www.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap12.html#tag_12_01c >>

=back

