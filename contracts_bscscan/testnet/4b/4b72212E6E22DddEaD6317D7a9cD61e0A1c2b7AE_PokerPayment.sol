// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PokerPayment {
    // array countains: amount, token
    mapping(uint256 => mapping(address => uint256[2])) games;

    function depositToken(uint256 gameId, uint256 amount, uint256 token) public {
        require(msg.sender != address(0) && msg.sender != address(this), "PokerPayment: sender is the zero address");
        // validate amount for game
        // validate token: only accept support token

        uint256[2] memory amountToken = games[gameId][msg.sender];
        require(amountToken[0] == 0, "PokerPayment: deposited token for game");

        games[gameId][msg.sender] = [amount, token];
    }
}

