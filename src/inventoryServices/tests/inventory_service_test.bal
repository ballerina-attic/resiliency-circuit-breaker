package inventoryServices;

import ballerina/net.http;
import ballerina/test;

endpoint http:ClientEndpoint httpEndpoint {
    targets:[
            {
                uri:"http://localhost:9092/inventory"
            }
            ]
};

function beforeFunction () {
    // Start the inventory service
    _ = test:startServices("inventoryServices");
}

function afterFunction () {
    // Stop the inventory service
    test:stopServices("inventoryServices");
}

@test:Config {
    before:"beforeFunction",
    after:"afterFunction"
}
function testInventoryService () {
    // Initialize the empty http request and response
    http:Request req = {};

    // Test the inventory resource
    // Prepare order with sample items
    json requestJson = {"1":"Basket", "2":"Table", "3":"Chair"};
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    http:Response resp =? httpEndpoint -> post("/", req);
    json jsonResponse =? resp.getJsonPayload();
    test:assertEquals(resp.statusCode, 200, msg = "Inventory service didnot respond with 200 OK signal");
    // Test the responses from the service with the original test data
    test:assertEquals(jsonResponse.Status.toString(), "Order Available in Inventory",
                      msg = "respond mismatch");
}


