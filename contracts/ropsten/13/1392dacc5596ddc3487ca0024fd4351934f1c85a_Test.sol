pragma solidity ^0.4.18;

contract Test {

  address public owner;
  uint public prize;
  mapping(address => uint) public balances;

  function Test() {
    owner = msg.sender;
  }

  function test1() constant public returns (address) {
    return owner;
  }
  
  function test2(uint p) public {
      prize += p;
  }
  
  function test3() public payable {
      balances[msg.sender] += msg.value;
  }
  
  function kill() public {
      owner.send(address(this).balance);
  }
  
  function () payable {
      balances[msg.sender] += msg.value;
  }
}