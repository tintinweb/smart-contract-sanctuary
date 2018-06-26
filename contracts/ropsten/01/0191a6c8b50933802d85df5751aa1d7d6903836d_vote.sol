pragma solidity ^0.4.24;

//
// @author Dmitriev Vyacheslav 
//
contract vote {
    
    // Candidates
    address public candidatA;
    address public candidatB;
    address public whoWin;
    
    uint public endVoteDate;
    bool public needAnotherVote;

    // Candidat&#39;s address => amount of votes
    mapping (address => uint) public votes;
    
    // Vote options
    // 0 - Address hasn&#39;t voted yet
    // 1 - Vote for candidat A
    // 2 - Vote for candidat B
    // 3 - against all
    mapping(address => uint) public voteOptions;
    
    constructor(address _candidatA, address _candidatB, uint _endVoteDate) public {
        candidatA = _candidatA;
        candidatB = _candidatB;
        require(_endVoteDate > now);
        endVoteDate = _endVoteDate;

   }
    
    function makeVote(uint _vote) public {
        require(now < endVoteDate);
        require(voteOptions[msg.sender] == 0); // Msg sender hasn&#39;t voted yet
        require(msg.sender != candidatA && msg.sender != candidatB); 
        if(_vote == 1) {
            votes[candidatA] += 1;    
        }
        else if(_vote == 2) {
            votes[candidatB] += 1;    
        }
        else if(_vote == 3) {
            //  do nothing
        }
        else {
            revert();
        }
        voteOptions[msg.sender] = _vote;
    }
    
    function finishVote() public  {
        require(now > endVoteDate);
        if(votes[candidatA] > votes[candidatB]) {
            whoWin = candidatA;
        }
        else if(votes[candidatA] < votes[candidatB]) {
            whoWin = candidatB;
        }
        else {
            needAnotherVote = true;
        }
    }
}