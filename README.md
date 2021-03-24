# cc-transaction-app

A simple validator that validates the credit card account numbers whether they are blacklisted.

### Overview
This package connects to a MySQL database and caches a list of black listed users. 
Using that details, it validates the transaction HTTP requests of users with their respective account numbers. 

The module supports HTTP streaming requests with byte streams. 
The payload is expected to be of format, 

```
acc_number:action
```

The allowed actions are,
- WD - denotes a withdrawal transaction
- RP - denotes a repayment

The target endpoint can be configured through `Config.toml` in the following format.

```toml
[CCTransactionApp]
appHost = "<HOST>"
appPort = <PORT>

[CCTransactionApp.dbConnector]
username = "<USER_NAME>"
password = "<PASSWORD>"

[CCTransactionApp.dbConnector.database]
host = "<DATABASE_HOST>"
port = <DATABASE_PORT>
name = "<DATABASE_NAME>"

```


The expected path is 

```
http://localhost:<endpoint>/ccTransaction/validator
```
 
For example, if the endpoint is configured as `9096`, the expected request will be, 

```
curl -d "111222:WD" -X POST http://localhost:9096/ccTransaction/validator
```
The database related details can be found at module [dbConnector](modules/dbConnector/Package.md).
