/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// SPDX-License-Identifier: none

pragma solidity >=0.8.0 <0.9.0;

contract writer{
    uint256 public value;

    function write(
        uint256 data
    ) public virtual returns(uint256){
        value = data;
        return data;
    }
}