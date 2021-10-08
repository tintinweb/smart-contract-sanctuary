/**
 *Submitted for verification at polygonscan.com on 2021-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract BondeeV1 {
    
    // GLOBAL VARIABLES
    address internal dev;
    uint internal totalBonds;
    uint internal multiplierEndTime;
    uint internal currentMultiplier;
    mapping (address => uint) internal totalInvested;
    mapping (address => uint) internal totalReturn;
    mapping (address => uint) internal userBonds;
    mapping (address => uint) internal userLastTXN;
    mapping (address => bool) internal hasBonds;

    // CONSTRUCTOR
    constructor() {
        dev = msg.sender;
    }
    
    // FUNCTIONS
    function BuyBonds() public payable {
        require(msg.value >= 1 gwei, "Message value must be at least one gwei.");
        if (hasBonds[msg.sender] == true) {
            PayDevFee(msg.value);
            MintBonds(msg.value + RewardOwed(msg.sender), msg.sender);
            totalInvested[msg.sender] += msg.value;
        } else if (hasBonds[msg.sender] == false) {
            PayDevFee(msg.value);
            MintBonds(msg.value, msg.sender);
            totalInvested[msg.sender] += msg.value;
            hasBonds[msg.sender] = true;
        }
    }

    function MintBonds(uint amount, address _address) internal {
        if(CheckForMultiplier() == false) {
            userBonds[_address] += amount;
            totalBonds += amount;
            userLastTXN[_address] = uint(block.timestamp);
        } else if (CheckForMultiplier() == true) {
            userBonds[_address] += amount * uint(currentMultiplier);
            totalBonds += amount * uint(currentMultiplier);
            userLastTXN[_address] = uint(block.timestamp);
        }
    }

    function ClaimReward(address _address) public {
        require(RewardOwed(_address) > 0, "No reward is owed.");
        if (RewardOwed(_address) <= address(this).balance) {
            payable(_address).transfer(RewardOwed(_address));
            totalReturn[_address] += RewardOwed(_address);
            userLastTXN[_address] = uint(block.timestamp);
        } else if (RewardOwed(_address) > address(this).balance) {
            payable(_address).transfer(address(this).balance);
            totalReturn[_address] += uint(address(this).balance);
            userLastTXN[_address] = uint(block.timestamp);
        }
    }

    function CompoundReward(address _address) public {
        if (RewardOwed(_address) <= address(this).balance) {
            MintBonds((Percent(RewardOwed(_address), 10500)), _address);
        } else if (RewardOwed(_address) > address(this).balance) {
            MintBonds((Percent(address(this).balance, 10500)), _address);
        }
    }
    
    function SetMultiplier(uint multiplier, uint secondsToRun) public {
        require(msg.sender == dev, "Only the owner can call this function.");
        currentMultiplier = multiplier;
        multiplierEndTime = uint(block.timestamp) + secondsToRun;
    }
    
    function CheckForMultiplier() public view returns(bool isActive) {
        if(multiplierEndTime >= block.timestamp) {
            return true;
        } else if(multiplierEndTime < block.timestamp) {
            return false;
        }
    }
    
    function MultiplierMessage() public view returns (string memory message) {
        if(CheckForMultiplier() == false) {
            return "Multiplier is not active.";
        } else if(CheckForMultiplier() == true) {
            return "Multiplier is currently active!";
        }
    }

    function RewardPerSecond(address _address) internal view returns(uint) {
        return (((Percent(address(this).balance, 500) * userBonds[_address])) / totalBonds) / 86400;
    }

    function RewardOwed(address _address) internal view returns(uint) {
        return RewardPerSecond(_address) * ElapsedSeconds(_address);
    }

    function ElapsedSeconds(address _address) internal view returns(uint) {
        return block.timestamp - userLastTXN[_address];
    }

    function PayDevFee(uint amount) internal {
        payable(dev).transfer(Percent(amount, 500)); // 500 bp = 5%
    }

    function ViewRewardOwed(address _address) public view returns(uint) {
        return RewardOwed(_address);
    }

    function ViewMyBonds(address _address) public view returns(uint) {
        return userBonds[_address];
    }

    function ViewTotalBonds() public view returns(uint) {
        return totalBonds;
    }

    function ViewContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function ViewTotalInvested(address _address) public view returns (uint) {
        return totalInvested[_address];
    }

    function ViewTotalReturn(address _address) public view returns (uint) {
        return totalReturn[_address];
    }

    function ViewDailyROI(address _address) public view returns (uint) {
        return RewardPerSecond(_address) * 86400;
    }

    function Percent(uint number, uint bp) internal pure returns (uint) {
        return number * bp / 10000;
    }
    
    function ViewMultiplier() public view returns (uint) {
        return currentMultiplier;
    }

}