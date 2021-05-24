/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

//"SPDX-License-Identifier: MIT"
pragma solidity 0.7.0;

contract DevToken{
    
    string public name = "Dev Token";
    string public symbol = "DEV";
    uint256 public decimals = 18;
    uint256 public totalSupply; 
    
    event transferEvent (address indexed sender, address indexed to, uint256 amount);
    
    event approval (address indexed From, address indexed spender, uint256 amount);
    
    mapping (address => uint256) public balanceOf;
    
    mapping (address => mapping (address => uint256)) public allowance;
    
    
    constructor(uint256 _totalsupply) {
        totalSupply = _totalsupply;
        balanceOf[msg.sender] = _totalsupply;
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool success){
        require(balanceOf[msg.sender] >= _amount, "You have not enough balance");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit transferEvent(msg.sender, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success){
        allowance[msg.sender][_spender] += _amount;
        emit approval(msg.sender, _spender, _amount);
        return true;
    }
}