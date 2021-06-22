/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote {

    Question public question;
    mapping(uint => Response) public responses;
    uint countResponse;

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

    function getQuestion() external view returns(string memory, string[2] memory) {
        return (question.questionToAsk, question.answerChoice);
    }

    function getCountResponse() external view returns (uint) {
        return countResponse;
    }

    function getResponse(uint _id) external view returns(address, int) {
        return (responses[_id].author, responses[_id].choice);
    }

    function addAnswer(int _value) external {

        require(_value > (- 1) && _value < int(question.answerChoice.length), "Value must be greater than 0.");
        require(!isVoted(), "You have already voted !");

        address currentUser = msg.sender;
        responses[countResponse] = Response(currentUser, _value);
        countResponse++;
    }
}