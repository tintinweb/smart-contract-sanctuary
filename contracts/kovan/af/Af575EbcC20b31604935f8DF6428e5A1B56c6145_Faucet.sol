// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Faucet {

    // Accept any incoming BNB amount
    receive() external payable {}

    // Sends the amount of token to the caller.
    function send() external payable {

        // Check if faucet is empty
        require(address(this).balance > 1,"FaucetError: Empty");
        
        // Send requesting address all BNB
        payable(msg.sender).transfer(address(this).balance);
    }  
    
}

