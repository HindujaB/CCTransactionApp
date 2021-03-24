import ballerina/sql;
import ballerina/test;
import ballerinax/mysql;

@test:Config {}
function testDBConnection() {
    mysql:Client|sql:Error? initializeClientResult = initializeClient();
    if (initializeClientResult is sql:Error) {
        panic error("Database connection failed!\n", initializeClientResult);
    } else {
        mysql:Client dbClient = <mysql:Client>initializeClientResult;
        checkpanic closeClient(dbClient);
    }

}

@test:Config {}
function testBlackListQuery() {
    mysql:Client|sql:Error|() initializeClientResult = initializeClient();
    if (initializeClientResult is sql:Error) {
        panic error("Query execution failed!\n", initializeClientResult);
    } else if (initializeClientResult is ()) {
        panic error("Query returned nil\n", initializeClientResult);
    } else {
        stream<User, sql:Error> blackListResult = retrieveBlackList(initializeClientResult);
        checkpanic initializeClientResult.close();
        int count = 0;
        checkpanic blackListResult.forEach(function(User user) {
                                               count += 1;
                                           });
        test:assertEquals(count, 4);
    }

}

@test:Config {}
function testIsBlackListed() {
    mysql:Client|sql:Error|() initializeClientResult = initializeClient();
    if (initializeClientResult is sql:Error) {
        panic error("Query execution failed!\n", initializeClientResult);
    } else if (initializeClientResult is ()) {
        panic error("Query returned nil\n", initializeClientResult);
    } else {
        stream<User, sql:Error> blackListResult = retrieveBlackList(initializeClientResult);
        cacheBlackList(blackListResult);
        sql:Error? close = initializeClientResult.close();
    }
    test:assertTrue(isBlackListed(999000));
    test:assertFalse(isBlackListed(111222));
}
