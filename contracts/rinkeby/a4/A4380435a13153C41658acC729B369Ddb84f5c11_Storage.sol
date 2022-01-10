/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract Storage {

    uint256 number;

    function write(uint256 num) public {
        number = num;
    }

    function read() public view returns (uint256){
        return number;
    }
}