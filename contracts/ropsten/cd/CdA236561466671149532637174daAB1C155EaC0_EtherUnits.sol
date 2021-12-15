/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract EtherUnits {
    uint public oneWei = 1 wei;
    //  1 wei = 1
    bool public isOneWei = (1 wei == 1);
    uint public oneEther = 1 ether;
    //  1 ether = 10^18 wei
    bool public isOneEther = (1 ether == 1e18);
}