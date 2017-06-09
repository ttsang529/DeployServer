//https://github.com/mongodb/node-mongodb-native
var client = require('mongodb').MongoClient
        , assert = require('assert');

// Connection URL
var url = 'mongodb://localhost:27017/Device';

// Use connect method to connect to the server
exports.insert = function (status, device) {
    client.connect(url, function (err, db) {
        assert.equal(null, err);

        //console.log("Connected successfully to server ");
        insertDocuments(db, status, device, function () {
            db.close();
        });
    });
};


//Insert a Document
var insertDocuments = function (db, status, device, callback) {
    // Get the documents collection
    var collection = db.collection('records');
    var date = new Date();
    var ec_version = '';

    // Insert some documents
    if(status.mqtt == 'Online'){
        ec_version = status.ec_version ? status.ec_version : 'None';
    }
    
    var data = {
        "source": status.source, "device_id": device.id, "serial_no": status.serial_no, "action": 'Mqtt Status',
        "detail": 'Mqtt Status change from ' + device.mqttconnect + " to " + status.mqtt, "status": "Mqtt " + status.mqtt,
        "device_image": status.image_version, "device_ec": ec_version,
        "upgrade_status": device.upgrade_status, "updated_at": date, "created_at": date
    };
    collection.insertMany([
        data
    ], function (err, result) {
        assert.equal(err, null);
        assert.equal(1, result.result.n);
        assert.equal(1, result.ops.length);
//        console.log("insert mongo:%j", data);
        callback(result);
    });
};