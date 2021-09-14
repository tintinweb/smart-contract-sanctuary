/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract Token {
    string public name = "ANA"; // Ana tokenizovana! :)
    string public symbol = "ANA";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000; //1 million, add 18 zeroes after the real number
    
    mapping (address => uint256) public balanceOf;
    
    event Transfer (address indexed from, address indexed to, uint256 value);
    
    constructor (string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;
    balanceOf[msg.sender] = totalSupply;

    }
    function transfer(address _to, uint256 _value) external returns (bool success) { //move tokens from one to another address
        require (balanceOf[msg.sender] >= _value);
        balanceOf [msg.sender] = balanceOf[msg.sender] - (_value);
        balanceOf [_to] = balanceOf [_to] + (_value);
        emit Transfer (msg.sender, _to, _value);
    return true;
        
        
    }    
    
    
}