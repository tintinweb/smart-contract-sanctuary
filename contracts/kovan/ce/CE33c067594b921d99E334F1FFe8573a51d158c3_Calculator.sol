/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.8.5;

contract Calculator {
  uint256 public caclulateResult;
  address public user;
  uint256 public addCount;

  event Add(uint256 a, uint256 b);

  function add(uint256 a, uint256 b) public returns (uint256) {
    caclulateResult = a + b;
    user = msg.sender;
    addCount += 1;

    emit Add(a, b);

    return caclulateResult;
  }
}