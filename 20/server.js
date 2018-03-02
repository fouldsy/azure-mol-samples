const express = require('express');
const path = require('path');

var Client = require('azure-iothub').Client;
const iotHubClient = require('./IoTHub/iot-hub.js');
const WebSocket = require('ws');
const moment = require('moment');

var connectionString = 'HostName=azuremol.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=SPV0TyIHkucKG8mUnlYcabVVFAiplTwoMndKHCzViLM=';
var consumerGroup = 'molwebapp';

var index = require('./routes/index');

const app = express();
app.set('port', process.env.PORT || 8080);

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs')

app.use('/', index);

var server = app.listen(app.get('port'), function() {
    console.log('Listening on port %d', server.address().port);
});

// Create Web Sockets server
const wss = new WebSocket.Server({ server });

// Log when WebSockets clients connect or disconnect
wss.on('connection', (ws) => {
  console.log('Client connected');
  ws.on('close', () => console.log('Client disconnected'));
});

// Broadcast data to all WebSockets clients
wss.broadcast = function broadcast(data) {
  wss.clients.forEach(function each(client) {
    if (client.readyState === WebSocket.OPEN) {
      try {
        console.log('sending data ' + data);
        client.send(data);
      } catch (e) {
        console.error(e);
      }
    }
  });
};

// Read in data from IoT Hub and then create broadcast to WebSockets client as new data is received from device
var iotHubReader = new iotHubClient(connectionString, consumerGroup);
iotHubReader.startReadMessage(function (obj, date) {
  try {
    console.log(date);
    date = date || Date.now();
    wss.broadcast(JSON.stringify(Object.assign(obj, { time: moment().format('LTS L') })));

  } catch (err) {
    console.log(obj);
    console.error(err);
  }
});

module.exports = app;