/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract TestName {
    string public name;
    
    function changeName(string calldata _name) public {
        name = _name;
    }
}