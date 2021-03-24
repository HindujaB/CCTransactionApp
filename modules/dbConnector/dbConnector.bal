import ballerina/io;
import ballerina/sql;
import ballerinax/mysql;

const FAILED_CONNECTION = "Failed to connect the database";
configurable string username = ?;
configurable string password = ?;

type MySQLDB record {|
    string host = "localhost";
    int port = 9090;
    string name;
|};

# Account holder
#
# + name - Name   
# + acc_no - Account number 
# + card_ID - Credit card ID
public type User record {|
    string name;
    readonly int acc_no;
    string card_ID;
|};

configurable MySQLDB & readonly database = ?;

# Initialize database client
# + return - error, if the connection is not established  
public function initializeClient() returns mysql:Client|sql:Error? {
    mysql:Client dbClient = check new (database.host, username, password, database.name, database.port);
    io:println("Connected to database!");
    return dbClient;
}

# Close database client
#
# + dbClient - the client to be closed
# + return - Return error if the connection close fails  
public function closeClient(mysql:Client dbClient) returns sql:Error? {
    sql:Error? close = dbClient.close();
    if (close is sql:Error) {
        panic error("db connection failed!", <sql:Error>close);
    }
    io:println("Connection closed successfully!");
}

# Retrieve black listed Credit Card details 
#
# + mysqlClient - database client
# + return - stream of black listed users  
#
public function retrieveBlackList(mysql:Client mysqlClient) returns stream<User, sql:Error> {
    string selectQuery = "SELECT Accounts.Name, Accounts.Acc_no, Accounts.Card_ID FROM Accounts, BlackList where (BlackList.Card_ID = Accounts.Card_ID)";

    stream<record { }, error> resultStream = mysqlClient->query(selectQuery, User);

    return <stream<User, sql:Error>>resultStream;
}
