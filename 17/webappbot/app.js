// This script sample is part of "Learn Azure in a Month of Lunches" (Manning
// Publications) by Iain Foulds.
//
// This sample script covers the exercises from chapter 17 of the book. For more
// information and context to these commands, read a sample of the book and
// purchase at https://www.manning.com/books/learn-azure-in-a-month-of-lunches
//
// This script sample is released under the MIT license. For more information,
// see https://github.com/fouldsy/azure-mol-samples/blob/master/LICENSE

// Include the required npm packages for the Microsoft Bot Connector frameworks
var restify = require('restify');
var builder = require('botbuilder');
var botbuilder_azure = require("botbuilder-azure");

// Setup Restify Server to handle the REST responses for your bot
var server = restify.createServer();
server.listen(process.env.port || process.env.PORT || 3978, function () {
   console.log('%s listening to %s', server.name, server.url); 
});
  
// Create chat connector for communicating with the Bot Framework Service
var connector = new builder.ChatConnector({
    appId: process.env.MicrosoftAppId,
    appPassword: process.env.MicrosoftAppPassword,
    openIdMetadata: process.env.BotOpenIdMetadata 
});

// Listen for messages from users 
server.post('/api/messages', connector.listen());

// Store bot data in Azure Storage. You can also use Cosmos DB or Azure SQL Server
var tableName = 'botdata';
var azureTableClient = new botbuilder_azure.AzureTableClient(tableName, process.env['AzureWebJobsStorage']);
var tableStorage = new botbuilder_azure.AzureBotStorage({ gzipData: false }, azureTableClient);

// Create your bot with a function to receive messages from the user
var bot = new builder.UniversalBot(connector);
bot.set('storage', tableStorage);

// Read in application settings from your Azure Web App to populate the LUIS app ID and API key
var luisAppId = process.env.LuisAppId;
var luisAPIKey = process.env.LuisAPIKey;
var luisAPIHostName = process.env.LuisAPIHostName || 'westus.api.cognitive.microsoft.com';
const LuisModelUrl = 'https://' + luisAPIHostName + '/luis/v1/application?id=' + luisAppId + '&subscription-key=' + luisAPIKey;

// Start the main dialog with LUIS
var recognizer = new builder.LuisRecognizer(LuisModelUrl);
var intents = new builder.IntentDialog({ recognizers: [recognizer] })

// Handle a greeting from the user. With the bot's response, provide some suggested actions the user can take
.matches('greetings', (session) => {
    session.send('Hi! I\'m the Azure Month of Lunches pizza bot. What can I help you with? You can say things like, "Show me the menu", "Order pizza", "What\s the status of my order?"');
})

// Handle user intent to view the menu.
.matches('showMenu', (session) => {
    session.send('Here\s what we have on the menu today: ');
    session.send('- Pepperoni pizza: $18 \n - Veggie pizza: $15 \n - Hawaiian pizza: $12');
    
    // A good practice is to then help guide the user, so suggest some additional actions now
    session.send('You can order food with, "One pepperoni pizza", or "I\'d like a veggie, please"')
})

// Handle the user ordering food
.matches('orderFood', [(session, args, next) => {

        // Try to read in if the user included a type of pizza, an entity
        var food = builder.EntityRecognizer.findEntity(args.entities, 'pizza.type');
        var order = session.dialogData.order = {
          food: food ? food.entity : null,
        };

        // If they didn't include the type of pizza in their initial request, prompt for the type of pizza to order
        if (!order.food) {
            builder.Prompts.text(session, 'What type of pizza would you like to order?');
        } else {
           next();
        }
    },
    (session, results) => {
        // Read in the type of the pizza, or set it based on the entity found in the user's request
        var order = session.dialogData.order;
        if (results.response) {
            order.food = results.response;
        }
        
        // Create an object to hold the user's order
        if (!session.userData.order) {
            session.userData.order = {};
            console.log("initializing session.userData.order in orderFood dialog");
        }
        session.userData.order[0] = order;

        // Send confirmation to user
        session.endDialog('Created order for %s pizza!',
            order.food);
}])

// Handle the user looking for a status on their order
.matches('orderStatus',  [(session, args, next) => {
    // If an order has been placed, output a generic message that their order will be ready soon
    if (session.userData.order) {
        food = session.userData.order;
        session.endDialog("Your order of %s pizza will be ready soon!", session.userData.order[0].food);
    } 
    // Otherwise, guide the user to a couple of suggested actions for them to place an order
    else {
        session.endDialog('Hmmm, it doesn\'t look you\'ve place an order yet. \n You say, "Show me the menu", or "Order food" to get started.');
    }
}])

// Handle no intent being found
.matches('None', (session) => {
    session.send('Hi! I\'m the Azure Month of Lunches pizza bot. What can I help you with? You can say things like, "Show me the menu", "Order pizza", "What\s the status of my order?"');
})

// Handle anything else that isn't understand by LUIS and ask the user to state their question a different way.
.onDefault((session) => {
    session.send('Sorry, I didn\t understand \'%s\'. Can you try to rephrase that, please?', session.message.text);
});

bot.dialog('/', intents);