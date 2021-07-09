/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity >=0.4.22<0.7.1;

contract Voting{
    
    struct Candidate{
        uint id;
        string name;
        uint128 VoteCount;
    }
    
    mapping(uint=>Candidate)Candidates;
    mapping(address=>bool)Participants;
    
    uint128 CandidateCount;
    address owner;
    
    constructor()public{
        owner=msg.sender;
    }
    
    function AddCandidate(string memory _name) public returns(string memory){
        require(msg.sender==owner,"Error");
        CandidateCount++;
       Candidates[CandidateCount]=Candidate(CandidateCount,_name,0);
       return "Success";
    }
    
    function Vote(uint id) public returns(string memory){
        require(id<=CandidateCount && id>0 ,"Candidate Not Found");
        require(Participants[msg.sender]==false);
        Candidates[id].VoteCount++;
        Participants[msg.sender]=true;
        return "Success";
    }
    
    function ShowWinner() view public returns(string memory){
            uint winnerID=0;
            uint winnerVote=0;
            
            for(uint i=1;i<=CandidateCount;i++){
                if(Candidates[i].VoteCount>=winnerVote){
                    winnerID=i;
                    winnerVote=Candidates[i].VoteCount;
                }
            }
            return Candidates[winnerID].name;
            
    }
    
}