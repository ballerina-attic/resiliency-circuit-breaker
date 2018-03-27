package integrationTests;

import ballerina/io;
import ballerina/net.http;
import ballerina/test;

endpoint http:ClientEndpoint orderServiceEndpoint {
    targets:[
            {
                uri:"http://localhost:9090/order"
            }
            ]
};

function beforeFunction () {
    // Start the order service
    _ = test:startServices("orderServices");
}

function afterFunction () {
    // stop the order service
    test:stopServices("orderServices");
}

@test:Config {
    before:"beforeFunction",
    after:"afterFunction"
}
function testOrderService () {
    // Initialize the empty http request and response
    http:Request req = {};
    http:Response resp = {};

    // Start the inventory service
    _ = test:startServices("inventoryServices");

    // Prepare order with sample items
    json requestJson = {"items":{"1":"Basket", "2":"Table", "3":"Chair"}};
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    resp =? orderServiceEndpoint -> post("/", req);
    json jsonResponse =? resp.getJsonPayload();
    // Test the responses from the service with the original test data
    test:assertEquals(resp.statusCode, 200, msg = "Inventory service didnot respond with 200 OK signal");

    io:println(jsonResponse);
    test:assertEquals(jsonResponse.Error.toString(), msg = "Inventory Service did not respond",
                      " Error respond mismatch");

    // Stop the inventory service
    _ = test:startServices("inventoryServices");

    // Send the request to service and get the response
    resp =? orderServiceEndpoint -> post("/", req);
    jsonResponse =? resp.getJsonPayload();
    // Test the responses from the service with the original test data
    test:assertEquals(resp.statusCode, 200, msg = "Inventory service didnot respond with 200 OK signal");
    test:assertEquals(jsonResponse.Error.toString(), msg = "Inventory Service did not respond",
                      " Error respond mismatch");
    test:assertEquals(jsonResponse.Error_message.toString(), msg = "Connection refused, localhost-9092",
                      " Error message mismatch");

    // Send the same request to order management service to test Circuit Breaker
    resp =? orderServiceEndpoint -> post("/", req);
    jsonResponse =? resp.getJsonPayload();
    // Test the responses from the service with the original test data
    test:assertEquals(resp.statusCode, 200, msg = "Inventory service didn't respond with 200 OK signal");
    test:assertEquals(jsonResponse.Error.toString(), "Inventory Service did not respond",
                      msg = " Error respond mismatch");

    // Assert Circuit Breaker response
    test:assertTrue(jsonResponse.Error_message.toString().contains("Upstream service unavailable"),
                    msg = " Error message mismatch");
    io:println("test");

}
