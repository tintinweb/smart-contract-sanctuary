pragma solidity ^0.4.10;

contract TokenWithInvariants {
  mapping(address => uint) public balanceOf;
  uint public totalSupply;
  

  modifier checkInvariants {
    _;
    if (this.balance < totalSupply) throw;
  }
  
  constructor() public {
      totalSupply = 0;
  }

  function deposit(uint amount) payable checkInvariants {
    balanceOf[msg.sender] += amount;
    totalSupply += amount;
  }

  function transfer(address to, uint value) checkInvariants {
    if (balanceOf[msg.sender] >= value) {
      balanceOf[to] += value;
      balanceOf[msg.sender] -= value;
      // could have introduced another reentracy bug here?
      // following the example as in withdraw() where there is a check on call()
      to.call.value(value)(); 
    }
  }

  function withdraw() checkInvariants {
    uint balance = balanceOf[msg.sender];
    if (msg.sender.call.value(balance)()) {
      totalSupply -= balance;
      balanceOf[msg.sender] = 0;
    }
  }
  
  function () payable{
      if (msg.value > 0) {
          totalSupply += msg.value;
      }
  }
}