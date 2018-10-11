#!/usr/bin/env python
# Originally had coding: UTF-8 with -*- on both sides, but that
# causes emacs to be unhappy when saving the utf-8 format.
#
# Adapted to work on Ubuntu 18.04 LTS from
# http://www.eurion.net/python-snippets/snippet/GtkSourceView%20Example.html
# 
# Copyright (C) 2018 - Matt Postiff
#
# [SNIPPET_NAME: GtkSourceView Example]
# [SNIPPET_CATEGORIES: PyGTK, PyGTKSourceView]
# [SNIPPET_DESCRIPTION: Demonstrates using Actions with a gtk.Action and gtk.AccelGroup]
#
# This script shows the use of pygtksourceview module, the python wrapper
# of gtksourceview C library.
# It has been directly translated from test-widget.c
# and modified to use gtksourceview2
#
# Copyright (C) 2004 - Iñigo Serna <inigoserna@telefonica.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# To solve
# ImportError: No module named gtksourceview2
# Do this
# sudo apt install python-gtksourceview2
# sudo apt install libgtksourceview2.0-doc
# ?? pip install pygtk
# 

# To solve
# glib.GError: Failed to open file '/usr/share/pixmaps/apple-green.png': No such file or directory
# sudo apt install gnome-extra-icons
# and rename that file to pixmaps/other/Apple-Green.png (same with red as well).
# You might also find these icons in a package named like gnome-desktop-data 

# To add python gtk development docs to your devhelp
# sudo apt install python-gtk2-doc python-gtk2-dev

# To solve lack of language highlighting,
# sudo cp usfm.lang /usr/share/gtksourceview-2.0/language-specs/

# To Do
#   1. Get language configuration right
#   2. Add file name to title bar
#   3. Add search capability
#   4. Contribute usfm.lang to gtksourceview
#   5. Port to gtksourceview3
# X 6. Add About dialog
#   7. Add F3 hotkey for search
#   8. Add <enter> handler in Find dialog

import os, os.path
import sys
import pygtk
pygtk.require ('2.0')

import gtk
if gtk.pygtk_version < (2,10,0):
    pyversion = '.'.join(str(i) for i in gtk.pygtk_version)
    print "PyGtk 2.10 or later required. Installed version is " + pyversion
    raise SystemExit

import gtksourceview2
import pango


######################################################################
##### global vars
windows = []    # this list contains all view windows
MARK_CATEGORY_1 = 'one'
MARK_CATEGORY_2 = 'two'
DATADIR = '/usr/share'
findtext = 'Text to find'


######################################################################
##### error dialog
def error_dialog(parent, msg):
    dialog = gtk.MessageDialog(parent,
                               gtk.DIALOG_DESTROY_WITH_PARENT,
                               gtk.MESSAGE_ERROR,
                               gtk.BUTTONS_OK,
                               msg)
    dialog.run()
    dialog.destroy()
    

######################################################################
##### remove all markers
def remove_all_marks(buffer):
    begin, end = buffer.get_bounds()
    buffer.remove_source_marks(begin, end)


######################################################################
##### load file
def load_file(buffer, path):
    buffer.begin_not_undoable_action()
    try:
        txt = open(path).read()
    except:
        return False
    buffer.set_text(txt)
    buffer.set_data('filename', path)
    buffer.end_not_undoable_action()

    buffer.set_modified(False)
    buffer.place_cursor(buffer.get_start_iter())
    return True


######################################################################
##### buffer creation
def open_file(buffer, filename):
    # get the new language for the file mimetype
    manager = buffer.get_data('languages-manager')

    if os.path.isabs(filename):
        path = filename
    else:
        path = os.path.abspath(filename)

    language = manager.guess_language(filename)
    if language:
        buffer.set_highlight_syntax(True)
        buffer.set_language(language)
        print 'Guessed language "%s" for "%s"' % (language.get_name(), filename)
    else:
        print 'No language found for file "%s"' % filename
        buffer.set_highlight_syntax(False)

    remove_all_marks(buffer)
    load_file(buffer, path) # TODO: check return
    # not quite sure how to do this
    #window = buffer.get_toplevel()
    #window.set_title('USFM Viewer - ' + filename)
    return True


