# openwhisk-xcode
>Collection of OpenWhisk tools for OS X implemented in Swift 3.

Inside this Repo there are three projects.  Click into any directories to see more information about each project.

## OpenWhisk Xcode Extension

The OpenWhisk Xcode Source Editor Extension interfaces directly with OpenWhisk Playgrounds in order to test Swift OpenWhisk functions quickly.  

## WhiskBot - OpenWhisk Watson Conversation Chatbot

An iOS chatbot application that uses OpenWhisk actions as middleware.  WhiskBot has the ability to translate messages, using a translation OpenWhisk Action and post to Slack.  

## WskTools

A CLI tool that allows developers to install OpenWhisk "projects" into the OpenWhisk backend.  A project contains sets of actions (JS and Swift), triggers, and rules which can be installed with a single command `wsktool install`.  You can do the opposite with `wsktool uninstall`.  You can see an [example of an OpenWhisk project here](https://github.com/openwhisk/openwhisk-package-jira/tree/master/src).
