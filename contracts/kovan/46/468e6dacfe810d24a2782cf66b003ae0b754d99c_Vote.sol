/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote {

    Question public question;
    mapping(uint => Response) public responses;
    uint nbResponse;

    constructor() {
        nbResponse = 2;
        string[2] memory answerChoices = ["Yes", "No"];
        string memory questionToAsk = "Can you answer the question?";
        question = Question(questionToAsk, answerChoices);
    }

    struct Question {
        string questionToAsk;
        string[2] answerChoice;
    }

    struct Response {
        address author;
        int choice;
    }

    function isVoted() internal returns (bool) {

        bool result = false;
        address currentUser = msg.sender;

        for (uint i = 0; i < nbResponse; i++) {
            Response memory oldResponse = responses[i];
            if (oldResponse.author == currentUser) {
                result = true;
            }
        }

        return result;
    }

    // value from interface web
    function addAnswer(int _value) external {

        require(_value > (- 1) && _value < int(nbResponse));
        require(!isVoted());

        address currentUser = msg.sender;
        responses[nbResponse] = Response(currentUser, _value);
    }
}