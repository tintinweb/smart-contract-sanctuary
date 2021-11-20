/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.5.17;

contract BallotBox{
  
    uint ElectoralWard; 
    uint VotingSection; 
    uint TimeStampStart; 
    uint TimeStampEnd; 
    uint CandidateA = 0; 
    uint CandidateB = 0;  
    uint BlankVotes = 0; 
    uint Repeated_votes = 0; 
    uint NumberCandidateA = 1; 
    uint NumberCandidateB = 2; 
    uint NumberBlankVotes = 3; 
    address BallotBoxAdress; 
    address RemoteControllAdress; 
    uint[] ElectorID; 
    bool AlreadyVoted = false; 
    bool BallotBoxAdressEnable = false;


    
    constructor(uint _ElectoralWard, uint _VotingSection) public  { 
        ElectoralWard = _ElectoralWard;
        VotingSection = _VotingSection;
        BallotBoxAdress = msg.sender;
    }
    
function changeData(uint _ElectoralWard, uint _VotingSection)public {
    ElectoralWard = _ElectoralWard;
        VotingSection = _VotingSection;
        BallotBoxAdress = msg.sender;
          CandidateA = 0; 
     CandidateB = 0;  
    BlankVotes = 0; 
     Repeated_votes = 0; 
    
}
    
    
    function StartVoting() public verification1(){ 
    
        TimeStampStart = block.timestamp; 
        
    }

    
    function FirstPrinting() public view verification1() returns(uint zona, uint _VotingSection, uint _TimeStampStart, uint _CandidateA, uint _CandidateB, uint _BlankVotes, uint _Repeated_votes){

        return( ElectoralWard,
                VotingSection,
                TimeStampStart,
                CandidateA,
                CandidateB,
                BlankVotes,
                Repeated_votes);
        
    }
    
    function EnablePollWorker()public{
        RemoteControllAdress = msg.sender; 
    }
 
    
    function InsertElectorID(uint _ElectorID) public verification2 {
       
        for(uint i=0; i < ElectorID.length; i++){ 
            if(_ElectorID == ElectorID[i]){ 
                    AlreadyVoted = true;
            }
        }
        if(AlreadyVoted == false){ 
            ElectorID.push(_ElectorID); 
        }

    }
    
    function EnableElectronicBallotBox() public verification4(){
        BallotBoxAdressEnable = true; 
    }

    
    function ToVote(uint voto) public verification3(BallotBoxAdressEnable){
        if(BallotBoxAdressEnable == true){ 
            if(voto == NumberCandidateA){
                CandidateA++; 
            }
            else if(voto == NumberCandidateB){
                CandidateB++; 
            }
            else if(voto == NumberBlankVotes){
                BlankVotes++; 
            }
            else{
                Repeated_votes++;
            }
        }
        BallotBoxAdressEnable = false; 
    }

    
    function FinishVoting() public verification1(){
        TimeStampEnd = block.timestamp; 
        BallotBoxAdressEnable = false; 
    }
    
      
    function LastPrinting() public view verification1() returns(uint zona, uint _VotingSection, uint _TimeStampEnd, uint _CandidateA, uint _CandidateB, uint _BlankVotes, uint _Repeated_votes){ 

        return( ElectoralWard,
                VotingSection,
                TimeStampStart,
                CandidateA,
                CandidateB,
                BlankVotes,
                Repeated_votes);
        
    }
    modifier verification1(){
        require(msg.sender == BallotBoxAdress, "This command need come from the electronic Ballot Box Adress");
        _;
    }
    modifier verification2(){
        require(msg.sender == RemoteControllAdress, "This command need come from the poll worker Adress");
        _;
    }
    modifier verification3(bool status){
        require(msg.sender == BallotBoxAdress, "This command need come from the electronic Ballot Box Adress");
        _;
        require(status == true, "The electronic ballot box is disable, because this elector already voted");
        _;
    }
    modifier verification4(){
        require(msg.sender == RemoteControllAdress, "This command need come from the poll worker Adress");
        _;
        require(AlreadyVoted == false, "The electronic ballot box is disable, because this elector already voted");
        _;
    } 
}