/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract TryTo
{
    string private _name = "TryTo";
    string private _symbol = "TTO";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000000000000000000000;

    function name() public view returns(string memory)
    {
        return _name;
    }
    function symbol() public view returns(string memory)
    {
        return _symbol;
    }
    function decimals() public view returns(uint8)
    {
        return _decimals;
    }
    function totalSupply() public view returns(uint256)
    {
        return _totalSupply;
    }

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    function balanceOf(address _owner) public view returns(uint256 balance)
    {
        return _balanceOf[_owner];
    }
    function allowance(address _owner, address _spender) public view returns(uint256 remaining)
    {
        return _allowance[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor()
    {
        _balanceOf[msg.sender] = _totalSupply;
    }

    modifier hasFunds(address _from, uint256 _value)
    {
        require(_balanceOf[_from] >= _value, "Not enough minerals.");
        _;
    }

    modifier isNotOwner(address _address)
    {
        require(_address != address(0), "Can't use owner address.");
        _;
    }

    function transfer(address _to, uint256 _value) hasFunds(msg.sender, _value) external returns(bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }
 
    function _transfer(address _from, address _to, uint256 _value) isNotOwner(_to) internal
    {
        _balanceOf[_from] = _balanceOf[_from] - (_value);
        _balanceOf[_to] = _balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) isNotOwner(_spender) external returns(bool success)
    {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) hasFunds(_from, _value) external returns(bool success)
    {
        require(_allowance[_from][msg.sender] >= _value, "Low allowance.");
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}