/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SakToken{
    
    //Name
    string public name = "Sak Token";
    
    //Sybmol
    string public symbol = "SAK";
    
    //decimal
    uint256 public decimals = 18;
    
    //totalsupply
    uint256 public totalSupply;
    
    event Transfer(address indexed sender, address indexed receiver, uint256 amount );
    
    event Approval(address indexed admin, address indexed spender, uint256 amount);
    
    mapping (address => uint256) public balanceOf;
    
    mapping (address => mapping(address => uint256)) public allownce;
    
    constructor(uint256 _totalsupply){
        totalSupply = _totalsupply;
        balanceOf[msg.sender] = _totalsupply;
    }
    
    
    //transfer function
    function transfer( address _to, uint256 _amount) public returns(bool success){
        require(balanceOf[msg.sender] >= _amount, 'You dont have enough balance!!');
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        
        return true;
    }
    
    //Aproval function 
    function approve(address _spender, uint256 _amount) public returns(bool success){
        allownce[msg.sender][_spender] += _amount;
        emit Approval(msg.sender, _spender, _amount);
        
        return true;
    } 
    
    //Transfer from function
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
        require(balanceOf[_from] >= _amount, 'you dont have enough balance');
        require(allownce[_from][msg.sender] >= _amount, 'you are not allowed to send this amount of balance');
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        allownce[_from][msg.sender] -= _amount;
        
        emit Transfer(_from, _to, _amount);
        
        emit Approval(_from, msg.sender, _amount);
        
        return true;
    }
}