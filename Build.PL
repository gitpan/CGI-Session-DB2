#! /usr/bin/perl

use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'CGI::Session::DB2',
     license => 'perl',
     requires => {
         DB2::db => '0.19',
         CGI::Session => '3.95',
         perl => '5.8.0',
     },
    );

$build->create_build_script();

