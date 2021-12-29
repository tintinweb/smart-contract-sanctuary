/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;



// Smart Contract code
contract Token {
    string public name; // Token Name
    string public symbol; // Market Symbol
    uint256 public decimals; // Ether is divisible by 18, so this is the standard
    uint256 public totalSupply; // Add 18 decimal places AFTER the total supply you want for the token 

    // Track the balances / allowences that are approved
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    // Declare a transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

 
    // Constructor function that executes when passed to blockchain
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    
    // Transfer function - send tokens from one account to another
    // _to = address to transfer to
    // _value = amount of tokens to transfer
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value); // Deduct transfer amount from sender
        balanceOf[_to] = balanceOf[_to] + (_value); // Credit that value to the receiver
        emit Transfer(_from, _to, _value);
    }

    // Approve other users to spend on an exchange
    // _spender = allowed to spend this maximum amount
    // _value = amount value of token to spend
    
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // If tokens are exchanged via an exchange

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }


}