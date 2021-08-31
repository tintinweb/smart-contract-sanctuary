/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.6.9;

import {SafeMath} from "../SafeMath.sol";
import {InitializableOwnable} from "../InitializableOwnable.sol";

contract InitializableMintableERC20 is InitializableOwnable {
    using SafeMath for uint256;

    string public name;
    uint256 public decimals;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Mint(address indexed user, uint256 value);

    function init(
        address _creator,
        uint256 _initSupply,
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public {
        initOwner(_creator);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initSupply;
        balances[_creator] = _initSupply;
        emit Transfer(address(0), _creator, _initSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
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
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
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

    function mint(address user, uint256 value) external onlyOwner {
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

}