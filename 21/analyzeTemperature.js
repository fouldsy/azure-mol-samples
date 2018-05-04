// Every JavaScript Function App starts with exporting a function that
// contains a context object.
// This context object is used to pass data back and forth
module.exports = function (context, data) {

  // Read in message content from Service Bus and decode from base64
  var buffer = new Buffer(data.ContentData, 'base64')
  var decodedString = buffer.toString();

  // Create JSON object of decoded Service Bus message
  var objects = JSON.parse(decodedString);

  // Extract recorded temperature from IoT device
  var temperature = objects["temperature"];

  // Build response to send back to Logic App
  context.res = {
    body: {
      analysis: "Recorded temperature was  " + temperature + "!"
    }
  };

  // Output temperature to console log
  context.log("Recorded temperature was " + temperature);

  // Every JavaScript Function App must end with call to context.done
  // This call tells the Function App that your code is finished
  context.done();
};
