#!/usr/bin/perl
use warnings;
use strict;
use Try::Tiny;
use Curses;

#===========================Init/Declare Vars===============================
my ($row, $col, $slide, $command, $slides, $max_slides, $title);
my $color = 1;
my @slide_array;
my $current_slide = 0;
my $keypress;
my $content;
my $tflag;
my $footer;
my $y_offset = 0;
my $x_offset = 0;
my $win_border;
my $win_progress;
my $transition = 0;
my $speed = 1;
my $delay = 0;
my $display_slide = 0;
my $display_total = 0;
my $delay_slides = 0;
my @backtracks;
my $i;

#================================Sanity=====================================
if (!$ARGV[0]) {
	print "why come no slides\n";
	exit;
}

#Read our slide-deck file
open FILE, "$ARGV[0]" or die "Couldn't open $ARGV[0], $!\n";

#Init the ncurses stuff
initscr;				#init the screen
start_color(); 			#init colors
curs_set(0); 			#Don't echo the cursor
keypad(1);
noecho;
init_pair(2, COLOR_WHITE, COLOR_BLACK);

#Color Pairs for colored text with black background
init_pair(10, 1, COLOR_BLACK);
init_pair(11, 2, COLOR_BLACK);  
init_pair(12, 3, COLOR_BLACK);
init_pair(13, 4, COLOR_BLACK);
init_pair(14, 5, COLOR_BLACK);
init_pair(15, 6, COLOR_BLACK);
init_pair(16, 7, COLOR_BLACK);      

#========================Deconstruct Slide-Deck=============================
#Slurp up the deck
$/ = undef;
$slides = <FILE>;
$/ = "\n";
close FILE;

#Get global speed modifier
if ($slides =~ />>speed (\S+)/) {
    $speed = $1;
    $slides =~ s/$&//;
}

#Get backtrack indexes
$i = 0;
my $j = 0;
my $temp_slides = $slides;
while ($temp_slides =~ />>newslide\n(.+?)>>endslide/s) {   #if there's a slide
    my $temp_content = $1;  #grab it's contents
    if ($temp_content =~ />>delay [^0]/) {
        $backtracks[$i]++;
    } elsif ($temp_content =~ />>delay 0/) {
        $i++;
    } else {
        $backtracks[$i] = 0;
        $i++;
    }
    $temp_slides =~ s/>>newslide\n//;                    #remove slide start identifier
}
$backtracks[$i] = 0;

#Get slide info for each slide into an array
$i = 0;
while ($slides =~ />>newslide\n(.+?)>>endslide/s) {   #if there's a slide
    $slide_array[$i] = $1;                          #grab it's contents
    $slides =~ s/>>newslide\n//;                    #remove slide start identifier
    $delay_slides++ if ($slide_array[$i] =~ />>delay [^0]/);
    $delay_slides-- if ($slide_array[$i] =~ />>delay 0/);
    $i++;
}
$max_slides = @slide_array;
$display_total = $max_slides - $delay_slides;

#Load Slide
$keypress = "nothing";
while ($keypress ne "f") {
    #Get screen parameters each time loop is run
    getmaxyx($row, $col);   #Discover screen size
    $win_border = newwin($row, $col - 1, 0, 1);
    $win_progress = newwin($row, 1, 0, 0);

    generate_slide();

    #Capture keypresses and proceed
    $keypress = getch;
    if (($keypress eq KEY_RIGHT) || ($keypress eq KEY_DOWN) || ($keypress eq ' ')) {
        transitions($transition, 0);
        $display_slide++ if ($display_slide ne ($display_total - 1));  ;
    }
    if (($keypress eq KEY_LEFT) || ($keypress eq KEY_UP)) {
        transitions($transition, 1);
        $display_slide-- if ($display_slide ne 0);        
    }    
    $transition = 0 if $keypress eq 0;
    $transition = 1 if $keypress eq 1;    
    $transition = 2 if $keypress eq 2;     
    $transition = 3 if $keypress eq 3; 
    $transition = 4 if $keypress eq 4;     
    $transition = 5 if $keypress eq 5;   
    $transition = 6 if $keypress eq 6;    

    #Animation handling

    while ($delay gt 0) {
        my $delay2 = (1 / $delay);
        select(undef, undef, undef, $delay2);
        transitions(0,0);
    }    
}

endwin;

