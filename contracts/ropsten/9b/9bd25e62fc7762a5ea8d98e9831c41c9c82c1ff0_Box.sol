/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Box {

    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }

}