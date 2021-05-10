// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.0 <0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";

interface IERC20 {

    function allowance(address owner, address delegator) external view returns (uint256);
    function approve(address delegator, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed delegator, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
}

contract C98ERC20 is IERC20 {
    using SafeMath for uint256;
    
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        _decimals = 9;
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _balances[msg.sender] = totalSupply_;
    }
    
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    function allowance(address owner, address delegator) public view override returns (uint256) {
        return _allowances[owner][delegator];
    }

    function approve(address delegator, uint256 amount) public override returns (bool) {
        _approve(msg.sender, delegator, amount);
        return true;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exeeds allowance"));
        return true;
    }

    function decimal() public view returns (uint8) {
        return _decimals;
    }

    function _approve(address owner, address delegator, uint256 amount) internal {
        require(owner != address(0), "C98ERC20: zero address");
        require(delegator != address(0), "C98ERC20: zero address");

        _allowances[owner][delegator] = amount;
        emit Approval(owner, delegator, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "C98ERC20: zero address");
        require(recipient != address(0), "C98ERC20: zero address");

        _balances[sender] = _balances[sender].sub(amount, "C98ERC20: not enough balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}