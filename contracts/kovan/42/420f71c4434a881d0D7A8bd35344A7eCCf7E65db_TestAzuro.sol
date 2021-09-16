/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// File: contracts/TestAzuro.sol


pragma solidity ^0.8.0;

contract TestAzuro {
    
    struct Condition {
        uint256 reinforcement;
        uint256[2] fundBank;
        uint256[2] prizing;
        uint256 marginality;
        bytes32 ipfsHash;
        uint256 outcomeWin;
        uint256 maxPrizes; // maximum sum of prizes to be paid on some result
        uint256 timestamp; // after this time user cant put bet on condition
    }
    
    mapping(uint256 => Condition) public conditions;
    
    function createCondition(
        uint256 oracleConditionID_,
        uint256 rate1_,
        uint256 rate2_,
        uint256 timestamp_,
        bytes32 ipfsHash_
    ) external {
        require(timestamp_ > 0, "Core: timestamp can not be zero");
        
        Condition storage newCondition = conditions[oracleConditionID_];
        require(newCondition.timestamp == 0, "Core: condition already set");
        
        newCondition.timestamp = timestamp_;
        newCondition.ipfsHash = ipfsHash_;
    }
    
    function resolveCondition(uint256 conditionID_, uint256 outcomeWin_) external {
        Condition storage condition = conditions[conditionID_];
        require(condition.timestamp > 0, "Azuro: condition not exists");
        require(condition.outcomeWin == 0, "Condition already set");
        require(outcomeWin_ == 1 || outcomeWin_ == 2, "Outcome is Invalid");
        condition.outcomeWin = outcomeWin_;
    }
}