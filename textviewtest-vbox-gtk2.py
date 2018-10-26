#!/usr/bin/env python
# Thanks to Ben Carnes for this code
import pygtk
pygtk.require('2.0')
import gtk

win = gtk.Window()
win.connect("destroy", gtk.main_quit)
win.set_default_size(300, 500)
#win.show_all()

scrolledwindow = gtk.ScrolledWindow()
scrolledwindow.set_border_width(10)
scrolledwindow.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)
win.add(scrolledwindow)
#scrolledwindow.show()

vbox = gtk.VBox()
scrolledwindow.add_with_viewport(vbox)
#vbox.show()

def AddTextView(i):
    global vbox;
    textview = gtk.TextView()
    textbuffer = textview.get_buffer()
    textbuffer.set_text("This is some text inside of a Gtk.TextView. In GTK3, the more lines that are here, the more extra blank space appears after the textview when it is initially created. And as soon as we resize the window, the extra space disappears. If we expand the window a lot, the textviews are laid out tightly, and extra gray space appears at the bottom of the window. The same code on gtk2 behaves differently. The textviews are packed nicely together if they have lots of text. If they only have a line or two, then there are gaps. But if we expand the the window a lot, then gaps appear between the textviews instead of at the end. Our problem is with GTK3. How do we eliminate the blanks-between-textviews upon initial load?")
    textview.set_wrap_mode(gtk.WRAP_WORD)
    #textview.set_hexpand(True) # This is True by default
    vbox.add(textview) # attach(textview, 0, i, 1, 1)
    textview.show()

for i in range(6): AddTextView(i)

win.show_all()
gtk.main()
