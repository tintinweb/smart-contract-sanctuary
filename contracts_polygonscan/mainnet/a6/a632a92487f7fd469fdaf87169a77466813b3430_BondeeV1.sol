/**
 *Submitted for verification at polygonscan.com on 2021-10-07
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
    
    // MODIFIERS
    modifier HasReward {
        require(RewardOwed(msg.sender) > 0, "No reward is owed.");
        _;
    }

    modifier MinOneGwei {
        require(msg.value >= 1 gwei, "Message value must be at least one gwei.");
        _;
    }
    
    modifier OnlyOwner {
        require(msg.sender == dev, "Only the owner can call this function.");
        _;
    }
    
    // FUNCTIONS
    function BuyBonds() public payable MinOneGwei {
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
            userLastTXN[msg.sender] = uint(block.timestamp);
        } else if (CheckForMultiplier() == true) {
            userBonds[_address] += amount * uint(currentMultiplier);
            totalBonds += amount * uint(currentMultiplier);
            userLastTXN[msg.sender] = uint(block.timestamp);
        }
    }

    function ClaimReward() public HasReward {
        if (RewardOwed(msg.sender) <= address(this).balance) {
            payable(msg.sender).transfer(RewardOwed(msg.sender));
            totalReturn[msg.sender] += RewardOwed(msg.sender);
            userLastTXN[msg.sender] = uint(block.timestamp);
        } else if (RewardOwed(msg.sender) > address(this).balance) {
            payable(msg.sender).transfer(address(this).balance);
            totalReturn[msg.sender] += uint(address(this).balance);
            userLastTXN[msg.sender] = uint(block.timestamp);
        }
    }

    function CompoundReward() public {
        if (RewardOwed(msg.sender) <= address(this).balance) {
            MintBonds((Percent(RewardOwed(msg.sender), 10500)), msg.sender);
        } else if (RewardOwed(msg.sender) > address(this).balance) {
            MintBonds((Percent(address(this).balance, 10500)), msg.sender);
        }
    }
    
    function SetMultiplier(uint multiplier, uint secondsToRun) public OnlyOwner {
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

    function ViewRewardOwed() public view returns(uint) {
        return RewardOwed(msg.sender);
    }

    function ViewMyBonds() public view returns(uint) {
        return userBonds[msg.sender];
    }

    function ViewTotalBonds() public view returns(uint) {
        return totalBonds;
    }

    function ViewContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function ViewTotalInvested() public view returns (uint) {
        return totalInvested[msg.sender];
    }

    function ViewTotalReturn() public view returns (uint) {
        return totalReturn[msg.sender];
    }

    function ViewDailyROI() public view returns (uint) {
        return RewardPerSecond(msg.sender) * 86400;
    }

    function Percent(uint number, uint bp) internal pure returns (uint) {
        return number * bp / 10000;
    }
    
    function ViewMultiplier() public view returns (uint) {
        return currentMultiplier;
    }

}