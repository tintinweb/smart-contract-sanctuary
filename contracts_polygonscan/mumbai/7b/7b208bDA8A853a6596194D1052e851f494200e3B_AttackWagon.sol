/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AttackWagon {

    string public name = "ATTACK";
    
    string public symbol = "ATK";
    
    string public version = "v1.0";

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) {

        balanceOf[msg.sender] = _initialSupply;
        
        totalSupply = _initialSupply;
    
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Acceptance(
    
        address indexed _owner,
    
        address indexed _spender,
    
        uint256 _value
    
    );

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        
        require(balanceOf[msg.sender] >= _value, "Lack of funds");
        balanceOf[msg.sender] -= _value;
        
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;

        emit Acceptance(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    
    ) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Lack of funds");
        require(allowance[_from][msg.sender] >= _value, "Too many funds");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}