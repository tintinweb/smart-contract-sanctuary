/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity 0.4.25;

contract Bank {
    int bal;
    
    constructor() public{
        bal = 1;
    }
    
    function getBalance() view public returns(int){
        return bal;
    }
    
    function withdraw(int amt) public{
        bal = bal-amt;
    }
    
    function deposit(int amt) public{
        bal = bal+amt;
    }
}