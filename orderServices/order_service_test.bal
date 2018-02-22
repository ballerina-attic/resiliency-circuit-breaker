package orderServices;

import ballerina.net.http;
import ballerina.test;

function testInventoryService () {
    endpoint<http:HttpClient> httpEndpoint {
        create http:HttpClient("http://localhost:9090/order", {});
    }
    // Initialize the empty http request and response
    http:OutRequest req = {};
    http:InResponse resp = {};
    // Start inventory service
    _ = test:startService("orderService");

    // Test the inventory resource
    // Prepare order with sample items
    json requestJson = {"items":{"1":"Basket", "2":"Table", "3":"Chair"}};
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    resp, _ = httpEndpoint.post("/", req);
    // Test the responses from the service with the original test data
    test:assertIntEquals(resp.statusCode, 200, "Inventory service didnot respond with 200 OK signal");
    test:assertStringEquals(resp.getJsonPayload().Error.toString(), "Inventory Service did not respond",
                            " Error respond mismatch");
    test:assertStringEquals(resp.getJsonPayload().Error_message.toString(), "Connection refused, localhost-9092",
                            " Error message mismatch");

    // Sending the same request to order management service to test Circuit Breaker
    resp, _ = httpEndpoint.post("/", req);
    // Test the responses from the service with the original test data
    test:assertIntEquals(resp.statusCode, 200, "Inventory service didn't respond with 200 OK signal");
    test:assertStringEquals(resp.getJsonPayload().Error.toString(), "Inventory Service did not respond",
                            " Error respond mismatch");

    // Assert Circuit Breaker response
    test:assertTrue(resp.getJsonPayload().Error_message.toString().contains("Upstream service unavailable"),
                    " Error message mismatch");

}
