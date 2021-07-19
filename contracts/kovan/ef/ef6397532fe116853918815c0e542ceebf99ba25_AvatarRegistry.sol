/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AvatarRegistry {
    mapping (address => string) public avatars;
    
    event NewAvatar(address owner);
    
    function setAvatar(string calldata newUrl) public {
        avatars[msg.sender] = newUrl;
        emit NewAvatar(msg.sender);
    }
}