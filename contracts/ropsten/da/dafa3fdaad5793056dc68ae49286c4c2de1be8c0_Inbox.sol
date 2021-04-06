/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.5.2;

contract Inbox{

    string public message;
    int256 public number;
    
    //**Constructor** must be defined using “constructor” keyword
    
    //**In version 0.5.0 or above** it is **mandatory to use “memory” keyword** so as to 
    //**explicitly mention the data location**
    
    //you are free to remove the keyword and try for yourself

     constructor (string memory initialMessage,int256 newNumber ) public{
        message=initialMessage;
        number = newNumber;
     }
    
     function setMessage(string memory newMessage)public{
        message=newMessage;
     }

     function getMessage()public view returns(string memory){
        return message;
     }
     
     
     function setNumber(int256 newNumber) public {
        number = newNumber;
     }
     
     function setAdd(int256 newNumber) public {
        number += newNumber;
     }
     
     function setSub(int256 newNumber) public {
        number -= newNumber;
     }
     
    //  function allowance(address _owner, address _spender) public view returns (uint256){
    //       return allowed[_owner][_spender];
    //  }
}