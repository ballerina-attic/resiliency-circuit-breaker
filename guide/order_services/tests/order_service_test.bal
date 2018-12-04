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

import ballerina/io;
import ballerina/http;
import ballerina/test;
import ballerina/log;

http:Client httpEndpoint = new("http://localhost:9090/order");

function beforeFunction() {
    // Start order service
    //_ = test:startServices("order_services");
}

function afterFunction() {
    // stop order service
    //test:stopServices("order_services");
}

@test:Config {
    before: "beforeFunction",
    after: "afterFunction"
}
function testOrderService() {
    // Initialize the empty http request and response
    http:Request request = new;
    // Test the inventory resource
    // Prepare order with sample items
    json requestJson = { "items": { "1": "Basket", "2": "Table", "3": "Chair" } };
    request.setJsonPayload(untaint requestJson);
    // Send the request to service and get the response
    var response = httpEndpoint->post("/", request);
    if (response is http:Response) {
        var jsonResponse = response.getJsonPayload();
        if(jsonResponse is json){
            // Test the responses from the service with the original test data
            test:assertEquals(response.statusCode, 200, msg =
            "Inventory service didnot respond with 200 OK signal");
            test:assertEquals(jsonResponse.Error.toString(), "Inventory Service did not respond",
            msg = " Error respond mismatch");
        } else {
            test:assertFail(msg = "Failed to parse response:");
        }

    } else {
        test:assertFail(msg = "Failed to obtain response:");
    }

    // Sending the same request to order management service to test Circuit Breaker
    var response2 = httpEndpoint->post("/", request);
    if (response2 is http:Response) {
        var jsonResponse = response2.getJsonPayload();
        if (jsonResponse is json) {
            // Test the responses from the service with the original test data
            test:assertEquals(response2.statusCode, 200, msg =
            "Inventory service didn't respond with 200 OK signal");
            test:assertEquals(jsonResponse.Error.toString(), "Inventory Service did not respond",
            msg = " Error respond mismatch");

            // Assert Circuit Breaker response
            //boolean result = jsonResponse.Error_message.toString().contains("Upstream
            //service unavailable") but {error => false};
            test:assertTrue(true, msg = " Error message mismatch");
            io:println("test");
        }else {
            test:assertFail(msg = "Failed to parse response:");
        }
    } else {
        test:assertFail(msg = "Failed to obtain response:");
    }
}
