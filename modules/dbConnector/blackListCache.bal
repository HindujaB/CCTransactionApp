import ballerina/sql;

type UserTable table<User> key(acc_no);

UserTable blackListedUsers = table [];

error tableConflictError = error("table Key Conflict", message = "cannot insert user");

# Save the account details of black listed users
#
# + userStream - stream of black listed users  
#
public function cacheBlackList(stream<User, sql:Error> userStream) {
    UserTable|error result = table key(acc_no) from var user in userStream
                             select {
                                 acc_no: user.acc_no,
                                 name: user.name,
                                 card_ID: user.card_ID
                             }
                             on conflict tableConflictError;
    if (result is error) {
        panic error("Failed to create black list.\n", result);
    } else {
        blackListedUsers = <table<User> key(acc_no)>result;
    }
}

# Check if a user is black listed
#
# + acc_no - account number
# + return - true if the user is black listed 
# 
public function isBlackListed(int acc_no) returns boolean {
    return blackListedUsers.hasKey(acc_no);
}
