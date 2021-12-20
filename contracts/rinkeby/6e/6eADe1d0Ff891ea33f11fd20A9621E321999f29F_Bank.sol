/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank{
    uint bankBalance;

    //finding the balance of the bank
    function getBankBalance() public view returns(uint){
        return bankBalance;
    }

    //assign address and a uint 
    //address == user / uint == value
    //creates a user balance
    mapping(address => uint) public balances;

    // deposit event
    event depositCast(address user, uint amount);

    //withdraw even
    event withdrawCast(address user, uint amount);


    //deposit function
    //connects the function caller to the balances mapping
    //emits the event
    function deposit() public payable{
        balances[msg.sender] += msg.value; // manages user balances 
        bankBalance += msg.value; // manages bank balance 
        emit depositCast(msg.sender, msg.value);
    }
    //emits a withdraw event
    //subtracts the balance of the bank and sends it to the user
    //require the bankbalance to be greater than 0
    function withdraw() public payable{
        require( balances[msg.sender] >= msg.value , "Insufficient funds");
        require(bankBalance >= msg.value);
        bankBalance -= msg.value;
        balances[msg.sender] -= msg.value;

        emit withdrawCast(msg.sender, msg.value);
        
    }


}