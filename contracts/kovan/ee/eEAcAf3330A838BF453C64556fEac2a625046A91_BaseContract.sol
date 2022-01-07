// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BaseContract {
    Request[] requests;
    uint currentId = 0;
    uint minQuorum = 1;
    uint totalOracleCount = 1;

    struct Req{
        uint id;
        string url;
        string path;
    }

    struct Request {
        uint id;
        string url;
        string path;
        string value;
        mapping(uint => string) anwers;
        mapping(address => uint) quorum;
    }

    event NewRequest (
        uint id,
        string url,
        string path
    );

    event UpdatedRequest (
        uint id,
        string value
    );

    function createRequest (Req memory _req) public
    {
        requests.push();
        Request storage newRequest = requests[requests.length-1];
        newRequest.id= currentId;
        newRequest.url= _req.url;
        newRequest.path= _req.path;
        newRequest.quorum[address(0xb30C592b27c2198c9DaE167a8F348A798FB4260e)] = 1;
        emit NewRequest (
            newRequest.id,
            newRequest.url,
            newRequest.path
        );
        currentId++;
    }

    function updateRequest (uint _id, string memory _valueRetrieved) public
    {
        Request storage currRequest = requests[_id];
        if(currRequest.quorum[address(msg.sender)] == 1){
            currRequest.quorum[msg.sender] = 2;
            uint tmpI = 0;
            bool found = false;
            while(!found) {
                if(bytes(currRequest.anwers[tmpI]).length == 0){
                    found = true;
                    currRequest.anwers[tmpI] = _valueRetrieved;
                }
                tmpI++;
            }
            uint currentQuorum = 0;
            for(uint i = 0; i < totalOracleCount; i++){
                bytes memory a = bytes(currRequest.anwers[i]);
                bytes memory b = bytes(_valueRetrieved);
                if(keccak256(a) == keccak256(b)){
                    currentQuorum++;
                    if(currentQuorum >= minQuorum){
                        currRequest.value = _valueRetrieved;
                        emit UpdatedRequest (
                            currRequest.id,
                            currRequest.value
                        );
                    }
                }
            }
        }
    }
}