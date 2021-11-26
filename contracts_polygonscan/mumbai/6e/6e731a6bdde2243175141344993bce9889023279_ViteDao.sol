/**
 *Submitted for verification at polygonscan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract ViteDao {
  uint public voteEnd;
  bool ended;

  struct Voter {
    bool claimed;
    uint votetime;
  }
  address owner;
  mapping(address => Voter) public voters;

  constructor(uint _biddingTime) public {
    owner = msg.sender;
    voteEnd = now + _biddingTime;
  }

  function extend(uint _extendTime) public {
    require(owner == msg.sender, 'need owner privilege!');
    voteEnd = now + _extendTime;
  }

  function claim() public {
    require(now >= voteEnd, "Vote not yet ended.");
    require(!ended, "vote ended.");
    Voter storage voter = voters[msg.sender];
    require( !voter.claimed, "Already Claimed." );
    voters[msg.sender].claimed = true;
  }

  function vote() public{
    bool claimed = voters[msg.sender].claimed;
    require(claimed, "claim vote right first!");
    voters[msg.sender].votetime += 1;
  }

  function votetime() public view returns (uint number){
    bool claimed = voters[msg.sender].claimed;
    require(claimed, "claim vote right first!");
    number = voters[msg.sender].votetime;
  }
}