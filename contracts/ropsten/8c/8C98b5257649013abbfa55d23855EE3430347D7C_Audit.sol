//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract Audit {
    struct Voter {
        uint256[] preferences;
        uint256 current;
    }

    mapping(address => Voter) public allVoters;

    event Voted(address id, Voter user);

    // constructor() {
        
    // }

    function vote(uint256[] memory _preferences) public {
        // todo checks to verify the user is allowed to vote
        // todo checks to verify perferences is in the correct format

        Voter memory voterStruct = Voter(_preferences, 0);
        
        allVoters[msg.sender] = voterStruct;

        // log the vote
        emit Voted(msg.sender, voterStruct);
    }
}