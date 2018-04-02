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

import ballerina/log;
import ballerina/net.http;


endpoint http:ServiceEndpoint inventoryEP {
    port:9092
};

@http:ServiceConfig {basePath:"/inventory"}
service<http:Service> inventoryService bind inventoryEP {
    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    inventoryResource (endpoint httpConnection, http:Request request) {
        // Initialize the response message that needs to send back to client
        http:Response response = {};
        // Extract the items list from the request JSON payload
        json items =? <json>request.getJsonPayload();
        log:printInfo("Checking the order items : " + items.toString());
        // Prepare the response message
        json responseJson = {"Status":"Order Available in Inventory", "items":items};
        response.setJsonPayload(responseJson);
        // Send the response to the client
        _ = httpConnection -> respond(response);
    }
}
