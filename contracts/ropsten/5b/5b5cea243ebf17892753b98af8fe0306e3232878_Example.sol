pragma solidity ^0.4.24;

/*

  This is just a very simple example contract used to demonstrate the GasBoy broadcasting transactions on its behalf

*/


contract Example {

  constructor() public { }

  //it keeps a count to demonstrate stage changes
  uint public count = 0;

  //it can receive funds
  function () payable { emit Received(msg.sender, msg.value); }
  event Received (address indexed sender, uint value);

  //and it can add to a count
  function addAmount(uint256 amount) public returns (bool) {
    count = count + amount;
    return true;
  }
}