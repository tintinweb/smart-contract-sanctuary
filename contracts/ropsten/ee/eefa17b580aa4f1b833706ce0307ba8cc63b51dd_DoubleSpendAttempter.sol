/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.1;

contract DoubleSpendAttempter {
    function amountChance(address payable destination, uint256 denominator) external payable {
        uint256 destinationAmount = block.timestamp % 2 == 0 ? msg.value / denominator : msg.value;
        destination.transfer(destinationAmount);
        
        if (destinationAmount != msg.value) {
            msg.sender.transfer(msg.value - destinationAmount);
        }
    }
    
    function destinationChance(address payable destination) external payable {
        (block.timestamp % 2 == 0 ? msg.sender : destination).transfer(msg.value);
    }
}