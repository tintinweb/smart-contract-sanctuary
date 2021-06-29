/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.8.5;

contract Machine {
  uint256 public calculateResult;
  uint256 public addActionCount;
  address public user;

  function addVaulesWithDelegateCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
    (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
    return abi.decode(result, (uint256));
  }

  function addValuesWithCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
    (bool success, bytes memory result) = calculator.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
    return abi.decode(result, (uint256));
  }
}