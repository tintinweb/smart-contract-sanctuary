/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {

  mapping(address => int) public votes;

  function voteForPresident(address whoIamVotingFor) public payable returns(bool) {
    require(msg.value >= 1 ether, "You must pay at least 1 ether!");
    votes[whoIamVotingFor] += 1;
    return true;
  }

  function votesReceived(address candidate) public view returns(int) {
    return votes[candidate];
  }


  /*function returnTrue() public pure returns(bool) {
    return false;
  }

  function returnString() public pure returns(string memory) {
    return "hello world!";
  }//*/

}