#=============================Subroutines===================================
sub transitions($) {
    my $type = shift;
    my $dir = shift;

    #Just transition to the next slide with no effects (the default)
    if (($type eq 0) && ($dir eq 0)) {
        $current_slide++ if ($current_slide ne ($max_slides - 1));  
        generate_slide();
    }
    if (($type eq 0) && ($dir eq 1)) {
        if ($current_slide ne 0) {
            $current_slide = $current_slide - $backtracks[$display_slide] - 1;
        }
        generate_slide();
    }    

    #Swipe slide down
    if (($type eq 1) && ($dir eq 0)) {
        for ($i = 0; $i < $row; $i++) {
            $y_offset++;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }
        $current_slide++ if ($current_slide ne ($max_slides - 1));  
        $y_offset = 0 - $row;
        for ($i = 0; $i < $row; $i++) {
            $y_offset++;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }         
    }
    if (($type eq 1) && ($dir eq 1)) {
        for ($i = 0; $i < $row; $i++) {
            $y_offset++;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }
        if ($current_slide ne 0) {
            $current_slide = $current_slide - $backtracks[$current_slide] - 1;
        }
        $y_offset = 0 - $row;
        for ($i = 0; $i < $row; $i++) {
            $y_offset++;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }         
    }    

    #Swip slide up
    if (($type eq 2) && ($dir eq 0)) {
        for ($i = 0; $i < $row; $i++) {
            $y_offset--;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }
        $current_slide++ if ($current_slide ne ($max_slides - 1));  
        $y_offset = $row;
        for ($i = 0; $i < $row; $i++) {
            $y_offset--;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }         
    }
    if (($type eq 2) && ($dir eq 1)) {
        for ($i = 0; $i < $row; $i++) {
            $y_offset--;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }
        if ($current_slide ne 0) {
            $current_slide = $current_slide - $backtracks[$current_slide] - 1;
        }
        $y_offset = $row;
        for ($i = 0; $i < $row; $i++) {
            $y_offset--;
            generate_slide();
            select(undef, undef, undef, 0.02 * $speed);
        }         
    }

    #Disolve characters away at random
    if (($type eq 3) && ($dir eq 0)) {
        $current_slide++ if ($current_slide ne ($max_slides - 1));  
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $randx;
        my $randy;
        my $i = 0;
        while ($i < 5000) {
            $randx = rand($maxx);
            $randy = rand($maxy);        
            $slide->addstr($randx, $randy, " ");
            $slide->refresh();
            select(undef, undef, undef, 0.0002 * $speed);
            $i++;
        }
        generate_slide();
    }
    if (($type eq 3) && ($dir eq 1)) {
        if ($current_slide ne 0) {
            $current_slide = $current_slide - $backtracks[$current_slide] - 1;
        }
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $randx;
        my $randy;
        my $i = 0;
        while ($i < 5000) {
            $randx = rand($maxx);
            $randy = rand($maxy);        
            $slide->addstr($randx, $randy, " ");
            $slide->refresh();
            select(undef, undef, undef, 0.0002 * $speed);
            $i++;
        }
    }    

    #Randomly fill color into slide
    if (($type eq 4) && ($dir eq 0)) {
        $current_slide++ if ($current_slide ne ($max_slides - 1));  
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $randx;
        my $randy;
        my $i = 0;
        while ($i < 5000) {
            $randx = rand($maxx);
            $randy = rand($maxy);        
            $slide->addstr($randx, $randy, " ");
            $slide->chgat($randx, $randy, 1, A_NORMAL, 1, 1);            
            $slide->refresh();
            select(undef, undef, undef, 0.0002 * $speed);
            $i++;
        }
        generate_slide();
    }
    if (($type eq 4) && ($dir eq 1)) {
        if ($current_slide ne 0) {
            $current_slide = $current_slide - $backtracks[$current_slide] - 1;
        } 
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $randx;
        my $randy;
        my $i = 0;
        while ($i < 5000) {
            $randx = rand($maxx);
            $randy = rand($maxy);        
            $slide->addstr($randx, $randy, " ");
            $slide->chgat($randx, $randy, 1, A_NORMAL, 1, 1);             
            $slide->refresh();
            select(undef, undef, undef, 0.0002 * $speed);
            $i++;
        }      
    }                    
                
    #Vertical Bars
    if (($type eq 5) && ($dir eq 0)) {
        $current_slide++ if ($current_slide ne ($max_slides - 1));  
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $y = 0;
        while ($y < $maxy) {
            my $x = 0;
            while ($x < $maxx) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $x++;
            }
            $y += 2;
        }
        $y = 1;
        while ($y < $maxy) {
            my $x = 0;
            while ($x < $maxx) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $x++;
            }
            $y += 2;
        }
        generate_slide();        
    }
    if (($type eq 5) && ($dir eq 1)) {
        if ($current_slide ne 0) {
            $current_slide = $current_slide - $backtracks[$current_slide] - 1;
        }
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $y = 0;
        while ($y < $maxy) {
            my $x = 0;
            while ($x < $maxx) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $x++;
            }
            $y += 2;
        }
        $y = 1;
        while ($y < $maxy) {
            my $x = 0;
            while ($x < $maxx) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $x++;
            }
            $y += 2;
        }        
    }    

    #Horizontal Bars
    if (($type eq 6) && ($dir eq 0)) {
        $current_slide++ if ($current_slide ne ($max_slides - 1));  
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $x = 0;
        while ($x < $maxx) {
            my $y = 0;
            while ($y < $maxy) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $y++;
            }
            $x += 2;
        }
        $x = 1;
        while ($x < $maxx) {
            my $y = 0;
            while ($y < $maxy) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $y++;
            }
            $x += 2;
        }
        generate_slide();        
    }
    if (($type eq 6) && ($dir eq 1)) {
        if ($current_slide ne 0) {
            $current_slide = $current_slide - $backtracks[$current_slide] - 1;
        }
        my $maxy = $col - 7;
        my $maxx = $row - 6;
        my $x = 0;
        while ($x < $maxx) {
            my $y = 0;
            while ($y < $maxy) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $y++;
            }
            $x += 2;
        }
        $x = 1;
        while ($x < $maxx) {
            my $y = 0;
            while ($y < $maxy) {   
                $slide->addstr($x, $y, " ");
                $slide->chgat($x, $y, 1, A_NORMAL, 1, 1);            
                $slide->refresh();
                select(undef, undef, undef, 0.001 * $speed);
                $y++;
            }
            $x += 2;
        }        
    }
                    
}

