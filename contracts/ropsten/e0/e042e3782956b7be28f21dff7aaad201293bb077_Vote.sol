/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Vote {

    event Voted(address indexed voter, uint8 proposal);

    mapping(address => bool) public voted;

    uint256 public endTime;

    uint256 public proposal1;
    uint256 public proposal2;
    uint256 public proposal3;

    constructor(uint256 _endTime) {
        endTime = _endTime;
    }

    function vote(uint8 _proposal) public {
        require(block.timestamp < endTime, "Vote expired.");
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal.");
        // require(!voted[msg.sender], "Cannot vote again.");
        voted[msg.sender] = true;
        if (_proposal == 1) {
            proposal1 ++;
        }
        else if (_proposal == 2) {
            proposal2 ++;
        }
        else if (_proposal == 3) {
            proposal3 ++;
        }
        emit Voted(msg.sender, _proposal);
    }

    function votes() public view returns (uint256) {
        return proposal1 + proposal2 + proposal3;
    }
}