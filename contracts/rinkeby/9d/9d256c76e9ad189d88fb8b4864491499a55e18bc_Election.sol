/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity >=0.4.21 <0.7.0;

contract Election {
    // model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // store candidates
    // fetch candidates
    mapping(uint => Candidate) public candidates;

    // store voters
    mapping(address => bool) public voters;

    // store candidates count
    uint public candidatesCount;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );

    // constructor
    constructor() public {
        addCandidate("Candidate1");
        addCandidate("Candidate2");
    }

    // add candidate
    function addCandidate(string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    // vote candidate
    function vote(uint _candidateId) public {
        // require that the voter has not voted before 
        // if false, it will throw exception & stop executing next line (cost gas up to this line)
        require(!voters[msg.sender]);

        // require a valid candidate 
        // if false, it will throw exception & stop executing next line (cost gas up to this line)
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // get the sender's (voter's) address using solidity global variable `msg.sender` & record it
        voters[msg.sender] = true;

        // update candidate vote count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}