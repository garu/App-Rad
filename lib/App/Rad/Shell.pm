package App::Rad::Shell;
use Carp 'croak';
use Term::ReadLine;
use strict;
use warnings;

our $VERSION = '0.01';


#    App::Rad->shell( {
#        prompt     => 'cmd: ',
#        autocomp   => 1,
#        abbrev     => 1,
#        ignorecase => 0,
#        history    => 1, # or 'path/to/histfile.txt'
#    });
#
sub shell {
    my $class = shift; # should be 'App::Rad'
    my $c = {};
    bless $c, $class;

    my $prompt = $0;
    $prompt =~ s{\.pl$}{};

    eval 'use Term::ReadKey';
    %{$c->{'_shell'}} = (
            'has_readkey' => (defined $@) ? 0 : 1,
            'prompt'      => "$prompt> ",
            'autocomp'    => 1,
			);

    my $params_ref = shift;
    if ($params_ref) {
        croak 'argument to shell() method must be a hash reference'
            unless (ref $params_ref eq 'HASH');
    
        #TODO    
    }
#    $c->{'_shell'} = %{ shift() };
    $c->_init();
    $c->_register_functions();

	# dirty hack to override 'default' function
	$c->{'_functions'}->{'default'} = sub {};
	$c->{'_functions'}->{'invalid'} = sub { return "Invalid command. Type 'help' for a list of commands" };

    # this is *before* setup() because the application
    # developer might want to modify the command.
    $c->register('quit', \&quit, 'exits the shell');
    $c->register('help', \&App::Rad::Help::helpstr, 'show syntax and available commands');

    
    # then we run the setup to register
    # some commands
    $c->{'_functions'}->{'setup'}->($c);
    
    do {
		print $c->{'_shell'}->{'prompt'};
        @ARGV = split /\s+/, <>;
        $c->_get_input();
        $c->execute();
    } while (1);
}

sub quit {
	my $c = shift;
	$c->{'_functions'}->{'teardown'}->($c);
	exit;
}

42;
__END__

=head1 NAME

App::Rad::Shell - shell-like execution of App::Rad programs

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

With this extension you can run your App::Rad programs as an interactive command shell

    use App::Rad;
    App::Rad->shell();   # instead of App::Rad->run();

and now your App::Rad programs will run like a shell:

    [user@host]$ ./myapp.pl
    myapp> help
    
    Available Commands:
        help 	show syntax and available commands
        quit	exits the shell

    myapp>
    
You can also control the shell's behavior and appearance:

    use App::Rad;
    App::Rad->shell( {
        prompt     => 'cmd: ',
        autocomp   => 1,
        abbrev     => 1,
        ignorecase => 0,
        history    => 1, # or 'path/to/histfile.txt'
    });

=head1 DESCRIPTION

This is an internal module for App::Rad and should not be used separately. Please refer to L<< App::Rad >> for further documentation.


=head1 INTERNAL METHODS

=head2 load

Loads the module into App::Rad.

=head2 shell

Runs the shell environment. This method may receive a hash reference containing one or more of the options below:

=head3 prompt

Sets the shell prompt string. Default is the program name, followed by a '>' and a blank space. For example, if your program is called 'myapp.pl', the default shell prompt will be 'myapp> '.

=head4 autocomp

Enables (1) or disables (0) command autocompletion. When enabled, the user can press the TAB key after typing part of a command name and the shell will try to complete the string with the full command name. If there is any ambiguity (i.e., the string can be expanded into more than one command), the shell will not autocomplete it, but if the user presses the TAB key twice it will instead display a list of all possible commands. Default is enabled.

=head4 abbrev

Enables (1) or disables (0) command abbreviation. When enabled, the user can type just enough of the command name so its uniquely expandable (e.g. typing 'q' instead of 'quit' or 'h' instead of 'help'). If the typed string is still ambiguous, a 'command not found' message will be displayed. Default is enabled.


=head4 ignorecase

When enabled (1), commands can be typed without worrying about uppercase or lowercase. Default is disabled (0).


=head4 history

Enables (1) or disables (0) command history. When enabled, the user can press the UP key to see previously typed commands. 

Instead of '1', you may also pass the full path to a file that will then keep the history between sessions. If the file does not exist it will be created. If App::Rad cannot access the file path (or if no path is given), history will be kept only for the current session. Default is enabled (1).


=head1 DEPENDENCIES

* App::Rad

=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>, with several contributions from Fernano Correa de Oliveira, C<< <fco at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2008 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.



=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
