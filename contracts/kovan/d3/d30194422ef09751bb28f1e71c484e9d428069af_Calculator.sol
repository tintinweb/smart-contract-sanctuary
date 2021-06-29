/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.8.5;

contract Calculator {
  uint256 public calculateResult;
  uint256 public addActionCount;
  address public user;

  event AddEvent(address txOrigin, address msgSenderAddress, address _this);

  function add(uint256 a, uint256 b) public returns (uint256) {
    calculateResult = a + b;
    addActionCount ++;
    user = msg.sender;
    emit AddEvent(tx.origin, msg.sender, address(this));
    return calculateResult;
  }
}