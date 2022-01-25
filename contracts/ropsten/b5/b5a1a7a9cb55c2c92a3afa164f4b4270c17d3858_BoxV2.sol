/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

contract BoxV2 {

    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }

    function inc() external {
        val += 1;
    }

}