/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.4.25;



 contract EtherCash {
     struct User {
       address One;  
       address fastreferer;
       address secondreferer;
       }
       
       mapping(address => User) public users;
       uint prise = 10 finney;
       address public owner;
       event ownershipTransferred(address indexed previousowner, address indexed newowner);
       event prisetransferred(uint _prise, uint newprise);
  
   constructor()public{
        owner = msg.sender;
        }
        modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
    function transferowner(address newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
   function transferprise(uint newprise) public onlyOwner {
    require(newprise != uint(0));
    emit prisetransferred(prise, newprise);
    prise = newprise;
  }
  
  function Registracion(address One, address fastreferer) public payable {
      address helper = msg.sender;
      address sender = One;
      address secondreferer = users[fastreferer].fastreferer;
      require(One != fastreferer);
      uint value = msg.value*44/100;
      owner.transfer(value);
      require(msg.value >= prise);
      uint referervalue = msg.value*10/100;
      uint sreferervalue = msg.value*5/100;
      uint helpvalue = msg.value*5/100;
      fastreferer.transfer(referervalue);
      secondreferer.transfer(sreferervalue);
      helper.transfer(helpvalue);
       
       User memory newUser;
       newUser.fastreferer = fastreferer;
       newUser.secondreferer = users[fastreferer].fastreferer;
      
       
       users[sender] = newUser;
       
      
  }
 }