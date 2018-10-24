#!/usr/bin/env python
# Thanks to Ben Carnes for this code
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

win = Gtk.Window()
win.connect("destroy", Gtk.main_quit)
win.set_default_size(300, 500)
win.show_all()

scrolledwindow = Gtk.ScrolledWindow()
scrolledwindow.set_border_width(10)
scrolledwindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.ALWAYS)
win.add(scrolledwindow)
scrolledwindow.show()

grid = Gtk.Grid()
scrolledwindow.add(grid)

grid.show()

def AddTextView(i):
    textview = Gtk.TextView()
    textbuffer = textview.get_buffer()
    textbuffer.set_text("This is some text inside of a Gtk.TextView. djfkldjf kdsjfkd jblah blah blah yadda yaddah yaddah.")
    textview.set_wrap_mode(Gtk.WrapMode.WORD)
    textview.set_hexpand(True)
    grid.attach(textview, 0, i, 1, 1)
    textview.show()

for i in range(4): AddTextView(i)

Gtk.main()
