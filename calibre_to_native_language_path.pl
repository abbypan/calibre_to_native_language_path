#!/usr/bin/perl

use strict;
use warnings;

use DBI qw(:sql_types);
use File::Path qw/make_path/;
#use Data::Dumper;

#see also: https://bugs.launchpad.net/calibre/+bug/1882224

my ($calibre_db_path) = @ARGV;
$calibre_db_path ||= '~/Calibre';

my $dbh = DBI->connect("dbi:SQLite:$calibre_db_path/metadata.db",
    undef, undef, {
        AutoCommit => 1,
        RaiseError => 0,
    }
);

$dbh->do(qq[DROP TRIGGER books_update_trg]);

my $sth = $dbh->prepare("select id, title, author_sort, path from books");
$sth->execute();
while(1){
    my $row = $sth->fetch;
    last unless($row);

    my ($book_id, $title, $author_sort, $path) = @$row;
    my $new_path = "$author_sort/$title ($book_id)";
    my $new_file_name = "$author_sort - $title";

    print "book: $book_id, $title, $author_sort, $path -> $new_path\n";
    make_path("$calibre_db_path/$author_sort");

    my $file_rename_flag = 0;
    my $fth = $dbh->prepare("select id, format, name from data where book = ? ");
    $fth->execute($book_id);
    while(1){
        my $frow = $fth->fetch;
        last unless($frow);
        my ($file_id, $file_format, $file_name) = @$frow;
        if($file_name ne $new_file_name){
            print ">>> file: $file_id, $file_format, $file_name -> $new_file_name\n";
            if (-d "$calibre_db_path/$path"){
                system(qq[cd "$calibre_db_path/$path" && perl-rename 's/$file_name/$new_file_name/' *.*]);
                $file_rename_flag = 1;
            }
        }
    }
    $fth->finish;

    if($file_rename_flag){
        my $dth = $dbh->prepare("update data set name=? where book=?");
        $dth->execute($new_file_name, $book_id);
        $dth->finish;
    }

    if($new_path ne $path){
        rename("$calibre_db_path/$path", "$calibre_db_path/$new_path");

        my $bth = $dbh->prepare("update books set path=? where id=?");
        $bth->execute($new_path, $book_id);
        $bth->finish;
    }

    print "\n";
}

$dbh->do(qq[
    CREATE TRIGGER books_update_trg
    AFTER UPDATE ON books
    BEGIN
    UPDATE books SET sort=title_sort(NEW.title)
    WHERE id=NEW.id AND OLD.title <> NEW.title;
    END;
    ]);

system(qq[rmdir $calibre_db_path/*]);
