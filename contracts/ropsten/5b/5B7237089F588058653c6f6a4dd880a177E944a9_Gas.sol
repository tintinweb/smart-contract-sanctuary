/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Gas {
    uint public i = 0;

    function forever() public {
        while (true) {
            i += 1;
        }
    }
}