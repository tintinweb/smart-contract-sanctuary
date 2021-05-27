/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract EtherUnits {
    uint public oneWei = 1 wei;
    bool public isOneWei = 1 wei == 1;
    
    uint public oneEther = 1 ether;
    bool public isOneEther = 1 ether == 1e18;
}