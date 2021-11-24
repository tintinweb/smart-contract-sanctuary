/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.4.19;

contract Faucet {
    // Give ether to anyone who ask
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000);
        
        msg.sender.transfer(withdraw_amount);
    }
    
    // Accept any incoming payment
    function() public payable {}
}