/**
 *Submitted for verification at BscScan.com on 2021-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract EtherUnits {
    uint public oneWei = 1 wei;
    // 1 wei is equal to 1
    bool public isOneWei = 1 wei == 1;

    uint public oneEther = 1 ether;
    // 1 ether is equal to 10^18 wei
    bool public isOneEther = 1 ether == 1e18;
}