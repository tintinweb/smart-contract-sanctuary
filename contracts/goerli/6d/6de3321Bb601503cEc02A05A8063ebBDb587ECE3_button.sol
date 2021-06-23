/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract button {
    uint256 public buttonCount = 0;
    
    function addButton()
    public
    {
        buttonCount += 1;
    }
}