#!/usr/bin/perl
#
# Reanimator - audio filez renamer
# Copyright 2003 legion <a.lepore@xxxxxxxx>

use warnings;
use strict;
# modules #
use MP3::Info qw(:all);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

# config #
my $user = $ENV{USER};
my $config = "/home/$user/.reanimatorrc";
my $autofile = "/home/$user/.autosub";

if (!-e $config) {
        print BOLD "!!! $config : missing file.\nplease copy it from reanimator 
package\n";
        exit 1;
}
if (!-e $autofile) {
        print BOLD "!!! $autofile : missing file.\nplease copy it from 
reanimator package\n";
        exit 1;
}
require $config; # import conf file
our (@extensions,@word_separators);
if (@extensions eq 0 or @word_separators eq 0) {
        print BOLD "!!! $config : invalid configuration file.\nplease fix 
it.\n";
        exit 1;
}

# functions #
# some vars
my (@allfiles,@truefilez,@autoall,$path,$arg1,$name,$version);

### getfilez
sub getfilez {
        opendir(ROOT, $path) or die "!!! $path : $!\n";
        @allfiles = readdir(ROOT);
        closedir(ROOT);
        @allfiles = sort @allfiles;

        @truefilez = ();
        foreach (@allfiles) {
        my $file = $_;
                foreach (@extensions) {
                my $ext = $_;
                if ($file =~ /\.$ext$/i) {
                        push(@truefilez,$file);
                }
                }
        }
} ##################################################################

### getmp3
sub getmp3 {
        opendir(ROOT, $path) or die "!!! $path : $!\n";
        @allfiles = readdir(ROOT);
        closedir(ROOT);
        @allfiles = sort @allfiles;
        
        @truefilez = ();
        foreach (@allfiles) {
        my $file = $_;
                if ($file =~ /\.mp3$/i) {
                        push(@truefilez,$file);
                }
        }
} ##################################################################

### getauto
sub getauto {
        open(AUTOFILE, $autofile) or die "!!! $autofile : $!";
        @autoall = <AUTOFILE>;
        close (AUTOFILE);

} ##################################################################

### help
sub helpfunc {
print <<STOP
 Syntax: reanimator <action> <directory>
 
 Actions:
 add, a                 add a prefix to filenames
 del, d                 delete a string in filenames
 mod, m                 replace a string to filenames
 tagdel, td             remove id3 tag (mp3 only)
 tagadd, ta             add id3v1 tag (mp3 only)
 tagrename, tr          rename file according to id3 tag (mp3 only)
 lower, lo              lowercase filenames
 upper, up              uppercase filenames
 sentence, se           sentencecase (only first char uppercase)
 large, la              largecase (first char uppercased on all words)
 auto, au               autorename files according to $autofile file

 
STOP
} ##################################################################

### add
sub addfunc {

my ($addstring,$path) = @_;
print BOLD "\nI will prefix '$addstring' on '@extensions' files\n";
print "(";
print BOLD "Y";
print "es/";
print BOLD "N";
print "o/";
print BOLD "T";
print "est)\n";
chomp(my $choice=<STDIN>);

if ($choice =~ /^y$|^yes$|^t$|^test$/i) {
        getfilez();
        
        foreach (@truefilez) {
        my $file = $_;
        
                next if /^\./;
                next if (-d "$path/$file");
                
                #real or test?
                if ($choice =~ /^y$|^yes$/i) { # if real
                if ("$path/$file" ne "$path/$addstring$file") { 
                        print "renaming: '$file' => '$addstring$file'";

                        if (-e "$path/$addstring$file") {
                                print BOLD "  SKIPPED, file exist\n";
                        }
                        else {
                                if 
(rename("$path/$file","$path/$addstring$file")) {
                                        print "  [OK]\n";
                                }
                                else {
                                        print BOLD "  FAILED!\n";
                                }
                        }
                }
                }
                else { # if test
                        next if ("$path/$file" eq "$path/$addstring$file");
                        next if (-e "$path/$addstring$file");
                        print "Preview: '$file' => '$addstring$file'\n";
                }
        }
        if ($choice =~ /^y$|^yes$/i) { print "\n"; }
        else { addfunc($addstring,$path); }
}

elsif ($choice =~ /^n$|^no$/i) {
        print "\n";
}

else {
addfunc($addstring,$path)
}
} ##################################################################

