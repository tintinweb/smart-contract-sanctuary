/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
pragma abicoder v2;

contract EnsembleBallot{

    address ownersAddress;

    uint256 voteCount;

    modifier onlyOwner {
        require (msg.sender == ownersAddress);
        _;
    }

    struct Owner {
        address ownerAddress;
        string position;
        string name;
    }

    struct Member {
        address memberAddress;
        string name;
    }

    struct Voter {
        address voterAddress;
        uint256 vote;
    }

    Owner[] internal owners;

    Member[] internal members;
    mapping(address => string) internal addressToName;
    mapping(string => address) internal nameToAddress;

    Voter[] internal voters;
    mapping(address => uint256) internal addressToVote;

    constructor (string memory _position, string memory _name) {
        ownersAddress = msg.sender;
        Owner memory owner = Owner(ownersAddress, _position, _name);
        owners.push(owner);
    }

    function addMember(string memory _name) external{
        Member memory member = Member(msg.sender, _name);
        members.push(member);
        addressToName[member.memberAddress] = member.name;
        nameToAddress[member.name] = member.memberAddress;
    }

    function addVoter(uint256 _vote) external{
        Voter memory voter = Voter(msg.sender, _vote);
        voters.push(voter);
        addressToVote[voter.voterAddress] = _vote;
    }

    function viewMember(address _memAdd) public onlyOwner view returns(string memory){
        return addressToName[_memAdd];
    }

    function viewVoter(address _votAdd) public onlyOwner view returns(uint256){
        return addressToVote[_votAdd];
    }

}