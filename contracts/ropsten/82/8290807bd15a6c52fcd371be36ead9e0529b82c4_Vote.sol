pragma solidity ^0.4.17;

contract Vote{
    uint16 voter=0;
    address public owner;
    
    struct Candidate{
        uint16 votes;
    } Candidate[5] candidates;

    bytes8[5] res;

    constructor() public{
        owner=msg.sender;
    }

    function vote(uint8 who) public{
        require(owner==msg.sender);
        voter++;
        candidates[who-1].votes++;
    }

    function result() constant public returns(uint16,uint16,uint16,uint16,uint16,uint16){
        return (voter,candidates[0].votes,candidates[1].votes,candidates[2].votes,candidates[3].votes,candidates[4].votes);
    }
}