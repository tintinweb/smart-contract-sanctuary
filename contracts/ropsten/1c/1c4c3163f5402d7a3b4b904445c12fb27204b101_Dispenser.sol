/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Dispenser {

    address payable immutable owner;
    uint256 immutable dispenseAmountPerRequest;

    event DonationReceived(uint256 indexed amount);

    constructor(uint256 dispenseAmount) payable {
        owner = payable(msg.sender);
        dispenseAmountPerRequest = dispenseAmount;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner allowed!");
        _;
    }

    receive() external payable {
        emit DonationReceived(msg.value);
    }

    function requestCoins() public {
        payable(msg.sender).transfer(dispenseAmountPerRequest);
    }

    function withdraw() public ownerOnly {
        owner.transfer(address(this).balance);
    }

    function destroy() public ownerOnly {
        selfdestruct(owner);
    }
}