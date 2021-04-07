/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract GME {
    
    uint256 public totalSupply;
    uint8 constant public decimals = 3;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
    
    string constant public name = "Test token";
    string constant public symbol = "GME";
    
    uint256 constant IPOShares = 18055555e3;
    address owner;
    
    constructor() {
        owner = msg.sender;
        totalSupply = IPOShares;
        balanceOf[msg.sender] = IPOShares;
        emit Transfer(address(0), msg.sender, IPOShares);
    }
    
    function transferRaw(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(_to != address(0));
        //require(balanceOf[_from] >= _value);  solidity 0.8.0 does this on the next line anyway
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return transferRaw(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //require(allowance[_from][msg.sender] >= _value);  solidity 0.8.0 does this on the next line anyway
        allowance[_from][msg.sender] -= _value;
        return transferRaw(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function newEquity(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        totalSupply += _value;
        balanceOf[owner] += _value;
        emit Transfer(address(0), owner, _value);
        return true;
    }
    
    function retireShares(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        //require(balanceOf[owner] >= _value);  solidity 0.8.0 does this on the next line anyway
        balanceOf[owner] -= _value;
        totalSupply -= _value;
        emit Transfer(owner, address(0), _value);
        return true;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}