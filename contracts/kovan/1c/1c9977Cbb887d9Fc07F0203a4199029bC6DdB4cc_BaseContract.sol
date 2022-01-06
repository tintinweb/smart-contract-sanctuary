// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BaseContract {
    Request[] requests;
    uint currentId = 0;
    uint minQuorum = 1;
    uint totalOracleCount = 1;

    struct Request {
        uint id;
        string urlToQuery;
        string attributeToFetch;
        string agreedValue;
        mapping(uint => string) anwers;
        mapping(address => uint) quorum;
    }

    event NewRequest (
        uint id,
        string urlToQuery,
        string attributeToFetch
    );

    event UpdatedRequest (
        uint id,
        string urlToQuery,
        string attributeToFetch,
        string agreedValue
    );

    function createRequest (string memory _urlToQuery, string memory _attributeToFetch) public
    {
        requests.push();
        Request storage newRequest = requests[requests.length-1];
        newRequest.id=  currentId;
        newRequest.urlToQuery=  _urlToQuery;
        newRequest.attributeToFetch=  _attributeToFetch;
        newRequest.agreedValue=  "";
        newRequest.quorum[address(0xb30C592b27c2198c9DaE167a8F348A798FB4260e)] = 1;
        emit NewRequest (
            currentId,
            _urlToQuery,
            _attributeToFetch
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
                        currRequest.agreedValue = _valueRetrieved;
                        emit UpdatedRequest (
                            currRequest.id,
                            currRequest.urlToQuery,
                            currRequest.attributeToFetch,
                            currRequest.agreedValue
                        );
                    }
                }
            }
        }
    }
}