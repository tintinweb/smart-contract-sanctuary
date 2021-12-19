/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
/**
* @title SantaWar
* @dev Store & Retrieve SantaWar Game data
*/

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

struct Record {
    uint256 recordTime;
    address recordPlayer;
}

struct TopRecords {
    bool isFinished;
    Record[] topPlayers;
}

interface SANTAWARINTEFACE {
    function approve(address spender, uint256 amount) external returns (bool);

    function approveMax(address spender) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function decimals() external pure returns (uint8);

    function symbol() external pure returns (string memory);

    function name() external pure returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address holder, address spender) external view returns (uint256);
}


contract SantaWarGame is Ownable {
    using SafeMath for uint256;

    mapping(uint256 => TopRecords) public topRecords;
    mapping(uint256 => uint256) public minRecordTimes; 
    uint256 currentWeek;

    uint256 public createdTime;
    uint256 public startTime;
    uint256 public weekStartTime;

    bool public isStarted;

    uint256 public totalDays;
    uint256 public rewardPerWeek;

    address public tokenAddress = 0xfd16F4fb3717D7AFD76B54f49F132501015D9C90;

    SANTAWARINTEFACE SantaWar = SANTAWARINTEFACE(tokenAddress);
    /**
     * @dev Initializes the contract information and setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
        minRecordTimes[currentWeek] = 10000;
        createdTime = block.timestamp;
    }

    /**
     * @dev add new time record to current top player.
     */
    function newRecord(uint256 _recordTime, address _recordPlayer) public payable onlyOwner {
        require(startTime > 0, "Game not started yet.");
        if(checkWeek() == true)
            startWeek();

        require(_recordTime < minRecordTimes[currentWeek]);
        if(topRecords[currentWeek].topPlayers.length == 0) {
            Record memory record;
            record.recordTime = _recordTime;
            record.recordPlayer = _recordPlayer;

            topRecords[currentWeek].topPlayers.push(record);            
        }
        else {
            uint i = 0;
            for(i; i < topRecords[currentWeek].topPlayers.length; i++) {
                if(topRecords[currentWeek].topPlayers[i].recordTime > _recordTime) {
                    break;
                }
            }
            
            Record memory record;
            topRecords[currentWeek].topPlayers.push(record);     
            
            for(uint j = topRecords[currentWeek].topPlayers.length - 1; j > i ; j--) {
                topRecords[currentWeek].topPlayers[j].recordTime = topRecords[currentWeek].topPlayers[j - 1].recordTime;
                topRecords[currentWeek].topPlayers[j].recordPlayer = topRecords[currentWeek].topPlayers[j - 1].recordPlayer;
            }
            record.recordTime = _recordTime;
            record.recordPlayer = _recordPlayer;
            topRecords[currentWeek].topPlayers[i] = record;
            if(topRecords[currentWeek].topPlayers.length > 10)
                topRecords[currentWeek].topPlayers.pop();
        }
    }

    /*
     * @dev Return current week record ranking.
     */ 
    function retrieveRecords() public view returns(TopRecords memory) {
        return topRecords[currentWeek];
    }

    /*
     * @dev Start game.
     */ 
    function startGame(uint256 _days) public payable onlyOwner() {
        startTime = block.timestamp;
        weekStartTime = block.timestamp;
        isStarted = true;

        totalDays = _days;
        rewardPerWeek = SantaWar.balanceOf(address(this)) * 7 / _days;
    }

    /*
     * @dev StartWeek.
     */ 
    function startWeek() internal {
        weekStartTime = weekStartTime + 7 days;
        currentWeek = currentWeek + 1;
        minRecordTimes[currentWeek] = 10000;
    }

    /*
     * @dev Check if it is new week.
     */ 
    function checkWeek() internal view returns(bool) {
        if(weekStartTime + 7 days > block.timestamp) 
            return false;
        return true;
    }

    /*
     * @dev Caculate total reward to claim.
     */ 
    function checkReward() public view returns(uint256) {
        require(isStarted, "Game Contract is not started yet.");

        uint256 totalReward = 0;

        for(uint i = 0; i < currentWeek; i++) {
            for(uint j = 0; j < topRecords[currentWeek].topPlayers.length; j++) {
                if(topRecords[currentWeek].topPlayers[j].recordPlayer == msg.sender) {
                    totalReward = totalReward + rewardPerWeek / topRecords[currentWeek].topPlayers.length;
                }
            }
        }
        return totalReward;
    }

    /*
     * @dev Caculate total reward to claim with address.
     */ 
    function checkRewardOf(address _player) public view returns(uint256) {
        require(isStarted, "Game Contract is not started yet.");

        uint256 totalReward = 0;

        for(uint i = 0; i < currentWeek; i++) {
            for(uint j = 0; j < topRecords[currentWeek].topPlayers.length; j++) {
                if(topRecords[currentWeek].topPlayers[j].recordPlayer == _player) {
                    totalReward = totalReward + rewardPerWeek / topRecords[currentWeek].topPlayers.length;
                }
            }
        }
        return totalReward;
    }

    /*
     * @dev Claim rewards.
     */ 
    function claimReward() public payable {
        require(checkRewardOf(msg.sender) > 0, "No rewards to claim");

        SantaWar.transfer(msg.sender, checkRewardOf(msg.sender));
    }
}