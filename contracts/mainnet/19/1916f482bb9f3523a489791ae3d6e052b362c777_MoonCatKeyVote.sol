/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MoonCatKeyVote {

    // Should the MoonCatRescue developers destroy their private key so that no future Genesis MoonCats can ever be released?
    // true  = Yes
    // false = No

    event VoteSubmitted(address voter, bool vote);

    uint public voteStartTime = 0;
    bool public voteCancelled = false;
    mapping (address => bool) public hasVoted;
    uint32 public yesVotes = 0;
    uint32 public noVotes = 0;

    //bytes32 public immutable voterRollSha256;
    bytes32 public immutable merkleRoot;
    address public immutable owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Owner Only");
        _;
    }

    modifier voteContractIsPending {
        require(!voteCancelled, "Vote Contract Cancelled");
        require(voteStartTime == 0, "Vote Already Started");
        _;
    }

    modifier voteContractIsActive {
        require(!voteCancelled, "Vote Contract Cancelled");
        require(voteStartTime > 0, "Vote Not Started");
        require(block.timestamp < (voteStartTime + 48 hours), "Vote Ended");
        _;
    }

    modifier voteContractIsComplete {
        require(!voteCancelled, "Vote Contract Cancelled");
        require(voteStartTime > 0, "Vote Not Started");
        require(block.timestamp > (voteStartTime + 48 hours), "Vote Not Ended");
        _;
    }

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
        owner = msg.sender;
    }

    function startVote() public onlyOwner voteContractIsPending  {
        voteStartTime = block.timestamp;
    }

    function cancelVote() public onlyOwner voteContractIsPending {
        voteCancelled = true;
    }

    function getResult() public view voteContractIsComplete returns (bool) {
        return (yesVotes > noVotes);
    }

    uint24 empty = 0;

    function submitVote(bytes32[] calldata eligibilityProof, bool vote) public voteContractIsActive  {
        require(!hasVoted[msg.sender], "Duplicate Vote");

        // https://github.com/miguelmota/merkletreejs-solidity/blob/master/contracts/MerkleProof.sol
        bytes32 computedHash = keccak256(abi.encodePacked(msg.sender));
        for (uint256 i = 0; i < eligibilityProof.length; i++) {
            bytes32 proofElement = eligibilityProof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        require(computedHash == merkleRoot, "Ineligible Voter");

        hasVoted[msg.sender] = true;

        if(vote){
            yesVotes++;
        } else {
            noVotes++;
        }

        emit VoteSubmitted(msg.sender, vote);

    }
}