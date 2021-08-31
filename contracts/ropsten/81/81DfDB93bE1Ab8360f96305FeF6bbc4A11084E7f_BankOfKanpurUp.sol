/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.8.4;

contract BankOfKanpurUp{
    int bal;
    
    constructor() public {
        bal = 0;
    }
    
    function getbalance() view public returns(int){
        return bal;
    }
    function deposit(int amt) public {
        bal = bal +amt;
    }
    function withdraw(int amt)  public {
        bal = bal - amt;
    }
    
}