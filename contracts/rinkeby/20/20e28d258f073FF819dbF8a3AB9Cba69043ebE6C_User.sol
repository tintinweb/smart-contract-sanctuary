/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.4;

// create contract named BankAccount
contract BankAccount  {
     // address type variable called owner   
     address owner;
     // constructor: called at the intialization of the contract
      constructor() public {
        // save the persons address that deployed the contract into the owner variable
       owner=msg.sender;
    }
    // Access modifer by the name of onlyOwner
    modifier onlyOwner{
        // check to see if the invoker of the fucntion is the owner
        require(msg.sender==owner,"You are not the owner");
        // the fucntion that uses the modifer, it's code goes in place of the _
        _;
    }
}
// create contract named PersonalAccount and make BankAccount contract its Parent
contract PersonalAccount is BankAccount{
    // Minimum limit to Withdraw in Wei
    uint256 limit = 100000000000000000; // 0.1 ether in Wei
    // Decalaring the Deposit and Withdraw event , indexed keyword will help filter the logs
    event Deposit(address indexed from,uint256 amount);
    event Withdraw(address indexed to,uint256 amount);
    // functionn to withdraw the funcds  
    function withdraw(uint256 amount) public payable {
        // check if sent amount is less than 0.1 ether
        require(amount>=limit,"Not enough Balance");
        // send the amount to the invoker of the function and store result in success variable
        (bool success, ) = payable(msg.sender).call{
            value: amount
        }("");
        // check if the amount was successfully sent
        require(success);
        // trigger/emit the Withdraw event above
        emit Withdraw(msg.sender,msg.value);
    }    
    // functionn to deposit the funcds 
    function deposit() public payable {
        // Makes sure the user deposits some amount 
        require(msg.value>0,"Amount to deposit cannot be zero");
        // trigger/emit the Deposit event above
        emit Deposit(msg.sender, msg.value);
    }  
}
// create contract named User and make PersonalAccount contract its Parent
contract User is PersonalAccount {
    // function to deconstruct the Smart contract 
    function deconstruct() public onlyOwner{
        // after invoked , each transaction will be sucessfull but will do nothing
        selfdestruct(payable(owner));
    }
}