/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

//SPDX-License-Identifier:MIT
pragma solidity >0.8.7;

contract storge{
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}