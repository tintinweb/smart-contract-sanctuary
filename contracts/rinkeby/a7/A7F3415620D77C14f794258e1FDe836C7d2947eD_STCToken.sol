/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract STCToken{
    string public name="STC Token";
    string public symbol="STC";
    uint256 public totalSupply;
    mapping (address=>uint256)  public balanceOf;
    mapping (address=>mapping(address=>uint256)) public allowance;
    
    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    
    constructor(uint256 _initialSupply){
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }

    function transfer(address _to,uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;

    }

    // to handle delegated transfer
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balanceOf[_from]>=_value,"insufficient balance");
        require(allowance[_from][msg.sender]>=_value,"insufficient balance");

        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender,uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


}