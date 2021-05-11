/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity 0.6.4;

contract Faucet {
    
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 100000000000000000);

        // Send the amount to the address that requested it
        msg.sender.transfer(withdraw_amount);
    }
    
    receive() external payable {}
    
}