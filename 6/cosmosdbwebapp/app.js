"use strict";

var documentClient = require("documentdb").DocumentClient;
var config = require("./config");
var url = require('url');

var http = require('http');

var config = require("./config");
var url = require('url');

var client = new documentClient(config.endpoint, { "masterKey": config.primaryKey });

var databaseUrl = `dbs/${config.database.id}`;
var collectionUrl = `${databaseUrl}/colls/${config.collection.id}`;

var server = http.createServer(function(request, response) {

    response.writeHead(200, {"Content-Type": "text/plain"});

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
