/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

// this is only for testing, i swear

contract XSS {
    function testXSS() external pure returns(string memory) {
        return (unicode"<script>alert('rekt')</script>");
    }
}