import ballerina/http;
import ballerina/io;
import ballerina/regex;
import CCTransactionApp.dbConnector;
import ballerina/log;

http:Client endpoint = check new ("http://" + appHost +":" + appPort.toString() + "/ccTransaction");
public listener http:Listener appListener = new (appPort);

service /ccTransaction on appListener {

    resource function post withdraw(http:Caller caller, http:Request request) {
        http:ListenerError? result = caller->respond(getResponse(request, "Withdrawal"));
        if (result is error) {
            log:printError("Error responding to client.");
        }
    }

    resource function post repay(http:Caller caller, http:Request request) {
        http:Response response = new;
        string|http:ClientError textPayload = request.getTextPayload();
        if (textPayload is string) {
            response.setPayload("Repay to account : " + textPayload + " is successfull!");
        } else {
            setError(response, textPayload);
        }
        http:ListenerError? result = caller->respond(getResponse(request, "Repay"));
        if (result is error) {
            log:printError("Error responding to client.");
        }
    }

    resource function post validator(http:Caller caller, http:Request request) {
        stream<byte[], io:Error>|http:ClientError bStream = request.getByteStream(10);
        http:Response res = new;
        if (bStream is stream<byte[], io:Error>) {
            var iterator = bStream.iterator();
            record {| byte[] value; |}|error? nextLoad = iterator.next();
            if (nextLoad is error) {
                setError(res, nextLoad);
                sendResponse(caller, res);
            } else {
                while (!(nextLoad is ())) {
                    sendResponse(caller, processTransaction(caller, nextLoad.value));
                    nextLoad = iterator.next();
                }
            }
            close(bStream);
        } else {
            setError(res, bStream);
            sendResponse(caller, res);
        }
    }
}

function setError(http:Response response, error e) {
    response.statusCode = 500;
    response.setPayload(<@untainted>e.message());

}

function close(stream<byte[], io:Error> bStream) {
    var cr = bStream.close();
    if (cr is error) {
        log:printError("Error occurred while closing the stream: ", 'error = cr);
    }

}

function processTransaction(http:Caller caller, byte[] payLoad) returns http:Response {
    http:Response res = new;
    string|error chunk = string:fromBytes(payLoad);

    if (chunk is error) {
        setError(res, chunk);
        return res;
    } else {
        string[] accounts = regex:split(chunk, ";");

        foreach string acc in accounts {
            string[] parts = regex:split(acc, ":");
            if (parts.length() != 2) {
                continue;
            }
            int|error acc_no = int:fromString(parts[0]);

            if (acc_no is error) {
                continue;
            } else {
                string action = parts[1];
                if (dbConnector:isBlackListed(acc_no)) {
                    setError(res, error("Credit card is black listed. Access denied!"));
                    return res;
                } else {
                    http:Request request = new;
                    request.setTextPayload(acc_no.toString());

                    http:Response|http:ClientError clientResponse = new;
                    match action {
                        "RP" => {
                            clientResponse = endpoint->post("/repay", request);
                        }
                        "WD" => {
                            clientResponse = endpoint->post("/withdraw", request);
                        }
                    }

                    if (clientResponse is http:ClientError) {
                        setError(res, error("credit card action failed", clientResponse));
                        return res;

                    } else {
                        return clientResponse;
                    }
                }
            }
        }

    }
    return res;
}

function getResponse(http:Request request, string msg) returns http:Response {
    http:Response response = new;
    string|http:ClientError textPayload = request.getTextPayload();
    if (textPayload is string) {
        response.setPayload(msg + " to account : " + textPayload + " is successfull!");

    } else {
        setError(response, textPayload);
    }
    return response;

}

function sendResponse(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error occurred while sending response", 'error = result);
    }

}
