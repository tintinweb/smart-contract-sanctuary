pragma solidity ^0.4.24;

contract ReceivingSample {
  mapping(address => uint256) deposits;
  
  constructor() public {}
  
  function tokenFallback(address _from, uint _value, bytes _data) public {
    deposits[_from] += _value; 
  }
  
  function getDepositBalance(address _from) public view returns (uint256) {
    return deposits[_from];
  }
}