/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: GPL-3.0

// linkdin,twitter,github username: @imHukam

pragma solidity ^0.8.11;

contract Token{

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address=>uint256) public balanceOf;
    mapping(address=> mapping(address=>uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to , uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address payable _to, uint256 _value) public returns(bool success){
        require(balanceOf[msg.sender]>=_value , "balance not sufficient");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        success= true;
    }

    function approve(address _spender, uint256 _value) public returns(bool success){
        allowed[msg.sender][_spender]= _value;

        emit Approval(msg.sender, _spender, _value);
        success= true;
    }

    function transferFrom(address _from, address payable _to, uint256 _value) public returns(bool success){
        require(balanceOf[_from] >= _value, "balance not sufficient on owner's account");
        require(allowed[_from][msg.sender] >= _value ,"input value is greater then allowed value");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from,_to,_value);
        success= true;

    }

}