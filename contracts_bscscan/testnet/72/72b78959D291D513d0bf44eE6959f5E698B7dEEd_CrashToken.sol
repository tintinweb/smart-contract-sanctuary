/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract CrashToken{
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1000000*10**18;
    string public name = "CrashToken";
    string public symbol = "CRASH";
    uint8 public decimals = 18;
    address contractOwner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(){
        contractOwner = msg.sender;
        balances[contractOwner] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns(uint256){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns(bool){
        require(balanceOf(msg.sender) >= _value, 'balance too low');
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
        require(balanceOf(_from) >= _value, 'balance too low');
        require(allowance[_from][msg.sender] >= _value, 'allowance too low');
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}