# Getting the graphs
bin/keys_redis.rb #shows available keys TODO: automate via SQS again
bin/scrape_inbox <email>
bin/vold_to_graphml.rb <email>

# Steps to automate graphs in gephi:

# Use Gephi to render, filter and and export the network
* Gephi -> Import /tmp/imap:<email>.graphml
Gephi -> Data Table -> Copy node 'address' field to 'Label' field (or fix in JSON!)
Gephi -> Data Table -> Copy edge 'volume' field to 'Weight' field (or fix in JSON!)
Gephi -> Overview -> Ranking -> Nodes -> Size/Weight -> Degree (1, 100 linear)
Gephi -> Overview -> Ranking -> Edges -> Size/Weight -> Weight (1, 100 linear)
Gephi -> Overview -> Graph -> Show Node Labels
Gephi -> Overview -> Graph -> Node Font (Arial Plain 10pt)
Gephi -> Overview -> Graph -> Filters -> Topology -> Degree Range -> Parameters -> 12-MAX ( # Add K-Core Filter!!!  Weighted K-Cores!
Gephi -> Overview -> Layout -> OpenORD (25, 25, 25, 10, 15)
Gephi -> Overview -> Layout -> Label Adjust (Speed 5.0) x 2 (run this step twice, the 2nd one on Speed 1.0? or 5.0)

Gephi -> Preview -> Preview Settings -> Presets (Kontexa)
Gephi -> Preview -> Export: SVG/PDF/PNG -> File Format (PNG) -> Options -> Resolution (9046 x 9046) -> Filename (<email>.png)
mkdir <image_dir><email>_seadragon/ (ex: mkdir ~/Dropbox/Startup/Data\ Images/Alpha\ Test/Jay_seadragon)
Gephi -> File -> Export -> Seadragon Web (Width: 8192, Height: 6144, Tile Size: 256, Margins: Top/Left/Right/Bottom: 100)

# Overlay the logo - from Dattack/
composite -gravity southeast -geometry 1024x1024+300+200  gephi/logo-almostfinal-512trans.png ~/Dropbox/Startup/Data\ Images/Alpha\ Test/JayVarner.png gephi/out.png