/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;

contract Contest {
    uint8 constant maxQuestions = 64;

    address public oracle;
    uint256 contestEndTime;
    
    address [] ranking;
    address [] winners;
    uint8 numWinners;

    Question [] questions;
    address [] playerAddresses;
    mapping(address => Player) players;
    
    struct Question {
        string text;
        uint8 size;
        uint8 correctAnswer;
        uint24 defaultScore;
        uint deadline;
        uint [] gateDates;
        uint8 [] gateWeights;
        uint8 [] gateWeightSums;
    }
    
    struct Player {
        uint8 [][][maxQuestions] answers;
        uint8 [][maxQuestions] weights;
        uint8 [maxQuestions] lastGateNum;
        bool contestant;
    }
    
    constructor(uint _contestEndTime) {
        oracle = msg.sender;
        contestEndTime = _contestEndTime;
    }
    
    modifier onlyOracle () {
        require(
            msg.sender == oracle,
            "Only Oracle can call this."
        );
        _;
    }
    
    function sumWeights(uint8 [] memory _array) internal pure returns (uint8 sum_) {
        for (uint i = 0; i < _array.length; i++) sum_ += _array[i];
    }
    
    function getGateNum(uint [] memory _gateDates) internal view returns (uint8 num_) {
        while (block.timestamp > _gateDates[++num_] - 1) {}
    }
        
    function submitQuestion(string memory _text, uint8 _size, uint _deadline, uint [] memory _gateDates, uint8 [] memory _gateWeights) public onlyOracle {
        require(
            sumWeights(_gateWeights) == 100,
            "Weights must sum to 100"
        );
        
        require(
            _size > 0,
            "Invalid size of question provided, must be between [1, 255]."
        );
        uint8 [] memory tempSums = new uint8 [] (_gateWeights.length);
        tempSums[0] = 100;
        for (uint8 i = 1; i < tempSums.length; i++) {
            tempSums[i] = tempSums[i - 1] - _gateWeights[i - 1];
        }
        
        questions.push(Question({
            text: _text,
            size: _size,
            correctAnswer: 0,
            defaultScore: 200 * uint16((_size - 1)) / uint16(_size ** 2),
            deadline: _deadline,
            gateDates: _gateDates,
            gateWeights: _gateWeights,
            gateWeightSums: tempSums
        }));
    }
    
    function submitCorrectAnswer (uint8 _iQstn, uint8 _correctAnswer) public onlyOracle {
        require(
            _correctAnswer < questions[_iQstn].size,
            "Invalid answer provided, must be between [0, Question.size - 1]."
        );
        
        questions[_iQstn].correctAnswer = _correctAnswer;
    }
    
    function submitForecast(uint8 _iQstn, uint8[] memory _probs) public {
        Player storage player = players[msg.sender];
        if (!player.contestant) {
            playerAddresses.push(msg.sender);
            player.contestant = true;
        }
        Question storage question = questions[_iQstn];
        
         require(
            block.timestamp <= question.deadline,
            "You are past the deadline."
        );       
        
        require(
            _iQstn < questions.length,
            "Question is unavailable."
        );
        
        require(
            _probs.length == question.size,
            "Wrong answer size provided."
        );
        
        require(
            sumWeights(_probs) == 100,
            "Weights must sum to 100"
        );
        
        uint8 gateNum = getGateNum(question.gateDates);
        if (player.lastGateNum[_iQstn] == 0) {
            player.lastGateNum[_iQstn] = gateNum;
            player.answers[_iQstn].push(_probs);
            player.weights[_iQstn].push(question.gateWeightSums[gateNum-1]);
        }
        else if (gateNum > player.lastGateNum[_iQstn]) {
            player.lastGateNum[_iQstn] = gateNum;
            player.answers[_iQstn].push(_probs);
            uint8 prevWeight = player.weights[_iQstn][player.weights[_iQstn].length - 1];
            player.weights[_iQstn][player.weights[_iQstn].length - 1] = prevWeight - question.gateWeightSums[gateNum-1];
            player.weights[_iQstn].push(question.gateWeightSums[gateNum-1]);
        }
        else if (gateNum == player.lastGateNum[_iQstn]) {
            player.answers[_iQstn][player.answers[_iQstn].length - 1] = _probs;
        }
    }
    
    function calculateScore(address adrs) internal view returns(uint24 score_) {
        Player storage player = players[adrs];
        for (uint8 iQstn = 0; iQstn < questions.length; iQstn++) {
            if (player.lastGateNum[iQstn] == 0) {
                score_ += questions[iQstn].defaultScore;
                continue;
            }
            uint8 tempSum = 0;
            for (uint8 iWght = 0; iWght < player.weights[iQstn].length; iWght++) {
                tempSum += player.weights[iQstn][iWght];
                score_ += uint24(player.weights[iQstn][iWght]) * (200 - 2 * uint24(player.answers[iQstn][iWght][questions[iQstn].correctAnswer])) / uint24(questions[iQstn].size);
            }
            score_ += (100 - tempSum) * questions[iQstn].defaultScore;
        }
    }
    
    function findMyScore() public view returns(uint24 score_) {
        return calculateScore(msg.sender);
    }
    
    function findLeaders() public view returns(address [] memory winners_) {
        address [] memory ranking_ = new address [] (playerAddresses.length);
        uint8 tempRankId;
        uint8 numWinners_ = 1;
        uint24 playerScore;
        uint24 bestScore = type(uint24).max;

        for (uint8 iAdrs = 0; iAdrs < playerAddresses.length; iAdrs++) {
            playerScore = calculateScore(playerAddresses[iAdrs]);
            
            if (playerScore == bestScore) {
                ranking_[tempRankId++] = playerAddresses[iAdrs];
                numWinners_ += 1;
            }
            else if (playerScore < bestScore) {
                ranking_[tempRankId++] = playerAddresses[iAdrs];
                numWinners_ = 1;
                bestScore = playerScore;
            }
        }
        
        winners_ = new address [] (numWinners_);
        for (uint8 i = 0; i < numWinners_; i++) {
            winners_[i] = ranking_[tempRankId - i - 1];
        }
    }
    
    function contestEnd() public onlyOracle {
        require(
            block.timestamp > contestEndTime,
            "Contest end time hasn't been reached yet."
        );
        
        winners = findLeaders();
    }
}