sub generate_slide {
    $win_border = newwin($row, $col - 1, 0, 1);

    #Clear "title" part of slide
    $title = ' ' x ($col - 6);
    addstr(1, ($col / 2) - (length($title) / 2) - 4, $title);

    #Extract MetaData
    if ($slide_array[$current_slide] =~ />>color.(\d)/i){    #if the slide has a color
        $color = $1;                                            #extract it
    }
    if ($slide_array[$current_slide] =~ />>title.(.+)/i){    #if the slide has a title
        $title = $1;                                            #extract it    
        $tflag = 1;
    } else {
        $title = ' ' x ($col - 5);
        $tflag = 0;
    }
    if ($slide_array[$current_slide] =~ />>delay.(\d)/i){    #if the slide has a delay
        $delay = $1;                                            #extract it
    }
    #Get slide content and remove metadata 'tags'
    $content = $slide_array[$current_slide];        #Get the content 
    fix_content();
    
    #Add title part of slide if there is a title (also add footer)
    $footer = "Slide " . ($display_slide + 1) . " of $display_total";
    addstr(1, ($col / 2) - (length($title) / 2) - 4, $title); 
    addstr($row - 2, $col - length($footer) - 1, $footer);            
    create_slide($row - 1 + $y_offset ,$col - 2 + $x_offset,$x_offset,$y_offset, $color);    #create the border/slide 
    chgat(1, ($col / 2) - (length($title) / 2) - 4, length($title), A_BOLD, 1, 1) if $tflag;   
    chgat($row - 2, $col - length($footer) - 1, length($footer), A_BOLD, 1, 1);

    #Add slide content and refresh   
    try {
        while($content) {  #while there is still slide content left to process
            if ($content =~ /(.*?)(>>(con|coff|B|b|U|u|K|k)\d?)/s) {    #If there is a format modifier
                $slide->addstr($1);                             #Add the part before the modifier (unprocessed)
                my $mod = $2;                                   #Capture the actual modifier
                $content =~ s/\Q$&\E//;                         #update content by removing our full match
                if ($mod =~ /con(\d)/) {                        #if color on #
                    $slide->attron(COLOR_PAIR($1 + 10));        #turn that color on
                }
                if ($mod =~ /coff(\d)/) {                       #if color off #
                    $slide->attroff(COLOR_PAIR($1 + 10));       #Turn that color off
                }
                if ($mod =~ /B/) {                              #if bold on
                    $slide->attron(A_BOLD);                     #turn it on
                }
                if ($mod =~ /b/) {                              #if bold off
                    $slide->attroff(A_BOLD);                    #turn it off
                }
                if ($mod =~ /U/) {                              #if underline on
                    $slide->attron(A_UNDERLINE);                #turn it on
                }
                if ($mod =~ /u/) {                              #if underline off
                    $slide->attroff(A_UNDERLINE);               #turn it off
                }
                if ($mod =~ /K/) {                              #if blinking on
                    $slide->attron(A_BLINK);                    #turn it on
                }
                if ($mod =~ /k/) {                              #if blinking off
                    $slide->attroff(A_BLINK);                   #turn it off
                }
            } else {                                            #if there were no modifiers
                $slide->addstr($content);                       #just print all of it unmodified
                $content = undef;                               #no more content
            }
        } 
        $slide->refresh;                                #Refresh slide
    };

    #Update Progress Bar
    progress_bar();
    refresh;
}

