/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Hacker {
    uint public V = 0;
    bytes32 public BH;
    uint public BN = 0;
    bool public solved;
    address public recoveraddr;
    
    address target = 0x7C3b0CCCAa94328A28129014A22499A50c770Eae;
    
    constructor() {
        uint v = 27;
        BN = block.number;
        bytes32 bh = blockhash(block.number - 1);
        BH = bh;
        v = v + (((uint256)(bh) >> (12 * 8)) << (12 * 8));
        V = v;
    }
    
    function test() public {
        bytes32 r = 0x3ec07bbb0fe7fd6e6d2abbb5f0a0c9947173da8daa5265f6231beea212772585;
        bytes32 s = 0x26236f50af44e91e608d5946b411a4f86a83ace0543bf8efca7bee233d1f98db;
        uint8 v = 27;
        recoveraddr = ecrecover(keccak256("solved"), v, r, s);
    }
    
    function solve(uint8 v, bytes32 r, bytes32 s) public {
        require(ecrecover(keccak256("solved"), v, r, s) == 0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF);
        solved = true;
    }
}