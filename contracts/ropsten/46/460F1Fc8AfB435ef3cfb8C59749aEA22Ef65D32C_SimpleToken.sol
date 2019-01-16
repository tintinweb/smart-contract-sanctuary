pragma solidity ^0.5.0;

contract SimpleToken {
  mapping (address => uint) vault;

  function getMore() public {
    vault[msg.sender] += 10000;
  }

  function give(address to, uint amount) public {
    // check?
    vault[to] += amount;
    vault[msg.sender] -= amount;
  }

  function check() public view returns(uint) {
    return vault[msg.sender];
  }
}