/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote {

    string public question;
    string[] public answerChoices;
    mapping(address => Response) public responses;
    mapping(uint => address) public listResponces;
    uint public nbResponse;

    constructor() {
        answerChoices.push("Yes");
        answerChoices.push("No");
        question = "Can you answer the question?";
        nbResponse = 0;
    }

    struct Response {
        uint choice;
        bool active;
        
    }

    function getNumberAnswerChoices() external view returns(uint){
        return answerChoices.length;
    }

    modifier isNotVoted() {

        address currentUser = msg.sender;
        Response memory response = responses[msg.sender];

        require(response.active == false, "You have already voted !");
        _;
    }

    // value from interface web
    function addAnswer(uint _value) external isNotVoted {

        require(_value < answerChoices.length, "Incorrect value !");

        address currentUser = msg.sender;
        responses[currentUser] = Response(_value, true);
        listResponces[nbResponse] = currentUser;
        nbResponse++;
    }
}