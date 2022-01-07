/**
 *Submitted for verification at polygonscan.com on 2022-01-06
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED

contract RevelryEngMeetingSchedule {
    string[] public schedule;

    function generateSchedule(string[] memory _people) external {
        schedule = shuffle(_people);
    }

    function getSchedule() public view returns (string[] memory) {
        return schedule;
    }

    function shuffle(string[] memory array) public view returns (string[] memory) {
        for (uint256 i = 0; i < array.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (array.length - i);
            string memory temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }

        return array;
    }
}