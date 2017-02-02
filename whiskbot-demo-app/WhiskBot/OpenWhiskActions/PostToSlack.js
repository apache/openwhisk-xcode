/*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
var request = require('request');

/**
 *   Action to post to slack
 *  @param {string} url - Slack webhook url
 *  @param {string} channel - Slack channel to post the message to
 *  @param {string} username - name to post the message as
 *  @param {string} text - message to post
 *  @param {string} icon_emoji - (optional) emoji to use as the icon for the message
 *  @param {boolean} as_user - (optional) when the token belongs to a bot, whether to post as the bot itself
 *  @param {object} attachments - (optional) message attachments (see Slack documentation for format)
 *  @return {object} whisk async
 */
function main(params) {
    var promise = new Promise(function (resolve, reject) {
      checkParams(params, reject);

      var body = {
        channel: params.channel,
        username: params.username || 'Simple Message Bot',
        text: params.text
      };

      if (params.icon_emoji) {
        // guard against sending icon_emoji: undefined
        body.icon_emoji = params.icon_emoji;
      }

      if (params.token) {
        //
        // this allows us to support /api/chat.postMessage
        // e.g. users can pass params.url = https://slack.com/api/chat.postMessage
        //                 and params.token = <their auth token>
        //
        body.token = params.token;
      } else {
        //
        // the webhook api expects a nested payload
        //
        // notice that we need to stringify; this is due to limitations
        // of the formData npm: it does not handle nested objects
        //
        console.log(body);
        console.log("to: " + params.url);

        body = {
          payload: JSON.stringify(body)
        };
      }

      if (params.as_user === true) {
          body.as_user = true;
      }

      if (params.attachments) {
          body.attachments = params.attachments;
      }

      request.post({
        url: params.url,
        formData: body
      }, function (err, res, body) {
        if (err) {
          console.log('error: ', err, body);
          reject(err);
        } else {
          console.log('success: ', params.text, 'successfully sent');
          resolve();
        }
      });
    });

    return promise;
}

/**
Checks if all required params are set
*/
function checkParams(params, reject) {
  if (params.text === undefined) {
    reject('No text provided');
  }
  if (params.url === undefined) {
	reject('No Webhook URL provided');
  }
  if (params.channel === undefined) {
	reject('No channel provided');
  }
}
