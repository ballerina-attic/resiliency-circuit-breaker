package inventoryServices;

import ballerina.log;
import ballerina.net.http;

@http:configuration {basePath:"/inventory", port:9092}
service<http> inventoryService {
    @http:resourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource inventoryResource (http:Connection httpConnection, http:InRequest request) {
        // Initialize the response message that needs to send back to client
        http:OutResponse response = {};
        // Extract the items list from the request JSON payload
        json items = request.getJsonPayload();
        log:printInfo("Checking the order items : " + items.toString());
        // Prepare the response message
        json responseJson = {"Status":"Order Available in Inventory", "items":items};
        response.setJsonPayload(responseJson);
        // Send the response to the client
        _ = httpConnection.respond(response);
    }
}