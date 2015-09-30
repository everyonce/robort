# Description:
#   emm386 will parrot back images or text stored
#
# Configuration:
#   None
#
# Commands:
#   hubot mem all
#   hubot mem|memorize|remember keyword value1..n
#   hubot mem|remember keyword
#
# Author:
#   everyonce
  crypto = require('crypto')


  webdisUrl = "http://webdis.myurl.com/"

  gifMeApi = (cb) ->
    cb "Prefix all of these with 'robort' then your gifme command:" +
    "\nSave a gif for a keyword (url must begin with http:// and end with .gif): gifme add highfive <my highfive url here>" +
    "\nRetrieve a random gif for a keyword: gifme highfive" +
    "\nRetrieve a specific gif for a keyword (ordered in ascending order of upload): gifme highfive 2" +
    "\nRetrieve all of your gifs and keyords (not in general or random rooms): gifme all" +
    "\n Copy another user's gif to your personal keyword collection: gifme copy mknowles highfive" +
    "\n Copy another user's alternate gif to your personal keyword collection: gifme copy mknowles highfive 2"

  # Display all the user's uploaded gifs
  listAll = (robot, userId, room, cb) ->
      lookupHash = crypto.createHash('md5').update(userId).update("LIST").digest("hex")
      robot.http(webdisUrl + 'GET/' + lookupHash)
        .get() (err, res, body) ->
          # error checking code here
          if res.statusCode isnt 200
            cb "Request didn't come back HTTP 200 :("
            return
          cb JSON.parse(body)

  # Add a gif to the user's collection
  memAdd = (robot, userId, keyword, value, cb) ->
    lookupHash = crypto.createHash('md5').update(userId).update(keyword).digest("hex")
    robot.http(webdisUrl + 'SET/' + lookupHash + '/' + value.toString('base64'))
      .get() (err, res, body) ->
        # error checking code here
        if res.statusCode isnt 200
          cb "Error: #{body}"
          return
        cb "I'll remember #{keyword} forever"

  module.exports = (robot) ->
    robot.respond /mem ([^\s]+)\S?(.+)?/i, (msg) ->
      firstWord = msg.match[1]
      user = msg.message.user
      room = msg.message.room
      msg.send JSON.stringify(user)
      if firstWord is "all"
        msg.send "Please visit: http://gifatme.azurewebsites.net/"
      else if firstWord is "all"
        msg.send "Please visit: http://gifatme.azurewebsites.net/"
      else
        keyword = msg.match[4]
          #if firstWord is "add"
            #url = msg.match[6]
            #if url?
              #gifMeAdd robot, userName, keyword, url, (response) ->
                #msg.send response
            #else
              #msg.send "Invalid URL. Start with http:// and end with .gif"
          #else
            ## get a gif entry
            #index = msg.match[6]
            #if !index
              #index = 0
            #gifMeGet robot, userName, keyword, index, (response) ->
              #msg.send response
