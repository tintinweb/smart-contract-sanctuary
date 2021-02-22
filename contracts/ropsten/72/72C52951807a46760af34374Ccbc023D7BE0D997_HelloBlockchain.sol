/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract HelloBlockchain
{

    struct Response {
        string answer;
        bool answered;
    }

    //List of properties
    address public  quizmaster;

    string public question;
    bool public questionHasBeenAnswered;

    mapping(address => Response) givenAnswers;
    address[] public respondents;

    // constructor function
    constructor()
    {
        quizmaster = msg.sender;
        question = "";
        questionHasBeenAnswered = true;
    }

    function setNewQuestion(string memory newQuestion) public {
        require(msg.sender == quizmaster, "Only quizmasters can set the question");
        require(questionHasBeenAnswered, "You must first answer the current question");
        
        // Reset the givenAnswer mapping
        for (uint i = 0; i < respondents.length; i ++) {
            delete givenAnswers[respondents[i]];
        }

        // Reset the respondents array
        delete respondents;
        
        // Set the new question
        question = newQuestion;
        questionHasBeenAnswered = false;
    }

    function checkAnswer(string memory newAnswer) public returns (uint nrCorrectAnswers) {
        require(msg.sender == quizmaster, "Only quizmasters can set the answer");
        require(!questionHasBeenAnswered, "This question has already been answered");
        nrCorrectAnswers = 0;

        for (uint i = 0; i < respondents.length; i ++) {
            if (keccak256(bytes(givenAnswers[respondents[i]].answer)) == keccak256(bytes(newAnswer))) {
                nrCorrectAnswers += 1;
            }
        }

        questionHasBeenAnswered = true;
    }

    function giveAnswer(string memory newAnswer) public {
        require(msg.sender != quizmaster, "Quizmasters cannot participate in the quiz");
        require(!givenAnswers[msg.sender].answered, "You can only answer once");
        require(!questionHasBeenAnswered, "The question has already been checked");
        givenAnswers[msg.sender].answer = newAnswer;
        givenAnswers[msg.sender].answered = true;
        respondents.push(msg.sender);
    }
}