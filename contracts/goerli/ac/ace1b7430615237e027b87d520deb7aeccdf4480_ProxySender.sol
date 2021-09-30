/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ProxySender
 * @dev Send incoming ETH to current recipient
 */
contract ProxySender {
    
    address payable public recipient;
    
    function setRecipient(address payable _recipient) external {
        recipient = _recipient;
    }
    
    receive() external payable {
       recipient.transfer(msg.value);
    }
}