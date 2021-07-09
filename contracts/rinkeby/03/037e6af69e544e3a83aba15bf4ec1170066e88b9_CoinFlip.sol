/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract CoinFlip {
    function attach() external {
        Flipper flipper = Flipper(0x81B35e1fAc26b0E311f23498D04ECFc78EE62650);
        bool answer = flipper.flip(true);
        if (answer) {
            for(uint i = 0; i < 9; i++) {
                flipper.flip(true);
            }
        } else {
            for(uint i = 0; i < 10; i++) {
                flipper.flip(false);
            }
        }
    }
}

interface Flipper {
    function flip(bool) external returns (bool);
}