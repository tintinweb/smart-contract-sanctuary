/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals; 
    uint256 public totalSupply;
    
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // stored on ethereum blockchain. so exchange performs the transfer on behalf of user 
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply; // total boundary 
    }
    
    
    // call an ethereum contract and pass your address and amount of ether to the function (it will 
    
    function _transfer(address _from, address _to, uint256 _value) public returns (bool success) {
        // check if caller account has money to spend 
        require(balanceOf[_from] >= _value, "Insufficient Balance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // approve transaction to be spent on behalf of user 
    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value; // so for each allocation of allowance, we are giving this particular spender e.g metamask ability to spend on our behalf 
        emit Approval(msg.sender, _spender, _value);
        return true ;
    }
    
    // transferFrom is used via exchanges that trade tokens on your behalf
   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
       require(allowance[_from][msg.sender] >= (_value)); // check that allowed spend 
       allowance[_from][msg.sender] -= (_value);
       _transfer(_from, _to, _value);
       return true;
   }
}