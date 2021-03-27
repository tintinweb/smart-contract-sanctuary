/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-v2-or-later
pragma solidity ^0.8.2;

contract MyEtherOrMyLife {
    function bequeath(address payable target) payable external {
        selfdestruct(target);
    }
}