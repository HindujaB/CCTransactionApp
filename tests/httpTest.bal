import ballerina/test;
import ballerina/http;
import ballerina/io;

http:Client clientEndpoint = check new ("http://localhost:" + appEndPoint.toString() + "/ccTransaction");

class accNumberGenerator {

    boolean closed = false;
    int count = 0;
    boolean isPositive;

    function init(boolean isPositive) {
        self.isPositive = isPositive;
    }

    public isolated function next() returns record {| byte[] value; |}|io:Error? {

        if (!self.closed) {
            if (self.count == 5) {
                error? closeResult = self.close();
            } else {
                string data;
                if (self.isPositive) {
                    data = "111222:WD;";
                } else {
                    data = "999000:WD;";
                }
                self.count += 1;
                return {value: data.toBytes()};
            }
        } else {
            panic error("IllegalState", message = "cannot call next() on a closed stream.");
        }

    }
    public isolated function close() returns error? {
        if (!self.closed) {
            self.closed = true;
        }
    }
}

@test:Config {}
function testValidatorPositive() returns error? {
    connectDB();
    accNumberGenerator gen = new (true);
    stream<byte[], io:Error> testStream = new stream<byte[], io:Error>(gen);
    http:Request req = new;
    req.setByteStream(testStream, "text/plain");
    http:Response res = check clientEndpoint->execute("POST", "/validator", testStream);
    test:assertEquals(res.getTextPayload(), "Withdrawal to account : 111222 is successfull!");
    io:Error? closeResult = testStream.close();
}

@test:Config {}
function testValidatorNegative() returns error? {
    connectDB();
    accNumberGenerator gen = new (false);
    stream<byte[], io:Error> testStream = new stream<byte[], io:Error>(gen);
    http:Request req = new;
    req.setByteStream(testStream, "text/plain");
    http:Response res = check clientEndpoint->execute("POST", "/validator", testStream);
    test:assertEquals(res.getTextPayload(), "Credit card is black listed. Access denied!");
    io:Error? closeResult = testStream.close();
}
