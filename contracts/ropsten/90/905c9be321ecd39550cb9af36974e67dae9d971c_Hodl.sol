/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.8.4;

//let you define a time of lock and deposit your token during that time
//you will not be able to withdraw them before the time of unlock

contract Hodl {
    
    
    address public owner;
    uint public balance;
    uint public timeOfUnlock;
    
    event fundsWithdrawn(uint balance, uint time);
    event fundsDeposited(uint amount, uint time);
    
    modifier isOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier isTimeOfUnlockNull {
        require(timeOfUnlock == 0);
        _;
    }
    
    modifier isTimeToDeposit {
        require(block.timestamp < timeOfUnlock);
        _;
    }
    
    modifier isTimeToWithdraw {
        require((block.timestamp > timeOfUnlock) && (timeOfUnlock != 0));
        _;
    }
    
    constructor () {
        owner = msg.sender;
    }
    
    function setTimeOfLock(uint time) isOwner isTimeOfUnlockNull public {
        timeOfUnlock = block.timestamp + time;
    }
    
    function deposit() isOwner isTimeToDeposit external payable {
        balance += msg.value;
        emit fundsDeposited(msg.value, block.timestamp);
    }
    
    function withdraw() isOwner isTimeToWithdraw public {
        payable(msg.sender).transfer(balance);
        emit fundsWithdrawn(balance, block.timestamp);
        balance = 0;
        timeOfUnlock = 0;
    }
    
}