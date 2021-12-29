/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.7;

contract Vote {

    event Voted(address indexed voter, uint8 proposal);

    mapping(address => uint256) public voted;

    address public owner;
    uint256 public endTime;

    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;

    constructor(uint256 _endTime) {
        owner = msg.sender;
        endTime = _endTime;
    }

    function vote(uint8 _proposal) public {
        require(block.timestamp < endTime, "Vote expired.");
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal.");
        require(voted[msg.sender] == 0, "Cannot vote again.");
        voted[msg.sender] ++;
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

    function kill() public {
        require(owner == msg.sender, "kill must be owner");
        selfdestruct(payable(msg.sender));
    }
}