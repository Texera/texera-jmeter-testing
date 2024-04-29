# texera-jmeter-testing
Used for HTTP stress testing of Texera deployments based on jmeter. For now only a simple test plan is included.

### Notes:

- **Need to have jmeter installed first. Open `simple_test/jmx` in jmeter before reading the rest of this doc.**
- **Need to install extension [WebSocket Samplers by Peter Doornbosch](https://jmeter-plugins.org/?search=websocket-samplers) first before opening the jmx file.**
- **After opening the jmx file in jmeter, you need to replace all file paths used in the jmx plan with the absolute path in your machine.**
  1.  `Thread Group -> CSV Data Set Config -> Filename`
  2. `http://localhost:8080/api/dataset/create -> Files Upload -> File Path`
- **Any disabled http headers/cookie managers can be ignored.**

- **Disabled HTTP requests may be used but are not necessary for the testplan to work. (Check port numbers being used before using these, change whenever necessary)**

- **Thread Group:** (Defines number of threads and other thread related configuration)
  1. Number of threads: number of users to simulate
  2. Ramp up period: Number of seconds to initially ramp up to the load(number of users) defined
  3. Loop count: Number of times each thread should run/repeat.
  4. Check “Same user on each iteration”. This makes sure that same user is used by the same thread for every iteration. (Each thread maps to one user)

- **CSV Dataset Config**: CSV file that defines all the username and password pairs to be used for testing.
  1. CSV format: user, password
  2. Variable name: Generate jmeter variable name to store username and password

### **HTTP requests in simple_test:**

**For all request:**

- Server name: localhost

- Port: 8080

- Path: /api/{path}

#### Explanation of requests

1. [http://localhost:8080/api/auth/register](http://localhost:4200/api/auth/register)
    1. Registers the user with given username and password
    2. Response assertion has a regex matching to make sure accessToken is generated and returned in response.
2. [http://localhost:8080/api/auth/login](http://localhost:8080/api/auth/login)
    3. Login user similar to above
    4. Does response assertion as described above
    5. JSON extractor:
        1. Used to extract the accessToken from HTTP response and store it in a jmeter variable for use in further requests
        2. Name of created variable: name of the jmeter variable to store the access token
        3. JSON Path expression: $.accessToken ($ being the json object)
        4. Match No.: 1 (matches and returns the first match we get)
3. [http://localhost:8080/api/auth/refresh](http://localhost:8080/api/auth/refresh)
    6. Same as above except the accessToken is sent in the body instead of the user, password
4. ~~[http://localhost:8080/api/user/file/upload](http://localhost:8080/api/user/file/upload)~~
    7. ~~Uploads a file to the account that is being used~~
    8. ~~In HTTP header manager(expand the http request to get this), content type and authorization are defined. (Authorization contains the access token as value defined as follows: Bearer {accessToken}) (All requests following this make use of this token)~~
    9. ~~Check “Use multipart/form data”. (Data is sent in form data)~~
    10. ~~Under “Files upload” tab, enter file path, parameter name(“file” is how it is referenced in form data), MIME type - “text/plain”~~
5. ~~[http://localhost:4200/api/user/file/list](http://localhost:4200/api/user/file/list)~~
    11. ~~Simple get request that returns list of all files stored in a user’s account~~
    12. ~~3 JSON extractors are used:~~
        5. ~~First extracts file id and stores in variable “fid”~~
            1. ~~JSON path expressions: $.[-1].file.fid~~
                1. ~~Response is a list of files so index -1 gives us the last/most recently added file response object. Access file within this object which contain fid(file id)~~
            2. ~~Match no.: 1~~
        6. ~~Second JSON extractor stores username~~
            3. ~~JSON path expressions: $.[-1].ownerEmail~~
                2. ~~Similar to above, get the last file object using index -1, and get ownerEmail for username~~
        7. ~~Third JSON extractor gets filename:~~
            4. ~~JSON path expressions: $.[-1].file.name~~
                3. ~~Same as above~~
6. [http://localhost:8080/api/dataset/create](http://localhost:8080/api/dataset/create)
    13. Creates a test dataset named “Test Dataset” with the provided file “Assignment 5.csv”.
    14. Extracts the dataset id as ${did} from the response JSON.
7. [http://localhost:8080/api/workflow/create](http://localhost:8080/api/workflow/create)
    15. Creates the workflow to be run and tested
    16. Generate the workflow and download it as a json file
    17. JSON file will be of following format:
        8. {“operators”: [{list of operator objects}]}
    18. Copy the above json object(json_obj) and insert into the request body as follows:
        9. {“name”: “workflow_name”, “content”: {insert copied json_obj}}
            5. Make sure to use quotes around the object along with necessary escape characters (refer jmx file for clarity)
8. [http://localhost:8080/api/workflow/${wid}/environment](http://localhost:8080/api/workflow/${wid}/environment)
    19. Retrieves the eid of the created workflow.
9. [http://localhost:8080/api/environment/${eid}/dataset/add](http://localhost:8080/api/environment/${eid}/dataset/add)
    20. Adds the test dataset to the environment of this workflow.

### Websocket requests in simple_test:

- **Websocket Connections:** Uses a WebSocket request-response Sampler to send a request to the server with the request data and get a singular response.

- **WebSocket Single Read Sampler:** Reads messages coming from the server. This sampler is put inside a **Loop controller **which loops and allows this sampler to run a given number of times (loop count defined in the loop controller).

- **Websocket configuration:**

  - Server url: ws://localhost:8080/wsapi/workflow-websocket?access-token=${accessToken}

    - The url is defined in the sampler as follows:

    - Protocol: ws

    - Server name/IP: localhost

    - Port: 8080

    - Path: wsapi/workflow-websocket?access-token=${accessToken}

There are 4 websocket requests sent from the client to the server. These will be defined below. After each request, there is a loop controller with a read sampler as explained above to read multiple responses that would be received by the client after sending the request. (The request response sampler only checks for one response, subsequent responses are ignored unless we use a read sampler).

1. WebSocket request-response Sampler 1
    1. Request that registers the given workflow using the workflow id
    2. Request data:
        1. ```
           {
                "type": "RegisterWorkflowIdRequest",
                "workflowId": "${wid}"
            }
           ```

2. WebSocket request-response Sampler 2
    3. Initiates a EditingTimeCompilationRequest to send the updated workflow with all the operators, their configuration and how they link to each other.
    4. Sample Body(Refer Chrome Network tab to get body for alternate workflow):

            {
                "type": "EditingTimeCompilationRequest",
                "operators": [
                    {
                        "fileEncoding": "US_ASCII",
                        "customDelimiter": ",",
                        "hasHeader": true,
                        "fileName": "${username}/${filename}",
                        "operatorID": "CSVFileScan-operator-68c5b948-6246-47a4-9d70-618d346b8c17",
                        "operatorType": "CSVFileScan",
                        "inputPorts": [],
                        "outputPorts": [
                            {
                                "portID": "output-0",
                                "displayName": "",
                                "allowMultiInputs": false,
                                "isDynamicPort": false
                            }
                        ]
                    },
                    {
                        "operatorID": "SimpleSink-operator-838553b8-5873-4d13-a589-9c969479d7c2",
                        "operatorType": "SimpleSink",
                        "inputPorts": [
                            {
                                "portID": "input-0",
                                "displayName": "",
                                "allowMultiInputs": false,
                                "isDynamicPort": false,
                                "dependencies": []
                            }
                        ],
                        "outputPorts": [
                            {
                                "portID": "output-0",
                                "displayName": "",
                                "allowMultiInputs": false,
                                "isDynamicPort": false
                            }
                        ]
                    }
                ],
                "links": [
                    {
                        "fromOpId": "CSVFileScan-operator-68c5b948-6246-47a4-9d70-618d346b8c17",
                        "fromPortId": {
                            "id": 0,
                            "internal": false
                        },
                        "toOpId": "SimpleSink-operator-838553b8-5873-4d13-a589-9c969479d7c2",
                        "toPortId": {
                            "id": 0,
                            "internal": false
                        }
                    }
                ],
                "opsToViewResult": [],
                "opsToReuseResult": []
            }

3. WebSocket request-response Sampler 3
    5. Workflow execute request to start workflow execution
    6. Sample Body (Refer Chrome Network tab to get body for alternate workflow):

            {
                "type": "WorkflowExecuteRequest",
                "executionName": "",
                "engineVersion": "8b84d50c2",
                "logicalPlan": {
                    "operators": [
                        {
                            "fileEncoding": "US_ASCII",
                            "customDelimiter": ",",
                            "hasHeader": true,
                            "fileName": "${username}/${filename}",
                            "operatorID": "CSVFileScan-operator-68c5b948-6246-47a4-9d70-618d346b8c17",
                            "operatorType": "CSVFileScan",
                            "inputPorts": [],
                            "outputPorts": [
                                {
                                    "portID": "output-0",
                                    "displayName": "",
                                    "allowMultiInputs": false,
                                    "isDynamicPort": false
                                }
                            ]
                        },
                        {
                            "operatorID": "SimpleSink-operator-838553b8-5873-4d13-a589-9c969479d7c2",
                            "operatorType": "SimpleSink",
                            "inputPorts": [
                                {
                                    "portID": "input-0",
                                    "displayName": "",
                                    "allowMultiInputs": false,
                                    "isDynamicPort": false,
                                    "dependencies": []
                                }
                            ],
                            "outputPorts": [
                                {
                                    "portID": "output-0",
                                    "displayName": "",
                                    "allowMultiInputs": false,
                                    "isDynamicPort": false
                                }
                            ]
                        }
                    ],
                    "links": [
                        {
                            "fromOpId": "CSVFileScan-operator-68c5b948-6246-47a4-9d70-618d346b8c17",
                            "fromPortId": {
                                "id": 0,
                                "internal": false
                            },
                            "toOpId": "SimpleSink-operator-838553b8-5873-4d13-a589-9c969479d7c2",
                            "toPortId": {
                                "id": 0,
                                "internal": false
                            }
                        }
                    ],
                    "opsToViewResult": [],
                    "opsToReuseResult": []
                }
            }

4. WebSocket request-response Sampler 4
    7. Get the final result of the workflow executed.
    8. In this case, SimpleSink operator is referred which is “View Results”(Displays results in a tabulated format). Sample Body (Refer Chrome Network tab to get body for alternate workflow):

            {
                "type": "ResultPaginationRequest",
                "operatorID": "SimpleSink-operator-838553b8-5873-4d13-a589-9c969479d7c2",
                "pageIndex": 1,
                "pageSize": 5
            }

    9. The request also has a response assertion to check for the accuracy of the response. Response expected for the inputted csv file is as follows:

            [{"id":100,"name":"John Smith","city":"Austin","state":"TX","zipcode":78727},{"id":200,"name":"Joe Johnson","city":"Dallas","state":"TX","zipcode":75201},{"id":300,"name":"Bob Jones","city":"Houston","state":"TX","zipcode":77028},{"id":400,"name":"Andy Davis","city":"San Antonio","state":"TX","zipcode":78227},{"id":500,"name":"James Williams","city":"Austin","state":"TX","zipcode":78727}]
        As seen above, response is in the form of a list of objects. Each object is a key value pair like a dictionary with key being the column and value being the value of that column for a particular entry.
        Also, path matching is “$.table” as this list comes in the table parameter of the response object.

5. Close the websocket using websocket close.

### “View Results Tree” Listener is used to track and view the output/status of all the requests executed.
