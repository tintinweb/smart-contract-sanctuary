/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

// This contract accepts ETH, delivering it to the miner of the current block.
// The FlashbotsPayment event is interpretted by Flashbots MEV-geth at block construction time to determine bundle profitability
// queueEther() can be used if multiple transactions pay the miner, saving gas from emitting multiple events and sending ETH twice

contract FlashbotsMinerPaymentV1 {
    event FlashbotsPayment(address coinbase, address msgSender, uint256 amount);

    receive() external payable {
        _payMiner();
    }
    
    function _payMiner() private {
        uint256 amount = address(this).balance;
        payable(block.coinbase).transfer(amount);
        emit FlashbotsPayment(block.coinbase, msg.sender, amount);
    }
    
    function payMiner() external payable {
        _payMiner();
    }
    
    function queueEther() external payable { }
}