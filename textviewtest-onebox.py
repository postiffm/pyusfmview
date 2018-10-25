#!/usr/bin/env python
# Thanks to Ben Carnes for this code
import pygtk
pygtk.require('2.0')
import gtk

win = gtk.Window()
win.connect("destroy", gtk.main_quit)
win.set_default_size(300, 500)
win.show_all()

scrolledwindow = gtk.ScrolledWindow()
scrolledwindow.set_border_width(10)
scrolledwindow.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)
win.add(scrolledwindow)
scrolledwindow.show()

vbox = gtk.VBox()
scrolledwindow.add_with_viewport(vbox)
vbox.show()

# Instead of multiple textviews, we make a single one, and add text to it
textview = gtk.TextView()
vbox.add(textview) # attach(textview, 0, i, 1, 1)
textview.show()
textview.set_wrap_mode(gtk.WRAP_WORD)
#textview.set_hexpand(True) # This is True by default

def AddText(i):
    global vbox
    global textview
    textbuffer = textview.get_buffer()
    enditer = textbuffer.get_end_iter()
    textbuffer.insert(enditer, "This is some text inside of a Gtk.TextView. In GTK3, the more lines that are here, the more extra blank space appears after the textview when it is initially created. And as soon as we resize the window, the extra space disappears. If we expand the window a lot, the textviews are laid out tightly, and extra gray space appears at the bottom of the window. The same code on gtk2 behaves differently. The textviews are packed nicely together if they have lots of text. If they only have a line or two, then there are gaps. But if we expand the the window a lot, then gaps appear between the textviews instead of at the end. Our problem is with GTK3. How do we eliminate the blanks-between-textviews upon initial load?\n")

for i in range(6): AddText(i)

gtk.main()
