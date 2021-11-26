/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract Graph {

    event deposit(address indexed user, uint256 amount);
    event withdraw(address indexed user, uint256 amount);
    
  struct UserInfo {
        uint256 amount;
        uint lastdeposittime;
        }

    uint public TotalbalanceReceived;
    uint public balancenow;
    uint public lockedUntil;
    mapping(address => UserInfo) public userInfo;
    function Deposit() public payable {
        UserInfo storage user = userInfo[msg.sender];
        balancenow += msg.value;
        user.amount += msg.value;
        TotalbalanceReceived += msg.value;
        user.lastdeposittime = block.timestamp;
        lockedUntil = block.timestamp + 60 minutes; 
        emit deposit(msg.sender, msg.value);
    }
    
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    function getUserBalance() public view returns (uint) {
    UserInfo storage user = userInfo[msg.sender];
    return user.amount;
    }
    function Withdraw() public {
     if(lockedUntil < block.timestamp)
        {
        address payable to = payable(msg.sender);
        balancenow -= getUserBalance();
        to.transfer(getUserBalance());
        UserInfo storage user = userInfo[msg.sender];
        user.amount -= getUserBalance();
        emit withdraw(msg.sender, user.amount);
        }
    }
}