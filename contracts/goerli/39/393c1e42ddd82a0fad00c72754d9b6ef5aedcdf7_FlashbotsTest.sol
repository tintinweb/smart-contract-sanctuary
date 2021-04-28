/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract FlashbotsTest {
    function accept(address payable target, uint256 bribe) payable external {
        uint256 amount = msg.value - bribe;
        target.transfer(amount);
    
        block.coinbase.transfer(bribe);
    }
}