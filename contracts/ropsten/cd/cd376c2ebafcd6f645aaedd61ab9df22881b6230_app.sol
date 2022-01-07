/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract app {
    uint data;

    function getdata() public view returns(uint) {
        return data;
    }

    function setData(uint _data) public {
        data = _data ;
    }
}