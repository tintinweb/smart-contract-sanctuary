/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
     //	prevent implicit acceptance of ether 
    receive() external payable
    {
         revert();
    }
}