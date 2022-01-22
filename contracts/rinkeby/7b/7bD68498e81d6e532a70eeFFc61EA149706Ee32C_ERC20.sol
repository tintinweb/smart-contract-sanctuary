/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    uint private _totalSupply;
    //owner => balance
    mapping(address => uint) private _balances;

    //owner => spender => amount
    mapping(address => mapping(address => uint)) private _allowances;

    address _admin;

    constructor() {
        _admin = msg.sender;
    }

    function name() public pure returns (string memory) {
        return "Yorozuya Coin";
    }

    function symbol() public pure returns (string memory) {
        return "YRZ";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
        address from = msg.sender;
        require(amount <= _balances[from], "Transfer amount exceeds balance.");        
        require(to != address(0), "Transfer to zero address.");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        require(spender != address(0), "Approve spender ero address.");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        require(from != address(0), "Transfer from zero address.");
        require(to != address(0), "Transfer to zero address.");
        require(amount <= _balances[from], "Transfer amount exceeds balance.");

        if (from != msg.sender) {
            uint allowanceAmount = _allowances[from][msg.sender];
            require(amount <= allowanceAmount, "Transfer amount exceeds allowance.");
            uint remaining = allowanceAmount - amount;
            _allowances[from][msg.sender] = remaining;
            emit Approval(from, msg.sender, remaining);
        }

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint amount) public {
        require(msg.sender == _admin, "Not authorized.");
        require(to != address(0), "Transfer to zero address.");

        _balances[to] += amount;
        _totalSupply += amount;

        address from = address(0);

        emit Transfer(from, to, amount);
    }

    function burn(address from, uint amount) public {
        require(msg.sender == _admin, "Not authorized.");
        require(from != address(0), "Burn from zero address.");
        require(amount <= _balances[from], "Burn amount exceeds balance.");

        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

}