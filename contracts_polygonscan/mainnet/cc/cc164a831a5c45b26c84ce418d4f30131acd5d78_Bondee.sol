/**
 *Submitted for verification at polygonscan.com on 2021-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Bondee {
    
    // GLOBAL VARIABLES
    address internal dev;
    uint internal totalBonds;
    uint internal multiplierEndTime;
    mapping (address => uint) internal totalInvested;
    mapping (address => uint) internal totalReturn;
    mapping (address => uint) internal bondsEarnedFromReferrals;
    mapping (address => uint) internal userBonds;
    mapping (address => uint) internal userLastTXN;
    mapping (address => bool) internal hasBonds;
    mapping (address => address) internal userReferredBy;

    // CONSTRUCTOR
    constructor() {
        dev = msg.sender;
    }
    
    // FUNCTIONS
    function BuyBonds(address referrer) public payable {
        require(msg.value >= 1 gwei, "Message value must be at least one gwei.");
        if (hasBonds[msg.sender] == true) {
            PayDevFee(msg.value);
            MintBonds(msg.value + RewardOwed(msg.sender));
            MintToReferrer(msg.value/10);
            totalInvested[msg.sender] += msg.value;
        } else if (hasBonds[msg.sender] == false) {
            AddReferrer(msg.sender, referrer);
            PayDevFee(msg.value);
            MintBonds(msg.value);
            MintToReferrer(msg.value/10);
            totalInvested[msg.sender] += msg.value;
            hasBonds[msg.sender] = true;
        }
    }
    
    function AddReferrer(address referred, address referrer) internal {
        userReferredBy[referred] = referrer;
    }
    
    function MintToReferrer(uint amount) internal {
        if(userReferredBy[msg.sender] != address(0x0) && userReferredBy[msg.sender] != msg.sender) {
            if(CheckForMultiplier() == false) {
                userBonds[userReferredBy[msg.sender]] += amount;
                totalBonds += amount;
                bondsEarnedFromReferrals[userReferredBy[msg.sender]] += amount;
            } else if (CheckForMultiplier() == true) {
                userBonds[userReferredBy[msg.sender]] += amount * 2;
                totalBonds += amount * 2;
                bondsEarnedFromReferrals[userReferredBy[msg.sender]] += amount *2;
            }
        } else if (userReferredBy[msg.sender] != address(0x0) || userReferredBy[msg.sender] == msg.sender) {
            userBonds[userReferredBy[msg.sender]] += 0;
        }
    }

    function MintBonds(uint amount) internal {
        if(CheckForMultiplier() == false) {
            userBonds[msg.sender] += amount;
            totalBonds += amount;
            userLastTXN[msg.sender] = uint(block.timestamp);
        } else if (CheckForMultiplier() == true) {
            userBonds[msg.sender] += amount * 2;
            totalBonds += amount * 2;
            userLastTXN[msg.sender] = uint(block.timestamp);
        }
    }

    function ClaimReward() public {
        require(RewardOwed(msg.sender) > 0, "No reward is owed.");
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
            MintBonds((Percent(RewardOwed(msg.sender), 10500)));
        } else if (RewardOwed(msg.sender) > address(this).balance) {
            MintBonds((Percent(address(this).balance, 10500)));
        }
    }
    
    function SetMultiplierTime(uint secondsToRun) public {
        require(msg.sender == dev, "Only the owner can call this function.");
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
            return "2x multiplier IS NOT active.";
        } else if(CheckForMultiplier() == true) {
            return "2x multiplier is currently active!";
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
    
    function ViewBondsFromReferrals(address _address) public view returns (uint) {
        return bondsEarnedFromReferrals[_address];
    } 
    
    function ViewReferrer(address _address) public view returns (address) {
        return userReferredBy[_address];
    }

}