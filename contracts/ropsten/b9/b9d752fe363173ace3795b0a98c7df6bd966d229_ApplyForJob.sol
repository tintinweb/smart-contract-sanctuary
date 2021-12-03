/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface Challenge {
    function applyUsingEmail(bytes32 emailHash) external;
    function getApplicationID(string memory email) external view returns (uint256);
    }

contract ApplyForJob {

    Challenge public challenge = Challenge(0x78D36BA446D73Be73f32e2Cc181A82E3ba5fEf2E);

    function applyUsingEmail(string memory _text) public returns (bytes32) {
        bytes32 answer = keccak256(abi.encodePacked(_text));
        challenge.applyUsingEmail(answer);
        return answer;
    }    

    function getApplicationID(string memory email) external view returns (uint256) {
        return challenge.getApplicationID(email);
    }
}