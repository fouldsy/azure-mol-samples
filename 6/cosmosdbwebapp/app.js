"use strict";

var documentClient = require("documentdb").DocumentClient;
var config = require("./config");
var url = require('url');
var http = require('http');


var lib = require("./node_modules/documentdb/lib/");
var connectionPolicy = new lib.DocumentBase.ConnectionPolicy();
connectionPolicy.EnableEndpointDiscovery = 'True';

var client = new documentClient(config.endpoint, { "masterKey": config.primaryKey }, connectionPolicy);

var databaseUrl = `dbs/${config.database.id}`;
var collectionUrl = `${databaseUrl}/colls/${config.collection.id}`;

//client.deleteDatabase(`dbs/${databaseId}`, callback);

var read = documentClient.getReadEndpoint;
var write = documentClient.getWriteEndpoint;

var server = http.createServer(function(request, response) {

    response.writeHead(200, {"Content-Type": "text/plain"});

    response.write('Write endpoint is: ' + read);
    response.write('\nRead endpoint is: ' + read + '\n\n');

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

var port = process.env.PORT || 3000;
server.listen(port);

console.log("Server running at http://localhost:%d", port);