######################################################################
##### Printing callbacks
def begin_print_cb(operation, context, compositor):
    while not compositor.paginate(context):
        pass
    n_pages = compositor.get_n_pages()
    operation.set_n_pages(n_pages)


def draw_page_cb(operation, context, page_nr, compositor):
    compositor.draw_page(context, page_nr)


######################################################################
##### Action callbacks
def numbers_toggled_cb(action, sourceview):
    sourceview.set_show_line_numbers(action.get_active())
    

def marks_toggled_cb(action, sourceview):
    sourceview.set_show_line_marks(action.get_active())
    

def margin_toggled_cb(action, sourceview):
    sourceview.set_show_right_margin(action.get_active())
    

def auto_indent_toggled_cb(action, sourceview):
    sourceview.set_auto_indent(action.get_active())
    

def insert_spaces_toggled_cb(action, sourceview):
    sourceview.set_insert_spaces_instead_of_tabs(action.get_active())
    

def tabs_toggled_cb(action, action2, sourceview):
    sourceview.set_tab_width(action.get_current_value())


def fontsize_toggled_cb(action, action2, sourceview):
    font_name = 'monospace ' + str(action.get_current_value())
    font_desc = pango.FontDescription(font_name)
    if font_desc:
        sourceview.modify_font(font_desc)


def new_view_cb(action, sourceview):
    window = create_view_window(sourceview.get_buffer(), sourceview)
    window.set_default_size(800, 500)
    window.show()


def print_cb(action, sourceview):
    window = sourceview.get_toplevel()
    buffer = sourceview.get_buffer()
    
    compositor = gtksourceview2.print_compositor_new_from_view(sourceview)
    compositor.set_wrap_mode(gtk.WRAP_CHAR)
    compositor.set_highlight_syntax(True)
    compositor.set_print_line_numbers(5)
    compositor.set_header_format(False, 'Printed on %A', None, '%F')
    filename = buffer.get_data('filename')
    compositor.set_footer_format(True, '%T', filename, 'Page %N/%Q')
    compositor.set_print_header(True)
    compositor.set_print_footer(True)
    
    print_op = gtk.PrintOperation()
    print_op.connect("begin-print", begin_print_cb, compositor)
    print_op.connect("draw-page", draw_page_cb, compositor)
    res = print_op.run(gtk.PRINT_OPERATION_ACTION_PRINT_DIALOG, window)
     
    if res == gtk.PRINT_OPERATION_RESULT_ERROR:
        error_dialog(window, "Error printing file:\n\n" + filename)
    elif res == gtk.PRINT_OPERATION_RESULT_APPLY:
        print 'file printed: "%s"' % filename


def help_about_cb(action, sourceview):
    dialog = gtk.AboutDialog()
    dialog.set_name("Python USFM Viewer")
    dialog.set_authors("Matt Postiff")
    dialog.set_copyright("(C) 2018 Matt Postiff")
    dialog.set_version("1.0")
    response = dialog.run()
    dialog.destroy()


def view_find_cb(action, sourceview):
    global findtext
    # I don't have a gtkWindow to be a parent here...
    dialog = gtk.Dialog("Find Text", None,
                        gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
                        (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                         gtk.STOCK_FIND,   gtk.RESPONSE_APPLY))

    # Add the text box for search text, etc.
    dialog.set_size_request(200, 100)
    entry = gtk.Entry();
    entry.set_text(findtext)
    entry.set_editable(True)
    entry.set_visibility(True)
    entry.show()
    entry.set_icon_from_icon_name(gtk.ENTRY_ICON_PRIMARY, gtk.STOCK_FIND)
    dialog.vbox.pack_start(entry, True, True, 0)
    
    response = dialog.run()
    findtext = entry.get_buffer().get_text()
    dialog.destroy()
    # Do something
    if response == gtk.RESPONSE_APPLY:
      do_find(findtext)
    else:
      print 'Canceled the find.'

def view_find_again_cb(action, sourceview):
    do_find(findtext)
      
def do_find(findtext):
    print 'Trying to find ' + findtext 

    found_anything = False;

    if found_anything == False:
        error_dialog(None, "Could not find " + findtext)
    
