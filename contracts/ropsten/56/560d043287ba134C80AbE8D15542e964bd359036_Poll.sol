/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: None
pragma solidity >=0.4.22 <0.9.0;

contract Poll {
    //VARIABLES
    struct response {
        string name;
        uint32 nbVote;
    }

    string public question;
    mapping(string => response) public responses;

    address public owner;

    // MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }

    //FUNCTIONS
    constructor(string memory _question, string[] memory _responseNames) {
        owner = msg.sender;

        question = _question;
        for (uint8 i = 0; i < _responseNames.length; i++) {
            responses[_responseNames[i]] = response({
                name: _responseNames[i],
                nbVote: 0
            });
        }
    }

    function vote(response[] memory _responses) 
        public
        onlyOwner()
    {
        for (uint8 i = 0; i < _responses.length; i++) {
            responses[_responses[i].name].nbVote = _responses[i].nbVote;
        }
    }
}