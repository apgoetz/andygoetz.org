#!/usr/bin/perl

#script to generate website
use warnings;
use strict;
use File::Path qw(make_path remove_tree);
use File::Copy;
use File::Slurp qw(read_file);
use Date::Calc qw(Date_to_Text Delta_Days);
use Clone qw(clone);
use Image::Magick;
use DateTime;
use Data::Dumper;
use HTTP::Server::Brick;
use HTTP::Status;


#Configuration Variables
my $MD_GENERATOR='markdown_py';
my $MD_ARGS='-x mathjax';
my $CURTIME;

my $WEBSITE = 'www.andygoetz.org';
my $AUTHOR = "Andy Goetz";
my $URI_SCHEME='http://';
my $SITE_TITLE = "Andy Goetz";
my $POST_TEMPLATE_FILE='_post.html';
my $POST_PAGE_TEMPLATE_FILE='_postpage.html';
my $PAGE_TEMPLATE_FILE='_page.html';
my $BASE_TEMPLATE_FILE='_base.html';
my $MAX_FRONT = 5;
my $MAX_IMAGE_WIDTH = 600;
my $IMAGE_REGEX = '(jpg|jpeg|png|gif)';
my $post_template;
my $base_template;
my $page_template;
my $post_page_template;
my $MAGICK;
my $mock = '';
my @tags_list;
########################################
#Subroutines

sub temp_server {
  my $dir = shift;
  my $port = shift;

  my $server = HTTP::Server::Brick->new(port => $port);
  
  $server->mount( '/' => {
			  path => $dir,
			  });

  $server->start;
}

sub get_permalink
{
    my $file = shift;
    my $url = ""; 
    $url = "$URI_SCHEME$WEBSITE/" unless ($WEBSITE eq "");
    my $permalink = "$url"."$file";
    return $permalink;
    
}

sub print_help {
    print "Usage: [-m] genwebsite.pl inputdir outputdir\n";
    return;
}

sub apply_base_template
{
    my $title = shift;
    my $content = shift;
    my $fmtd_page = $base_template;
    $fmtd_page =~ s/{content}/$content/g;
    $fmtd_page =~ s/{title}/$title/g;
    my $urlbase = get_permalink('');
    $fmtd_page =~ s/{website}/$urlbase/g;

    my $tagstr = '';
    if(scalar(@tags_list) > 0) {
      for(my $i = 0; $i < scalar @tags_list; $i++){
	my $tag = $tags_list[$i];
	$tagstr .= ', ' if($i != 0);
	$tagstr .= "<a href='$URI_SCHEME$WEBSITE/TAG-$tag.html'>$tag</a>";
      }
    }
    $fmtd_page =~ s/{alltags}/$tagstr/g;
    return $fmtd_page;

}

sub verify_and_create_dirs {
    my $inputdir = shift;
    my $outputdir = shift;
    if($inputdir eq $outputdir)
    {
	print "inputdir cannot be same as outputdir\n";
	return 1;
    }
    if(!(-d $inputdir))
    {
	print "inputdir does not exist\n";
	return 1;
    }
    
    make_path($outputdir) unless (-d $outputdir);
    
    return 0;
}

sub copy_file
{
    my ($src, $dest) = @_;

    if ($src =~ /\.$IMAGE_REGEX$/)
    {

	$MAGICK->Read($src);
	my $width = $MAGICK->Get('columns');
	my $height = $MAGICK->Get('rows');
	if($width > $MAX_IMAGE_WIDTH)
	{
	    my $newheight = $height * $MAX_IMAGE_WIDTH / $width;	 
	    $MAGICK->Resize(width =>$MAX_IMAGE_WIDTH, height=>$newheight);
	    $MAGICK->Write($dest);
	    @$MAGICK = ();
	    return;
	}
	@$MAGICK = ();
    }
    copy($src, $dest);
}

sub copy_r
{

    my $srcdir = shift;
    my $destdir = shift;
    my $regex = shift;
    make_path($destdir);

    opendir(my $dir, $srcdir) or die("could not open dir\n");
    my @files = readdir($dir);
    
    # base case
    return if(scalar @files == 0);

    foreach(@files)
    {
	unless(/($regex)/ or /^\.\.?$/)
	{
	    if (-d)
	    {
		copy_r("$srcdir/$_", "$destdir/$_", $regex);
	    }
	    else
	    {
		print "Copying $srcdir/$_ to $destdir/$_\n";
		copy_file("$srcdir/$_", "$destdir/$_");
	    }
	}

    }
    

    
}

