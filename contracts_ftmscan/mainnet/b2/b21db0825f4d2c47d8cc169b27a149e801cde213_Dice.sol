// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "Ownable.sol";

contract Dice is Ownable {
    mapping (address => uint256) public balances;
    bool public inRound;

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    modifier onlyOutsideRounds() {
        require(!inRound, "Can't withdraw during a round");
        _;
    }

    function withdraw(uint256 amount) public onlyOutsideRounds {
        require(balances[msg.sender] >= amount, "Inadequate balance");
        (bool _sent,) = msg.sender.call{value: amount}("");
        balances[msg.sender] -= amount;
        require(_sent, "Failed to withdraw Ether");
    }

    function startRound() public onlyOwner {
        inRound = true;
    }

    function payout(address[] calldata losers, uint256[] calldata lossAmounts, address winner, uint256 pot) public onlyOwner {
        require(losers.length == lossAmounts.length, "Bad arrays");
        for (uint i = 0; i < losers.length; i++) {
            balances[losers[i]] -= lossAmounts[i];
        }
        (bool _sent,) = msg.sender.call{value: pot * 5 / 100}("");
        balances[winner] += pot * 95 / 100;
        inRound = false;
        require(_sent, "Failed to withdraw Ether");
    }
}