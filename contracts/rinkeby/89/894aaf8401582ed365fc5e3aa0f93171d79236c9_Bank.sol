/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.25;
 
contract Bank{
    
    int bal;
    constructor () public{
        bal = 1;
    }
    function getBalance() view public returns(int){
        return bal;
    }
    function withdrawBalance(int amt) public{
        bal =bal-amt;
    }
    function deposit(int amt) public{
        bal= bal+amt;
    }
}