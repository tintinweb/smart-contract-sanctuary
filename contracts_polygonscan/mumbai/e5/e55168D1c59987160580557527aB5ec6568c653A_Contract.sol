/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Contract {
    struct WL {
        address addr;
        string username;
        bool register;
    }

    mapping(address => WL) private isWhitelisted;

    event NewRegister(string username);

    function register(string memory username) public {
        require(!isWhitelisted[msg.sender].register, "already whitelisted!");
        isWhitelisted[msg.sender] = WL(msg.sender, username, true);
        emit NewRegister(username);
    }

    function checkWL(address _address) public view returns(string memory) {
        require(isWhitelisted[_address].register, "unknow user...");
        return isWhitelisted[_address].username;
    }
}