sub get_posts
{
    my $postdir = shift;
    opendir(my $dir, $postdir);
    
    my @postarray;
    my @rawfiles = sort readdir($dir);
    my $index = 1;
    foreach(@rawfiles)
    {


	if(/(\d+-\d+-\d+)-(.+)\.md$/)
	{
	    my $rawdate = $1;
	    my $rawtitle = $2;
	    my $title = $rawtitle;
	    $title =~s/^(.)/\U$1/;
	    $title =~ s/-(.)/ \U$1/g;
	    # If the title begins with an underscore...
	    if(/^_/)
	    {
		# if we are mocking, just skip this file
		next if($mock eq '');
		# otherwise, render it, but put test in front.
		$title = "**TEST** ".$title;
	    }
	     
	    my $filename = "$rawdate-$rawtitle.html";
	    my @dateparts = split /-/, $rawdate;
	    my $date = Date_to_Text($dateparts[0], $dateparts[1], $dateparts[2]);

	    print "Generating \"$filename\"\n";
	    my $content = `$MD_GENERATOR $MD_ARGS $postdir/$_`;
	    my $permalink = get_permalink("$filename");
	    my $tags = '';
	    if($content =~ /<\s*meta\s*name=["']keywords["']\s*content=["']([\w\s,]+)["']/i) {
	      $tags = $1;
	      push @tags_list, split(/[\s,]/, $tags);
	    }

	    push @postarray, { 'content' => $content,
			       'date' => $date,
			       'title' => $title,
			       'rawdate' => $rawdate,
			       'filename' => $filename,
			       'permalink' => $permalink,
			       'tags' => $tags,
	    };
	    
	}
    }

    @tags_list = keys %{{ map {$_ => 1} @tags_list }};
    @tags_list = (sort {lc($a) cmp lc($b)} @tags_list);
    my @sorted_posts;
    @sorted_posts = sort { Delta_Days((split /-/, $b->{rawdate}), (split /-/, $a->{rawdate})) } @postarray;
    for(my $i = 0; $i < (scalar @sorted_posts); $i++)
      {
	$sorted_posts[$i]->{'id'} = $i + 1;
      }
    return \@sorted_posts;
}

sub get_delta_value
{
    my $postref = shift;
    my $key = shift;
    my $postid = shift;
    my $delta = shift;


    my $postcount = scalar @{$postref};
    my $index = $postid;
    $index = $postid + $delta 
	if($postid + $delta < $postcount and $postid + $delta >= 0);
    
    my $value =  $postref->[$index]->{$key};
    return $value;


}

sub format_posts
{
    my $postref = shift;
    my @posthtmlary;
    for(my $i = 0; $i < scalar @{$postref}; $i++)
    {
	push @posthtmlary, format_post($postref, $i);
	
    }
    return \@posthtmlary;
}

sub format_post
{
    my $postref = shift;
    my $id = shift;
    my $post = $postref->[$id];

    my $fmtd_post = $post_template;
    
    while (my ($key, $value) = each %{$post})
    {
	$fmtd_post =~ s/{$key}/$value/g;
    }

    return $fmtd_post;
    
}
sub print_post_pages
{
    my $postref = shift;
    my $htmlary = shift;
    my $destdir = shift;
    

    for(my $i = 0; $i < scalar @{$postref}; $i++)
    {
	my $post_html = $htmlary->[$i];
	my $posthash = $postref->[$i];
	my $title = $posthash->{'title'};
	my $fmtd_post = $post_page_template;
	my $filename = "$destdir/".$postref->[$i]->{'filename'};
	
	foreach(('permalink', 'title', 'id', 'date', 'content'))
	{
	    $fmtd_post =~ s/{$_}\[(-?\d+)\]/get_delta_value($postref, $_, $i, $1)/eg;
	}
	$fmtd_post =~ s/{content}/$post_html/;

	my @tags = split /[\s,]/, $posthash->{'tags'};
	my $tagstr = '';
	for(my $i = 0; $i < scalar @tags; $i++) {
	  my $curtag = $tags[$i];
	  $tagstr .= ", " unless ($i == 0);
	  $tagstr .= "<a href='$URI_SCHEME$WEBSITE/TAG-$curtag.html'>$curtag</a>";
	}
	$fmtd_post =~ s/{tags}/$tagstr/;
	my $fmtd_page = apply_base_template($title, $fmtd_post);

	print("Writing out $filename\n");

	open(my $fh, ">", $filename);
	print $fh  $fmtd_page;
	close $fh;
    }
}

sub print_page
{
    my $postref = shift;
    my $filename = shift;
    my $content = shift;    
    my $permalink = shift;
    my $title = shift;
    my $id = scalar @{$postref};
    
    my $page = $page_template;
    $page =~ s/{content}/$content/g;

    my @fields = ('content', 'permalink', 'title', 'date', 'id', 'filename');
    foreach(@fields)
    {
	$page =~ s/{$_}\[(-?\d+)\]/get_delta_value($postref, $_, $id, $1)/eg;
    }
    $page =~ s/{title}/$title/g;
    $page =~ s/{permalink}/$permalink/g;
    my $finished_page = apply_base_template($title, $page);
    open my $fh, ">", "$filename";
    print $fh $finished_page;
    
    close $fh;
}

sub print_tag_pages
{
  my $postarray = shift;
  my $outputdir = shift;
  my $headers = get_headers($postarray);
  foreach(@tags_list) {
    my $curtag = $_;
    my $filename = "TAG-$curtag.html";
    my @matched_headers = grep {$_->{tags} =~ /$curtag/} @{$headers};
    my $formatted_posts = format_posts(\@matched_headers);
    my $numposts = scalar @matched_headers;
    my $tag_page = '';

    for(my $i = 0; $i < $numposts; $i++)
    {
	my $index = $numposts - 1 - $i;
	$tag_page .= $formatted_posts->[$index];
	
    }
    print "Generating $outputdir/$filename...\n";
    print_page($postarray, "$outputdir/$filename", $tag_page, "$URI_SCHEME$WEBSITE/$filename", "Posts Tagged $curtag:");
  }
}

sub print_pages
{
    my $postref = shift;
    my $srcdir = shift;
    my $destdir = shift;
    my $id = scalar @{$postref};
    opendir (my $dir, $srcdir);
    my @files = readdir($dir);

    foreach(@files)
    {
	if(/(.*)\.(md|html)$/)
	{
	    
	    my $filename = "$destdir/$1.html";
	    my $title = $1;
	    my $permalink = get_permalink("$title.html");
	    $title =~ s/^(.)/\U$1/;
	    $title =~ s/-(.)/\U$1/g;
	    
	    my $rawtext = '';

	    if(/md$/)
	    {
		$rawtext = `$MD_GENERATOR $MD_ARGS $srcdir/$_`;
	    }
	    else
	    {
		$rawtext = read_file("$srcdir/$_");
	    }

	    print_page($postref, $filename, $rawtext, $permalink, $title);
	}
    }
    
}

sub get_top_headers
{

    my $headers = get_headers(shift);
    my $numposts = scalar @{$headers};
    my $numshow = $MAX_FRONT < $numposts ? $MAX_FRONT : $numposts;
    my @last_n = @{$headers}[-$numshow..-1];
    return \@last_n;

}


sub get_headers
{
    my $postary = clone (shift);    
    my $numposts = scalar @{$postary};
    my @newary;

    for(my $i = 0; $i < $numposts; $i++)
    {
	my $permalink = $postary->[$i]->{'permalink'};
	my $content = $postary->[$i]->{'content'};
	$content = (split /<a *name=['"]more['"] *> *<\/ *a *>/i, $content)[0];
	my $open_count =()= $content =~ /<\w*p\w*>/;
	my $closed_count =()= $content =~ /<\\\w*p\w*>/;
	$content .= '</p>' if ($open_count != $closed_count);
	$content .= "<a class='more postfooter' href='$permalink#more'>more...</a>";	
	push (@newary, $postary->[$i]);
	$newary[-1]->{'content'} = $content;
    }

    return \@newary;

}

sub print_index_pg
{
# print index page
    my $postary = shift;
    my $outputdir = shift;
    my $index_pg = '';
    my $shortposts = format_posts(get_top_headers($postary));

    my $numposts = scalar @{$shortposts};
    for(my $i = 0; $i < $numposts; $i++)
    {
	my $index = $numposts - 1 - $i;
	$index_pg .= $shortposts->[$index];
	
    }
    
    my $finished_page = apply_base_template('Index', $index_pg);
    print "writing index page: $outputdir/index.html\n";
    open my $fh, ">", "$outputdir/index.html";
    print $fh $finished_page;    
    close $fh;


}

sub make_feed 
{
    my $headers = get_top_headers(shift);    
    my $outputdir = shift;
    my $atomstr = '';
    my $link = $URI_SCHEME.$WEBSITE.'/';
	
	
    $atomstr .= '<?xml version="1.0" encoding="utf-8" standalone="yes"?>';
    $atomstr .= '<feed xmlns="http://www.w3.org/2005/Atom">';
    $atomstr .='<title>'.$SITE_TITLE.'</title>';
    $atomstr .= '<link rel="self" href="'.$link.'atom.xml"/>';
    $atomstr .= '<link rel="alternate" href="'.$link.'"/>';
    $atomstr .= '<id>'.$link.'</id>';
    $atomstr .= '<updated>'.$CURTIME.'</updated>';
    
    
    foreach my $hash (reverse @{$headers}) 
    {
	my @date_elements = split /-/, $hash->{rawdate};
	my $tmpdate = DateTime->new(
	    year => $date_elements[0],
	    month => $date_elements[1],
	    day => $date_elements[2],
	    );
	my $datestr = $tmpdate->datetime();
	$atomstr .= '<entry>';
	$atomstr .= '<title>'.$hash->{title}.'</title>';
	$atomstr .= '<link rel="alternate" type="text/html" href="'.$hash->{permalink}.'"/>';
	$atomstr .= '<id>'.$hash->{permalink}.'</id>';
	$atomstr .= '<published>'.$datestr.'</published>';
	$atomstr .= '<updated>'.$datestr.'</updated>';
	$atomstr .= '<author><name>'.$AUTHOR.'</name></author>';
	$atomstr .= '<content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml">';
	$atomstr .= $hash->{content};
	$atomstr .= '</div></content></entry>'
    }
    
    $atomstr .= '</feed>';

    open my $fh, ">", "$outputdir/atom.xml";
    print $fh $atomstr;
    close $fh;
}

########################################
#Script Starts Here

if(scalar @ARGV < 2)
{
    print_help();
    exit(-1);
}

my $inputdir = '';
my $outputdir = '';
foreach(@ARGV)
{
    if(/^-+m/)
    {
	$mock = 'yes';
    }
    elsif(/^-+s/)
    {
      foreach(@ARGV)
      {
	unless(/^-+s/)
	{
	  my $port = 8080;
	  print "Starting Webserver on port $port\n";
	  temp_server($_, $port);
	  print "Shutting down Webserver\n";
	  exit 0;
	}
      }
      print "Cannot start webserver: no source directory specified.\n";
      print_help();
      exit -1;
    }
    elsif($inputdir eq '')
    {
	$inputdir = $_;
    }
    elsif($outputdir eq '')
    {
	$outputdir = $_;
    }
    else
    {
	print_help();
	exit(-1);
    }

}

unless ($mock eq '')
{
    print "testing website...\n";
    # $URI_SCHEME = 'file://';
     $WEBSITE = "localhost:8080";
}
else
{
    print "deploying website...\n";
}


exit -1 if(verify_and_create_dirs($inputdir, $outputdir));

$post_template = read_file("$inputdir/_templates/$POST_TEMPLATE_FILE");
$base_template = read_file("$inputdir/_templates/$BASE_TEMPLATE_FILE");
$page_template = read_file("$inputdir/_templates/$PAGE_TEMPLATE_FILE");
$post_page_template = read_file("$inputdir/_templates/$POST_PAGE_TEMPLATE_FILE");
$MAGICK = Image::Magick->new();

my $dt = DateTime->now;
$CURTIME = $dt->iso8601();

#copy simple files over
copy_r($inputdir, $outputdir, '(^[_]|~$)');

#copy post simple files over
copy_r("$inputdir/_posts", "$outputdir", '^[_]|(\d+-\d+-\d+)-(.+)\.md$|~$');
my $postref = get_posts("$inputdir/_posts");

my $htmlposts = format_posts($postref);
print_index_pg($postref, $outputdir);

make_feed($postref, $outputdir);

print_post_pages($postref, $htmlposts, $outputdir);

print_pages($postref, "$inputdir/_pages",$outputdir);

print "printing tag pages...\n";
print_tag_pages($postref, $outputdir);

# print archive page
my $archive_fmt = '';
my $numposts = scalar @{$postref};
for(my $i = 1; $i <= $numposts; $i++)
{
    $archive_fmt .= "<p><a href='{permalink}[-$i]'> {title}[-$i]</a> - Posted {date}[-$i]</p>";
}

print "writing out archive: $outputdir/post-archive.html\n";

print_page($postref, "$outputdir/post-archive.html", $archive_fmt, get_permalink('post-archive.html'), 'Post Archive');
