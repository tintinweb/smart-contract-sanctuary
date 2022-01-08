// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owner.sol";

contract Token is Owner {
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal delegateTransferAmount;

    event Transfer(address sender, address recipent, uint256 amount);
    event Mint(uint256 amount);

    constructor() {
        balances[owner]= 1000000000000;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        balances[to] += amount;
        emit Mint(amount);
    }

    function transfer(address to, uint256 amount) public {
        address sender = msg.sender;
        _transfer(sender, to, amount);
    }

    function balanceOf(address account) public view returns (uint256){
        return balances[account];
    }

    function transerFrom(address from, address to, uint256 amount) public {
        require(delegateTransferAmount[from][msg.sender] >= amount, "not delegate");
        _transfer(msg.sender, to, amount);
        delegateTransferAmount[from][msg.sender] -= amount;
    }

    function _transfer(address sender,address to, uint256 amount) private {
        require(balanceOf(sender) >= amount,"Insuficient Balance");
        balances[sender] -= amount;
        balances[to] += amount;
        emit Transfer(sender, to, amount);
    }

    function approve(address spender, uint256 amount) public {
        delegateTransferAmount[msg.sender][spender] += amount;
    }
}