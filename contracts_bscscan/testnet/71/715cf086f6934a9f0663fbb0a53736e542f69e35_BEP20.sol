//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IBEP20.sol";

contract BEP20 is IBEP20, Ownable {

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (uint totalSupply_, string memory name_, string memory symbol_, uint8 decimals_) {
        _balances[owner()] = totalSupply_;
        emit Transfer(address(0), owner(), totalSupply_);
        _totalSupply = totalSupply_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function mint(uint256 amount) public { 
        require(amount > 0, "Zero amount");

        _balances[msg.sender] = _balances[msg.sender] + amount;
        _totalSupply = _totalSupply + amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}