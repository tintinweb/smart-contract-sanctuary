/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Test {
    string name;
    
    function changeName(string memory _newName) public returns (string memory) {
        name = _newName;
        return _newName;
    }
}