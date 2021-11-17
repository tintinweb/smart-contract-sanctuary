/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Count{

    uint256 public count;
    
    function add() public {
        count = count + 1;
    }

    function getCount() public view returns(uint256){
        return count;
    }
}