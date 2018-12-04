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

import ballerina/log;
import ballerina/mime;
import ballerina/http;
//import ballerinax/docker;
//import ballerinax/kubernetes;

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"order_service",
//    tag:"v1.0"
//}

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-order-service",
//    path:"/"
//}
//
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-order-service"
//}
//
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/order_service:v1.0",
//    name:"ballerina-guides-order-service"
//}

//@docker:Expose{}
listener http:Listener orderServiceListener = new(9090);

http:Client circuitBreakerEP = new("http://localhost:9092", config = {
        // The 'circuitBreaker' term incorporate circuit breaker pattern to the client endpoint
        // Circuit breaker will immediately drop remote calls if the endpoint exceeded the failure threshold
        circuitBreaker: {
            // Failure calculation window. This is how long Ballerina
            // circuit breaker keeps the statistics for the operations.
            rollingWindow: {

                // Time period in milliseconds for which the failure threshold
                // is calculated.
                timeWindowMillis: 10000,

                // The granularity at which the time window slides.
                // This is measured in milliseconds.
                // The `RollingWindow` is divided into buckets
                //  and slides by these increments.
                // For example, if this `timeWindowMillis` is set to
                // 10000 milliseconds and `bucketSizeMillis` 2000.
                // Then `RollingWindow` breaks into sub windows with
                // 2-second buckets and stats are collected with
                // respect to the buckets. As time rolls a new bucket
                // will be appended to the end of the window and the
                // old bucket will be removed.
                bucketSizeMillis: 2000,

                // Minimum number of requests in a `RollingWindow`
                // that will trip the circuit.
                requestVolumeThreshold: 0
            },
            // The threshold for request failures.
            // When this threshold exceeds, the circuit trips.
            // This is the ratio between failures and total requests
            //  and the ratio is considered only within the configured
            // `RollingWindow`
            failureThreshold: 0.2,

            // The time period (in milliseconds) to wait before
            // attempting to make another request to the upstream service.
            // When the failure threshold exceeds, the circuit trips to
            // `OPEN` state. Once the circuit is in `OPEN` state
            // circuit breaker waits for the time configured in `resetTimeMillis`
            // and switch the circuit to the `HALF_OPEN` state.
            resetTimeMillis: 10000,

            // HTTP response status codes that are considered as failures
            statusCodes: [400, 404, 500]

        },
        timeoutMillis: 2000
    });

@http:ServiceConfig {
    basePath: "/order"
}
service Order on orderServiceListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    resource function orderResource(http:Caller caller, http:Request request) {
        // Initialize the request and response message to send to the inventory service
        http:Request outRequest = new;
        http:Response inResponse = new;
        // Initialize the response message to send back to client
        // Extract the items from the json payload
        var result = request.getJsonPayload();
        json items;
        if (result is json) {
            items = result.items;
        } else {
            http:Response outResponse = new;
            // Send bad request message to the client if request don't contain order items
            outResponse.setPayload("Error : Please check the input json payload");
            outResponse.statusCode = 400;
            _ = caller->respond(outResponse);
            return;
        }
        string orderItems = items.toString();
        log:printInfo("Recieved Order : " + orderItems);
        // Set the outgoing request JSON payload with items
        outRequest.setPayload(untaint items);
        // Call the inventory backend through the circuit breaker
        var response = circuitBreakerEP->post("/inventory", outRequest);
        if (response is http:Response) {
            _ = caller->respond("Order Placed : " + untaint orderItems);
        } else if (response is error) {
            // If inventory backend contain errors forward the error message to client
            log:printInfo("Inventory service returns an error :" + <string>response.detail().message);
            _ = caller->respond({ "Error": "Inventory Service did not respond",
                    "Error_message": <string>response.detail().message });
            return;
        }
    }
}
