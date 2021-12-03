/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;

    uint256 _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    constructor() {
        name = "ERC20Basic";
        symbol = "ERC20Basic";
        decimals = 18; //10^18

        _totalSupply = 100000000000000000000000; //10^23
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

	function balanceOf(address account) override external view returns (uint256) {
        return balances[account];
    }

	function allowance(address owner, address spender) override external view returns (uint256) {
        return allowances[owner][spender];
    }

	function transfer(address recipient, uint256 amount) override external returns (bool) {
        require(amount <= balances[msg.sender], "Amount must be <= balance!");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

	function approve(address spender, uint256 amount) override external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

	function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
        require(amount <= balances[sender], "Amount must be <= balance!");
        require(amount <= allowances[sender][msg.sender], "Amount must be <= allowance!");

        balances[sender] = balances[sender] - amount;
        allowances[sender][msg.sender] = allowances[sender][msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }
}