/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract BscSwapper {

    address private constant WBNB =
        0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    function expxRoute(
        uint256 amountIn,
        address[] memory pools
    ) public pure returns (uint256) {
        uint256 tempAmount = amountIn;

        for (uint256 i = 0; i < pools.length; i++) {
            if (i == pools.length - 1) {
                tempAmount = tempAmount + 1;
            } else {
                tempAmount = tempAmount + 2;
            }
        }

        return tempAmount;
    }
}