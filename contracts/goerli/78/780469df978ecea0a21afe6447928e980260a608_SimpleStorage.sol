/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage{
    uint public storedData;

    function set(uint x) public {
        storedData =x ;
    }

    function get() public view returns(uint){
        return storedData;
    }




}