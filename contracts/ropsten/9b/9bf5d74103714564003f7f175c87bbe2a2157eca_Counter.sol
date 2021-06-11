/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Counter {

  uint256 public counter = 0;

  event Add(address indexed _address, uint256 _amount);
  event Sub(address indexed _address, uint256 _amount);

  function add() external {
    counter++;

    emit Add(msg.sender, 1);
  }

  function sub() external {
    if (counter > 0) {
      counter--;

      emit Sub(msg.sender, 1);
    }
  }

  function addAmount(uint256 _amount) external returns(uint256) {
    emit Add(msg.sender, _amount);

    return (counter+= _amount);
  }

  function getCounter() external view returns(uint256) {
    return counter;
  }

}