/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    bool public is_approved;
    bool private irrelevant = false;

    function set_approve(bool approved) public {
        is_approved = approved;
    }

    function test_approve() public {
        require(is_approved == true, "Deu ruim");
        irrelevant = false;
    }
}