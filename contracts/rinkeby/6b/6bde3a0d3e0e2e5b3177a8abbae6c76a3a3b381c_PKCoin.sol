/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity 0.6.6;

contract PKCoin{

    int balance = 0;

    function getBalance() public view returns(int){

        return balance;
    }

    function depositbalance(int amt) public{
        balance = balance + amt;
    }

    function withdrawbalance(int amt) public{
        balance = balance - amt;
    }
 

    
}