package App::Rad::Tester;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = 'test_app';

sub test_app {
	my ($app, @args) = (@_);

	# if user gave us a filename, we use it.
	# otherwise we assume $app to be a string
	# containing code and run it in a temp file.
	my $filename = '';
	if ($app !~ /\n/ and -r $app) { 
		$filename = $app;
	}
	else {
		eval 'use File::Temp qw(tempfile tempdir)';
		return if $@;
		my $fh;
		($fh, $filename) = tempfile(UNLINK => 1);
		print $fh $app;
		close $fh;
	}
	my $out = `$^X $filename @args`;
    return wantarray ? ($out, $filename) : $out;
}

42;
__END__

=head1 NAME

App::Rad::Tester - Test your App::Rad applications with ease

=head1 SYNOPSIS

  use Test::More tests => 3;
  use App::Rad::Tester;

  # get STDOUT from your tested app
  my $output = test_app("myapp.pl", qw(somecommand --foo=bar) );
  
  # alternatively, pass any string with code and it
  # will create a temporary file for you.
  my ($output, $filename) = test_app(\*DATA, qw(help) );

  __DATA__
  use App::Rad;
  App::Rad->run


=head1 HIC SVNT DRACONES

C<< App::Rad::Tester >> is a B<< very experimental >> framework for testing App::Rad programs. You may already use it in your app's tests but please keep in mind that this tester module might (most likely will) change its behavior in future releases.


=head1 LICENSE AND COPYRIGHT

Copyright 2008 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.
