/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;
// specifies what version of compiler this code will be compiled with

contract Voting {

    address public administrator;
    modifier onlyAdministrator() {
       require(msg.sender == administrator,
          "the caller of this function must be the administrator");
       _;
    }
  /* the mapping field below is equivalent to an associative array or hash.
  */

  mapping (string => uint256) votesReceived;

  /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
  We will use an array of bytes32 instead to store the list of candidates
  */

  string[] public candidateList;

  /* Broadcast event when a user voted
  */
  event VoteReceived(address user, string candidate);

  /* This is the constructor which will be called once and only once - when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of candidates who will be contesting in the election
  */
  constructor(string[] memory candidateNames) public {
    candidateList = candidateNames;
    administrator = msg.sender;
  }

  // This function returns the total votes a candidate has received so far
  function totalVotesFor(string memory candidate) public view returns (uint256) {
    return votesReceived[candidate];
  }

  // This function increments the vote count for the specified candidate. This
  // is equivalent to casting a vote
  function voteForCandidate(string memory candidate) public onlyAdministrator {
    votesReceived[candidate] += 1;

    // Broadcast voted event
    emit VoteReceived(msg.sender, candidate);
  }

  function candidateCount() public view returns (uint256) {
      return candidateList.length;
  }
}