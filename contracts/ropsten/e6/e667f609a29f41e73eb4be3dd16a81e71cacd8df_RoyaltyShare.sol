/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RoyaltyShare {
    address public owner;
    address[] public receivers;

    event Received(address, uint);

    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function addReceiver(address receiver) public {
        require(
            msg.sender == owner,
            "Only owner can add receivers"
        );
        receivers.push(receiver);
    }
    
    function share() public {
        uint256 amount = address(this).balance / receivers.length;
        for (uint i = 0; i < receivers.length; i++) {
            payable(receivers[i]).transfer(amount);
        }
    }
}