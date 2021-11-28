/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multicall {

    struct CallInfo {
        uint256 first;
        uint256 second;
        uint256 third;
    }

    mapping (address => CallInfo) public calls;
    mapping (address => bool) public winners;

    function first() external {
        calls[msg.sender].first = block.number;
    }

    function second() external {
        calls[msg.sender].second = block.number;
    }

    function third() external {
        calls[msg.sender].third = block.number;
    }

    function claimWin() external {
        if (
            calls[msg.sender].first == block.number &&
            calls[msg.sender].second == block.number &&
            calls[msg.sender].third == block.number
        ) {
            winners[msg.sender] = true;
        }
    }

}