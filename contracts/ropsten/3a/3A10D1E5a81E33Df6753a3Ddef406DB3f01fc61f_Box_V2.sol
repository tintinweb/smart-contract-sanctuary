/**
 *Submitted for verification at BscScan.com on 2022-01-17
 */
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Box_V2 {
    uint256 public val;

    // function initialize(uint _val) external{
    //     val = _val ;
    // }

    function inc() external {
        val += 1;
    }
}