/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.8.5;

contract Machine {
    uint256 public results;
    address public sender;
    uint256 public addCount;
    address public calculator_address;

    event AddedValuesByDelegateCall(uint256 a, uint256 b, bool success);
    event AddedValuesByCall(uint256 a, uint256 b, bool success);

    function addValuesWithDelegateCall(address calculator, uint256 a, uint b) public returns (uint256) {
        calculator_address = calculator;
        (bool success, bytes memory result) = calculator_address.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByDelegateCall(a, b, success);
        return abi.decode(result, (uint256));
    }

    function addValuesWithCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
        calculator_address = calculator;
        (bool success, bytes memory result) = calculator_address.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByCall(a, b, success);
        return abi.decode(result, (uint256));
    }
}