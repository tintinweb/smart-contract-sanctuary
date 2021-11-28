/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract QuizSol{
    
    struct QuizModel{
        string question;
        string answerA;
        string answerB;
        string answerC;
        string answerD;
        string correctAnswer;
    }

    uint totalQuestions;
    address owner;
    mapping(uint => QuizModel) questions;

    constructor(){
        owner = msg.sender;
        totalQuestions = 0;

    }

    function addNewQuestion(string memory question,
    string memory answerA,
    string memory answerB,
    string memory answerC,
    string memory answerD,
    string memory correctAnswer
    ) public{
        require(msg.sender == owner,"Only admin can add new questions...!!");
        addQuestion(question,answerA,answerB,answerC,answerD,correctAnswer);
    }

    function addQuestion(string memory newQuestionToBeAdded,
    string memory answerA,
    string memory answerB,
    string memory answerC,
    string memory answerD,
    string memory correctAnswer) internal{
        newQuestionToBeAdded;
        totalQuestions++;
        QuizModel memory quizModel = QuizModel(newQuestionToBeAdded,
        answerA,
        answerB,
        answerC,
        answerD,
        correctAnswer);
        questions[totalQuestions] = quizModel;
    }


    function getQuestionByIndex(uint questionIndex) public view returns(string memory){
        require(questionIndex != 0,"Question index must not be empty");
        require(questionIndex > 0,"Question index must be greater than zero");
        return questions[questionIndex].question;
    }


    function getTotalQuestionsOnChain() public view returns(uint){
        return totalQuestions;
    }

    


}