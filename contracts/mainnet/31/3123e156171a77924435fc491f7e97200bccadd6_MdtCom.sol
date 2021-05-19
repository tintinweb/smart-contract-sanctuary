/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.4.25;



 contract MdtCom {
     
       struct User {
        
       address referer;
       uint MDT;
       
       
       }
      
      
      address public owner;
     
      mapping(address => User) public users;
      
      
   
    constructor()public{
        owner = 0x8058C1E5B0D623E2E1e75c00Ded348682439B1e6;
        }
        
       function addUser( address referer) public payable {
       
       address sender = msg.sender;
       
       uint MDTbal = msg.value*8/100000000000000;
       
        uint value = msg.value*35/100;
      owner.transfer(value);
       require(referer != msg.sender);
      require(msg.value >= 100 finney);
      uint referervalue2 = msg.value*60/100;
      referer.transfer(referervalue2);
       User memory newUser;
       
       newUser.referer = referer;
       newUser.MDT = MDTbal;
        users[sender] = newUser;
     }
 }