### del
sub delfunc {

my ($delstring,$path) = @_;
print BOLD "\nI will delete '$delstring' on '@extensions' files\n";
print "(";
print BOLD "Y";
print "es/";
print BOLD "N";
print "o/";
print BOLD "A";
print "ll Occurrences/";
print BOLD "T";
print "est/";
print BOLD "T";
print "est";
print BOLD "A";
print "ll)\n";
chomp(my $choice=<STDIN>);

if ($choice =~ /^y$|^yes$|^a$|^all|^t$|^test$|^ta$|^testall$/i) {
        getfilez();

        foreach (@truefilez) {
        my $file = $_;
        my $newfile;
        
                next if /^\./;
                next if (-d "$path/$file");

                if ($choice =~ /^y|^t$|^test$/i) { ($newfile = $file) =~ 
s/$delstring//; }
                else { ($newfile = $file) =~ s/$delstring//g; }
                
                # real or test?
                if ($choice =~ /^y|^a$|^all/i) { # if real
                if ("$path/$file" ne "$path/$newfile") { 
                        print "renaming: '$file' => '$newfile'";

                        if (-e "$path/$newfile") {
                                print BOLD "  SKIPPED, file exist\n";
                        }
                        else {
                                if (rename("$path/$file","$path/$newfile")) {
                                        print "  [OK]\n";
                                }
                                else {
                                        print BOLD "  FAILED!\n";
                                }
                        }
                }
                }
                else { # if test
                        next if (-e "$path/$newfile");
                        next if ("$path/$file" eq "$path/$newfile");
                        print "Preview: '$file' => '$newfile'\n";
                }
                
        }
        if ($choice =~ /^y$|^yes$|^a$|^all/i) { print "\n"; }
        else { delfunc($delstring,$path); }
}

elsif ($choice =~ /^n$|^no$/i) {
        print "\n";
}

else {
        delfunc($delstring,$path);
}
} ##################################################################


### mod
sub modfunc {

my ($modstring,$newstring,$path) = @_;
print BOLD "\nI will replace '$modstring' with '$newstring' on '@extensions' 
files\n";
print "(";
print BOLD "Y";
print "es/";
print BOLD "N";
print "o/";
print BOLD "A";
print "ll Occurrences/";
print BOLD "T";
print "est/";
print BOLD "T";
print "est";
print BOLD "A";
print "ll)\n";
chomp(my $choice=<STDIN>);      

if ($choice =~ /^y$|^yes$|^a$|^all|^t$|^test$|^ta$|^testall$/i) {
        getfilez();

        foreach (@truefilez) {
        my $file = $_;
        my $newfile;
        
                next if /^\./; 
                next if (-d "$path/$file");

                if ($choice =~ /^y|^t$|^test$/i) { ($newfile = $file) =~ 
s/$modstring/$newstring/; }
                else { ($newfile = $file) =~ s/$modstring/$newstring/g; }
                
                # real or test?
                if ($choice =~ /^y|^a$|^all/i) { # if real
                if ("$path/$file" ne "$path/$newfile") { 
                        print "renaming: '$file' => '$newfile'";

                        if (-e "$path/$newfile") {
                                print BOLD "  SKIPPED, file exist\n";
                        }
                        else {
                                if (rename("$path/$file","$path/$newfile")) {
                                        print "  [OK]\n";
                                }
                                else {
                                        print BOLD "  FAILED!\n";
                                }
                        }
                }
                }
                else { # if test
                        next if (-e "$path/$newfile");
                        next if ("$path/$file" eq "$path/$newfile");
                        print "Preview: '$file' => '$newfile'\n";
                }
        }
        if ($choice =~ /^y$|^yes$|^a$|^all/i) { print "\n"; }
        else { modfunc($modstring,$newstring,$path); } 
}

elsif ($choice =~ /^n$|^no$/i) {
        print "\n";
}

else {
        modfunc($modstring,$newstring,$path);
}
} ##################################################################

### tagdel
sub tagdelfunc {

my ($path) = @_;
print BOLD "I will delete id3 tags on 'mp3' files\n";
print "(id3v";
print BOLD "1";
print "/";
print "id3v";
print BOLD "2";
print "/";
print BOLD "B";
print "oth/";
print BOLD "V";
print "iew Tags/";
print BOLD "E";
print "xit).\n";
chomp(my $choice=<STDIN>);

if ($choice =~ /^b$|^both$|1$|2$/i) {
        getmp3();

        foreach (@truefilez) {
        my $file = $_;

                next if /^\./;
                next if (-d "$path/$file");
                my $info = get_mp3tag("$path/$file");
                if ($info) {
                        print "removing tag on `$file`\n";
                        if ($choice =~ /^b/i) { 
remove_mp3tag("$path/$file","ALL"); }
                        if ($choice =~ /1$/) { remove_mp3tag("$path/$file",1); }
                        if ($choice =~ /2$/) { remove_mp3tag("$path/$file",2); }
                }
        }
        print "\n";
}

elsif ($choice =~ /^v$|^view$/i) {
        getmp3();

        foreach (@truefilez) {
        my $file = $_;

                next if /^\./;
                next if (-d "$path/$file");
                my $info = get_mp3tag("$path/$file");
                if ($info) {
                        print "'$info->{ARTIST} - $info->{TITLE}' (file: 
'$file' - $info->{TAGVERSION})\n";
                }
        }
        print "\n";
        tagdelfunc($path);
}
elsif ($choice =~ /^e$|^exit$/i) {
        print "\n";
}

else {
        tagdelfunc($path);
}
} ##################################################################

### tagadd
sub tagaddfunc {
my ($path) = @_;

print BOLD "I will add id3v1 tag on 'mp3' files in current directory\n";
print "(";
print BOLD "Y";
print "es/";
print BOLD "N";
print "o/";
print BOLD "V";
print "iew tags)\n";
chomp(my $choice=<STDIN>);

if ($choice =~ /^y$|^yes$/i) {
        getmp3();

if (@truefilez != 0) {

                print BOLD "Global settings:\n";
                print "Enter value for ARTIST:\t\t";
                chomp(my $artist=<STDIN>);
                print "Enter value for ALBUM:\t\t";
                chomp(my $album=<STDIN>);
                print "Enter value for YEAR:\t\t";
                chomp(my $year=<STDIN>);
                print "Enter value for COMMENT:\t";
                chomp(my $comment=<STDIN>);
                my $genre;
                my $genreok;
                while (!$genreok) {
                print "Enter value for GENRE:\t\t";
                chomp($genre=<STDIN>);
                if (!$genre) { last; }
                foreach (@mp3_genres) {
                        my $validgenre = $_;
                        if ($validgenre =~ /^$genre$/i) {
                                $genreok = $genre;
                        }
                }
                if (!$genreok) {
                        print "'$genre' is not a standard genre.\n";
                }
                }
                
                my %titles = ();
                my %tracknums = ();
                foreach (@truefilez) {
                        my $file = $_;
                        print BOLD "\nSettings for $file:\n";
                        print "Enter value for TITLE:\t\t";
                        chomp(my $title=<STDIN>);
                        $titles{"$file"} .= "$title";
                        print "Enter value for TRACKNUM:\t";
                        chomp(my $tracknum=<STDIN>);
                        $tracknums{"$file"} .= "$tracknum";
                }
                
        print "\nOk,proceed? (";
        print BOLD "Y";
        print "es/";
        print BOLD "N";
        print "o)\n";
        chomp(my $choice2=<STDIN>);
        
        if ($choice2 =~ /^y$|^yes$/i) {

        foreach (@truefilez) {
        my $file = $_;
        
                next if /^\./;
                next if (-d "$ path/$file");
                print "tagging `$file`";
                if 
(set_mp3tag($file,$titles{"$file"},$artist,$album,$year,$comment,$genre,$tracknums{"$file"}))
 {
                        print "  [OK]\n";
                }
                else {
                        print BOLD "  FAILED!\n";
                }
        }
        }
        else {
                print "\n";
        }
        print "\n";
        
}
        
        else {
                print "No mp3 files in this directory.\n";
        }
}
elsif ($choice =~ /^n$|^no$/i) {
        print "\n";
}
elsif ($choice =~ /^v$|^view/i) {
        getmp3();

        foreach (@truefilez) {
        my $file = $_;

                next if /^\./;
                next if (-d "$path/$file");
                my $info = get_mp3tag("$path/$file");
                if ($info) {
                        print "'$info->{ARTIST} - $info->{TITLE}' ($file - 
$info->{TAGVERSION})\n";
                }
        }
        print "\n";
        tagaddfunc($path);
}
else {
        tagaddfunc($path);
}
} ##################################################################

