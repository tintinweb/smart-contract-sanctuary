pragma solidity ^0.4.0;

contract  Vote {
    
    address admin;          //To store the address of the admin
    
    struct voter{
        bool voted;         //To check if the person already voted
    }
    
    constructor() public{
        admin = msg.sender;
    }
    
    uint public candidateOneVoteCount=0;            //count to respresent the no of votes of candidateOne
    uint public candidateTwoVoteCount=0;              //count to respresent the no of votes of candidateOne
    
    
    mapping(address => voter) voters;                //varaible to map each voter by its address

    event recVote(address voter,string name,uint c1Vote,uint c2Vote);
    
    
    function voteCandidateOne() public returns(bool) {                  //fuction to vote for candidate one
         voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted) return false;                                 //if already voted , return
        candidateOneVoteCount = candidateOneVoteCount +1;//cast the vote
        sender.voted = true;                //ensuring he doesn&#39;t vote again    return true;
        recVote(msg.sender,"Candidate One", candidateOneVoteCount, candidateTwoVoteCount);
        return true;
    }
    
    
     function voteCandidateTwo() public returns(bool) {                  //fuction to vote for candidate two
        voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted) return false;                                 //if already voted , return
        candidateTwoVoteCount = candidateTwoVoteCount +1;//cast the vote
        sender.voted = true;                //ensuring he doesn&#39;t vote again
        recVote(msg.sender,"Candidate Two", candidateOneVoteCount, candidateTwoVoteCount);
        return true;
    }
    
    
    function viewVotes() public constant returns (uint,uint){
        
        return(candidateOneVoteCount,candidateTwoVoteCount);
        
    }

    
}