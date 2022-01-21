/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Token {

    // My Variables
    string public name;             // = "Fa Tsai Bee";
    string public symbol;           // = "FTB";
    uint256 public decimals;        // = 18;
    uint256 public totalSupply;     //= 1000000000000000000000000000000; // total supply + 18 decimals

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
    }

    // Keep track balances and allowances approved
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}