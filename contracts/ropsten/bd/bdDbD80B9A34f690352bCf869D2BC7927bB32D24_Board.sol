/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity ^0.8.7;

/**
 * "SPDX-License-Identifier: MIT"
 */
contract Board{
            
    struct Member{
        address self;
        bool hasVoted;
        uint votes;
    }
    
    Member public CEO;
        modifier callerIsCEO() {
            require(msg.sender == CEO.self, "Caller is not the CEO");
            _;
        }
    
    Member[] public members;
        modifier callerIsMember() {
            require(isMember(msg.sender), "Caller is not a board member");
            _;
        }

    
    event CEOChange(address indexed oldOwner, address indexed newOwner);

    constructor() {
        CEO = Member({
            self: msg.sender,
            hasVoted : false,
            votes : 0
        });
        members.push(CEO);
        emit CEOChange(address(0), CEO.self);
    }
    
    function isMember(address individual) public view returns (bool){
        bool membership = false;
        for(uint i = 0; i < members.length; i++){
            if(members[i].self == individual){
                membership=true;
                break;
            }
        }
        return membership;
    }
    
    function addMembers(address newMember) public callerIsCEO{
        members.push(Member({
            self : newMember,
            hasVoted : false,
            votes : 0
        }));
    }
    
    function getMembers() public view returns (Member[] memory){
        return members;
    }
    
    function vote(address candidate) public callerIsMember {
        require(isMember(candidate), "Given candidate is not a board member");
        for(uint i = 0; i < members.length; i++){
            if(members[i].self == msg.sender){
                require(!members[i].hasVoted, "Member has already voted");
                members[i].hasVoted = true;
                for(uint j = 0; j < members.length; j++){
                    if(members[j].self == candidate){
                        members[j].votes +=1;
                    }
                }
                break;
            }
        }
    }
    
    function tallyVotes() public{
        Member storage newCEO = CEO;
        bool tie = false;
        for(uint i = 0; i < members.length; i++){
            if(members[i].votes > newCEO.votes){
                newCEO = members[i];
                tie = false;
            }else if(members[i].votes == newCEO.votes){
                tie = true;
            }
        }
        require(!tie, "Three has been a tie");
        require(newCEO.votes > members.length/2);
        emit CEOChange(newCEO.self, CEO.self);
        CEO = newCEO;
    }
    
    function resetElection() public{
        for(uint i = 0; i < members.length; i++){
            members[i].hasVoted = false;
            members[i].votes = 0;
        }
    }
 
}