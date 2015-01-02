#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;
use Getopt::Long;

my $utdir = $ENV{HOME} . "/Games/ut/";
my $cachedir = $ENV{HOME} . "/.loki/ut/" . "Cache/";
my $utdep = "$ENV{HOME}/Scripts/dev/utdep.pl";

my %names;
my ($found, $done, $error, $all) = (0, 0, 0, 0);
my $version = "0.3";

GetOptions("a|all" => \$all);

# check if directories exist
unless (-e $cachedir . "cache.ini") {
  print "Warning: source file " . $cachedir . "cache.ini doesn't exist\n";
  exit;
}

foreach ("System", "Music", "Textures", "Sounds", "Maps") {
  unless (-e $utdir . $_) {
    print "Warning: target directory $utdir$_ doesn't exist\n";
    exit;
  }
}

if ($all and (!-e $utdep)) {
  print "Warning: can't find utdep.pl, using normal mode\n";
  $all = 0;
}

print "Reading cache.ini\n";
open(CACHEINI, "<", $cachedir . "cache.ini") or die "Can't open ini: $!";
while(<CACHEINI>) {
  chomp $_;
  $_ =~ s/[\n\r]//g;
  next unless $_ =~ m/=/;
  my ($cname, $rname) = split(/=/, $_);
  $names{$cname . ".uxx"} = $rname;
}

print "Cleaning cache\n";
opendir(DIR, $cachedir) or die "Can't open cachedir: $!";
while($_ = readdir(DIR)) {
  if ($_ =~ m/\.uxx/) {
    $found++;
    my $rname = $names{$_};
    unless (defined($rname)) {
      print $_ . ": Real name not found\n";
      $error++;
    }
    elsif ($rname =~ m/\.u$/i) {
      # it's a uscript
      if (move($cachedir . $_, $utdir . "System/" . $rname)) {
        print $_ . " --> System/" . $rname . "\n";
        delete($names{$_});
        $done++;
      }
      else {
        print "$rname: Couldn't be moved: $!\n";
        $error++;
      }
    }
    elsif ($rname =~ m/\.unr$/i) {
      # it's a map
      if (move($cachedir . $_, $utdir . "Maps/" . $rname)) {
        print $_ . " --> Maps/" . $rname . "\n";
        delete($names{$_});
        $done++;
      }
      else {
        print "$rname: Couldn't be moved: $!\n";
        $error++;
      }
    }
    elsif ($rname =~ m/\.utx$/i) {
      # it's a texture
      if (move($cachedir . $_, $utdir . "Textures/" . $rname)) {
        print $_ . " --> Textures/" . $rname . "\n";
        delete($names{$_});
        $done++;
      }
      else {
        print "$rname: Couldn't be moved: $!\n";
        $error++;
      }
    }
    elsif ($rname =~ m/\.umx$/i) {
      # it's music
      if (move($cachedir . $_, $utdir . "Music/" . $rname)) {
        print $_ . " --> Music/" . $rname . "\n";
        delete($names{$_});
        $done++;
      }
      else {
        print "$rname: Couldn't be moved: $!\n";
        $error++;
      }
    }
    elsif ($rname =~ m/\.uax$/i) {
      # it's sound
      if (move($cachedir . $_, $utdir . "Sounds/" . $rname)) {
        print $_ . " --> Sounds/" . $rname . "\n";
        delete($names{$_});
        $done++;
      }
      else {
        print "$rname: Couldn't be moved: $!\n";
        $error++;
      }
    }
    else {
      if ($all) {
         my $command = $utdep . " " . $cachedir . $_ . " -i";
         my @imports = `$command`;

         my $type;
         foreach my $import(@imports) {
           if ($import =~ m/Core.Class.Engine.Actor/i) {
             $type = "u";
             last;
           }
           elsif ($import =~ m/Core.Class.Engine.Sound/i) {
             $type = "uax";
           }
           elsif ($import =~ m/Core.Class.Engine.Texture/i) {
             $type = "utx";
           }
           elsif ($import =~ m/Core.Class.Engine.Music/i) {
             $type = "umx";
           }
         }

         if (defined($type)) {
           $rname =~ s/(\.\w+)$/\.$type/i;
           $names{$_} = $rname;
           redo;
         }
         else {
            print "type not found: $rname\n";
            $error++;
         }
      }
      else {
        print "type not found: $rname\n";
        $error++;
      }
    }
  }
}
closedir(DIR);

if ($found == 0) {
  print "No files found.\n\n";
  exit;
}

print "Updating cache.ini\n";
open(NEWINI, ">",  $cachedir . "cache.ini") or die "Can't open newini: $!";
print NEWINI "[Cache]\n";
foreach my $key (keys %names) {
  $key =~ s/\.uxx$//i;
  print NEWINI $key . "=" . $names{$key . ".uxx"} . "\n";
}

print "Found: $found\nMoved: $done\nErrors: $error\n\n";
