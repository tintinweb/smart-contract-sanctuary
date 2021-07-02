/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Machine {
    uint public calculateResult;
    uint public addCount;
    address public calculator;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('add(uint,uint)')));

    event AddUsingCall(uint a, uint b, bool success);
    event AddUsingDelegateCall(uint a, uint b, bool success);

    function addUsingCall(address _calculator, uint _a, uint _b) public returns (uint) {
        calculator = _calculator;
        (bool success, bytes memory result) = calculator.call(abi.encodeWithSelector(SELECTOR, _a, _b));
        emit AddUsingCall(_a, _b, success);
        return abi.decode(result, (uint));
    }

    function addusingDelegateCall(address _calculator, uint _a, uint _b) public returns (uint) {
        calculator = _calculator;
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSelector(SELECTOR, _a, _b));
        emit AddUsingDelegateCall(_a, _b, success);
        return abi.decode(result, (uint));
    }
}