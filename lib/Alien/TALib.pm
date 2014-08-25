package Alien::TALib;
use strict;
use warnings;
use File::Which 'which';
use File::Spec;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

our $VERBOSE = 0;

sub _find_ta_lib_config {
    my $cflags = $ENV{TALIB_CFLAGS};
    my $libs = $ENV{TALIB_LIBS};
    if (defined $cflags and defined $libs) {
        return {
            cflags => $cflags,
            libs => $libs,
        };
    }
    my ($talibconfig) = which('ta-lib-config');

    my $inc_dir = '';
    my $lib_dir = '';
    if (defined $talibconfig) {
        # usually the ta-lib-config is in the path format /abc/bin/ta-lib-config
        my ($vol, $dir, $file) = File::Spec->splitpath($talibconfig);
        my @dirs = File::Spec->splitdir($dir);
        pop @dirs if @dirs; # remove the bin/ portion from the path
        # create the include directory and lib directory path
        # to take care of ta-lib-config's malformed output
        # the user may have installed ta-lib-config in a non /usr/local area.
        $inc_dir = File::Spec->catdir(@dirs, 'include', 'ta-lib') if @dirs;
        $lib_dir = File::Spec->catdir(@dirs, 'lib') if @dirs;
        $inc_dir = File::Spec->catfile($vol, $inc_dir) if $inc_dir;
        $lib_dir = File::Spec->catfile($vol, $lib_dir) if $lib_dir;
        $inc_dir = File::Spec->canonpath($inc_dir);
        $lib_dir = File::Spec->canonpath($lib_dir);
        if (not defined $libs) {
            $libs = `$talibconfig --libs`;
            chomp $libs if length $libs;
            $libs =~ s/[\s\n\r]*$// if length $libs;
            $libs .= " -lta_lib" if length $libs && $libs !~ /-lta_lib/;
            # fix the problem with ta-lib-config --libs giving the wrong -L path
            $libs = "-L$lib_dir $libs" if $lib_dir;
        }
        if (not defined $cflags) {
            $cflags = `$talibconfig --cflags`;
            chomp $cflags if length $cflags;
            $cflags =~ s/[\s\n\r]*$// if length $cflags;
            $cflags = "-I$inc_dir $cflags" if $inc_dir;
        }
    }
    return unless (defined $cflags and defined $libs);
    #$cflags = " -DHAVE_CONFIG_H";
    #$libs = "-lpthread -ldl -lta_lib";
    if ($VERBOSE) {
        print "Expected ta-lib cflags: $cflags\n" if defined $cflags;
        print "Expected ta-lib libs: $libs\n" if defined $libs;
    }
    return {
        cflags => $cflags,
        libs => $libs,
        talibconfig => $talibconfig,
    };
}

sub new {
    my $class = shift || __PACKAGE__;
    my $obj = {};
    my $installed = &_find_ta_lib_config();
    if ($installed) {
        $obj->{installed} = 1;
        foreach (keys %$installed) {
            $obj->{$_} = $installed->{$_};
        }
    }
    return bless($obj, $class);
}

sub cflags { return shift->{cflags}; }
sub libs { return shift->{libs}; }
sub installed { return shift->{installed}; }
sub ta_lib_config { return shift->{talibconfig}; }

1;

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### LICENSE: Refer LICENSE file.

=head1 NAME

Alien::TALib

=head1 SYNOPSIS

Alien::TALib is a perl module that enables the installation of the technical
analysis library TA-lib from "L<http://ta-lib.org>" on the system and easy
access by other perl modules in the methodology cited by Alien::Base.

You can use it in the C<Build.PL> file if you're using Module::Build or
C<Makefile.PL> file if you're using ExtUtils::MakeMaker.

            my $talib = Alien::TALib->new;

            my $build = Module::Build->new(
                ...
                extra_compiler_flags => $talib->cflags(),
                extra_linker_flags => $talib->libs(),
                ...
            );


=head1 VERSION

0.04

=head1 WARNING

This module is not supported on Windows unless running under Cygwin. We are
working to fix this soon.

=head1 METHODS

=over

=item B<cflags>

This method provides the compiler flags needed to use the library on the system.

=item B<libs>

This method provides the linker flags needed to use the library on the system.

=item B<config>

This method provides the access to configuration information for the library on
the system. More information can be seen in the module
L<Alien::TALib::ConfigData>.

=back

=head1 SEE ALSO

=over

=item C<Alien::TALib::ConfigData>

=back

=head1 AUTHORS

Vikas N Kumar <vikas@cpan.org>

=head1 REPOSITORY

L<https://github.com/vikasnkumar/Alien-TALib.git>

=head1 COPYRIGHT

Copyright (C) 2013-2014. Vikas N Kumar <vikas@cpan.org>. All Rights Reserved.

=head1 LICENSE

This is free software. YOu can redistribute it or modify it under the terms of
Perl itself.
