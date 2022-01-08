/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract TributeToken{
    // Constructor
    // Set the total number of tokens
    // Read the total number of tokens

    uint256 public totalSupply;

    // add name
    string public name = "Tribute Token";
    // add symbol
    string public symbol = "TRB";
    // add standard
    string public standard = "Tribute Token v1.0";
    // decimals
    uint public decimals = 3;


    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    // transferFrom event
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // mapping is an associative array
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    constructor() {
        uint256 _initialSupply = 1000000000;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;

        // alocate the initial supply
    }

    // transfer function
    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;    

        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

    // approve function
    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);            
        return true;
    }

    // transfer from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    
    }

}