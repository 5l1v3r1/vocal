namespace Vocal {

    public class iTunesProvider {

        private Json.Object itunes_result;
        public iTunesProvider() {}

        public string get_rss_from_itunes_url(string itunes_url, out string? name = null) {

            string rss = "";

            // We just need to get the iTunes store iD
            int start_index = itunes_url.index_of("id") + 2;
            int stop_index = itunes_url.index_of("?");

            string id = itunes_url.slice(start_index, stop_index);

            var uri =  "https://itunes.apple.com/lookup?id=%s&entity=podcast".printf(id);
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", uri);
            session.send_message (message);

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                var root_object = parser.get_root ().get_object ();

                if(root_object == null) {
                    stdout.puts("Error. Root object was null.");
                    return null;
                }


                var elements = root_object.get_array_member("results").get_elements();

                foreach(Json.Node e in elements) {
                    var obj = e.get_object();
                    rss = obj.get_string_member("feedUrl");
                    name = obj.get_string_member("trackName");
                }

            } catch (Error e) {
                warning ("An error occurred while discovering the real RSS feed address");
            }

            return rss;

        }

        public Gee.ArrayList<DirectoryEntry>? get_top_podcasts(int? limit = 100) {

            var uri =  "https://itunes.apple.com/us/rss/toppodcasts/limit=%d/json".printf(limit);
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", uri);
            session.send_message (message);

            Gee.ArrayList<DirectoryEntry> entries = new Gee.ArrayList<DirectoryEntry>();

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                var root_object = parser.get_root ().get_object ();

                if(root_object == null) {
                    stdout.puts("Error. Root object was null.");
                    return null;
                }

                var elements = root_object.get_object_member("feed").get_array_member ("entry").get_elements();

                foreach(Json.Node e in elements) {

                    // Create a new DirectoryEntry to store the results
                    DirectoryEntry ent = new DirectoryEntry();

                    var obj = e.get_object();

                    // Objects
                    var id = obj.get_object_member("id"); // The podcast store URL
                    ent.itunesUrl = id.get_string_member("label");
                    var title = obj.get_object_member("title");
                    ent.title = title.get_string_member("label");
                    var summary = obj.get_object_member("summary");
                    ent.summary = summary.get_string_member("label");
                    var artist = obj.get_object_member("im:artist");
                    ent.artist = artist.get_string_member("label");

                    // Remove the artist name from the title
                    ent.title = ent.title.replace(" - " + ent.artist, "");

                    // Arrays
                    var image = obj.get_member("im:image").get_array().get_elements();

                    int i = 0;

                    foreach(Json.Node f in image) {
                        switch(i) {
                            case 0:
                                ent.artworkUrl55 = f.get_object().get_string_member("label");
                                break;
                            case 1:
                                ent.artworkUrl60 = f.get_object().get_string_member("label");
                                break;
                            case 2:
                                ent.artworkUrl170 = f.get_object().get_string_member("label");
                                break;
                        }
                        i++;
                    }

                    entries.add(ent);

                }

            } catch (Error e) {
                warning ("An error occurred while loading the iTunes results");
            }

            return entries;
        }

        public Gee.ArrayList<DirectoryEntry>? search_by_term(string term, int? limit = 25) {

            var uri = "https://itunes.apple.com/search?term=%s&entity=podcast&limit=%d".printf(term.replace(" ", "+"), limit);

            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", uri);
            session.send_message (message);

            Gee.ArrayList<DirectoryEntry> entries = new Gee.ArrayList<DirectoryEntry>();

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                var root_object = parser.get_root ().get_object ();

                if(root_object == null) {
                    stdout.puts("Error. Root object was null.");
                    return null;
                }


                var elements = root_object.get_array_member ("results").get_elements();

                foreach(Json.Node e in elements) {


                    // Create a new DirectoryEntry to store the results
                    DirectoryEntry ent = new DirectoryEntry();


                    var obj = e.get_object();

                    // Objects
                    ent.itunesUrl = e.get_object().get_string_member("collectionViewUrl");
                    ent.title = e.get_object().get_string_member("collectionName");
                    ent.artist = e.get_object().get_string_member("artistName");

                    // Remove the artist name from the title
                    ent.title = ent.title.replace(" - " + ent.artist, "");

                    ent.artworkUrl600 = e.get_object().get_string_member("artworkUrl600");

                    entries.add(ent);

                }

            } catch (Error e) {
                warning ("An error occurred while loading the iTunes results");
            }

            return entries;

        }
    }
}
