/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {
    string value = "Hallo world";


    function hallo() public view
            returns (string memory)
    {
        return value;
    }
    
}