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

package inventoryServices;

import ballerina.net.http;
import ballerina.test;

function testInventoryService () {
    endpoint<http:HttpClient> httpEndpoint {
        create http:HttpClient("http://localhost:9092/inventory", {});
    }
    // Initialize the empty http request and response
    http:OutRequest req = {};
    http:InResponse resp = {};
    // Start inventory service
    _ = test:startService("inventoryService");

    // Test the inventory resource
    // Prepare order with sample items
    json requestJson = {"1":"Basket", "2":"Table", "3":"Chair"};
    req.setJsonPayload(requestJson);
    // Send the request to service and get the response
    resp, _ = httpEndpoint.post("/", req);
    // Test the responses from the service with the original test data
    test:assertIntEquals(resp.statusCode, 200, "Inventory service didnot respond with 200 OK signal");
    test:assertStringEquals(resp.getJsonPayload().Status.toString(), "Order Available in Inventory",
                            " respond mismatch");
}
