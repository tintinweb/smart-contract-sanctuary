/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract TokenA {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimal;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint256 totalSupply_, uint8 decimal_) {
        _name = "tokenA";
        _symbol = "TKA";
        _decimal = decimal_;
        _totalSupply = totalSupply_ * (10 ** decimal_);
        _balances[msg.sender] = _totalSupply;
    }


    event Approval(
        address indexed owner,
        address indexed spender,
        uint amount
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint amount
    );


    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function decimal() public view returns(uint8) {
        return _decimal;
    }

    function balanceOf(address _account) public view returns(uint256 balance) {
        return _balances[_account];
    }

    function allowance(address _account, address _spender) public view returns(uint256 remaining) {
        return _allowances[_account][_spender];
    }

    function transfer(address _to, uint256 _amount) public returns(bool success) {
        require(_balances[msg.sender] >= _amount, "insufficent balance");
        _balances[msg.sender] -= _amount;
        _balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns(bool success) {
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success) {
        require(_balances[_from] >= _amount);
        require(_allowances[_from][msg.sender] >= _amount, "insufficent allowance");

        _balances[_from] -= _amount;
        _allowances[_from][msg.sender] -= _amount;

        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);

        return true;
    }

}