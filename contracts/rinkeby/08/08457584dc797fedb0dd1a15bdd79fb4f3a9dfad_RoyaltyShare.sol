/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RoyaltyShare {

    function share(address[] memory receivers, uint256[] memory shares) public payable {
        require(
            receivers.length == shares.length,
            "Receivers and shares must have the same length"
        );
        uint256 sharesCount = 0;
        for (uint i = 0; i < shares.length; i++) {
            sharesCount += shares[i];
        }
        uint256 amount = msg.value / sharesCount;
        for (uint i = 0; i < receivers.length; i++) {
            payable(receivers[i]).transfer(amount * shares[i]);
        }
    }
}