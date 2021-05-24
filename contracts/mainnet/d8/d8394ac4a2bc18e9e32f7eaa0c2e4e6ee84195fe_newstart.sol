/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.4.25;



 contract newstart {
     
       struct User {
        
       address referer;
       address referer2;
       address diler;
       }
      
       address public owner;
      address public ambassador;
      
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     event ambassadorshipTransferred(address indexed previousambassador, address indexed newambassador);
      mapping(address => User) public users;
      
     constructor()public{
        owner = msg.sender;
        ambassador = 0x2F6Cf50b71d71faFE45887F89ab3EA39ac1F5145;
        }
        
         modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
      function transferambassador(address newambassador) public onlyOwner {
    require(newambassador != address(0));
    emit ambassadorshipTransferred(ambassador, newambassador);
    ambassador = newambassador;
  }
      
     function addUser(address referer, address referer2, address diler) public payable {
       
       address sender = msg.sender;
        uint value = msg.value*42/100;
      ambassador.transfer(value);
       require(referer != msg.sender);
      require(referer2 != msg.sender);
      require(diler != msg.sender);
      require(msg.value >= 500 finney);
      require(msg.value <= 550 finney);
      uint referervalue = msg.value*30/100;
      referer.transfer(referervalue);
      uint referer2value = msg.value*20/100;
      referer2.transfer(referer2value);
      uint dilervalue = msg.value*5/100;
      diler.transfer(dilervalue);
      
       User storage newUser;
       
       newUser.referer = referer;
       newUser.referer2 = referer2;
       newUser.diler = diler;
        users[sender] = newUser;   
       }
    }