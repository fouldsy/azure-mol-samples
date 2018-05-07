// This script sample is part of "Learn Azure in a Month of Lunches" (Manning
// Publications) by Iain Foulds.
//
// This sample script covers the exercises from chapter 10 of the book. For more
// information and context to these commands, read a sample of the book and
// purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
//
// This script sample is released under the MIT license. For more information,
// see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

"use strict";

var config = require("./config");
var url = require('url');
var http = require('http');

// Create a connection to Cosmos DB
// Here, we use the Document model, and define a connection policy
var documentClient = require("documentdb").DocumentClient;
var lib = require("./node_modules/documentdb/lib/");

// The connection policy can use automatic endpoint discovery, or you can specify a list
// of preferred endpoints.
var connectionPolicy = new lib.DocumentBase.ConnectionPolicy();

// Using automatic discovery is a more dynamic approach, and your code requires no changes
// as you add or remove endpoints in Cosmos DB.
// If you wanted to use automatiic endpoint discovery, you would uncomment the following line.
//connectionPolicy.EnableEndpointDiscovery = 'True';

// Using a list of preferred locations allows you to control the order in which endpoints
// are used. In our example, we selected 'West Europe' as an additional endpoint. By then
// setting 'West Europe' as our preferred location, although all writes still go through the
// the primary endpoint of 'East US', all reads go through 'West Europe'.
connectionPolicy.PreferredLocations = ['West Europe', 'East US'];

// Now actually make the connection to Cosmos DB using our endpoint, key, and connection policy
var client = new documentClient(config.uri, { "masterKey": config.primaryKey }, connectionPolicy);
var databaseUrl = `dbs/${config.database.id}`;
var collectionUrl = `${databaseUrl}/colls/${config.collection.id}`;

// Start a basic HTTP server in Node.js for our basic web app
var server = http.createServer(function(request, response) {

    // Start to write a basic HTTP response to render our page
    response.writeHead(200, {"Content-Type": "text/plain"});

    // Output the current write endpoint
    // This is the endpoint where all write requests route through to ensure data consistency
    client.getWriteEndpoint(function(endpoint) {
        response.write('Current write endpoint is: ' + endpoint + '\n\n');
    });

    // Output the current read endpoint
    // This is the power of Cosmos DB. The APIs determine the most appropriate read endpoint and route your
    // requests accordingly. There's nothing your app does here.
    // This is purely for informational purposes. You just query the database in the next code block
    // and let the APIs determine the most appropriate endpoint to pull data from.
    client.getReadEndpoint(function(endpoint) {
        response.write('Current read endpoint is: ' + endpoint + '\n\n');
    });

    // Query the database to obtain a basic list of pizzas and their costs
    // This can be expanded to sort by price or alphabetically by pizza name, for example
    client.queryDocuments(
            collectionUrl,
            'SELECT c.description,c.cost FROM c'
        ).toArray((err, results) => {
            if (err) reject(err)
            else {

                for (var queryResult of results) {
                    response.write('Name: ' + queryResult.description + '\n');
                    response.write('Cost: $' + queryResult.cost+ '\n\n');
                }
                response.end();
            }
        });
});

// Start the web server listening on port 3000
// If you use Azure Web Apps, this port is mapped back to port 80 so that's all you need to
// enter in your web browser
var port = process.env.PORT || 3000;
server.listen(port);

console.log("Server running at http://localhost:%d", port);