### tagren
sub tagrenfunc {
my ($path) = @_;

print BOLD "Enter the filenames look string:\n";
print "(using: #A (artist), #T (title), #B (album), #N (track number), #Y 
(year))\n";
print "Example: #A - [#N] - #T for Artist - [Number] - Title.mp3\n";
chomp(my $look=<STDIN>);
if (!$look) { tagrenfunc($path); }
print BOLD "\nI will rename 'mp3' files according to their id3 tag\n";
print "(";
print BOLD "Y";
print "es/";
print BOLD "N";
print "o) or (";
print BOLD "T";
print "est) for preview\n";
chomp(my $choice=<STDIN>);

if ($choice =~ /^y$|^yes$|^t$|^test$/i) {
        getmp3();
        
        foreach (@truefilez) {
        my $file = $_;
        my $new = $look;

                next if /^\./;
                next if (-d "$path/$file");
                my $info = get_mp3tag($file);
                        
                if ($info) {

                        $new =~ s/#A/$info->{ARTIST}/g;
                        $new =~ s/#T/$info->{TITLE}/g;
                        $new =~ s/#B/$info->{ALBUM}/g;
                        $new =~ s/#N/$info->{TRACKNUM}/g;
                        $new =~ s/#Y/$info->{YEAR}/g;
                                        
                        $new =~ s/  / /g; # remove multiple spaces
                        $new =~ s/__/_/g;
                        while ($new =~ /^ /) { $new =~ s/^ //; } # no spaces as 
first char
                        
                        if ($choice =~ /^y$|^yes$/i) {
                                print "renaming: '$file' => '$new.mp3'";
                                if (rename("$path/$file","$path/$new.mp3")) {
                                        print "  [OK]\n";
                                }
                                else {
                                        print BOLD "  FAILED!\n";
                                }
                        }
                        else {
                                print "Preview: '$file' => '$new.mp3'\n";
                        
                        }
                }
        }
        print "\n";
        if ($choice =~ /^y$|^yes$/i) { print "\n"; }
        else { tagrenfunc($path); }
}

elsif ($choice =~ /^n$|^no$/i) {
        print "\n";
}

else {
        tagrenfunc($path);
        }
} ##################################################################

