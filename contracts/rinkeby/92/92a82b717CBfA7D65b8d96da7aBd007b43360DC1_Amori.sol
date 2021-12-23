/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract Amori is ERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _mintableSupply;
    uint256 private _mintDivisor;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _maxSupply;

    constructor() {
        _maxSupply = 21000000;
        _totalSupply = 4000000;
        _name = "Amori";
        _symbol = "AMORI";

        _balances[msg.sender] = _totalSupply;
        _mintableSupply = _maxSupply - _totalSupply;
        _mintDivisor = 10;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() override external view returns (string memory) { return _name; }
    function symbol() override external view returns (string memory) { return _symbol; }
    function decimals() override external pure returns (uint8) { return 0; }
    function totalSupply() override external view returns (uint256) { return _totalSupply; }

    function balanceOf(address _owner) override external view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) override external returns (bool success) {
        require(_balances[msg.sender] >= _value);

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override external returns (bool success) {
        require(_balances[_from] >= _value);
        require(_allowances[_from][msg.sender] >= _value);

        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) override external returns (bool success) {
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) override external view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function mint(address _to) external returns (bool success) {
        require(_mintableSupply > 0);

        uint256 amount = _mintableSupply / _mintDivisor;
        _mintDivisor += 1;

        _mintableSupply -= amount;
        _totalSupply += amount;
        _balances[_to] += amount;

        emit Transfer(address(0), _to, amount);

        return true;
    }
}