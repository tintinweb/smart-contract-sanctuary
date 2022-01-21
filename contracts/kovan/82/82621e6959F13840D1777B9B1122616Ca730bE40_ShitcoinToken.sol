/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ShitcoinToken {
    // initial state
    address private _contractOwner;
    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // emits
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // contract constructor
    constructor() {
        _contractOwner = msg.sender;
        _name = "Shitcoin Token";
        _symbol = "SHT";
        _decimals = 18;
    }

    //modifiers

    modifier _onlyOwner() {
        require(msg.sender == _contractOwner, "You are not the owner");
        _;
    }

    // view contract methods

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    // payable contract methods
    // allowance manipulation functions
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount)
        external
        returns (bool)
    {
        uint256 _currentAllowance = allowance(msg.sender, spender);
        _approve(msg.sender, spender, _currentAllowance + amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount)
        external
        returns (bool)
    {
        uint256 _currentAllowance = allowance(msg.sender, spender);
        require(
            _currentAllowance >= amount,
            "It's impossible to lower the value below zero"
        );
        _approve(msg.sender, spender, _currentAllowance - amount);
        return true;
    }

    // totalSupply changing functions
    function mint(address to, uint256 amount) external _onlyOwner {
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Zero tokens amount for mint");
        _totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external _onlyOwner {
        require(from != address(0), "Can't burn tokens from zero addrress");
        require(balanceOf(from) >= amount, "Burn amount exceeds balance");
        _totalSupply -= amount;
        balances[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    //functions

    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 _currentAllowance = allowance(msg.sender, to);
        _transfer(msg.sender, to, amount);
        require(_currentAllowance >= amount, "Amount exceeds allowance");
        _approve(msg.sender, to, _currentAllowance - amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 _currentAllowance = allowance(from, msg.sender);
        _transfer(from, to, amount);
        require(_currentAllowance >= amount, "Amount exceeds allowance");
        _approve(from, msg.sender, _currentAllowance - amount);
        return true;
    }

    // utility functions
    function _approve(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "Approve from the zero address");
        require(to != address(0), "Approve to the zero address");
        allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(balances[from] >= amount, "Transfer amount exceeds balance");
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}