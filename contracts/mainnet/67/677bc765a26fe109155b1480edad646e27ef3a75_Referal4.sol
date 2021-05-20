/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.4.25;



 contract Referal4 {
       struct User {
        string name;
        address referer;
       }
      
      address public owner;
     
      mapping(address => User) public users;
   
    constructor()public{
        owner = 0xd19C451329fe90D6F9d3c60fCb5b59e2197fe067;
        }
   
     

   function addUser(string memory name, address referer) public payable {
       
       address sender = msg.sender;
       
      
       
       uint value = msg.value*5/100;
      owner.transfer(value);
      // начисляем рефереру
      require(referer != msg.sender);
      
     
      uint referervalue2 = msg.value*90/100;
      // начисляем рефереру
      
      referer.transfer(referervalue2);
      
        User memory newUser;
       newUser.name = name;
       newUser.referer = referer;
       
       users[sender] = newUser;
       
   }
 }