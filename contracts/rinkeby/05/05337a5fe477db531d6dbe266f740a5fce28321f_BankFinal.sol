/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity ^0.8.3;
contract BankFinal

{
    mapping (address=>uint256) UserAccount; 
    mapping (address=>bool) UserExists;
    
function createAcc() public returns (bool)
{
/*
//if user doesn't exist if(UserExists[msg.sender]==false)
{UserExists[msg.sender]=true;} else
{return true;}
*/
require(UserExists[msg.sender]==false,'User already Exists'); UserExists[msg.sender]=true; return true;
}


function accountExists() public view returns (bool)
{
/*
//To verify that the account exists if(UserExists[msg.sender]==true) return true;
return false;
*/
return UserExists[msg.sender];
}


function deposit() public payable
{
//The one who calls the contract(i.e, msg.sender) deposites the amount (i.e, msg.value) require( (UserExists[msg.sender]==true) && (msg.value > 0) );
UserAccount[msg.sender] = UserAccount[msg.sender] + msg.value;
}


function withdraw(uint256 withdrawAmount) public payable
{
//Account should exist & Amount to be deposited should be greater than 0
require( (UserExists[msg.sender]==true) && (withdrawAmount <UserAccount[msg.sender]) );
UserAccount[msg.sender] = UserAccount[msg.sender] - withdrawAmount;
// Now get that amount withdrawed //Amount withdrawed must be transfered payable(msg.sender).transfer(withdrawAmount);
}


//To check Account Balance in the contaract for a given address(i.e, who calls the contract i.e, msg.sender) 
function accountBalance() public view returns(uint256)
{
return UserAccount[msg.sender];
}


//To transfer Ether amount to a particular given address & update the balance of the contract 
function transferEther(address payable reciever, uint256 transferAmount) public payable
{    require((UserExists[reciever]== true)&&(UserExists[msg.sender]== true)&&(transferAmount>0)); require( transferAmount < UserAccount[msg.sender] );
UserAccount[msg.sender] = UserAccount[msg.sender] - transferAmount;
//Amount withdrawed must be transfered reciever.transfer(transferAmount);
}
}