/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RoyaltyShare {
    address private owner;
    uint public sharesCount;
    uint public maxSharesCount;
    mapping(address => bool) private managers;
    
    struct Receiver {
        uint sharesCount;
        address wallet;
    }

    Receiver[] public receivers;

    event Received(address, uint);

    constructor() {
        owner = msg.sender;
        maxSharesCount = 20;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function addManager(address manager) public {
        require(
            msg.sender == owner,
            "Only owner can add manager"
        );
        managers[manager] = true;
    }

    function addReceiver(address receiver, uint count) public {
        require(
            msg.sender == owner || managers[msg.sender],
            "Only owner or manager can add receivers"
        );
        require(
            sharesCount + count < maxSharesCount,
            "Not enough vacant shares"
        );
        sharesCount += count;
        receivers.push(Receiver({wallet: receiver, sharesCount: count}));
    }
    
    function share() public {
        require(
            msg.sender == owner || managers[msg.sender],
            "Only owner or manager can share the balance"
        );
        require(
            sharesCount == maxSharesCount,
            "There are still vacant shares"
        );
        uint256 amount = address(this).balance / maxSharesCount;
        for (uint i = 0; i < receivers.length; i++) {
            payable(receivers[i].wallet).transfer(amount * receivers[i].sharesCount);
        }
    }
}