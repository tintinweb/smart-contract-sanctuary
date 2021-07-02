/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.8.5;

contract Machine {
  uint256 public caclulateResult;
  address public user;
  uint256 public addCount;
  address public calculator;
  
  function addValuesWithDelegateCall(address _calculator, uint256 a, uint256 b) public returns (uint256) {
    calculator = _calculator;
    (bool success, bytes memory result) = _calculator.delegatecall(abi.encodeWithSignature("add(uint256, uint256)", a, b));
    return abi.decode(result, (uint256));
  }

  function addValuesWithCall(address _calculator, uint256 a, uint256 b) public returns (uint256) {
    calculator = _calculator;
    (bool success, bytes memory result) = _calculator.call(abi.encodeWithSignature("add(uint256, uint256)", a, b));
    return abi.decode(result, (uint256));
  }
}