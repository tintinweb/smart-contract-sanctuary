/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract myToken{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalsupply;
    mapping(address=>uint256) public balanceof;
    mapping(address=>mapping(address=>uint256)) public allowance;
    event Transfer(address _from,address _to,uint256 _amount);
    event Approval(address _owner,address _spender,uint256 _amount);
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalsupply = _totalSupply; 
        balanceof[msg.sender] = totalsupply;
    }
    function transfer(address _to,uint256 _amount) public returns (bool success){
        require(balanceof[msg.sender]>=_amount);
        balanceof[msg.sender] -= _amount;
        balanceof[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceof[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceof[_from] -= _value;
        balanceof[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
}