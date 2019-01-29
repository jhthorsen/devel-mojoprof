package Devel::MojoProf::Reporter;
use Mojo::Base -base;

has handler => undef;

# Note that $prof is just here to be back compat
sub report {
  my ($self, $report, $prof) = @_;
  return $self->{handler}->($prof, $report) if $self->{handler};
  return printf STDERR "%0.5fms [%s::%s] %s\n", @$report{qw(elapsed class method message)} unless $report->{line};
  return printf STDERR "%0.5fms [%s::%s] %s at %s line %s\n", @$report{qw(elapsed class method message file line)};
}

1;

=encoding utf8

=head1 NAME

Devel::MojoProf::Reporter - Default mojo profile reporter

=head1 DESCRIPTION

L<Devel::MojoProf::Reporter> is an object that is capable of reporting how long
certain operations take.

See L<Devel::MojoProf> for how to use this.

=head1 ATTRIBUTES

=head2 handler

  my $cb       = $reporter->handler;
  my $reporter = $reporter->handler(sub { ... });

Only useful to be back compat with L<Devel::MojoProf> 0.01:

  $prof->reporter(sub { ... });

Will be removed in the future.

=head1 METHODS

=head2 report

  $self->report(\%report);

Will be called every time a meassurement has been done by L<Devel::MojoProf>.

The C<%report> variable contains the following example information:

  {
    file    => "path/to/app.pl",
    line    => 23,
    class   => "Mojo::Pg::Database",
    method  => "query_p",
    t0      => [Time::HiRes::gettimeofday],
    elapsed => Time::HiRes::tv_interval($report->{t0}),
    message => "SELECT 1 as whatever",
  }

The C<%report> above will print the following line to STDERR:

  0.00038ms [Mojo::Pg::Database::query_p] SELECT 1 as whatever at path/to/app.pl line 23

The log format is currently EXPERIMENTAL and could be changed.

Note that the C<file> and C<line> keys can be disabled by setting the
C<DEVEL_MOJOPROF_CALLER> environment variable to "0". This can be useful to
speed up the run of the program.

=head1 SEE ALSO

L<Devel::MojoProf>.

=cut
