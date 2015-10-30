namespace Vocal {

    public class DirectoryView : Gtk.Box {

        public signal void return_to_library();
        public signal void return_to_welcome();
        public signal void on_new_subscription(string url);

        private iTunesProvider itunes;
        private Gtk.FlowBox flowbox;
        private Gtk.Box banner_box;
        public  Gtk.Button return_button;
        public  Gtk.Button forward_button;
        private Gtk.Button first_run_continue_button;

        private Gtk.Box loading_box;

        public DirectoryView(iTunesProvider p, bool first_run = false) {

            this.set_orientation(Gtk.Orientation.VERTICAL);

            // Set up the banner

            banner_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            var itunes_title = new Gtk.Label(_("iTunes Top 100 Podcasts"));
            itunes_title.margin_top = 5;
            itunes_title.margin_bottom = 5;
            itunes_title.justify = Gtk.Justification.CENTER;
            itunes_title.expand = true;
            itunes_title.halign = Gtk.Align.CENTER;
            itunes_title.valign = Gtk.Align.CENTER;

            Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.H2, itunes_title);

            if(first_run) {
                return_button = new Gtk.Button.with_label(_("Go Back"));
                return_button.clicked.connect(() => { return_to_welcome (); });
            } else  {
                return_button = new Gtk.Button.with_label(_("Return to Library"));
                return_button.clicked.connect(() => { return_to_library (); });
            }
            return_button.get_style_context().add_class("back-button");
            return_button.margin_top = 12;
            return_button.margin_left = 12;
            return_button.margin_bottom = 0;
            return_button.expand = false;
            return_button.halign = Gtk.Align.START;

            first_run_continue_button = new Gtk.Button.with_label(_("Done"));
            first_run_continue_button.get_style_context().add_class("suggested-action");
            first_run_continue_button.margin_top = 12;
            first_run_continue_button.margin_right = 12;
            first_run_continue_button.margin_bottom = 0;
            first_run_continue_button.expand = false;
            first_run_continue_button.halign = Gtk.Align.END;
            first_run_continue_button.clicked.connect(() => {
                return_button.clicked.connect(() => { return_to_library(); });
                return_button.label = _("Return to Library");
                hide_first_run_continue_button();
                return_to_library();
            });
            first_run_continue_button.sensitive = false;

            banner_box.add(return_button);
            banner_box.add(first_run_continue_button);

            if(!first_run) {
                hide_first_run_continue_button();
            }

            banner_box.vexpand = false;
            banner_box.hexpand = true;

            itunes_title.vexpand = false;
            itunes_title.hexpand  = true;

            this.itunes = p;
            this.add(banner_box);
            this.add(itunes_title);
            
            loading_box = new  Gtk.Box(Gtk.Orientation.VERTICAL, 5);
            var spinner = new Gtk.Spinner();
            spinner.active = true; 
            var loading_label = new Gtk.Label(_("Loading iTunes Store"));
            loading_label.get_style_context().add_class("h2");
            loading_box.add(loading_label);
            loading_box.add(spinner);
            this.pack_start(loading_box, true, true, 5);

            load_top_podcasts();
        }

        public async void load_top_podcasts() {

            SourceFunc callback = load_top_podcasts.callback;

            ThreadFunc<void*> run = () => {

                flowbox = new Gtk.FlowBox();

                Gee.ArrayList<DirectoryEntry> entries = itunes.get_top_podcasts(100);

                int i = 1;
                foreach(DirectoryEntry e in entries) {

                    DirectoryArt a = new DirectoryArt(e.itunesUrl, "%d. %s".printf(i, e.title), e.artist, e.summary, e.artworkUrl170);
                    a.expand = false;
                    a.subscribe_button_clicked.connect((url) => {
                        first_run_continue_button.sensitive = true;
                        on_new_subscription(url);
                    });
                    flowbox.add(a);
                    i++;
                }

                Idle.add((owned) callback);
                return null;
            };
            Thread.create<void*>(run, false);

            yield;

            info ("Loading complete.");
            loading_box.set_no_show_all(true);
            loading_box.hide();

            this.pack_start(flowbox, true, true, 5);
            show_all();
        }

        public void show_first_run_continue_button() {
            first_run_continue_button.set_no_show_all(false);
            first_run_continue_button.show();
        }

        public void hide_first_run_continue_button() {
            first_run_continue_button.set_no_show_all(true);
            first_run_continue_button.hide();
        }
    }
}
