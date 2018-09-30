pragma solidity ^0.4.18;

contract Elections {
    //Declare a Owner
    address public owner;

    //Model a Candiate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        string comments;
    } 
     //Store accounts that has voted
     mapping(address => bool) public voters;
    //Store Candidate

    //Fetch Candidate
    mapping(uint => Candidate) public candidates;
    //Store Candidates Count
    uint public candidatesCount;
    
    //voted event
    event VotedEvent (
      uint indexed _candidateId
    ); 

    
    //Constructor
    constructor () public {
        owner = msg.sender;
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }
    function restricted () public view returns (bool) {
        if (msg.sender == owner)
           return true;
           else 
           return false;
    }
    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0,"");
    }
    function vote (uint  _candidateId, string _candidatesComments) public {
     //require that they haven&#39;t voted before
     require(!voters[msg.sender]);

     //require a valid candidate
     require(_candidateId > 0 && _candidateId <= candidatesCount);

     //record that voter has voted
      voters[msg.sender] = true;

      //update candidate vote Count
       candidates[_candidateId].voteCount ++;
       candidates[_candidateId].comments = _candidatesComments;

       //trigger voted event
      emit VotedEvent(_candidateId);
    }
}