######################################################################
##### Buffer action callbacks
def open_file_cb(action, buffer):
    chooser = gtk.FileChooserDialog('Open file...', None,
                                    gtk.FILE_CHOOSER_ACTION_OPEN,
                                    (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                                    gtk.STOCK_OPEN, gtk.RESPONSE_OK))
    response = chooser.run()
    if response == gtk.RESPONSE_OK:
        filename = chooser.get_filename()
        if filename:
            open_file(buffer, filename)
    chooser.destroy()


def update_cursor_position(buffer, view):
    tabwidth = view.get_tab_width()
    pos_label = view.get_data('pos_label')
    iter = buffer.get_iter_at_mark(buffer.get_insert())
    nchars = iter.get_offset()
    row = iter.get_line() + 1
    start = iter.copy()
    start.set_line_offset(0)
    col = 0
    while start.compare(iter) < 0:
        if start.get_char() == '\t':
            col += tabwidth - col % tabwidth
        else:
            col += 1
        start.forward_char()
    pos_label.set_text('char: %d, line: %d, column: %d' % (nchars, row, col+1))
    

def move_cursor_cb (buffer, cursoriter, mark, view):
    update_cursor_position(buffer, view)


def window_deleted_cb(widget, ev, view):
    if windows[0] == widget:
        gtk.main_quit()
    else:
        # remove window from list
        windows.remove(widget)
        # we return False since we want the window destroyed
        return False
    return True


def button_press_cb(view, ev):
    buffer = view.get_buffer()
    if not view.get_show_line_marks():
        return False
    # check that the click was on the left gutter
    if ev.window == view.get_window(gtk.TEXT_WINDOW_LEFT):
        if ev.button == 1:
            mark_category = MARK_CATEGORY_1
        else:
            mark_category = MARK_CATEGORY_2
        x_buf, y_buf = view.window_to_buffer_coords(gtk.TEXT_WINDOW_LEFT,
                                                    int(ev.x), int(ev.y))
        # get line bounds
        line_start = view.get_line_at_y(y_buf)[0]

        # get the markers already in the line
        mark_list = buffer.get_source_marks_at_line(line_start.get_line(), mark_category)
        # search for the marker corresponding to the button pressed
        for m in mark_list:
            if m.get_category() == mark_category:
                # a marker was found, so delete it
                buffer.delete_mark(m)
                break
        else:
            # no marker found, create one
            buffer.create_source_mark(None, mark_category, line_start)
    
    return False


######################################################################
##### Actions & UI definition
buffer_actions = [
    ('Open', gtk.STOCK_OPEN, '_Open', '<control>O', 'Open a file', open_file_cb),
    ('Quit', gtk.STOCK_QUIT, '_Quit', '<control>Q', 'Exit the application', gtk.main_quit)
]

view_actions = [
    ('FileMenu', None, '_File'),
    ('ViewMenu', None, '_View'),
    ('HelpMenu', None, '_Help'),
    ('Print', gtk.STOCK_PRINT, '_Print', '<control>P', 'Print the file', print_cb),
    ('NewView', gtk.STOCK_NEW, '_New View', None, 'Create a new view of the file', new_view_cb),
    ('HelpAbout', gtk.STOCK_ABOUT, '_About', None, 'Display the About dialog', help_about_cb),
    ('ViewFind', gtk.STOCK_FIND, '_Find', '<control>F', 'Find dialog', view_find_cb),
    ('ViewFindAgain', gtk.STOCK_FIND, 'Find A_gain', '<control>G', 'Find last text again', view_find_again_cb),
    ('TabsWidth', None, '_Tabs Width'),
    ('FontSize', None, '_Font Size'),
]

toggle_actions = [
    ('ShowNumbers', None, 'Show _Line Numbers', None, 'Toggle visibility of line numbers in the left margin', numbers_toggled_cb, False),
    ('ShowMarkers', None, 'Show _Markers', None, 'Toggle visibility of markers in the left margin', marks_toggled_cb, False),
    ('ShowMargin', None, 'Show M_argin', None, 'Toggle visibility of right margin indicator', margin_toggled_cb, False),
    ('AutoIndent', None, 'Enable _Auto Indent', None, 'Toggle automatic auto indentation of text', auto_indent_toggled_cb, False),
    ('InsertSpaces', None, 'Insert _Spaces Instead of Tabs', None, 'Whether to insert space characters when inserting tabulations', insert_spaces_toggled_cb, False)
]

