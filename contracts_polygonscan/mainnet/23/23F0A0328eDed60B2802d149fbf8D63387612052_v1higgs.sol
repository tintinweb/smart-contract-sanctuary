/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface QandA {
    struct Question {
        address payable asker;
        // address payable controller;
        string questionTitle;
        string questionBody;
        uint256 bountyAmount;
        uint256 startTime;
        uint256 endTime;
    }

    struct Answer {
        address payable answerer;
        string answerBody;
        uint256 answerTime;
        bool isWinner;
        int256 numVotes;
    }

    event QuestionSubmitted(uint256 indexed questionId);
    event AnswerSubmitted(uint256 indexed answerId, uint256 indexed questionId);
    event VoteSubmitted(
        address indexed voter,
        uint256 indexed answerId,
        uint256 indexed questionId
    );
}

contract v1higgs is QandA {
    uint256 questionId;
    uint256 answerId;

    mapping(uint256 => Question) private questions;
    mapping(uint256 => Answer[]) private answers;

    constructor() {
        questionId = 0;
    }

    function createQuestion(
        string memory _questionTitle,
        string memory _questionBody,
        uint256 _bountyAmount,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        // TO DO: modifiers

        questionId += 1;
        Question memory q;

        q.asker = payable(msg.sender);
        q.bountyAmount = _bountyAmount;
        q.questionTitle = _questionTitle;
        q.questionBody = _questionBody;
        q.startTime = _startTime;
        q.endTime = _endTime;

        questions[questionId] = q;
        // event to log data for front-end
        emit QuestionSubmitted(questionId);
    }

    function createAnswer(
        uint256 _questionId,
        string memory _answerBody,
        uint256 _answerTime
    ) public {
        // TO DO: modifiers
        answerId = answers[_questionId].length;
        Answer memory a;

        a.answerer = payable(msg.sender);
        a.answerBody = _answerBody;
        a.answerTime = _answerTime;
        a.isWinner = false;
        a.numVotes = 0;

        answers[_questionId].push(a);
        // event to log data for front-end
        emit AnswerSubmitted(answerId, _questionId);
    }

    function createVote(
        uint256 _questionId,
        uint256 _answerId,
        int256 _value
    ) public {
        // TO DO: modifiers
        Answer[] storage answerArray = answers[_questionId];
        Answer storage a = answerArray[_answerId];

        a.numVotes = a.numVotes + _value;
    }

    function getQuestion(uint256 _questionId)
        public
        view
        returns (Question memory)
    {
        return questions[_questionId];
    }

    function getAnswer(uint256 _questionId, uint256 _answerId)
        public
        view
        returns (Answer memory)
    {
        return answers[_questionId][_answerId];
    }

    function getNumVotes(uint256 _questionId, uint256 _answerId)
        public
        view
        returns (int256)
    {
        return answers[_questionId][_answerId].numVotes;
    }
}