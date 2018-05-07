This sample script creates a Traffic Manager profile with nested, redundant child profiles for two regions - East US and West Europe.

Each of the child profiles has priority rules assigned to direct traffic from the appropriate geography to a Web App closest to the user.

The parent Traffic Manager profile then automatically routes and directs customers to the closet Web App instance.