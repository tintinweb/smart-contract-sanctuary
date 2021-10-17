/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

//SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.5.0 <0.9.0;

contract MetaCoin {
    uint storeData;
    function set(uint num) public {
        storeData = num;
    }

    function get() public view returns (uint) {
        return storeData;
    }
}