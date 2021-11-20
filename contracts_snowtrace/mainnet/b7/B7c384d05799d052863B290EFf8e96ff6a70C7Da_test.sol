/**
 *Submitted for verification at snowtrace.io on 2021-11-19
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract test {
    function testing(address spender, uint256 amount) public {
        address payable token = payable(0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b);
        token.call(abi.encodeWithSignature("approve(address spender, uint256 amount)", spender, amount));
    }    
}