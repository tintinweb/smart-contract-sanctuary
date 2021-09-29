/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SjdToken {
    string public name ="Saj Token";
    string public symbol = "SJD";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    
    event Transfer(address indexed sender, address indexed to, uint256 amount);
    event Approval(address indexed From, address indexed spender, uint256 amount);
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
                               //to whom
    constructor (uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient Balance");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowance[msg.sender][_spender] += _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        // check the balance of from user
        require(balanceOf[_from] >= _amount, "Not enough balance");
        // check allowance of the msg.sender
        require(allowance[_from][msg.sender] >= _amount, "Doesnt have required allowance");
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        // decrease the allowance
        allowance[_from][msg.sender] -= _amount;
        emit Transfer(_from,_to,_amount);
        emit Approval(_from, msg.sender, _amount);
        return true;
    }
}