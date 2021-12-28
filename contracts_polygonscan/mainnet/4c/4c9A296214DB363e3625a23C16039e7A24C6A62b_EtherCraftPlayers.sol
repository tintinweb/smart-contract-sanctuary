/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract EtherCraftPlayers {

    mapping (address => bytes32) public users;
    mapping (bytes32 => bool) public isValid;

    /*
    *   @param username Account's official Minecraft player name
    */
    function login(string calldata username) external payable returns (bytes32) {
        require(msg.value == 1 ether, "1 MATIC collateral required");
        require(isValid[users[msg.sender]] == false, "Player already logged is");
        bytes32 user = keccak256(abi.encode(username));
        users[msg.sender] = user;
        isValid[user] = true;
        return user;
    }

    function logout() external returns (bytes32) {
        require(isValid[users[msg.sender]] == true, "Player not logged in");
        isValid[users[msg.sender]] = false;
        payable(msg.sender).transfer(1 ether);
        return users[msg.sender];
    }
}