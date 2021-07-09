/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

//Version of solidity compiler the program was written for

// pragma solidity >=0.7.0 <0.9.0;
pragma solidity ^0.4.19;

//Our first contract is a faucet!
contract faucet {
    
    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {
        //Limit withdrawal amount
        require(withdraw_amount < 100000000000000000);
        
        //Send the amount to the address that requested it
        msg.sender.transfer(withdraw_amount);
    }
    
    
    //Accept any incoming amount
    function() public payable {}
}