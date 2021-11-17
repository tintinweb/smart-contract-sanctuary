// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0;

import "./ITRC20.sol";
import "./SafeMath.sol";

contract Token is ITRC20 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor () {
        _name = "Good Good Coin";
        _symbol = "GGC";
        _decimals = 18;
        _totalSupply = 10000000 * (10 ** uint256(_decimals));

        _balances[msg.sender] = _totalSupply;
        emit Transfer(msg.sender, msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) override public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) override public returns (bool) {
        require(spender != address(0), "Approve to the zero address");
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) override public returns (bool) {
        require(_balances[msg.sender] >= value, "Not enough token");
        require(to != address(0), "Transfer to the zero address");
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override public returns (bool) {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(_allowances[from][msg.sender] >= value, "Not enough token");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);

        emit Transfer(from, to, value);
        return true;
    }

}