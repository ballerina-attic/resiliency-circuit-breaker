// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/test;

endpoint http:Client httpEndpoint {
    url: "http://localhost:9092/inventory"
};

function beforeFunction() {
    // Start the inventory service
    _ = test:startServices("inventoryServices");
}

function afterFunction() {
    // Stop the inventory service
    test:stopServices("inventoryServices");
}

@test:Config {
    before: "beforeFunction",
    after: "afterFunction"
}
function testInventoryService() {
    // Initialize the empty http request and response
    http:Request req;

    // Test the inventory resource
    // Prepare order with sample items
    json requestJson = { "1": "Basket", "2": "Table", "3": "Chair" };
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    http:Response resp = check httpEndpoint->post("/", request = req);
    json jsonResponse = check resp.getJsonPayload();
    test:assertEquals(resp.statusCode, 200, msg =
        "Inventory service didnot respond with 200 OK signal");
    // Test the responses from the service with the original test data
    test:assertEquals(jsonResponse.Status.toString(), "Order Available in Inventory",
        msg = "respond mismatch");
}


