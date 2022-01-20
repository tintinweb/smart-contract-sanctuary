/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Token {

    address owner;
    string public _name = "TEST";
    string public _symbol = "TST";
    uint8 public _decimals = 18;
    uint256 public _numberOfTokens = 1000000000;
    uint256 public _totalSupply = _numberOfTokens * (10 ** _decimals);
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;


    constructor() {
        owner = msg.sender;
        _balances[owner] += _totalSupply;
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


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value, "Insufficient funds");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_balances[_from] >= _value, "Insufficient funds");
        require(_allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value, "Insufficient funds");
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);


    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}