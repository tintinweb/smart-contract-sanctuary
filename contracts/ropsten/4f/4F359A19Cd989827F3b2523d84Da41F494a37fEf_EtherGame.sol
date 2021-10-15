// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherGame {
    uint public targetAmount = 3 ether;
    address public winner;

    // 不会执行 fallback 函数的内容

    function deposit() public payable {
        require(msg.value == 1 ether, "You can only send 1 Ether");

        uint balance = address(this).balance;
        require(balance <= targetAmount, "Game is over");

        if (balance == targetAmount) {
            winner = msg.sender;
        }
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function claimReward() public {
        require(msg.sender == winner, "Not winner");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}