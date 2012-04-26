#!/usr/bin/perl

#script to generate website
use warnings;
use strict;
use File::Path qw(make_path remove_tree);
use File::Copy;
use File::Slurp qw(read_file);
use Date::Calc qw(Date_to_Text);
use Clone qw(clone);
use Image::Magick;
#Configuration Variables
my $MD_GENERATOR='markdown_py';
my $MD_ARGS='-x mathjax';
#my $WEBSITE = '/home/agoetz/Dropbox/website/test-website';
my $WEBSITE = 'www.andygoetz.org';
#my $URI_SCHEME='file://';
my $URI_SCHEME='http://';
my $SITE_TILE = "Andy Goetz";
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

########################################
#Subroutines

sub get_permalink
{
    my $file = shift;
    my $url = ""; 
    $url = "$URI_SCHEME$WEBSITE/" unless ($WEBSITE eq "");
    my $permalink = "$url"."$file";
    return $permalink;
    
}

sub print_help {
    print "Usage: genwebsite.pl inputdir outputdir\n";
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
	unless(/($regex)/)
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
	    my $filename = "$rawdate-$rawtitle.html";
	    my @dateparts = split /-/, $rawdate;
	    my $date = Date_to_Text($dateparts[0], $dateparts[1], $dateparts[2]);

	    print "Generating \"$filename\"\n";
	    my $content = `$MD_GENERATOR $MD_ARGS $postdir/$_`;
	    my $permalink = get_permalink("$filename");
	    push @postarray, { 'content' => $content,
			       'id' => $index++,
			       'date' => $date,
			       'title' => $title,
			       'filename' => $filename,
			       'permalink' => $permalink,			       
	    };
	}
    }    
    return \@postarray;
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

sub print_index_pg
{
# print index page
    my $postary = clone (shift);
    my $outputdir = shift;
    
    my $numposts = scalar @{$postary};
    my $numshow = $MAX_FRONT < $numposts ? $MAX_FRONT : $numposts;
    my @newary;

    for(my $i = 0; $i < $numshow; $i++)
    {
	my $permalink = $postary->[$i]->{'permalink'};
	my $content = $postary->[$i]->{'content'};
	$content = (split /<a *name=['"]more['"] *> *<\/ *a *>/i, $content)[0];
	$content .= "<a class='more' href='$permalink#more'>more...</a>";
	push (@newary, $postary->[$i]);
	$newary[$i]->{'content'} = $content;
    }
    my $htmlposts = format_posts(\@newary);
    my $index_pg = '';
    for(my $i = 0; $i < $numshow; $i++)
    {
	my $index = $numposts - 1 - $i;
	$index_pg .= $htmlposts->[$index];
    }
    
    my $finished_page = apply_base_template('Index', $index_pg);
    open my $fh, ">", "$outputdir/index.html";
    print $fh $finished_page;    
    close $fh;


}
########################################
#Script Starts Here

if(scalar @ARGV != 2)
{
    print_help();
    exit(-1);
}
my $inputdir = $ARGV[0];
my $outputdir = $ARGV[1];

exit -1 if(verify_and_create_dirs($inputdir, $outputdir));

$post_template = read_file("$inputdir/_templates/$POST_TEMPLATE_FILE");
$base_template = read_file("$inputdir/_templates/$BASE_TEMPLATE_FILE");
$page_template = read_file("$inputdir/_templates/$PAGE_TEMPLATE_FILE");
$post_page_template = read_file("$inputdir/_templates/$POST_PAGE_TEMPLATE_FILE");
$MAGICK = Image::Magick->new();

#copy simple files over
copy_r($inputdir, $outputdir, '(^[\._]|~$)');

#copy post simple files over
copy_r("$inputdir/_posts", "$outputdir", '^[\._]|(\d+-\d+-\d+)-(.+)\.md$|~$');
my $postref = get_posts("$inputdir/_posts");

my $htmlposts = format_posts($postref);

print_post_pages($postref, $htmlposts, $outputdir);

print_pages($postref, "$inputdir/_pages",$outputdir);

print_index_pg($postref, $outputdir);

# print archive page
my $archive_fmt = '';
for(my $i = scalar @{$postref}; $i > 0; $i--)
{
    $archive_fmt .= "<p><b><a href='{permalink}[-$i]'>{date}[-$i] - {title}[-$i]</a></b></p>";
}
print_page($postref, "$outputdir/post-archive.html", $archive_fmt, get_permalink('post-archive.html'), 'Post Archive');
