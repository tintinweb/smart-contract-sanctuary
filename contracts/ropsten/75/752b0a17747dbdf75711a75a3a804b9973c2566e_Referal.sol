/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.4.25;
 
 
 
 contract Referal {
       struct User {
        string name;
        address referer;
        
       }
       
     
   mapping(address => User) public users;
  
   
   

   function addUser(string memory name, address referer) public {
       address sender = msg.sender;
      
       
       User memory newUser;
       newUser.name = name;
       newUser.referer = referer;
       
       
      users[sender] = newUser;
      
   
   }
   function () public payable{
      address referer = referer;
      uint value = msg.value*45/100;
      // начисляем рефереру
      referer.transfer(value);
    }
   }