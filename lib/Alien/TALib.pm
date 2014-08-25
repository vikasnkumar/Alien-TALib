package Alien::TALib;
use strict;
use warnings;
use File::Which 'which';
use File::Spec;
use LWP::Simple qw(getstore is_success);
use Archive::Tar;
use Archive::Zip;
use Alien::TALib::ConfigData;
use Cwd ();

our $VERSION = '0.05';
$VERSION = eval $VERSION;

our $VERBOSE = 0;
our $FORCE = 0;

sub _find_ta_lib_config {
    my $taconf = shift; # pass an existing ta-lib-config as argument
    my $cflags = $ENV{TALIB_CFLAGS};
    my $libs = $ENV{TALIB_LIBS};
    if (defined $cflags and defined $libs) {
        return {
            cflags => $cflags,
            libs => $libs,
        };
    }
    my ($talibconfig) = $taconf || which('ta-lib-config');
    unless ($talibconfig) {
        my $prefix = $ENV{PREFIX} || Alien::TALib::ConfigData->config('prefix');
        $talibconfig = File::Spec->catfile($prefix, 'bin', 'ta-lib-config');
    }

    my $inc_dir = '';
    my $lib_dir = '';
    if (defined $talibconfig) {
        print "ta-lib-config found installed at $talibconfig\n" if $VERBOSE;
        # usually the ta-lib-config is in the path format /abc/bin/ta-lib-config
        my ($vol, $dir, $file) = File::Spec->splitpath($talibconfig);
        my (@dirs) = File::Spec->splitdir($dir);
        pop @dirs if $dirs[$#dirs] eq '';
        pop @dirs if $dirs[$#dirs] eq 'bin';
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
    if ($FORCE or not $installed) {
        # ok ta-lib was not found or build was forced
        # so build it
        if ($^O =~ /Win32/i) {
            &_build_talib_src_win32();
        } else {
            # cygwin/linux/bsd/darwin
            my $taconf = &_build_talib_src_unix();
            $installed = &_find_ta_lib_config($taconf);
        }
    }
    if ($installed) {
        $obj->{installed} = 1;
        foreach (keys %$installed) {
            $obj->{$_} = $installed->{$_};
        }
    } else {
        die "Unable to find a ta-lib installation.";
    }
    return bless($obj, $class);
}

sub cflags { return shift->{cflags}; }
sub libs { return shift->{libs}; }
sub is_installed { return shift->{installed}; }
sub ta_lib_config { return shift->{talibconfig}; }

sub _build_talib_src_win32 {
    my $src_url = 'http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-msvc.zip';
    my $dest = 'ta-lib-0.4.0-mscv.zip';
    unless (-e $dest and -e 'ta-lib') {
        print "Trying to download $dest from $src_url\n" if $VERBOSE;
        my $rc = getstore($src_url, $dest);
        die "Unable to download source from $src_url into $dest" unless is_success($rc);
        if (Archive::Tar->has_zlib_support) {
            my $files = Archive::Tar->extract_archive($dest, COMPRESS_GZIP);
            die "Unable to extract source code in $dest ", Archive::Tar->error unless $files;
            die "Cannot find ta-lib/ directory" unless -d 'ta-lib';
        } else {
            die "No gzip/zlib support enabled in Archive::Tar. Cannot extract $dest";
        }
    } else {
        print "$dest already exists and is unarchived in ta-lib\n" if $VERBOSE;
    }
}

sub _build_talib_src_unix {
    my $src_url = 'http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz';
    my $dest = 'ta-lib-0.4.0-src.tar.gz';
    unless (-e $dest and -e 'ta-lib') {
        print "Trying to download $dest from $src_url\n" if $VERBOSE;
        my $rc = getstore($src_url, $dest);
        die "Unable to download source from $src_url into $dest" unless is_success($rc);
        if (Archive::Tar->has_zlib_support) {
            my $files = Archive::Tar->extract_archive($dest, COMPRESS_GZIP);
            die "Unable to extract source code in $dest ", Archive::Tar->error unless $files;
            die "Cannot find ta-lib/ directory" unless -d 'ta-lib';
        } else {
            die "No gzip/zlib support enabled in Archive::Tar. Cannot extract $dest";
        }
    } else {
        print "$dest already exists and is unarchived in ta-lib\n" if $VERBOSE;
    }
    my $prefix = $ENV{PREFIX} || Alien::TALib::ConfigData->config('prefix');
    my $prefix_cmd = "--prefix=$prefix" if $prefix;
    $prefix_cmd = '' unless $prefix;
    my @build_commands = (
        "./configure $prefix_cmd",
        'make',
        'make check',
        'make install',
    );
    my $cwd = Cwd::getcwd;
    chdir('ta-lib');
    my $ncwd = Cwd::getcwd;
    foreach my $cmd (@build_commands) {
        print "Executing $cmd\n" if $VERBOSE;
        system($cmd) == 0 || die "Unable to run '$cmd' in $ncwd";
    }
    chdir $cwd;
    my $taconf = File::Spec->catfile($prefix, 'bin', 'ta-lib-config');
    return $taconf if -e $taconf;
    die "Tried building the source but cannot find $taconf" unless -e $taconf;
}

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

0.05

=head1 DESCRIPTION

Installing ta-lib on various platforms can be a hassle for the end-user. Hence
the modules like L<Finance::Talib> and L<PDL::Finance::Talib> may choose to use
L<Alien::TALib> for automatically checking and verifying that there are already
existing installs of ta-lib on the system and if not, installing the ta-lib
libraries on the system.

=head1 METHODS

=over

=item B<new>

This method finds an already installed ta-lib or can install it if not found or
if the install is forced by setting the $Alien::TALib::FORCE variable to 1.
The user can set TALIB_CFLAGS at runtime to override the B<cflags> output of the
object created with this function.
The user can also set TALIB_LIBS at runtime to override the B<libs> output of
the object created with this function.

=item B<cflags>

This method provides the compiler flags needed to use the library on the system.

=item B<libs>

This method provides the linker flags needed to use the library on the system.

=item B<talibconfig>

This method returns the path of the ta-lib-config executable if it has been
installed.

=item B<is_installed>

This method returns a boolean saying whether ta-lib has been installed or not.

=item B<config>

This method provides the access to configuration information for the library on
the system. More information can be seen in the module
L<Alien::TALib::ConfigData>.

=back

=head1 SPECIAL VARIABLES

=over

=item $Alien::TALib::VERBOSE

Setting this value to 1 will turn on some verbose statements to help the user
debug the problems they are facing in using this module.

=item $Alien::TALib::FORCE

Setting this value to 1 before calling the B<new()> method will force the
download and install of the B<ta-lib> library.

=item $ENV{TALIB_CFLAGS} and $ENV{TALIB_LIBS}

Setting these environment variables will force Alien::TALib to use the values
that these provide as part of the B<new()> object's methods like B<cflags()> and
B<libs()>.

=item $ENV{PREFIX}

Setting this environment variable before running Build.PL will configure
Alien::TALib::ConfigData to use this value as the install prefix of B<ta-lib> if
it is built and installed.

Setting this environment variable before calling the B<new()> method will use
this as a place to look for B<ta-lib-config> if it has been installed or will
install B<ta-lib> if needed with this location as prefix.

=back

=head1 SEE ALSO

=over

=item C<Alien::TALib::ConfigData>

=item C<PDL::Finance::Talib>

=item C<Finance::Talib>

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
