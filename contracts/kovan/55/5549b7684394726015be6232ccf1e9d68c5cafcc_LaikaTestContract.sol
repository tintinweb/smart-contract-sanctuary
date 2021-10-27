/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LaikaTestContract {
    uint256 number = 0;
    
    function testPayable() external payable {
        number += 1;
    }
    
    function oneValueReturn() external view returns (uint256) {
        return number;
    }
    
    function stringReturn() external pure returns (string memory) {
        return "Hello from Laika!";
    }
    
    function stringWithNameReturn() external pure returns (string memory greeting) {
        return "Hello from Laika!";
    }
    
    function multipleReturn() external view returns (uint256, bool, string memory) {
        return (block.timestamp, true, "hello!");
    }
    
    function testSendTransaction() external {
        number += 1;
    }
    
    function testSendTransaction2() external returns (uint256) {
        number += 1;
        return number;
    }
}