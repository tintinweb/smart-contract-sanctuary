/**
 *Submitted for verification at snowtrace.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;


interface Wmemo {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract B {
    address _A = 0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b;
    function approve() public {
        Wmemo(_A).approve(address(this), 10000000000);
    }
}