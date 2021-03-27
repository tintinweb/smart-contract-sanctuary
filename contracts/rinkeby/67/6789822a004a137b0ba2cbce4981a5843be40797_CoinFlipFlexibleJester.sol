/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-v2-or-later
pragma solidity ^0.8.2;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipFlexibleJester {
    function dazzle(ICoinFlip target, bool guess) public {
        require(target.flip(guess), "CoinFlipFlexibleJester: unlucky");
    }
}