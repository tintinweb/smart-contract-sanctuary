/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity 0.4.25;

contract Bank
{
    uint public bal;
    constructor() public
    {
        bal=1;
        
    }
    // function getBalance() view public returns(int)
    // {
    //     return bal;
    // }
    function withdraw(uint amnt)public
    {
        bal = bal - amnt;
    }
    function deposit(uint amnt)public
    {
        bal = bal + amnt;
    }
}