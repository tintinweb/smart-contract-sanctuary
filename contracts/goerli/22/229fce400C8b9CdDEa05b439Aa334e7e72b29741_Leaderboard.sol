//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Leaderboard {
    string[] leaders;
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    event Winner(address);

    function addLeader(string calldata leader) external {
        require(msg.sender == owner);

        leaders.push(leader);

        emit Winner(msg.sender);
    }

    function getAllLeaders() external view returns(string[] memory) {
        return leaders;
    }
}