radio_tabwidth = [
    ('TabsWidth4', None, '4', None, 'Set tabulation width to 4 spaces', 4),
    ('TabsWidth6', None, '6', None, 'Set tabulation width to 6 spaces', 6),
    ('TabsWidth8', None, '8', None, 'Set tabulation width to 8 spaces', 8),
    ('TabsWidth10', None, '10', None, 'Set tabulation width to 10 spaces', 10),
    ('TabsWidth12', None, '12', None, 'Set tabulation width to 12 spaces', 12)
]

radio_fontsize = [
    ('FontSize8', None, '8', None, 'Set font size to 8 points', 8),
    ('FontSize9', None, '9', None, 'Set font size to 9 points', 9),
    ('FontSize10', None, '10', None, 'Set font size to 10 points', 10),
    ('FontSize11', None, '11', None, 'Set font size to 10 points', 11),
    ('FontSize12', None, '12', None, 'Set font size to 10 points', 12),
    ('FontSize14', None, '14', None, 'Set font size to 10 points', 14),
    ('FontSize16', None, '16', None, 'Set font size to 10 points', 16),
]

view_ui_description = """
<ui>
  <menubar name='MainMenu'>
    <menu action='FileMenu'>
      <menuitem action='NewView'/>
      <placeholder name="FileMenuAdditions"/>
      <separator/>
      <menuitem action='Print'/>
    </menu>
    <menu action='ViewMenu'>
      <separator/>
      <menuitem action='ViewFind'/>
      <menuitem action='ViewFindAgain'/>
      <separator/>
      <menuitem action='ShowNumbers'/>
      <menuitem action='ShowMarkers'/>
      <menuitem action='ShowMargin'/>
      <separator/>
      <menuitem action='AutoIndent'/>
      <menuitem action='InsertSpaces'/>
      <separator/>
      <menu action='TabsWidth'>
        <menuitem action='TabsWidth4'/>
        <menuitem action='TabsWidth6'/>
        <menuitem action='TabsWidth8'/>
        <menuitem action='TabsWidth10'/>
        <menuitem action='TabsWidth12'/>
      </menu>
      <menu action='FontSize'>
        <menuitem action='FontSize8'/>
        <menuitem action='FontSize9'/>
        <menuitem action='FontSize10'/>
        <menuitem action='FontSize11'/>
        <menuitem action='FontSize12'/>
        <menuitem action='FontSize14'/>
        <menuitem action='FontSize16'/>
      </menu>
    </menu>
    <menu action='HelpMenu'>
      <menuitem action='HelpAbout'/>
    </menu>
  </menubar>
</ui>
"""

