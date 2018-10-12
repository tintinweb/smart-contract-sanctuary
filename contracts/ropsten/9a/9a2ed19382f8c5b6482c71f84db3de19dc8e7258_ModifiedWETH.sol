/*
LAB 3: WETH contract

A simplified weth contract

Yanesh
*/

pragma solidity ^0.4.25;

contract ModifiedWETH {
    
    address public owner;
    mapping (address => uint) public balanceOf;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        balanceOf[tx.origin] += msg.value;
    }
    
    function() public payable {
        deposit();
    }
    
    function withdraw(uint amount) public {
        require(balanceOf[tx.origin] >= amount);
        balanceOf[tx.origin] -= amount;
        tx.origin.transfer(amount);
    }
    
    function transfer(address dst, uint amount) public returns (bool) {
        require(balanceOf[tx.origin] >= amount);
        balanceOf[tx.origin] -= amount;
        balanceOf[dst] += amount; 
        return true;

    }
    
    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }
    
}