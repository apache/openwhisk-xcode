#WhiskBot Demo App
>A Chatbot iOS application that uses OpenWhisk Swift Actions

## Installation

In order to install and setup WhiskBot there are a lot of things to get set up.  

#### Installing OpenWhisk and setting up the actions

The backend of WhiskBot is built with OpenWhisk actions.  There is a main Conversation Action, which is what the app directly interfaces with.  The Conversation Action communicates with the IBM Watson Conversation API in order to get responses to user inputs.  Based on the response and node visited inside the IBM Watson Conversation Service, the conversation Action will invoke other actions (Slack Post, Translation).  In order to set up WhiskBot, the Actions must be uploaded to the Cloud.

`The Actions to be uploaded to OpenWhisk can be found in the folder /WhiskBot/OpenWhiskActions`
