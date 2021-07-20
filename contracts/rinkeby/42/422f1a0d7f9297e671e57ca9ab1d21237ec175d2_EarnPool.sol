/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity 0.4.25;

contract EarnPool
{
    int bal;
    
    constructor()  public
    {
       bal = 1;
    }
    
    function getbalance() view public returns(int)
    {
        return bal;
    }
    
    function withdraw(int amt) public
    {
        bal = bal - amt;
    }
    
    function deposit(int amt) public
    {
        bal = bal + amt;
    }
}