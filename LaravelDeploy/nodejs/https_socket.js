require('console-stamp')(console, '[HH:MM:ss.l]');
var fs = require( 'fs' );
var app = require('express')();
var https = require('https');
var server = https.createServer({
    key: fs.readFileSync('/etc/nginx/ssl/nginx.key'),
    cert: fs.readFileSync('/etc/nginx/ssl/nginx.crt'),
    requestCert: false,
    rejectUnauthorized: false
},app);
server.listen(8890);
var io = require('socket.io')(server);
var redis = require('redis');

io.on('connection', function (socket) {

  console.log("client connected");
  var redisClient = redis.createClient();
  redisClient.subscribe('message');

  redisClient.on("message", function(channel, data) {
    	console.log("new message add in queue "+ data +" channel");
	socket.emit(channel, data);
  });

  socket.on('disconnect', function() {
    redisClient.quit();
  });

});
