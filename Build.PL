use strict;
use warnings;
use Module::Build;
use File::Spec;
use File::Which qw(which);
use LWP::Simple qw(getstore is_success);
use Archive::Tar;
use Archive::Zip;
use Cwd ();

my $VERBOSE = 0;

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
    my $prefix = shift || $ENV{PREFIX};
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

sub _find_ta_lib_config {
    my ($taconf, $prefix) = @_; # pass an existing ta-lib-config as argument
    my $cflags = $ENV{TALIB_CFLAGS};
    my $libs = $ENV{TALIB_LIBS};
    if (defined $cflags and defined $libs) {
        return {
            cflags => $cflags,
            libs => $libs,
            installed => 1,
        };
    }
    my ($talibconfig) = $taconf || which('ta-lib-config');
    if (not defined $talibconfig and defined $prefix) {
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
        ta_lib_config => $talibconfig,
        installed => 1,
    };
}

my $build = Module::Build->new(
    module_name => 'Alien::TALib',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for ta-lib from http://ta-lib.org',
    create_readme => 1,
    create_license => (-e 'LICENSE' ? 0 : 1),
    needs_compiler => 1,
    configure_requires => {
        'Module::Build' => 0,
        'Software::License' => 0,
        'File::Spec' => 0,
        'File::Which' => 0,
        'LWP::Simple' => 0,
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'Cwd' => 0,
    },
    build_requires => {
        'Module::Build' => 0,
        'Test::More' => 0,
        'Software::License' => 0,
        'File::Spec' => 0,
        'File::Which' => 0,
        'LWP::Simple' => 0,
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'Cwd' => 0,
    },
    requires => {
        'File::Spec' => 0,
        'File::Which' => 0,
        'LWP::Simple' => 0,
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'Cwd' => 0,
    },
    meta_merge => {
        resources => {
            repository => "https://github.com/vikasnkumar/Alien-TALib",
            bugtracker => "https://github.com/vikasnkumar/Alien-TALib/issues",
        },
    },
);
$VERBOSE = $build->verbose;
my $installed = &_find_ta_lib_config();
if ($ENV{TALIB_FORCE} or not $installed) {
    # ok ta-lib was not found or build was forced
    # so build it
    if ($^O =~ /Win32/i) {
        $installed = &_build_talib_src_win32();
    } else {
        # cygwin/linux/bsd/darwin
        my $prefix = $ENV{PREFIX} || $build->install_destination('bin');
        $prefix =~ s/bin\/?$//g if defined $prefix; # remove the bin
        my $taconf = &_build_talib_src_unix($prefix);
        $installed = &_find_ta_lib_config($taconf, $prefix);
    }
}
die "Unable to find ta-lib or install it" unless $installed;

foreach (keys %$installed) {
    $build->config_data($_ => $installed->{$_});
}
#my $pref = $build->install_destination('bin');
#$pref =~ s/bin\/?$//g; # remove the bin. Maybe use File::Basename
#$build->config_data(prefix => $ENV{PREFIX} || $build->prefix() || $pref);
$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');
$build->dispatch('build');

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### LICENSE: Refer LICENSE file.
