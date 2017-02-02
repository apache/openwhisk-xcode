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


#### Setting up the Watson Conversation Service

In order to set up the Watson Conversation Service, there are a lot of steps that are very similar to Setting up the Conversation service for the IBM Demo [Cognative Concierge](https://www.ibm.com/blogs/bluemix/2016/12/mobile-chatbot-cognitive-concierge/).  To start, go to the [Watson Conversation Page](https://www.ibm.com/watson/developercloud/conversation.html) and create a conversation instance.  In the creation of the conversation service, the `Service name` and `Credential name` do not matter.  Your conversation service should now appear in the [Watson Services page](https://console.ng.bluemix.net/dashboard/services).  Click on it, and launch it.  

Instead of creating a Workspace, `Import a workspace`.  
The WhiskBot Workspace is saved as a json in app directory, named `ConversationWorkspace.json`.

After the Workspace is imported, you should be able to test the conversation with the Demo Side bar.


To complete the connections between the Conversation Workspace and the actions, there are three keys that are necessary to find.  The `conversation_workspace_id`, `conversation_username`, and `conversation_password`.  All three keys should be input into the `getConstants` function, found in the OpenWhisk ConversationAction.Swift file.

To find the `conversation_workspace_id`, follow the instructions [here](https://www.ibm.com/blogs/bluemix/2016/12/mobile-chatbot-cognitive-concierge/).

To find the `conversation_username` and `conversation_password`, use the following link,  [Obtaining Credentials for Watson Services](https://www.ibm.com/watson/developercloud/doc/getting_started/gs-credentials.shtml)

#### Setting up the Watson Translation Service

To set up the Watson Language Translator Service, it is quite straightforward.  Simply go yo the [Watson Language Translator Website](https://www.ibm.com/watson/developercloud/language-translator.html) and click start free in Bluemix.  Name the service with whatever name you want.  


There are two keys that are necessary to use the Watson Language Translator Service, `translation_username` and `translation_password`.  The same link above used to find the Watson Conversation Service Authentication keys will get you to the Translator keys.  [Obtaining Credentials for Watson Services](https://www.ibm.com/watson/developercloud/doc/getting_started/gs-credentials.shtml)

#### Setting up Slack Webhooks

In order to give WhiskBot the ability to post to Slack, your Slack group needs webhook integration.  In order to setup URL Hooks for slack use the following [setup link](https://api.slack.com/custom-integrations).  You can setup webhook urls for different channels.  To add the channels to the OpenWhisk Action, under `getConstants` in `ConversationAction.swift`, there are `slack_channel_url_channelName` keys.  Add your own channelName and URL and modify the Conversation Workspace entity @slack_channels, to allow WhiskBot to pick up different channel names.





