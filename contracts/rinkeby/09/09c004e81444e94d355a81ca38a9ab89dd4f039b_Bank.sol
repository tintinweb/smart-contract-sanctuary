/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity 0.4.25;

contract Bank
{
    int Bal;
    
    constructor() public
    {
        Bal = 1;
    }
    
    function getBalance() view public returns(int)
    {
        return Bal;
    }
    
    function withdraw(int amt) public
    {
        Bal = Bal - amt;
    }
    
    function deposit(int amt) public
    {
        Bal = Bal + amt;
    }
}