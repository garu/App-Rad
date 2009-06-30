package App::Rad::Plugin::Abbrev;
use strict;
use warnings;

sub execute {
	my $c   = shift;
	my $cmd = shift || $c->cmd;

	unless ($c->is_command($cmd)) {

		# if we find a single command that
		# expands from the given command name
		# we return it
		my @cmds = $c->get_commands_like($cmd);
		if (@cmds == 1) {
			$cmd = $cmds[0];
		}
	}
	return $c->SUPER::execute($cmd);
}

sub get_commands_like {
	my $c   = shift;
	my $cmd = shift;

	my @cmds = ();
	my $len = length($cmd);
	foreach (@{$c->commands}) {
		push (@cmds, $_) if substr ($_, 0, $len) eq $cmd;
	}
	return @cmds;
}

42;
__END__
=head1 NAME

App::Rad::Plugin::Abbrev - Abbreviate your App::Rad commands

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

myapp.pl:

    use App::Rad qw(Abbrev);
    App::Rad->run;

	sub mycmd { return "Hello!" }

And from the command line:

    > ./myapp.pl m
	Hello!
	> ./myapp.pl my
	Hello!
	> ./myapp.pl myc
	Hello!
	> ./myapp.pl mycm
	Hello!
	> ./myapp.pl mycmd
	Hello!

=head1 DESCRIPTION

This plugin lets you abbreviate your command names when calling them (as long as there is no ambiguity - see below). This is useful when you have a long command name and not too much patience to type it :)

=head2 $c->execute( I<COMMAND_NAME> );

This plugin overrides Rad's C<execute> method. The new one will work exactly like the former, but will expand abbreviated command names whenever they are ambiguous.

Suppose you have:

   sub command  { ... }
   sub command2 { ... }
   sub yet_another_command { ... }

This is the expected behavior:

   $c->execute('yet');     # same as $c->execute('yet_another_command')
   $c->execute('com');     # ambiguous call, so falls to invalid command
   $c->execute('command'); # not ambiguous, as it's a direct hit


=head2 $c->get_commands_like( I<ABBREVIATED_COMMAND_NAME> )

This plugin also creates a new method that returns a list of valid commands that expand from the given abbreviation. If no commands match, returns an empty list.


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 ACKNOWLEDGEMENTS

Many thanks go to Andre Ramoni for suggesting this plugin, Gabriel Vieira for discussing the API and to Fernando Correa for some internals' discussion as well.

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
