/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Poll {
    //VARIABLES
    struct responseInput {
        string name;
        uint nbVote;
    }

    struct response {
        string name;
        uint nbVote;
    }

    string public question;
    mapping(string => response) public responses;
    string[] internal responseIndex;
    uint public voteCount;

    enum State { Voting, Ended }
    State public state;

    address public owner;

    // MODIFIERS
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    //FUNCTION
    constructor(string memory _question, string[] memory _responseNames) {
        owner = msg.sender;

        question = _question;
        for (uint i = 0; i < _responseNames.length; i++) {
            responses[_responseNames[i]] = response({
                name: _responseNames[i],
                nbVote: 0
            });
            responseIndex.push(_responseNames[i]);
        }
        voteCount = 0;

        state = State.Voting;
    }

    function vote(responseInput[] memory _responses) 
        public
        onlyOwner()
        inState(State.Voting)
    {
        for (uint i = 0; i < _responses.length; i++) {
            responses[_responses[i].name].nbVote += _responses[i].nbVote;
            voteCount+= _responses[i].nbVote;
        }
    }

    function getNbResponse() public view returns (uint) {
        return responseIndex.length;
    }

    function getResponses(uint indexResponse) public view returns (response memory) {
        return responses[responseIndex[indexResponse]];
    }

    function endVote()
        public
        inState(State.Voting)
        onlyOwner()
    {
        state = State.Ended;
    }
}