/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface TurboVerifier {
    function verify(bytes calldata, bytes calldata)
        external
        view
        returns (bool);
}

contract NoirBounty {
    mapping(address => bool) public bountyParticipants;
    mapping(bytes32 => bool) public answers;

    address public verifierAddress = 0x4a4c996918BA0d1C3bD9BeC4B8EfEf607a6e610d;

    event BountyComplete(address bountyParticipant, bytes uniqueToken);

    function submitBountyProof(
        bytes calldata _proof,
        uint256 _answer1,
        uint256 _answer2,
        uint256[32] calldata _answer3
    ) public {
        bytes memory public_inputs =
            abi.encodePacked(_answer1, _answer2, _answer3);
        require(
            TurboVerifier(verifierAddress).verify(_proof, public_inputs),
            "Proof not correct, try again"
        );
        require(
            answers[keccak256(abi.encodePacked(_answer1))] == false,
            "Answer already used"
        );
        require(
            bountyParticipants[msg.sender] == false,
            "Address already used"
        );
        answers[keccak256(abi.encodePacked(_answer1))] = true;
        answers[keccak256(abi.encodePacked(_answer3))] = true;
        answers[keccak256(abi.encodePacked(_answer3))] = true;

        emit BountyComplete(msg.sender, abi.encodePacked(_answer3));
    }
}