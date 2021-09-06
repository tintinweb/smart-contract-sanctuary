/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract SebastianToken {
    string private _name = "Sebastian Token";
    string private _symbol = "SBT";
    uint256 private _totalSupply = 1000000;
    address private _owner;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _balances;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address sender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][sender] += amount;

        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "Not enough tokens");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Transfer amount exceeds allowance");
        require(_balances[from] >= amount, "Not enough tokens");

        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;

        return true;
    }


    function mint(address to, uint256 amount) external {
        _totalSupply += amount;
        _balances[to] += amount;
    }
}