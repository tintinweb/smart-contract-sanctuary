/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.5;


contract Calculator {
  uint256 public calculateResult;
  address public user;
  address public calculator;
  uint256 public operations;

  event Calculate(address msgSender, uint256 a, uint256 b);

  function add(uint256 a, uint256 b) public returns (uint256) {
    calculateResult = a + b;
    operations = operations + 1;
    user = msg.sender;
    emit Calculate(user, a, b);
    return calculateResult;
  }
}