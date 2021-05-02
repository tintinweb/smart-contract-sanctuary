/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;


contract Storage {

    string public text;
    
    function write(string memory content) external {
        text = content;
    }
}