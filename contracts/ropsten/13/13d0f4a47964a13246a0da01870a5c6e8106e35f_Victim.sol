pragma solidity ^0.4.25;

contract Victim {

  mapping (address => uint) public balances;

  function Victim() payable {
    deposit();
  }

  function deposit() payable {
    balances[msg.sender] += msg.value;
  }

  function withdraw(address _receiver) payable {

    require (balances[_receiver] > 0);

    if (! _receiver.call.value(balances[_receiver])()) {
      throw;
    }  
    
      balances[_receiver] = 0;
  }

  function getBalance (address _receiver) public constant returns(uint) {
    return balances[_receiver];
  }
  

  function() {
    throw;
  }
}