### case
sub casefunc {
my ($path,$arg1) = @_;
my $action;
if ($arg1 =~ /^lo$|^lower$/i) { $action="lowercase"; }
elsif ($arg1 =~ /^up$|^upper$/i) { $action="uppercase"; }
elsif ($arg1 =~ /^se$|^sentence$/i) { $action="uppercase firts character on"; }
elsif ($arg1 =~ /^la$|^large$/i) { $action="uppercase first char of all word 
on";  }

print BOLD "I will $action '@extensions' files\n";
print "(";
print BOLD "Y";
print "es/";
print BOLD "N";
print "o/";
print BOLD "T";
print "est)\n";
chomp(my $choice=<STDIN>);

if ($choice =~ /^y$|^yes$|^t$|^test$/i) {
        getfilez();
        
        foreach (@truefilez) {
        my $file = $_;
        my $newfile;
                next if /^\./;
                next if (-d "$path/$file");
                
                if ($arg1 =~ /^lo$|^lower$/i) {
                        ($newfile = $file) =~ tr/A-Z/a-z/;
                }
                elsif ($arg1 =~ /^up$|^upper$/i) {
                        ($newfile = $file) =~ tr/a-z/A-Z/;
                        foreach (@extensions) { # lowercase extensions
                        my $ext = $_;
                        my $newext;
                        if ($newfile =~ /\.$ext$/i) {
                                ($newext = $ext) =~ tr/A-Z/a-z/;
                                $newfile =~ s/\.$ext$/\.$newext/i;
                        }
                        }
                }
                elsif ($arg1 =~ /^se$|^sentence$/i) {
                        ($newfile = $file) =~ tr/A-Z/a-z/;
                        my @filename = split(//,$newfile);
                        $filename[0] =~ tr/a-z/A-Z/;
                        $newfile = join("",@filename);
                }
                elsif ($arg1 =~ /^la$|^large$/i) {
                        ($newfile = $file) =~ tr/A-Z/a-z/;
                        foreach(@word_separators) {
                        my $sep = $_;
                                my $suf="\\"; # needed for particular chars 
(like '.')
                                my @filearr = split(/$suf$sep/,$newfile);
                                my @newfilearr = ();
                                foreach (@filearr) {
                                my $list = $_;
                                        my @listarr = split(//,$list);
                                        $listarr[0] =~ tr/a-z/A-Z/;
                                        $list = join("",@listarr);
                                        push(@newfilearr,$list);
                                }
                                $newfile = join($sep,@newfilearr);
                        }
                        foreach (@extensions) { # lowercase extensions
                        my $ext = $_;
                        my $newext;
                        if ($newfile =~ /\.$ext$/i) {
                                ($newext = $ext) =~ tr/A-Z/a-z/;
                                $newfile =~ s/\.$ext$/\.$newext/i;
                        }
                        }
                }
                # real or test?
                if ($choice =~ /^y$|^yes$/i) { # if real
                if ("$path/$file" ne "$path/$newfile") {
                        print "renaming: '$file' => '$newfile'";

                        if (-e "$path/$newfile") {
                                print BOLD "  SKIPPED, file exist\n";
                        }
                        else {
                                if (rename("$path/$file","$path/$newfile")) {
                                        print "  [OK]\n";
                                }
                                else {
                                        print BOLD "  FAILED!\n";
                                }
                        }
                }
                }
                else { # if test
                        next if (-e "$path/$newfile");
                        next if ("$path/$file" eq "$path/$newfile");
                        print "Preview: '$file' => '$newfile'\n";
                }
        }
        if ($choice =~ /^y/i) { print "\n"; }
        else { print "\n"; casefunc($path,$arg1); }
        
}
elsif ($choice =~ /^n$|^no$/i) {
        print "\n";
}
else {
        casefunc($path,$arg1);
}
} ##################################################################

### auto
sub autofunc {
my ($path) = @_;

print BOLD "I will rename '@extensions' files according to the $autofile 
file\n";
print "(";
print BOLD "Y";
print "es/";
print BOLD "N";
print "o/";
print BOLD "T";
print "est)\n";
chomp(my $choice=<STDIN>);

if ($choice =~ /^y$|^yes$|^t$|^test$/i) {
        getfilez();

        foreach (@truefilez) {
        my $file = $_;
        my $newfile = $file;;
                getauto();
                foreach(@autoall) {
                        my $line = $_;
                        next if /^\#/;
                        next if /^\s/;
                        my @line = split(/;;/,$line);
                        if ($#line != 1) {
                                chomp $line;
                                print "[$line : syntax error, fix $autofile]\n";
                                next;
                        }
                        my $if = $line[0];
                        chomp(my $of = $line[1]);
                        $newfile =~ s/$if/$of/i;
                }
                if ("$path/$file" ne "$path/$newfile") {
                        if ($choice =~ /^y$|^yes$/i) { print "renaming: '$file' 
=> '$newfile'\n"; }
                        if ($choice =~ /^t$|^test$/i) { print "preview: '$file' 
=> '$newfile'\n"; }             
                }
        }
        if ($choice =~ /^y/i) { print "\n"; }
        else { print "\n"; autofunc($path); }
}

elsif ($choice =~ /^n$|^no$/i) {
        print "\n";
}       
} ##################################################################

### main

$name="Reanimator";
$version="1.0-rc1";

print BOLD "\n$name (";
print "$version";
print BOLD ")";
print " - audio filez renamer. USE AT YOUR OWN RISK\n\n";

if ($#ARGV != 1 ){ # we want 2 arguments
        helpfunc(); 
        exit;
}

$arg1=$ARGV[0];
$path=$ARGV[1];

if (-d $path) {
        if ($arg1 =~ /^a$|^add$/i) {
                my $addstring;
                while (!$addstring) {
                        print BOLD "Enter the prefix you want to add:\n";
                        chomp($addstring=<STDIN>);
                }
                addfunc($addstring,$path);
        }
        elsif ($arg1 =~ /^d$|^del$/i) {
                my $delstring;
                while (!$delstring) {
                        print BOLD "Enter the string you want to delete:\n";
                        chomp($delstring=<STDIN>);
                }
                delfunc($delstring,$path);
        }
        elsif ($arg1 =~ /^m$|^mod$/i) {
                my ($modstring,$newstring);
                while (!$modstring) {
                        print BOLD "Enter the string you want to replace:\n";
                        chomp($modstring=<STDIN>);
                }
                while (!$newstring) {
                        print BOLD "Enter the new string:\n";
                        chomp($newstring=<STDIN>);
                }
                if ($modstring eq $newstring) {
                        print "You have entered the same string.\n";
                        exit;
                }
                modfunc($modstring,$newstring,$path);
        }
        elsif ($arg1 =~ /^td$|^tagdel$/i) {
                tagdelfunc($path);
        }
        elsif ($arg1 =~ /^ta$|^tagadd$/i) {
                tagaddfunc($path);
        }
        elsif ($arg1 =~ /^tr$|^tagren$/i) {
                tagrenfunc($path);
        }
        elsif ($arg1 =~ 
/^lo$|^lower$|^up$|^upper$|^se$|^sentence$|^la$|^large$/i) {
                casefunc($path,$arg1);
        }
        elsif ($arg1 =~ /^au$|^auto$/i) {
                autofunc($path);
        }
        else {
                helpfunc();
        }
}
else {
        print BOLD "ERROR: ";
        print "$path is not a valid directory!\n";
} ##################################################################
