// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

import './console.sol';

contract mohaCaller is console{
    function checkAvalable(address calculator,string memory methodName) public returns (uint256) {
    
     bool ss;
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature(methodName));
     ss = success;
       log("result", abi.decode(result, (uint256)));
        return abi.decode(result, (uint256));
    }
    
}