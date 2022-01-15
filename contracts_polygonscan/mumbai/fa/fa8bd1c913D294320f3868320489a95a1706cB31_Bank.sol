/**
 *Submitted for verification at polygonscan.com on 2022-01-14
*/

/// @title Bank 0.0.1
/// @author awphi (https://github.com/awphi)
/// @notice Bank from GlassCasino - L3 BSc ComSci Project @ Durham University
/// @dev -

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Bank {
    address public house;
    mapping(address => uint) public funds;
    mapping (address => bool) public games;

    constructor() {
        house = msg.sender;
    }

    modifier onlyHouse {
        require(msg.sender == house);
        _;
    }

    modifier onlyGames {
        require(games[msg.sender]);
        _;
    }

    // ---- FOR HOUSE ----
    function registerGame(address game) public onlyHouse {
        games[game] = true;
    }

    function unregisterGame(address game) public onlyHouse {
        games[game] = false;
    }

    // ---- FOR USERS ----
    receive() external payable {
        funds[msg.sender] += msg.value;
    }

    function withdrawFunds(uint amount) public {
        require(funds[msg.sender] >= amount);
        require(address(this).balance >= amount);

        funds[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // ---- FOR GAMES (CONTRACTS) ----
    // Compiler (0.8+) takes care of under/overflows
    function addFunds(address player, uint amount) public onlyGames {
        funds[player] += amount;
    }

    function removeFunds(address player, uint amount) public onlyGames {
        funds[player] -= amount;
    }
}