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

