/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.8.4;

contract Hodl {
    
    
    address owner;
    uint period;
    uint balance;
    uint dateOfDeposit;
    
    modifier isOwner {
        require(msg.sender == owner);
        _;
    }
    
    error balanceNotNull();
    error dateTooEarly();
    
    
    constructor () {
        owner = msg.sender;
    }
    
    //we can only deposit one at the time
    function deposit(uint _period) isOwner external payable {
        require (balance == 0);
        dateOfDeposit = block.timestamp;
        period = _period;
        balance = msg.value;
    }
    
    function withdraw() isOwner public {
        require (block.timestamp >= dateOfDeposit + period);
        payable(msg.sender).transfer(balance);
    }
    
    function showInfo() public returns(uint, uint) {
        return (balance, dateOfDeposit+period);
    }

    
}