// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Send ETH to multiple users 
 */
 
 contract MultiSend {
     
    struct SendData {
        address receiver;
        uint256 amount;
    }
     
    function multiSend(SendData[] calldata sendData) public payable {
        uint256 totalAmount;
        for (uint i = 0; i < sendData.length; i++) {
            totalAmount += sendData[i].amount;
        }
        
        require(totalAmount == msg.value, "Invalid amount");
        
        uint256 totalRefund;
        for (uint i = 0; i < sendData.length; i++) {
            (bool sent, ) = sendData[i].receiver.call{value: sendData[i].amount}("");
            if (!sent) {
                // On failure, accrue to refund to sender
                totalRefund += sendData[i].amount;
            }
        }
        
        if (totalRefund > 0) {
            // Refund any amounts necessary
            (bool sent, ) = msg.sender.call{value: totalRefund}("");
            if (!sent) {
                revert("Send failure");
            }
        }
    }
 }