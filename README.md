# NAME

Devel::MojoProf - Profile blocking, non-blocking a promise based Mojolicious APIs

# SYNOPSIS

    $ perl -d:MojoProf myapp.pl
    $ perl -d:MojoProf -e'Mojo::UserAgent->new->get("https://mojolicious.org")'

# DESCRIPTION

[Devel::MojoProf](https://metacpan.org/pod/Devel::MojoProf) can add profiling output for blocking, non-blocking and
promise based methods. It can be customized to log however you want, but the
default is to print a line like the one below to STDERR:

    0.00038ms [Mojo::Pg::Database::query_p] SELECT 1 as whatever at path/to/app.pl line 23

# ATTRIBUTES

## reporter

    my $cb   = $prof->reporter;
    my $prof = $prof->reporter(sub { my ($prof, $report) = @_; ... });

A callback used to generate a log message for a profiled method. See the
description for the default output. The `$report` variable is a hash-ref with
the following example information:

    {
      file    => "path/to/app.pl",
      line    => 23,
      class   => "Mojo::Pg::Database",
      method  => "query_p",
      t0      => [Time::HiRes::gettimeofday],
      elapsed => Time::HiRes::tv_interval($report->{t0}),
      message => "SELECT 1 as whatever",
    }

The `$report` above will result in the following output, using the default
["reporter"](#reporter):

    0.00038ms [Mojo::Pg::Database::query_p] SELECT 1 as whatever at path/to/app.pl line 23

The log format is currently EXPERIMENTAL and could be changed.

Note that the `file` and `line` keys can be disabled by setting the
`DEVEL_MOJOPROF_CALLER` environment variable to "0". This can be useful to
speed up the run of the program.

# METHODS

## add\_profiling\_for

    my $prof = $prof->add_profiling_for($moniker);
    my $prof = $prof->add_profiling_for($class => $method1, $method2, ...);
    my $prof = $prof->add_profiling_for($class => $method1 => $make_message, ...);
    my $prof = $prof->add_profiling_for($class => $method1 => $make_message, ..., \%params);
    my $prof = $prof->add_profiling_for($class => $method1 => $make_message, ..., \%params);
    my $prof = Devel::MojoProf->add_profiling_for(...);

Used to add profiling for either a `$moniker` (short module identifier) or a
class and method. This method can also be called as a class method.

The supported `$moniker` are for now "mysql", "pg", "redis", "sqlite" and
"ua". See ["import"](#import) for more details.

It is also possible to manually add support for other custom modules. Here is
an example:

    $prof->add_profiling_for("My::Cool::Class", "get_stuff" => sub {
      my ($my_cool_obj, @args) = @_;
      return "This will be the 'message' part in the report";
    });

The CODE ref passed in will get all the arguments that the `get_suff()` method
gets, and the return value should be a string that becomes the `message` part
in the `$report` hash-ref passed to the ["reporter"](#reporter).

`%params` is optional and can have the following keys:

- ignore\_caller

    Defaults to a regex holding the `$class`, but can set to any class that you
    want to skip to generate the `class` key for the ["reporter"](#reporter) method.

## import

    use Devel::MojoProf (); # disable auto-detect
    use Devel::MojoProf;    # All of the modules from the list below
    use Devel::MojoProf -mysql;
    use Devel::MojoProf -pg;
    use Devel::MojoProf -redis;
    use Devel::MojoProf -sqlite;
    use Devel::MojoProf -ua;
    use Devel::MojoProf -pg, -redis, -ua; # Load multiple

Used to automatically ["add\_profiling\_for"](#add_profiling_for) know modules. Currently supported
modules are [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql), [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg), [Mojo::Redis](https://metacpan.org/pod/Mojo::Redis), [Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite) and
[Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent).

Please submit a PR or create an issue if you think more modules should be
supported at [https://github.com/jhthorsen/devel-mojoprof](https://github.com/jhthorsen/devel-mojoprof).

## singleton

    my $prof = Devel::MojoProf->singleton;

Used to retrive the singleton object that is used by ["add\_profiling\_for"](#add_profiling_for) when
called as a class method.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

# SEE ALSO

This module is inspired by [Devel::KYTProf](https://metacpan.org/pod/Devel::KYTProf).