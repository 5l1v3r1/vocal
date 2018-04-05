/***
  BEGIN LICENSE

  Copyright (C) 2014-2018 Nathan Dyer <mail@nathandyer.me>
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as
  published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses>

  END LICENSE
***/

using Gtk;
using Gee;
using Granite;
namespace Vocal {

    public class NewEpisodesView : Gtk.Box {
    
        private Controller controller;
        private ListBox new_episodes_listbox;
        private GLib.List<Episode> episodes;
        public signal void go_back();
        public signal void play_episode_requested (Episode episode);
        
        public NewEpisodesView (Controller cont) {
            controller = cont;
            
            var toolbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            toolbar.get_style_context().add_class("toolbar");
            toolbar.get_style_context().add_class("library-toolbar");

            var go_back_button = new Gtk.Button.with_label(_("Your Podcasts"));
            go_back_button.clicked.connect(() => { go_back(); });
            go_back_button.get_style_context().add_class("back-button");
            go_back_button.margin = 6;
            
            toolbar.pack_start(go_back_button, false, false, 0);
            this.pack_start(toolbar, false, true, 0);
            
            var new_episodes_label = new Gtk.Label (_("New Episodes"));
            new_episodes_label.get_style_context ().add_class ("h2");
            new_episodes_label.margin_top = 12;
            this.pack_start(new_episodes_label, false, true, 0);
            
            new_episodes_listbox = new Gtk.ListBox ();
            new_episodes_listbox.margin_left = 50;
            new_episodes_listbox.margin_right = 50;
            var add_all_to_queue_button = new Gtk.Button.with_label (_("Add all new episodes to the queue"));
            add_all_to_queue_button.margin_left = 50;
            add_all_to_queue_button.margin_right = 50;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.pack_start (new_episodes_listbox, true, true, 15);
            this.pack_start (add_all_to_queue_button, false, false, 15);
            new_episodes_listbox.activate_on_single_click = false;
            new_episodes_listbox.row_activated.connect(on_row_activated);
        }
        
        public void populate_episodes_list () {
            episodes = new GLib.List<Episode>();
            var children = new_episodes_listbox.get_children ();
            for (int i = 0; i < children.length (); i++) {
                children.remove (children.nth_data (0));
            }
            foreach (Podcast p in controller.library.podcasts) {
                foreach (Episode e in p.episodes) {
                    if (e.status == EpisodeStatus.UNPLAYED) {
                        var new_episode = new EpisodeDetailBox (e, 0, 0, false, true);
                        new_episode.margin_top = 12;
                        new_episodes_listbox.prepend (new_episode);
                        episodes.prepend(e);
                    }
                }
            }
        }
        
        public void on_row_activated (Gtk.ListBoxRow row) {
            var index = row.get_index ();
            info("Index: %d".printf(index));
            Episode ep = episodes.nth(index).data;
            play_episode_requested (ep);
        }
        
        
        
        public void remove_episode_from_list (Episode e) {
            var children = new_episodes_listbox.get_children ();
            for (int i = 0; i < children.length (); i++) {
                var box = children.nth_data (i) as EpisodeDetailBox;
                if (box.episode.title == e.title) {
                    new_episodes_listbox.remove (box);
                    return;
                }
            }
        }
    }
}
