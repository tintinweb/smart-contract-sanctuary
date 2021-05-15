/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Ferhat7 {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint256 public constant maxSupply = 1000000000000;
    string public name = "Ferhat 7";
    string public symbol = "FRHT7";
    uint public decimals = 0;
    uint256 public lotteryParticipantCount = 0;
    uint256 public totalSupply = 0;
    uint256 public numberOfTokensThatCannotBeMined = 0;
    address ownerOfToken;
    uint256 public lastLotteryTimeStamp;
    address public tokenCreator = 0x0000000000000000000000000000000000000000;
    uint256 public firstLotteryTimeStamp;
    uint256 public distrubutedTokenCount;
    uint256 public distrubutedTokenPerParticipant;
    uint256 public planckConstant = 62607015;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = maxSupply - 750000000000;
        totalSupply = balances[msg.sender];
        ownerOfToken = msg.sender;
        firstLotteryTimeStamp = block.timestamp;
        distrubutedTokenCount = calculateNumberOfTokensToBeDistrubuted();
        distrubutedTokenPerParticipant = calculateTokenCountPerParticipant();
        lastLotteryTimeStamp = firstLotteryTimeStamp;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value+1, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'balance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function currentSupply() public view returns (uint256) {
      return totalSupply;
    }
    
    function currentParticipantCount() public view returns (uint256) {
      return lotteryParticipantCount;
    }
    
    function remainingTimeForNextTokenCreation() public view returns (uint256) {
        if ((lastLotteryTimeStamp + 86400) > block.timestamp) {
            return (lastLotteryTimeStamp + 86400) - block.timestamp;
        }
        else {
            return 0;
        }
    }
    
    function joinLottery() public payable returns(bool) {
        require((totalSupply + numberOfTokensThatCannotBeMined) < maxSupply, 'Token mining is finished');
        require(distrubutedTokenCount > 0, 'the number of tokens that can be distributed is over');
        require(block.timestamp - lastLotteryTimeStamp < 86400, 'time is up, wait for lottery result');
        //require(isUser(msg.sender) == false, 'user has already entered the lottery');
        require(balanceOf(msg.sender) >= 100, 'balance too low');
        lotteryParticipantCount++;
        balances[ownerOfToken] += 100;
        balances[msg.sender] -= 100;
        emit Transfer(msg.sender, ownerOfToken, 100);
        uint256 currentLuckyPersonValueResult = getLuckyPerson(distrubutedTokenPerParticipant);
        if (currentLuckyPersonValueResult > distrubutedTokenCount) {
            totalSupply += distrubutedTokenCount;
            balances[msg.sender] += distrubutedTokenCount;
            distrubutedTokenCount = 0;
            emit Transfer(tokenCreator, msg.sender, distrubutedTokenCount);
        }
        else {
            totalSupply += currentLuckyPersonValueResult;
            balances[msg.sender] += currentLuckyPersonValueResult;
            distrubutedTokenCount -= currentLuckyPersonValueResult;
            emit Transfer(tokenCreator, msg.sender, currentLuckyPersonValueResult);
        }
        return true;
    }
    
    function getLuckyPerson(uint256 count) private view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(lastLotteryTimeStamp, block.timestamp, lotteryParticipantCount, planckConstant)))%count);
    }
    
    function calculateNumberOfTokensToBeDistrubuted() private view returns (uint256) {
        uint256 result = block.timestamp - firstLotteryTimeStamp;
        if (result <= 6*30*24*60) {
            return 1000000000;
        }
        else if (result <= 12*30*24*60) {
            return 750000000;
        }
        else if (result <= 18*30*24*60) {
            return 500000000;
        }
        else if (result <= 24*30*24*60) {
            return 250000000;
        }
        else if (result <= 36*30*24*60) {
            return 125000000;
        }
        else {
            return 50000000;
        }
    }
    
    function calculateTokenCountPerParticipant () private view returns (uint256) {
        uint256 result = block.timestamp - firstLotteryTimeStamp;
        if (result <= 6*30*24*60) {
            return 10000;
        }
        else if (result <= 12*30*24*60) {
            return 5000;
        }
        else if (result <= 18*30*24*60) {
            return 2500;
        }
        else if (result <= 24*30*24*60) {
            return 1000;
        }
        else if (result <= 36*30*24*60) {
            return 500;
        }
        else {
            return 200;
        }
    }
    
    function reStartLottery() public returns(bool) {
        require((totalSupply + numberOfTokensThatCannotBeMined) < maxSupply, 'Token mining is finished');
        require(block.timestamp - lastLotteryTimeStamp >= 86400, 'time is not up yet');
        numberOfTokensThatCannotBeMined += distrubutedTokenCount;
        distrubutedTokenCount = calculateNumberOfTokensToBeDistrubuted();
        distrubutedTokenPerParticipant = calculateTokenCountPerParticipant();
        lotteryParticipantCount = 0;
        lastLotteryTimeStamp = block.timestamp;
        return true;
    }
}