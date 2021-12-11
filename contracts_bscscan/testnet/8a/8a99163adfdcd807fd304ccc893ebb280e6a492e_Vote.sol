/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Vote {
    uint256 public counter = 0;
    function up() public { counter += 1; }
    function down() public { counter -= 1; }
}