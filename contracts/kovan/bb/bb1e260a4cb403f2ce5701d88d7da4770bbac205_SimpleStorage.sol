/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

contract SimpleStorage
{
    uint256 public favNum;


    function changeFav(uint256 _newFav) public
    {
        favNum = _newFav;
    }

    
}