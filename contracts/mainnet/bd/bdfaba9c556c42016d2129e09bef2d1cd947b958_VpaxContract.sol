pragma solidity ^0.4.18;

contract VpaxContract {

  function VpaxContract(){}

  function transferCoins(address receiver) payable public {
    require(receiver != 0X0);
    require(msg.sender != receiver);
    require(msg.value > 0);
    receiver.transfer(msg.value);
  }
}