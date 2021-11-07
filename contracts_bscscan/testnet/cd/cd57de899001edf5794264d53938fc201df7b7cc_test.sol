/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

contract test {
    constructor () {
    }

function _updateOriginalTokens(uint256 tAmount) public view returns (uint256 haha) {
        // update sender
        if (tAmount < 10) 
        {
            tAmount = 0;
        } else {
            tAmount = tAmount-10;
        }

        if (tAmount > 0 && tAmount < 30) {
            tAmount=0;
        } else if (tAmount >= 30){
            tAmount = tAmount - 30;
        }

        // update recipient
        return tAmount;
    }
}