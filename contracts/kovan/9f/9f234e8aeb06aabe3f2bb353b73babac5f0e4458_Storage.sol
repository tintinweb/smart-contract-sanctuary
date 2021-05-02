/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;


contract Storage {
    
    string public constant tokenMinuta = "Céu, Carraço"; 

    string public text;
    
    function write(string calldata content) external {
        text = content;
    }
}