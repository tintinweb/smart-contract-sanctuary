/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: GPL 3.0

pragma solidity >=0.7.0 <0.9.0;

contract Outpost {
    string public owner;
    
    function setOwner (string memory _owner) public {
        owner = _owner;
    }
}