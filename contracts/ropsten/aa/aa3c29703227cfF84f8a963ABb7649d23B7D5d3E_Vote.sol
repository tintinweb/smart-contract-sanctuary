/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/Vote.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Vote{
    struct Proposal{
        string name;
        uint votesCount;
    }
    struct Voter{
        bool voted;
        uint vote;
    }

    address chairperson;

    Proposal[] public proposals;

    mapping(address => Voter) public voters;

    constructor(){
        chairperson = msg.sender;
    }

    modifier onlyAdmin(){
        require(msg.sender == chairperson, "you aren't the admin");
        _;
    }

    modifier onlyUserNotVotedYet(){
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "you already voted");
        _;
    }

    function addProposal(string memory _name) public onlyAdmin{
        proposals.push(Proposal({
            name:_name,
            votesCount:0
        }));
    }

    function vote(uint32 index) public onlyUserNotVotedYet{
        Voter storage sender = voters[msg.sender];
        sender.voted=true;
        sender.vote=index;
        proposals[index].votesCount += 1;
    }

    function getChairPerson() public view returns(address){
      return chairperson;
    }

    function getLengthProposals() public view returns(uint256){
      return proposals.length;
      
    }
    function getVotesById(uint index) public view returns(uint256){
      return proposals[index].votesCount;

    }
    function getProposals() public view returns(Proposal[] memory){
      return proposals;
    }
}