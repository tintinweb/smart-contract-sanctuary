/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// import "./Storage.sol";

contract Machine {
    // Storage public s;
    
    uint256 public calculateResult;
    
    address public user;
  
    event AddedValuesByDelegateCall(uint256 a, uint256 b, bool success);
    event AddedValuesByCall(uint256 a, uint256 b, bool success);
    
    // constructor(Storage addr) {
    //     calculateResult = 0;
    // }

    
    function addValuesWithDelegateCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByDelegateCall(a, b, success);
        // user = msg.sender;
        return abi.decode(result, (uint256));
    }
    
    function addValuesWithCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
        (bool success, bytes memory result) = calculator.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByCall(a, b, success);
        // user = msg.sender;
        return abi.decode(result, (uint256));
    }
}