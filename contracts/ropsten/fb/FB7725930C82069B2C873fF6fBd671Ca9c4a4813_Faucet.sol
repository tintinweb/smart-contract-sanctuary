/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity ^0.4.26;

contract Faucet {
    function withdraw(uint withdraw_amount) public {
        
        require(withdraw_amount <= 100000000);
        
        msg.sender.transfer(withdraw_amount);
    }
    
    function () public payable {}
}