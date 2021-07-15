/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.5;

contract ConditionalVault {
    address payable public immutable recipient;
    address payable public immutable overflow;
    uint256 public immutable threshold;

    constructor(
        address payable recipient_,
        address payable overflow_,
        uint256 threshold_
    ) {
        recipient = recipient_;
        overflow = overflow_;
        threshold = threshold_;
    }

    function transfer() public {
        uint256 balance = address(this).balance;

        if (balance > threshold) {
            _sendFunds(overflow, balance - threshold);
            _sendFunds(recipient, threshold);
        } else {
            _sendFunds(recipient, balance);
        }
    }

    receive() external payable {}

    // ============ Private Utils ============

    function _sendFunds(address payable to, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Insufficient balance for send"
        );

        (bool success, ) = to.call{value: amount}("");
        require(success, "Unable to send value: recipient may have reverted");
    }
}