buffer_ui_description = """
<ui>
  <menubar name='MainMenu'>
    <menu action='FileMenu'>
      <placeholder name="FileMenuAdditions">
        <menuitem action='Open'/>
      </placeholder>
      <separator/>
      <menuitem action='Quit'/>
    </menu>
    <menu action='ViewMenu'>
    </menu>
    <menu action='HelpMenu'>
    </menu>
  </menubar>
</ui>
"""

    
######################################################################
##### create view window
def create_view_window(buffer, sourceview=None):
    # window
    window = gtk.Window(gtk.WINDOW_TOPLEVEL)
    window.set_border_width(0)
    window.set_title('USFM Viewer')
    windows.append(window) # this list contains all view windows

    # view
    view = gtksourceview2.View(buffer)
    buffer.connect('mark_set', move_cursor_cb, view)
    buffer.connect('changed', update_cursor_position, view)
    view.connect('button-press-event', button_press_cb)
    window.connect('delete-event', window_deleted_cb, view)

    # action group and UI manager
    action_group = gtk.ActionGroup('ViewActions')
    action_group.add_actions(view_actions, view)
    action_group.add_toggle_actions(toggle_actions, view)
    action_group.add_radio_actions(radio_tabwidth, -1, tabs_toggled_cb, view)
    action_group.add_radio_actions(radio_fontsize, -1, fontsize_toggled_cb, view)

    ui_manager = gtk.UIManager()
    ui_manager.insert_action_group(action_group, 0)
    # save a reference to the ui manager in the window for later use
    window.set_data('ui_manager', ui_manager)
    accel_group = ui_manager.get_accel_group()
    window.add_accel_group(accel_group)
    ui_manager.add_ui_from_string(view_ui_description)

    # misc widgets
    vbox = gtk.VBox(0, False)
    sw = gtk.ScrolledWindow()
    sw.set_shadow_type(gtk.SHADOW_IN)
    pos_label = gtk.Label('Position')
    view.set_data('pos_label', pos_label)
    menu = ui_manager.get_widget('/MainMenu')

    # layout widgets
    window.add(vbox)
    vbox.pack_start(menu, False, False, 0)
    vbox.pack_start(sw, True, True, 0)
    sw.add(view)
    vbox.pack_start(pos_label, False, False, 0)

    # setup view
    font_desc = pango.FontDescription('monospace 10')
    if font_desc:
        view.modify_font(font_desc)

    # change view attributes to match those of sourceview (only initially)
    if sourceview:
        action = action_group.get_action('ShowNumbers')
        action.set_active(sourceview.get_show_line_numbers())
        action = action_group.get_action('ShowMarkers')
        action.set_active(sourceview.get_show_line_marks())
        action = action_group.get_action('ShowMargin')
        action.set_active(sourceview.get_show_right_margin())
        action = action_group.get_action('AutoIndent')
        action.set_active(sourceview.get_auto_indent())
        action = action_group.get_action('InsertSpaces')
        action.set_active(sourceview.get_insert_spaces_instead_of_tabs())
        action = action_group.get_action('TabsWidth%d' % sourceview.get_tab_width())
        if action:
            action.set_active(True)
        action = action_group.get_action('FontSize%d' % sourceview.get_tab_width())
        if action:
            action.set_active(True)

    # add marker pixbufs
    pixbuf = gtk.gdk.pixbuf_new_from_file(os.path.join(DATADIR,
                                                       'pixmaps/other/Apple-Green.png'))
    if pixbuf:
        view.set_mark_category_pixbuf(MARK_CATEGORY_1, pixbuf)
    else:
        print 'could not load marker 1 image.  Spurious messages might get triggered'
    pixbuf = gtk.gdk.pixbuf_new_from_file(os.path.join(DATADIR,
                                                       'pixmaps/other/Apple-Red.png'))
    if pixbuf:
        view.set_mark_category_pixbuf(MARK_CATEGORY_2, pixbuf)
    else:
        print 'could not load marker 2 image.  Spurious messages might get triggered'

    vbox.show_all()

    return window
    
    
######################################################################
##### create main window
def create_main_window(buffer):
    window = create_view_window(buffer)
    ui_manager = window.get_data('ui_manager')
    
    # buffer action group
    action_group = gtk.ActionGroup('BufferActions')
    action_group.add_actions(buffer_actions, buffer)
    ui_manager.insert_action_group(action_group, 1)
    # merge buffer ui
    ui_manager.add_ui_from_string(buffer_ui_description)

    # preselect menu checkitems
    groups = ui_manager.get_action_groups()
    # retrieve the view action group at position 0 in the list
    action_group = groups[0]
    action = action_group.get_action('ShowNumbers')
    action.set_active(True)
    action = action_group.get_action('ShowMarkers')
    action.set_active(True)
    action = action_group.get_action('ShowMargin')
    action.set_active(False)
    action = action_group.get_action('AutoIndent')
    action.set_active(True)
    action = action_group.get_action('InsertSpaces')
    action.set_active(True)
    action = action_group.get_action('TabsWidth8')
    action.set_active(True)
    action = action_group.get_action('FontSize10')
    action.set_active(True)

    return window


######################################################################
##### main
def main(args):
    # create buffer
    lm = gtksourceview2.LanguageManager()
    buffer = gtksourceview2.Buffer()
    buffer.set_data('languages-manager', lm)

    # parse arguments
    if len(args) >= 2:
        open_file(buffer, args[1])
        
    # create first window
    window = create_main_window(buffer)
    window.set_default_size(1000, 1000)
    window.show()

    # main loop
    gtk.main()
    

if __name__ == '__main__':
    if '--debug' in sys.argv:
        import pdb
        pdb.run('main(sys.argv)')
    else:
        main(sys.argv)
