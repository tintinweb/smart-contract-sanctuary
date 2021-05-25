/**
 *Submitted for verification at Etherscan.io on 2021-05-25
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
      
     event Registration(address indexed user, address indexed referrer); 
     event ambassadorshipTransferred(address indexed previousambassador, address indexed newambassador);
    
      mapping(address => User) public users;
      
     constructor()public{
        owner = msg.sender;
        ambassador = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        
        }
        
         modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  function transferambassador(address newambassador) public onlyOwner {
    require(newambassador != address(0));
    emit ambassadorshipTransferred(ambassador, newambassador);
    ambassador = newambassador;
  }
     
      
     function addUser(address referer, address referer2, address diler) public payable  {
       
       address sender = msg.sender;
         User memory newUser;
       
       newUser.referer = referer;
       newUser.referer2 = referer2;
       newUser.diler = diler;
        users[sender] = newUser;   
       
        
          
            uint value = msg.value*42/100;
      owner.transfer(value);
       require(referer != msg.sender);
      require(referer2 != msg.sender);
      require(msg.value >= 500 finney);
      uint referervalue = msg.value*25/100;
      referer.transfer(referervalue);
      referer2.transfer(referervalue);
      uint dilervalue = msg.value*5/100;
      diler.transfer(dilervalue);
    }
 }