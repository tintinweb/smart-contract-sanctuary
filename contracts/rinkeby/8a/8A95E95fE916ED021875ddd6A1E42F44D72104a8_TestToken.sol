/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


error InsufficientBalance(uint256 unavailable, address who);

contract TestToken {
    function testRevert(address to, uint256 amount, bool fail) public pure {
        if (fail) {
            revert InsufficientBalance({
                unavailable: amount,
                who: to
            });
        }
    }

    function testRequire(address to, uint256 amount, bool fail) public pure {
        if (fail) {
            require(!fail, "Not gonna work");
        }
    }
    // ...
}