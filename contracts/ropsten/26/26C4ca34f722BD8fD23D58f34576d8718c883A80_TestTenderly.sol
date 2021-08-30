/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract TestTenderly {
    function testNoError() external  {}
    
    function testError() external {
        revert("Fail");
    }
}