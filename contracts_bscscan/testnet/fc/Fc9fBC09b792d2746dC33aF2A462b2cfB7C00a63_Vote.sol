// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Vote {

    event Voted(address indexed voter, uint8 proposal);

    mapping(address => bool) public voted;

    uint256 public endTime;

    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;

    constructor(uint256 _endTime) {
        endTime = _endTime;
    }

    function vote(uint8 _proposal) public {
        require(block.timestamp < endTime, "Vote expired.");
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal.");
        require(!voted[msg.sender], "Cannot vote again.");
        voted[msg.sender] = true;
        if (_proposal == 1) {
            proposalA ++;
        }
        else if (_proposal == 2) {
            proposalB ++;
        }
        else if (_proposal == 3) {
            proposalC ++;
        }
        emit Voted(msg.sender, _proposal);
    }

    function votes() public view returns (uint256) {
        return proposalA + proposalB + proposalC;
    }
}