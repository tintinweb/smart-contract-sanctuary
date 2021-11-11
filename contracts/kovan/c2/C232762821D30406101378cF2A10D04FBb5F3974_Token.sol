/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Token
{
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    
    uint private exponent;
    
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor()
    {
        name = "Raccoon";
        symbol = "RAC";
        decimals = 18;
        exponent = 10**decimals;
        totalSupply = 800000000000 * exponent;
        balances[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint _value) external returns (bool success)
    {
        require(balances[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal
    {
        require(_to != address(0));
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) external returns (bool)
    {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}