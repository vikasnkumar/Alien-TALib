use strict;
use warnings;
use Alien::Build::MB;
use File::Which 'which';
use File::Spec;

my $build = Alien::Build::MB->new(
    module_name => 'Alien::TALib',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for ta-lib from http://ta-lib.org',
    create_readme => 0,
    configure_requires => {
        'Module::Build' => 0,
        'Alien::Build' => 0,
        'Alien::Build::MB' => 0,
        'Software::License' => 0,
        'File::Which' => 0,
        'File::Spec' => 0,
    },
    build_requires => {
        'Alien::Build::MB' => 0,
        'Test::More' => 0,
        'Module::Build' => 0,
        'Software::License' => 0,
        'Alien::cmake3' => 0,
        'Mozilla::CA' => 0,
    },
    requires => {
        'perl' => '5.10.0',
        'Alien::Build::MB' => 0,
        'Alien::cmake3' => 0,
        #'Alien::MSYS' => 0,
    },
    meta_merge => {
        resources => {
            repository => "https://github.com/vikasnkumar/Alien-TALib",
            bugtracker => "https://github.com/vikasnkumar/Alien-TALib/issues",
        },
    },
);

$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### DATE: 26th Dec 2022
#### LICENSE: Refer LICENSE file.
if (0) {
print $Alien::Base::ModuleBuild::VERSION, "\n";
my $cflags = $ENV{TALIB_CFLAGS};
my $libs = $ENV{TALIB_LIBS};
$Alien::Base::ModuleBuild::Verbose = 1;
my ($talibconfig) = which('ta-lib-config');
$Alien::Base::ModuleBuild::Force = 1 unless $talibconfig;

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

if (defined $cflags and defined $libs) {
    $Alien::Base::ModuleBuild::Force = 0;
    print "Will NOT build ta-lib\n";
} else {
    $Alien::Base::ModuleBuild::Force = 1;
    $cflags = " -DHAVE_CONFIG_H";
    $libs = "-lpthread -ldl -lta_lib";
    print "Will build ta-lib\n";
}
print "Expected ta-lib cflags: $cflags\n";
print "Expected ta-lib libs: $libs\n";
}## endif-0
