// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Faucet {

    // Accept any incoming BNB amount
    receive() external payable {}

    // Sends the amount of token to the caller.
    function send(address payable recipient) external {

        // Check if faucet is empty
        require(address(this).balance > 1,"FaucetError: Empty");
        
        (bool success, ) = recipient.call{value: 1000}("");
        require(success, "Transfer failed.");
    }  
    
}

