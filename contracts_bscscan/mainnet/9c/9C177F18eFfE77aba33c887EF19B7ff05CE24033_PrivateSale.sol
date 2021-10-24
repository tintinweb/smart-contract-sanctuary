/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

contract PrivateSale {
    function privateSale(uint amount, BEP20 token, address [] calldata dst) public lock {
        for (uint i; i < dst.length; i++) {
            token.transferFrom(msg.sender,dst[i],amount);
        }
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

interface BEP20 {
    event Transfer(address indexed from, address indexed to, uint value);
    function transferFrom(address from, address to, uint value) external returns (bool);
}