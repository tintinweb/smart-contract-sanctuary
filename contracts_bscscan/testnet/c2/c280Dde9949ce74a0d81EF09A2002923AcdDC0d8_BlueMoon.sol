/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;                 // declaring version of solidity


contract BlueMoon{

    mapping(address =>uint256) public balanceOf;
    mapping(address =>mapping(address =>uint256))public allowance;
    

    string public name = "BlueMoon";
    string public symbol ="BMN";
    uint256 public decimals = 18;
    uint256 public totalSupply = 100000000000000000000000;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    constructor() {
        balanceOf[msg.sender] = totalSupply;
        
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value,"not enough tokens to spend");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowance[_from][msg.sender] >= _value,"not approved to spend");
        require(balanceOf[_from] >= _value,"not enough tokens to spend");

        balanceOf[_from] -= _value;
        balanceOf[_to] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from,_to,_value);
        return true;

    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

}