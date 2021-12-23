/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

/*, __              _                           ___                                     
 /|/  \o           | |       |                 / (_)                                    
  | __/    ,_  _|_ | |     __|   __,          |      __   _  _  _|_  ,_    __,   __ _|_ 
  |   \|  /  |  |  |/ \   /  |  /  |  |   |   |     /  \_/ |/ |  |  /  |  /  |  /    |  
  |(__/|_/   |_/|_/|   |_/\_/|_/\_/|_/ \_/|/   \___/\__/   |  |_/|_/   |_/\_/|_/\___/|_/
                                         /|
                                         \|*/
// SPDX-License-Identifier: MIT
// www.florianbuchner.com
pragma solidity ^0.7.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BirthdayContract {
    struct BirthdayEntry {
        uint256 timestamp;
        uint256 amount;
    }

    event Deposit(address d_address, uint256 amount, uint256 timestamp);
    event Withdraw(address w_address, uint256 amount);

    IERC20 ierc20;

    mapping (address => BirthdayEntry[]) public tokens;

    using SafeMath for uint256;

    constructor(address coin) {
        require(coin != address(0));
        ierc20 = IERC20(coin);
    }

    // Needs approval first
    function depositToken(uint256 amount, address receiver, uint256 timestamp) public {
        require(amount > 0);
        if (!ierc20.transferFrom(msg.sender, address(this), amount)) revert();
        tokens[receiver].push(BirthdayEntry(timestamp, amount));
        emit Deposit(receiver, amount, timestamp);
    }

    function withdrawToken() public returns (uint256) {
        uint256 amount = 0;
        BirthdayEntry[] memory entries = tokens[msg.sender];
        for (uint i = 0; i < entries.length; i++) {
            if (block.timestamp >= entries[i].timestamp) {
                amount = amount.add(entries[i].amount);
                tokens[msg.sender][i].amount = 0;
            }
        }
        require(amount > 0);
        if (!ierc20.transfer(msg.sender, amount)) revert();
        emit Withdraw(msg.sender, amount);
        return amount;
    }

    function totalBalanceOf(address user) public view returns (uint256) {
        return balanceOf(user, false);
    }

    function currentBalanceOf(address user) public view returns (uint256) {
        return balanceOf(user, true);
    }

    function balanceOf(address user, bool untilNow) private view returns (uint256) {
        uint256 result = 0;
        BirthdayEntry[] memory entries = tokens[user];
        for (uint i = 0; i < entries.length; i++) {
            if (!untilNow || block.timestamp >= entries[i].timestamp) {
                result = result.add(entries[i].amount);
            }
        }
        return result;
    }

    function nextWithdrawal(address user, uint256 from) public view returns (uint256, uint256) {
        uint256 upcommingTimestamp = uint256(-1);
        uint256 previousAmount = 0;
        uint256 upcomingAmount = 0;
        BirthdayEntry[] memory entries = tokens[user];
        for (uint i = 0; i < entries.length; i++) {
            uint256 timestamp = entries[i].timestamp;
            uint256 amount = entries[i].amount;
            if (amount == 0)
                continue;
            if (timestamp < from) {
                previousAmount = previousAmount.add(amount);
            }
            else if (timestamp == upcommingTimestamp) {
                upcomingAmount = upcomingAmount.add(amount);
            }
            else if (timestamp < upcommingTimestamp) {
                upcommingTimestamp = timestamp;
                upcomingAmount = amount;
            }
        }
        return (upcommingTimestamp, previousAmount.add(upcomingAmount));
    }
}

library SafeMath {
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