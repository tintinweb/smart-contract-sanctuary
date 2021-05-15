/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.4.25;


contract Ownable  {
   
    address public owner;
   
   

    constructor() public {
        owner = 0xe32BA03860564aC6ebfC13658CdC7827FBC72078;
      
    }
    
    
   
    function () public payable{
        uint value = msg.value*35/100;
    
        owner.transfer(value);
        
        
       
    }
}



 
 contract Referal is Ownable {
       struct User {
        string name;
        address referer;
        
       }
       
      address public referer;
      
   mapping(address => User) public users;
   
    constructor()public{
       
   }
   
   

   function addUser(string memory name, address referer) public {
       address sender = msg.sender;
      
       
       User memory newUser;
       newUser.name = name;
       newUser.referer = referer;
       
       
      users[sender] = newUser;
      
   
   }
   
   
   
    function () public payable{
      address referer = referer;
      uint value2 = msg.value*60/100;
      // начисляем рефереру
      referer.transfer(value2);
    }
   }