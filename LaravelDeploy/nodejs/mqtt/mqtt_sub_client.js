//const args = process.argv;
require('console-stamp')(console, '[HH:MM:ss.l]');
const mqtt = require('mqtt'),
      fs = require('fs'),
      events = require('events'),
      async = require('async'),
      mysql = require( './mysql' ),
      mongo = require('./mongo'),
      eventEmitter = new events.EventEmitter();

var options = {
    host: 'mqtt://localhost',
    clientId: 'mqttjs_' + Math.random().toString(16).substr(2, 8), 
    keepalive: 60,
    reconnectPeriod: 1000,
    protocolId: 'MQIsdp',
    protocolVersion: 3,
    clean: true,
    encoding: 'utf8'
};  

var clientListen= function clientListen(){
        var client = mqtt.connect(options["host"], options);
        client.on('connect', function() { // When connected
            console.log('connected');
            // subscribe to a topic
            client.subscribe('OTA/Client', function() {
                // when a message arrives, do something with it
                client.on('message', function(topic, message, packet) {
                    try{
                            status=JSON.parse(message);
                            //console.log(status.mqtt);
                            if (status.source==null){
                                status["source"]="mqtt server";
                            }
                            mysql.mqttStat(status,function cb(device){
                                if (device != null){
                                    //console.log(device[0]);
                                    mongo.insert(status,device[0]);
                                }
                            });
                    }catch(err) {
                        console.log(err);
                    }
                    
//                    console.log(" Received '" + message + "' on '" + topic + "'");
                });
            });
        });
};


async.waterfall(
    [  
        function(callback) {   
             mysql.infoQuery("sysinfos", function(err,result) {
                   if (err) return callback(err);
                    //console.log("mqtt:"+result.mqtt_port);
                    setOption(result);
                    callback(null);
                    
                });
        },
        function(callback) {   
           //get Name and Password Setting 
           var child_process = require('child_process');
            try {
            //change dir for nodejs main path
            process.chdir('/var/www/mgmt');
            child_process.exec('php artisan jwtmqtt:reset |awk \'{print $5} {print $6}\'', function (error, stdout, stderr) {
                    var result=stdout.replace(/ /g,'').split("\n").filter(String);
                    //console.log(result);
                    if (error !== null) {
                        console.log('exec error: ' + error);
                    }
                    if (result.length==2){
                        //console.log("username="+result[0]);
                            options["username"]=result[0]; 
                            options["password"]=result[1]; 
                            callback(null);
                    }
                    
                });
            }
            catch (err) {
                console.log('chdir: ' + err);
            }
        }
        ],  function( err) {
             if (err) return console.log(err);
             //console.log(options);
             clientListen();

        }
    
);

function setOption(result){
          //justine mqtt port and mqtt ssl to setting the option
          options["port"]= parseInt(result.mqtt_port);

                    if (result.mqtt_ssl == "Enable"){
                        console.log("mqtt ssl Enable");
                        options["key"] = fs.readFileSync("/etc/mosquitto/ssl/ca.key");
                        options["cert"]= fs.readFileSync("/etc/mosquitto/ssl/ca.crt");
                        options["protocolVersion"]=4;
                        options["protocolId"]='MQTT';
                        options["rejectUnauthorized"]=false;
                    }else{
                        console.log("mqtt ssl Disable"); 
                    }

}






