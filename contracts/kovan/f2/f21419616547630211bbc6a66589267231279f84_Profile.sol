/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Profile {
    event save(address user, string data);
    mapping(address => string) public profiles;
    
    function saveProfile (string calldata _data) external{
        profiles[msg.sender] = _data;
        emit save(msg.sender,_data);
    }
}