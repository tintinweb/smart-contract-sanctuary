/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

pragma solidity 0.6.6;

contract PkCoin{
    
    int balance;
    
    constructor()public
    {
        balance=0;
    }
    
    function getBalance() public view returns(int)
    {
        return balance;
    }
    
    function depositBalance(int amt) public 
    {
         balance=balance+amt;
    }
    
     function withdrawBalance(int amt) public 
    {
         balance=balance-amt;
    }
    
}