/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.5.0;


contract ProfitSplitter {
    address payable user1;
    address payable user2;
    address payable user3;

// Defining constructor function to accept 3 employees and avoid hardcoding of account addresses.
    constructor(address payable _one, address payable _two, address payable _three) public {
        user1 = _one;
        user2 = _two;
        user3 = _three;
    }

// Function to check the balance.  Should always be 0 due to returning leftover amounts to the sending address.
    function balance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        uint amount = msg.value / 3;
        uint total;
        total += amount;
        user1.transfer(amount);
        
        total += amount;
        user2.transfer(amount);
        
        total += amount;
        user3.transfer(amount);
        
        address payable sender = msg.sender;
        sender.transfer(msg.value - total);// send remaining wei back to sender
    }

// Deining a fallback function to accept deposits from external accounts. 
    function() external payable {
        deposit();
    }
}