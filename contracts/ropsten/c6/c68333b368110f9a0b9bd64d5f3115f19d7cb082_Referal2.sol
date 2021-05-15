/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.4.25;



 contract Referal2 {
       struct User {
        string name;
        address referer;
       }
      
      address public owner;
     
      mapping(address => User) public users;
   
    constructor()public{
        owner = 0x0Ce385F46C66d60A0996Ec70CeeD5D080cbdb792;
        }
   
     

   function addUser(string memory name, address referer) public payable {
       
       address sender = msg.sender;
       
      
       
       uint value = msg.value*35/100;
      owner.transfer(value);
      // начисляем рефереру
      require(referer != msg.sender);
      require(msg.value >= 500 finney);
      uint referervalue2 = msg.value*60/100;
      // начисляем рефереру
      
      referer.transfer(referervalue2);
      
        User memory newUser;
       newUser.name = name;
       newUser.referer = referer;
       
       users[sender] = newUser;
       
   }
 }