package Devel::MojoProf;
use Mojo::Base -base;

use Class::Method::Modifiers 'install_modifier';
use Mojo::Loader 'load_class';
use Scalar::Util 'blessed';
use Time::HiRes qw(gettimeofday tv_interval);

use constant CALLER => $ENV{DEVEL_MOJOPROF_CALLER} // 1;
use constant DEBUG  => $ENV{DEVEL_MOJOPROF_DEBUG} // 1;

has reporter => sub { \&_default_reporter };

sub add_profiling_for {
  my $self = _instance(shift);
  return $self->can("_add_profiling_for_$_[0]")->($self) if @_ == 1;

  return unless my $target = $self->_ensure_loaded(shift);
  while (my $method = shift) {
    next if $self->{installed}{$target}{$method}++;
    $self->_add_profiling_for_method($target, $method, ref $_[0] ? shift : undef);
  }

  return $self;
}

sub import {
  my $class = shift;
  my @flags = @_ ? @_ : qw(-pg -mysql -sqlite -ua);

  $class->add_profiling_for($_) for map { s!^-!!; $_ } @flags;
}

sub singleton { state $self = __PACKAGE__->new }

sub _add_profiling_for_method {
  my ($self, $target, $method, $make_message) = @_;

  install_modifier $target => around => $method => sub {
    my ($orig, @args) = @_;
    my $wantarray = wantarray;
    my %report = (class => $target, method => $method);
    _add_caller_to_report($target, \%report) if CALLER;

    my $cb = ref $args[-1] eq 'CODE' ? pop @args : undef;
    push @args, sub { $self->_report_for(\%report, $make_message->(@args)); $cb->(@_) }
      if $cb;

    $report{t0} = [gettimeofday];
    my @res = $wantarray ? $orig->(@args) : (scalar $orig->(@args));

    if ($cb) {
      1;    # do nothing
    }
    elsif (blessed $res[0] and $res[0]->isa('Mojo::Promise')) {
      $res[0]->finally($self->_report_for(\%report, $make_message->(@args)));
    }
    else {
      $self->_report_for(\%report, $make_message->(@args));
    }

    return $wantarray ? @res : $res[0];
  };
}

sub _add_caller_to_report {
  my ($target, $report) = @_;

  my $i = 0;
  while (my @caller = caller($i++)) {
    next if $caller[0] eq $target or $caller[0] eq 'Devel::MojoProf';
    @$report{qw(file line)} = @caller[1, 2];
    last;
  }
}

sub _add_profiling_for_pg {
  my $self = shift;
  $self->add_profiling_for('Mojo::Pg::Database', query => \&_make_desc_for_db, query_p => \&_make_desc_for_db)
    if $self->_ensure_loaded('Mojo::Pg', 1);
}

sub _add_profiling_for_mysql {
  my $self = shift;
  $self->add_profiling_for('Mojo::mysql::Database', query => \&_make_desc_for_db, query_p => \&_make_desc_for_db)
    if $self->_ensure_loaded('Mojo::mysql', 1);
}

sub _add_profiling_for_sqlite {
  my $self = shift;
  $self->add_profiling_for('Mojo::SQLite::Database', query => \&_make_desc_for_db)
    if $self->_ensure_loaded('Mojo::SQLite', 1);
}

sub _add_profiling_for_ua {
  shift->add_profiling_for('Mojo::UserAgent', start => \&_make_desc_for_ua, start_p => \&_make_desc_for_ua);
}

sub _default_reporter {
  my ($self, $report) = @_;
  return warn sprintf "%0.5fms [%s::%s] %s\n", @$report{qw(elapsed class method message)} unless $report->{line};
  return warn sprintf "%0.5fms [%s::%s] %s at %s line %s\n", @$report{qw(elapsed class method message file line)};
}

sub _ensure_loaded {
  my ($self, $target, $no_warn) = @_;
  return $target unless my $e = load_class $target;
  die "[Devel::MojoProf] Could not load $target: $e" if ref $e;
  warn "[Devel::MojoProf] Could not find module $target\n" if DEBUG and !$no_warn;
  return;
}

sub _instance { ref $_[0] ? $_[0] : shift->singleton }

sub _make_desc_for_db { $_[1] }
sub _make_desc_for_ua { sprintf '%s %s', $_[1]->req->method, $_[1]->req->url->to_abs }

sub _report_for {
  my ($self, $report, $message) = @_;
  @$report{qw(elapsed message)} = (tv_interval($report->{t0}), $message);
  $self->reporter->($self, $report);
}

1;