sub fix_content {
    #This sub does a little bit of content unfucking
    $content =~ s/>>color.\d.*\n//;                     #extract the color tag
    $content =~ s/>>title.+\n//;                        #extract the title tag   
    $content =~ s/>>delay.\d.*\n//;                     #extract the delay tag    
}

sub progress_bar {
    #Clear the vertical bar with "clear" color
    for (my $i = 0; $i < $row; $i++) {
        $win_progress->chgat($i, 0, 1, A_NORMAL, 0, 1);
    }    
    #Get the current amount of vertical lines we are at
    my $amount = (($display_slide + 1) / $display_total) * $row;
    #Highlight these characters
    for (my $i = 0; $i < $amount - 1; $i++) {
        $win_progress->chgat($i, 0, 1, A_NORMAL, 1, 1);
    }    
    $win_progress->refresh;
}

sub create_slide {
    my $h = shift;	
    my $w = shift;
    my $x = shift;
    my $y = shift;   
    my $color = shift;     
	delwin($slide) if $slide;
	create_frame($h, $w ,$x , $y ,ACS_ULCORNER,ACS_URCORNER,ACS_LLCORNER,ACS_LRCORNER,ACS_HLINE,ACS_HLINE,ACS_VLINE,ACS_VLINE,$color);
	$slide = newwin($h - 5, $w - 5, $y + 3, $x + 4);
}

sub create_frame {
	#Get arguments
    my $h = shift;	
    my $w = shift;
    my $x = shift;
    my $y = shift;    
    my $tl_corner = shift;
    my $tr_corner = shift;
    my $bl_corner = shift;
    my $br_corner = shift;
    my $tline = shift;
    my $bline = shift;
    my $lline = shift;
    my $rline = shift;
    my $color = shift;

    #print outer border
    $win_border->addch($y, $x, $tl_corner);
    $win_border->addch($y, $x + $w, $tr_corner);
    $win_border->addch($y + $h, $x, $bl_corner);
    $win_border->addch($y + $h, $x + $w, $br_corner);
    $win_border->hline($y, $x + 1, $tline, $w - 1);
    $win_border->hline($y + $h, $x + 1, $bline, $w - 1);
    $win_border->vline($y + 1, $x, $lline, $h - 1);
    $win_border->vline($y + 1, $x + $w, $rline, $h - 1);

    #print inner border
    $win_border->addch($y + 2, $x + 2, $tl_corner);
    $win_border->addch($y + 2, $x + $w - 2, $tr_corner);
    $win_border->addch($y + $h - 2, $x + 2, $bl_corner);
    $win_border->addch($y + $h - 2, $x + $w - 2, $br_corner);
    $win_border->hline($y + 2, $x + 3, $tline, $w - 5);
    $win_border->hline($y + $h - 2, $x + 3, $bline, $w - 5);
    $win_border->vline($y + 3, $x+2, $lline, $h - 5);
    $win_border->vline($y + 3, $x + $w - 2, $rline, $h - 5);    

    #print color border
    init_pair(1, COLOR_WHITE, $color);  
    $win_border->chgat($y + 1, $x + 1, $w - 1, A_NORMAL, 1, 1); 	#x,y,length,attribute,colorpairindex, 1
    $win_border->chgat($y + $h - 1, $x + 1, $w - 1, A_NORMAL, 1, 1);
    for (my $i = $y + 1; $i < ($y + $h); $i++) {
    	$win_border->chgat($i, $x + 1, 1, A_NORMAL, 1, 1);
    }
    for (my $i = $y + 1; $i < ($y + $h); $i++) {
    	$win_border->chgat($i, $x + $w - 1, 1, A_NORMAL, 1, 1);
    }    
    $win_border->refresh();
}
