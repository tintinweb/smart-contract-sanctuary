// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owner.sol";

contract Token is Owner {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => mapping(uint256 => uint256)) private _currentBalance;

    event Transfer(address sender, address recipent, uint256 amount);
    event Mint(uint256 amount);
    event Approval(address account, address spender, uint256 amount);

    constructor() {
        _balances[owner] = 1000000000000;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _balances[to] += amount;
        updateBalancePerBlock(block.number, to, amount, true);
        emit Mint(amount);
    }

    function transfer(address to, uint256 amount) public {
        address sender = msg.sender;
        _transfer(sender, to, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transerFrom(
        address from,
        address to,
        uint256 amount
    ) public {
        require(_allowances[from][msg.sender] >= amount, "not delegate");
        _transfer(msg.sender, to, amount);
        _allowances[from][msg.sender] -= amount;
    }

    function _transfer(
        address sender,
        address to,
        uint256 amount
    ) private {
        require(balanceOf(sender) >= amount, "Insuficient Balance");
        _balances[sender] -= amount;
        _balances[to] += amount;
        updateBalancePerBlock(block.number, sender, amount, false);
        emit Transfer(sender, to, amount);
    }

    function approve(address spender, uint256 amount) public {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

    function allowances(address spender) public view returns (uint256) {
        return _allowances[msg.sender][spender];
    }

    function removeAllowances(address spender) public {
        _allowances[msg.sender][spender] = 0;
    }

    function getBalancePerBlock(uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        return _currentBalance[msg.sender][blockNumber];
    }

    function updateBalancePerBlock(
        uint256 blockNumber,
        address account,
        uint256 amount,
        bool isIncrease
    ) public {
        if (isIncrease) {
            _currentBalance[account][blockNumber] += amount;
        } else {
            _currentBalance[account][blockNumber] -= amount;
        }
    }
}