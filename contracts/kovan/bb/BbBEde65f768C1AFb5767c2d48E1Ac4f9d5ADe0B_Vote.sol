//SPDX-License-Identifier:MIT
pragma solidity >=0.6.6;


contract Vote
{
    
    mapping(address=>Voter) public Voters;
    VCandidate[] public Candidates;
    uint public total_cand=0;
    uint public total_voters=0;
    
    int256 end;
    //winner feature to be added
    uint256 public winner;
    // uint256 start;
    address public owner;
    
    enum VOTE_STATE {
        
        OPEN,
        CLOSED
      
    }

    
    VOTE_STATE public vote_state;
    
    struct Voter
    {
      bool isauthorised;
      bool hasVoted;
    }
    struct VCandidate
    {
        string name;
        uint256 voteCount;
    }
    
      
    modifier OnlyOwner
    {
        require(owner==msg.sender);
        _;
    }


    constructor(){
    
    vote_state=VOTE_STATE.CLOSED; 
    owner=msg.sender;
        
    }
    

    
    function addCandidate(string memory _name) public OnlyOwner
    {
     Candidates.push(VCandidate(_name,0));
     total_cand+=1;   
    }

       function addCandidateBulk(string [] memory _names) public OnlyOwner
    {
        for(uint i =0;i<_names.length;i++)
        {
            Candidates.push(VCandidate(_names[i],0));
            total_cand+=1;   
    
        }
    }
    
    
    function addVoterseBulk(address [] memory _names) public OnlyOwner
    {
        for(uint i =0;i<_names.length;i++)
        {   Voters[_names[i]].isauthorised=true;
            Voters[_names[i]].hasVoted=false;
            
            total_voters+=1;   
    
        }
    }
    
     
    function addVoter(address a) public OnlyOwner
    {
     Voters[a].isauthorised=true;
     Voters[a].hasVoted=false;
     total_voters+=1 ;

    }
    
    
    function startVote(uint256 _time) public OnlyOwner
    {
     require(vote_state==VOTE_STATE.CLOSED,"Cant be initiated");
     vote_state=VOTE_STATE.OPEN; 
     
     end=int256(block.timestamp+_time);

    }
    

    
    
    function voteCandidate(uint Index) public
    
    {   
        require(end-int256(block.timestamp)>0,"time ends");
        require(vote_state==VOTE_STATE.OPEN,"vote not started");
        require(Voters[msg.sender].isauthorised==true,"No voter");
        require(Voters[msg.sender].hasVoted==false,"Already voted");
        Candidates[Index].voteCount+=1;   
        Voters[msg.sender].hasVoted=true;
        
    }

    
    function timeleft() public view returns (int256)
    {
        return end-int256(block.timestamp);
    }
        
    function endVote() public OnlyOwner
    {require(end-int256(block.timestamp)<1,"time left");

    
     selfdestruct(payable(owner)); 

    }
    function getCandidateArray()public view returns( VCandidate[]memory){
    return Candidates;
    }
    
    
    
    
    
}