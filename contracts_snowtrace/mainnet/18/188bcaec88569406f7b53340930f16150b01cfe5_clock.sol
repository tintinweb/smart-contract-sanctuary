/**
 *Submitted for verification at snowtrace.io on 2021-11-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// there must be a better way to find this but I don't know it!
contract clock {
    function time() external view returns (uint256) {
        return block.timestamp;
    }
}