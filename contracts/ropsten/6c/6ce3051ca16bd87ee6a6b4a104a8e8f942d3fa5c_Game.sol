/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Game {
    
    struct QuestionAndAnswer {
        string question;
        string answer;
    }
    
    string[] questions;
    mapping (string => QuestionAndAnswer) questionToQuestionAndAnswer;
    
    function numberOfQuestions() public view returns (uint) {
        return questions.length;
    }
    
    function readQuestionByNumber(uint _number) public view returns (string memory) {
        return questions[_number];
    }
    
    function readQuestionAndAnswerByNumber(uint _number) public view returns (QuestionAndAnswer memory) {
        string memory question = questions[_number];
        return questionToQuestionAndAnswer[question];
    }
    
    function latestQuestion() public view returns(string memory) {
        QuestionAndAnswer memory latest = questionToQuestionAndAnswer[questions[numberOfQuestions() - 1]];
        return latest.question;
    } 
    
    function addQuestionAndAnswer(string memory _question, string memory _answer) public {
        questions.push(_question);
        questionToQuestionAndAnswer[_question] = QuestionAndAnswer(_question, _answer);
    }
    
    function makeAGuess(string memory _question, string memory _guess) public view returns (bool) {
     return compareStrings(questionToQuestionAndAnswer[_question].answer, _guess);
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}