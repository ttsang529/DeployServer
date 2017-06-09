require('console-stamp')(console, '[ddd mmm dd yyyy HH:MM:ss.l]');
const  mysql = require('./mysql'),
       mongo = require('./mongo'); 


var status={"mqtt":"Offline","serial_no":"1234567890qwer"};
//var status={"mqtt":"Online","serial_no":"1234567890qwer","image_version":"1468229249","source":"192.168.82.133"};
if (status.source==null){
    status["source"]="mqtt server";
}
mysql.mqttStat(status,function cb(device){
    if (device != null){
        //console.log(device[0]);
        mongo.insert(status,device[0]);
    }
    mysql.end();
});
