Url   = require "url"
Redis = require "redis"
RedisSMQ = require "rsmq"
RSMQWorker = require( "rsmq-worker" )

module.exports = (robot) ->
  redisUrl = if process.env.REDISTOGO_URL?
               redisUrlEnv = "REDISTOGO_URL"
               process.env.REDISTOGO_URL
             else if process.env.REDIS_URL?
               redisUrlEnv = "REDIS_URL"
               process.env.REDIS_URL
             else
               'redis://localhost:6379'


  info   = Url.parse redisUrl, true
  client = if info.auth then Redis.createClient(info.port, info.hostname, {no_ready_check: true}) else Redis.createClient(info.port, info.hostname)
  prefix = info.path?.replace('/', '') or 'hubot'
  rsmq = new RedisSMQ
  worker = new RSMQWorker
  queueName = if process.env.QUEUE_NAME?
    process.env.QUEUE_NAME
  else
    'queued-messages'
  delayTime = if process.env.QUEUE_DEFAULT_DELAY?
    process.env.QUEUE_DELAY
  else
    900
 

  if info.auth
    client.auth info.auth.split(":")[1], (err) ->
      if err
        robot.logger.error "hubot-redis-brain: Failed to authenticate to Redis"
      else
        robot.logger.info "hubot-redis-brain: Successfully authenticated to Redis"

  client.on "connect", ->
    robot.logger.debug "hubot-queue: Successfully connected to Redis"

# Everything above this line was pulled straight from hubot-redis-brain
# I wish I could access the redis connection in the brain object, but it's a private property and I didn't want to create my own version of it.

# MAKE SURE QUEUE(S) EXIST
    rsmq = new RedisSMQ( {client: client, ns: "robort-mq"} )
    createFn = (resp, err) ->
      if (resp == 1)
        robot.logger.info "created queue"
    fn = (err, queues) -> 
      if( err )
        robot.logger.error( err )
        return
      robot.logger.info "Active queues: " + queues.join( "," )
      if queues.indexOf(queueName) == -1
        robot.logger.info "need to create queue"
        rsmq.createQueue({ qname:queueName }, createFn)
    rsmq.listQueues(fn)
    worker = new RSMQWorker(queueName, {rsmq: rsmq} )
    fnMessageRcv = (msg, next, id) ->
      x = JSON.parse(msg)
      robot.logger.info "Message id : " + id
      robot.logger.info x
      robot.send { room: x.room}, 'Hey ' + x.recipient + ', ' + x.message
      next()
    worker.on( "message", fnMessageRcv )
    worker.start()
  
# LISTEN FOR MESSAGES TO QUEUE
  robot.listen(
    (msg) -> 
      match = msg.match(/^later\s+((([0-9]+)?\s+)?tell\s+(\S+)\s+(\S.*))$/i)
      if match && match[3]
        thisDelay=match[3]
      else
        thisDelay=delayTime
      msgSent = (err,resp)->
        console.log("Message sent with delay ", thisDelay, ". ID:", resp, " ERR:", err)
      # Only match if there is a matching factoid
      if match
        robot.logger.info msg
        qItem = JSON.stringify {room:msg.room, user:msg.user.name, recipient:match[4], message:match[5]}
        robot.logger.info 'queueing message: ', qItem, ' [delay: ',thisDelay,']'
        rsmq.sendMessage {qname:queueName, message:qItem, delay:thisDelay}, msgSent 
        match
      else
        false
    (response) -> true
  )

