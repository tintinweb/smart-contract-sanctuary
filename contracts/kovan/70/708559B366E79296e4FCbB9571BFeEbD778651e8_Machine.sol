/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.8.5;

contract Machine {
    uint256 public result;
    address public userAddress;
    uint256 public addCount;
    address public calculatorAddress;
    
    function addValuesWithDelegateCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
        calculatorAddress = calculator;
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        return abi.decode(result, (uint256));
    }
    
    function addValuesWithCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
        calculatorAddress = calculator;
        (bool success, bytes memory result) = calculator.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        return abi.decode(result, (uint256));
    }
}