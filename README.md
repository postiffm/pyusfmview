This is a simple USFM viewer implemented with Python and gtksourceview.

(C) 2018 Matt Postiff

Use it to look at USFM files and see the syntactical elements
highlighted.

# Installing

I developed this in Ubuntu 18.04 LTS. I had to do the following to
get pyusfmview to function:

    sudo apt install python-gtksourceview2
    sudo apt install libgtksourceview2.0-doc
    sudo apt install gnome-extra-icons
    (Not sure, but you might have to do pip install pygtk also.)

Then, take the usfm language definition file and copy it to 
wherever your gtksourceview-2.0 language-specs are located. 
For example:

    sudo cp usfm.lang /usr/share/gtksourceview-2.0/language-specs/

Then gtksourceview can find the language definition.

# Usage

A simple example is provided in this repository:
    ./pyusfmview.pl eph.usfm

And a more complicated example:
    ./pyusfmview.pl rev.usfm
