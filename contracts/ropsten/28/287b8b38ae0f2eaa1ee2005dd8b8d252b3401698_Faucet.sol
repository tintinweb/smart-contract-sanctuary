/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

pragma solidity ^0.5.0;

contract Faucet{

    //give out test ether to anyone who ask
    function withdraw(uint withdraw_amount) public{
        //limit withdraw amount
        require(withdraw_amount <= 10**9);
        //send the amount to the address that asked for it
        msg.sender.transfer(withdraw_amount);
    }

    //to accept any incoming amount
    function() external payable{}

}