/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.5.0;

contract mywallet {
    
    uint balance;
    address owner = msg.sender;
   
    
    //function to fetch the value 
    function getBalance() public view returns(uint){
        return balance;
    }
    
    // function to update the getBalance
    function setBalance(uint _depositAmount) public{
        balance = balance + _depositAmount;
    }
    
     modifier restricted() {
    require(
      msg.sender != owner,
      "This function is restricted to the contract's owner"
    ) ;
     _;}
    
    function withdraw(uint _withdrawalAmount) public restricted{
        balance = balance - _withdrawalAmount;
    }
   
    
    
    
}

//problem statements
// implement a function so that you can withdraw balance from the myWallet
// implement the changes in the code only the owner can withdraw from the walle