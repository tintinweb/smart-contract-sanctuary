/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote {

    Question question;
    mapping(uint => Response) public responses;
    uint public countResponse;

    constructor() {
        string[2] memory answerChoices = ["Yes", "No"];
        string memory questionToAsk = "Can you answer the question?";
        question = Question(questionToAsk, answerChoices);
        countResponse = 0;
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

        for (uint i = 0; i < countResponse; i++) {
            Response memory oldResponse = responses[i];
            if (oldResponse.author == currentUser) {
                result = true;
            }
        }

        return result;
    }

    function getQuestion() external view returns (string memory) {
        return question.questionToAsk;
    }

    function getChoices() external view returns (string memory, string memory) {
        return (question.answerChoice[0], question.answerChoice[1]);
    }

    function addAnswer(int _value) external {

        require(_value > (- 1) && _value < int(question.answerChoice.length), "Value must be greater than 0.");
        require(!isVoted(), "You have already voted !");

        address currentUser = msg.sender;
        responses[countResponse] = Response(currentUser, _value);
        countResponse++;
    }
}