/*
LAB 4: WETH AGENT

This contract will be deployed to ropsten and interact with the existing modified weth contract.

Yanesh
*/

pragma solidity ^0.4.25;

contract WethAgent {
    
    address public owner;
    ModifiedWETH w;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function set_modified_weth_address(address addr) public {
        // set w to be a new contract of type WETH
        w = ModifiedWETH(addr);
    }
    
    function callDeposit() public payable {
        w.deposit.value(msg.value)();

    }
    
    function callTransfer(address dst, uint amount) public {
        w.transfer(dst, amount);
    }
    
    function callWithdraw(uint amount) public {
        w.withdraw(amount);
    }
    
    function getBalanceOfModifiedWeth() public view returns (uint) {
        //returns balance of modified weth this contract has
        return w.totalSupply();
    }
}

contract ModifiedWETH {
    
    function deposit() public payable;
    
    function withdraw(uint amount) public;
    
    function transfer(address dst, uint amount) public returns (bool);
    
    function totalSupply() public view returns (uint);
}