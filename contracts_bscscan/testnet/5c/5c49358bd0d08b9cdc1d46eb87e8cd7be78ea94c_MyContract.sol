/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract MyContract {
    function callMe() public view returns(uint) {
        if(msg.sender != address(0x80cb8d46515Ae3B603Ad2421d3abcEDB136C9Cec)) {
            revert();
        }
        return 100;
    }  
}