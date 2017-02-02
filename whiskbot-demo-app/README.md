#WhiskBot Demo App
>A Chatbot iOS application that uses OpenWhisk Swift Actions

## Installation

In order to install and setup WhiskBot there are a lot of things to get set up.  

#### Installing OpenWhisk and setting up the actions

The backend of WhiskBot is built with OpenWhisk actions.  There is a main Conversation Action, which is what the app directly interfaces with.  The Conversation Action communicates with the IBM Watson Conversation API in order to get responses to user inputs.  Based on the response and node visited inside the IBM Watson Conversation Service, the conversation Action will invoke other actions (Slack Post, Translation).  In order to set up WhiskBot, the Actions must be uploaded to the Cloud.

`The Actions to be uploaded to OpenWhisk can be found in the folder /WhiskBot/OpenWhiskActions`

To upload the Actions to OpenWhisk, you can either use the Command Line Interface or the Web Browser. [Get set up with OpenWhisk](https://console.ng.bluemix.net/openwhisk/getting-started)

#### Setting up the OpenWhisk Swift Client SDK

After all of the Actions are uploaded to IBM Bluemix, they are invoked with the app by using the [OpenWhisk Swift Client SDK](https://github.com/openwhisk/openwhisk-client-swift).  To install the Swift Client SDK, simply run `pod install` from the directory of the demo app.  

Along with the installation, the SDK has two credentials needed.  OpenWhisk has an Access Token and an Access Key that need to be updated inside the `IBMConstants.plist` file found in the main directory.  

In order to find the tokens, you can either use the CLI as documented in the [OpenWhisk Swift Client SDK](https://github.com/openwhisk/openwhisk-client-swift) README.

Or you can go to the [OpenWhisk Bluemix website](https://console.ng.bluemix.net/openwhisk/learn/cli) and under Step 2. copy the Authorization Key and Token.  Found in the command `wsk property set --apihost openwhisk.ng.bluemix.net --auth key:token`
