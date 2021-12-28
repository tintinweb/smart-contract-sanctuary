/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

// SPDX-License-Identifier: Unlicensed;
pragma solidity ^0.8.4;

contract Mgcashfinance {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100_000_000_000 * 10 ** 9;
    uint256 private maxSaleLimit = 100_000_000 * 10 ** 9;
    string public name = "MG CASH FINANCE";
    string public symbol = "MG CASH";
    uint public decimals = 9;
    address public owner;
    address public poolAddress =  address(0); //will be set after adding liquidity. 


    function setPoolAddress(address _address) public
    {
        require(msg.sender == owner, "Only owner can set this value");
        poolAddress = _address;
    }

    function setMaxSaleLimit(uint256 _amount) public
    {
        require(msg.sender == owner, "Only owner can set this value");
        maxSaleLimit = _amount;
    }
   
     function checkforWhale(address to, uint256 amount) private view
     {
         if(to==poolAddress && msg.sender != owner)
         {
            require(amount<maxSaleLimit);
         }
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        owner =  msg.sender;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        checkforWhale(to, value);
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        checkforWhale(to, value);
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }



}