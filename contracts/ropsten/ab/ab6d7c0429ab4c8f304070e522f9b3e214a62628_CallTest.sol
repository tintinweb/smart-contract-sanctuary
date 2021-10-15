/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract CallTest {
    function testOne(address nameReg) external view returns (bool) {
        bytes memory payload = abi.encodeWithSignature("register(string)", "MyName");
        (bool success, bytes memory returnData) = nameReg.staticcall(payload);
        returnData;
        require(success);
        return success;
    }
    
    function testTwo(address nameReg) external returns (bool) {
        bytes memory payload = abi.encodeWithSignature("register(string)", "MyName");
        (bool success, bytes memory returnData) = nameReg.delegatecall(payload);
        returnData;
        require(success);
        return success;
    }
    
    function testThree(address nameReg) external returns (bool) {
        bytes memory payload = abi.encodeWithSignature("register(string)", "MyName");
        (bool success, bytes memory returnData) = nameReg.call(payload);
        returnData;
        require(success);
        return success;
    }
}