import ballerina/log;
import ballerinax/mysql;
import ballerina/sql;
import CCTransactionApp.dbConnector;

configurable int appEndPoint = ?;

public function main() {
    connectDB();
    error? startResult = appListener.start();
    if (startResult is error) {
        log:printError("Error starting listener");
    }
}

function connectDB() {
    mysql:Client|sql:Error|() initializeClientResult = dbConnector:initializeClient();
    if (initializeClientResult is sql:Error) {
        panic error("Query execution failed!\n", initializeClientResult);
    } else if (initializeClientResult is ()) {
        panic error("Query returned nil\n", initializeClientResult);
    } else {
        stream<dbConnector:User, sql:Error> blackListResult = dbConnector:retrieveBlackList(initializeClientResult);
        dbConnector:cacheBlackList(blackListResult);
        sql:Error? close = initializeClientResult.close();
    }
}
