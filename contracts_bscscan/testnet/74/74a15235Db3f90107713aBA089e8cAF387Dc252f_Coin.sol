// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Coin {
    address public minter;

    mapping(address => uint256) public balances;

    event Sent(address from, address to, uint256 amount);

    constructor() {
        minter = msg.sender;
    }

    function mint(address receiver, uint256 amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    error InsufficientBalance(uint256 requested, uint256 available);

    function send(address receiver, uint256 amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;

        emit Sent(msg.sender, receiver, amount);
    }
}