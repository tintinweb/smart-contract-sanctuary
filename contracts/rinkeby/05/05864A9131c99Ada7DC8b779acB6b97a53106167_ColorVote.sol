/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract ColorVote {
    uint256 public blueTotal;
    uint256 public redTotal;
    mapping(address => uint256) public blueVoteAmount;
    mapping(address => uint256) public redVoteAmount;

    event Vote(address indexed voter, string indexed color, uint256 amount);
    event UnVote(address indexed voter, string indexed color, uint256 amount);

    constructor() {}

    function voteBlue() public payable {
        require(msg.value != 0, "You need to deposit some amount of money!");
        blueVoteAmount[msg.sender] += msg.value;
        blueTotal += msg.value;
        emit Vote(msg.sender, "blue", msg.value);
    }

    function voteRed() public payable {
        require(msg.value != 0, "You need to deposit some amount of money!");
        redVoteAmount[msg.sender] += msg.value;
        redTotal += msg.value;
        emit Vote(msg.sender, "red", msg.value);
    }

    function whoIsWinning() external view returns (string memory) {
        if (blueTotal > redTotal) {
            return "blue";
        } else if (redTotal > blueTotal) {
            return "red";
        } else {
            return "draw";
        }
    }

    function withdrawVote(uint256 _total, string memory color) public {
        if (
            keccak256(abi.encodePacked(color)) ==
            keccak256(abi.encodePacked("blue"))
        ) {
            // Withdraw blue vote
            require(
                _total <= blueVoteAmount[msg.sender],
                "You have insuffient funds to withdraw from Blue Vote"
            );
            blueVoteAmount[msg.sender] -= _total;
            blueTotal -= _total;
            emit UnVote(msg.sender, "blue", _total);
        } else if (
            keccak256(abi.encodePacked(color)) ==
            keccak256(abi.encodePacked("red"))
        ) {
            // Withdraw red vote
            require(
                _total <= redVoteAmount[msg.sender],
                "You have insuffient funds to withdraw from Red Vote"
            );
            redVoteAmount[msg.sender] -= _total;
            redTotal -= _total;
            emit UnVote(msg.sender, "red", _total);
        } else {
            require(false, "Invalid color");
        }

        address payable to = payable(msg.sender);
        to.transfer(_total);
    }

    function getUserVote() external view returns (uint256, uint256) {
        uint256 a = blueVoteAmount[msg.sender];
        uint256 b = redVoteAmount[msg.sender];
        return (a, b);
    }
}