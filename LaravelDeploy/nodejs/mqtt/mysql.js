const fs = require('fs'),
        ini = require('ini'),
        mysql = require('mysql'),
        async = require('async');

var date = new Date(Date.now());
var config = ini.parse(fs.readFileSync('/var/www/mgmt/.env', 'utf-8'));
//console.log('  host:'+config.DB_HOST+'  password:'+config.DB_PASSWORD+'   username:'+config.DB_USERNAME+'  database:'+config.DB_DATABASE+ '   port:'+config.DB_PORT);
var connection = mysql.createConnection({
    host: config.DB_HOST,
    user: config.DB_USERNAME,
    password: config.DB_PASSWORD,
    database: config.DB_DATABASE,
    port: config.DB_PORT
});



//http://stackoverflow.com/questions/14992879/node-js-mysql-query-syntax-issues-update-where
exports.connect = function connect() {
    connection.connect();
}
exports.end = function end() {
    connection.end();
}

exports.infoQuery = function (table, callback) {

    connection.query('SELECT * FROM ' + table, function (err, results)
    {
        if (err)
        {
            console.error(err);
            callback(err, null);
        } else
        {
            //console.log('First row of sysinfos table : ', results[0]);
            callback(null, results[0]);
        }
    });

};

exports.mqttStat = function (status, cb) {

    var table = "devices";

    async.waterfall(
            [
                function (callback) {
                    //check serial_no is existed on devices
                    var query = "SELECT * FROM ?? WHERE ?? = ?";
                    var inserts = [table, 'serial_no', status.serial_no];
                    var sql = mysql.format(query, inserts);
                    //connection.connect();
                    connection.query(sql, function (err, results)
                    {
                        if (results == "") {
                            err = "serial_no is not existed";
                            console.log("serial_no is not existed");
                            callback(err);
                        } else {
                            //console.log('First row of devices results : ', results[0]);
                            callback(null, results);
                        }
                    });
                },
                function (results, callback) {
                    var query = "";
                    if (results == "") {
                        callback(err);
                    } else {
                        //Convert the mqttstatus mapping mysql status
                        query = 'update ' + table + ' set mqttconnect=' + "'" + status.mqtt + "'" + ', updatetime=' + "'" + Math.round(new Date().getTime() / 1000) + "'";
                        switch(status.mqtt){
                            case 'Online':
                                var ec_version = status.ec_version ? status.ec_version : null;
                                query = query + ', image_version=' + "'" + status.image_version + "'" + 
                                        ', ec_version=' + "'" + ec_version + "'" +
                                        '  where serial_no =' + "'" + status.serial_no + "'";
                                break;
                            case 'Offline':
                                query = query + '  where serial_no =' + "'" + status.serial_no + "'";
                                break;
                        }
//                        console.log(query);

                        connection.query(query, function (err, res)
                        {
                            //console.log(err);
                            if (err)
                                return callback(err);
                            callback(null, results);

                        });
                    }
                }
            ], function (err, results) {
        //
        if ((err) || (results == null)) {
            cb(null);
        } else {
            cb(results);
        }
    }
    );


};


