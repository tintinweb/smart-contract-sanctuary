/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.1;


contract Contest {

    // the following record the oracle for this Contest (the one that will determine winning outcomes for questions)
    // and end time for this season, when the winner for the whole season will be determined
    uint public seasonEndTime;
    address public oracle;

    // array of questions initiated
    Question[] public questionRegister; 
    // counts the number of questions that have been initiated
    uint8 public questionCount; 

    // array of all contestants
    address[] public contestants; 
    // returns true if an address is a contestant, and false if it is not
    mapping (address => bool) isContestant; 

    // keeps record of all modified Brier scores
    mapping (address => uint256) scoreRegister;  
    uint256 totalScore;
    
    // a Contest includes different Questions, which people are betting on
    struct Question {
        uint8 questionID;
        uint256 questionStartTime;
        uint256 questionEndTime;
        string questionWording;
        uint defaultForecast;
        bool closed;
        uint finalOutcome;
    }

    mapping (uint => Bet[]) bookkeeper;

    struct Bet {
        address bettor;
        uint timeOfBet;
        uint forecastedOutcome;
    }

    event newQuestionSubmitted(uint8 questionID, uint256 questionEndTime, string questionWording);
    event newForecastSubmitted(uint8 questionID, uint256 forecast);
    event outcomeRevealed(uint8 questionID, uint256 outcome);
    event winnersDetermined(address winner);

    // establishing the contract with the end time of it, and makes the person making contract the oracle
    constructor (uint _seasonEndTime) {
        seasonEndTime = _seasonEndTime;
        oracle = msg.sender;
    }

    modifier onlyOracle () {
        require (oracle == msg.sender);
        _;
    }
    
    function totalSupply() public view returns (uint256) {
        return(totalScore);
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return(scoreRegister[_owner]);
    }

    // allows the oracle to submit a new question
    function newQuestion (string memory _questionWording, uint256 _questionEndTime, uint _defaultForecast) public onlyOracle {

        questionRegister.push(Question({
            questionID : questionCount++,
            questionStartTime : block.timestamp,
            questionEndTime : _questionEndTime,
            questionWording : _questionWording,
            defaultForecast : _defaultForecast,
            closed : false,
            finalOutcome : 0
        }));
        emit newQuestionSubmitted(questionCount, _questionEndTime, _questionWording);
    }

    // allows anyone to submit an answer to a question
    function submitForecast (uint8 _questionID, uint _submittedForecast) public {
        require(_questionID <= questionCount);
        require(questionRegister[_questionID].questionEndTime > block.timestamp);
        require(_submittedForecast >= 0 && _submittedForecast <= 100);

        Bet memory submittedAnswer;
        submittedAnswer.bettor = address(this);
        submittedAnswer.timeOfBet = block.timestamp;
        submittedAnswer.forecastedOutcome = _submittedForecast;

        if(!isContestant[address(this)]) {
            contestants.push(address(this));
            isContestant[address(this)] = true;
        }

        bookkeeper[_questionID].push(submittedAnswer);
        emit newForecastSubmitted(_questionID, _submittedForecast);
    }

    // oracle can close the question if it is past the end time and it hasn't been closed yet
    function closeTheQuestion (uint8 _questionID, uint _outcome) public onlyOracle {
        require(questionRegister[_questionID].questionEndTime < block.timestamp);
        require(questionRegister[_questionID].closed == false);

        questionRegister[_questionID].closed = true;
        questionRegister[_questionID].finalOutcome = _outcome;

        for (uint i = 0; i < bookkeeper[_questionID].length; i++) {
            uint256 scoreForThisBettor = calculateScore(_questionID, bookkeeper[_questionID][i].bettor);
            scoreRegister[bookkeeper[_questionID][i].bettor] += scoreForThisBettor;
            totalScore += scoreForThisBettor;
        }
        emit outcomeRevealed(_questionID, _outcome);
    }

    // iterates through all questions to check if they are all closed
    function allQuestionsClosed () public view returns (bool) {
        for (uint q = 0; q < questionRegister.length; q++) {
            if (questionRegister[q].closed == false) {
                return false;
            }
        }
        return true;
    }

    // calculates modified Brier score so far for answers in the questions
    function calculateScore (uint8 _questionID, address _bettor) public view returns (uint score) {
        if (!questionRegister[_questionID].closed) {
            return(0);
        }
        for (uint i = 0; i < bookkeeper[_questionID].length; i++) {
          if (bookkeeper[_questionID][i].bettor == _bettor) {
            score +=
                // (uint(questionRegister[_questionID].questionEndTime - bookkeeper[_questionID][i].timeOfBet) /
                // uint(questionRegister[_questionID].questionEndTime - questionRegister[_questionID].questionStartTime) ) *
                (bookkeeper[_questionID][i].forecastedOutcome - questionRegister[_questionID].finalOutcome) ** 2;
            break;
            }
        }
        // if bettor has not put a bet, calculate score based on default
        if (score == 0) {
            score += (questionRegister[_questionID].defaultForecast - questionRegister[_questionID].finalOutcome) ** 2;
        }
        score = 10000 - score;
    }

    function whosWinning () public view returns (address winning) {
        uint maxScore;
        for (uint8 q = 0; q < questionCount; q++) {
            for (uint c = 0; c < contestants.length; c++) {
                uint m = calculateScore(q, contestants[c]);
                if (m > maxScore) {
                    maxScore = m;
                    winning = contestants[c];
                }
            }
        }
    }

    //lets the oracle close the season by determining answers; calculates teh winners of the season
    function closeTheSeason() public onlyOracle returns (address maxAddress) {
        require(block.timestamp > seasonEndTime);

        uint maxScore = 0;

        if (allQuestionsClosed()) {
            for (uint c = 0; c < contestants.length; c++) {
                if (scoreRegister[contestants[c]] > maxScore) {
                    maxScore = scoreRegister[contestants[c]];
                    maxAddress = contestants[c];
                }
            }
        }
        
        emit winnersDetermined(maxAddress);
    }
}