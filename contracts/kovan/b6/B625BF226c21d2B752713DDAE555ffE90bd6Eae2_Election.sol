/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Issue {
    bool open;
    mapping(address => bool) voted;
    mapping(address => uint) ballots;
    //uint[] scores;
}

struct Candidate {
    uint id;
    string name;
    uint voteCount;
    }

contract Election {
    
    address _admin;
    mapping(uint => Issue) _issues; 
    uint _issueId;
    //uint _min;
    //uint _max;
    mapping(uint => Candidate) public _candidates;
    uint public candidatesCount;

    event StatusChange(uint indexed _issueId, bool open);
    event Vote(uint indexed _issueId, address voter, uint indexed _candidateId);

    constructor() {
        _admin = msg.sender;
       // _min = min;
       // _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "unauthorized");
        _;
    }

    function open() public onlyAdmin {
        require(!_issues[_issueId].open, "election opening");

        _issueId++;
        _issues[_issueId].open = true;
        //_candidates[_candidateId].voteCount = 0;
        //_issues[_issueId].scores = new uint[](_max+1);
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        emit StatusChange(_issueId, true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open, "election closed");

        _issues[_issueId].open = false;
        emit StatusChange(_issueId, false);
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        _candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        require(_issues[_issueId].open, "election closed");
        require(!_issues[_issueId].voted[msg.sender], "you're voted");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "incorrect candidateId");

        _candidates[_candidateId].voteCount ++;
        _issues[_issueId].voted[msg.sender] = true;
        _issues[_issueId].ballots[msg.sender] = _candidateId;
        emit Vote(_issueId, msg.sender, _candidateId);
    }

    function status() public view returns(bool open_) {
        return _issues[_issueId].open;
    }

    function ballot() public view returns(uint candidateId_) {
        require(_issues[_issueId].voted[msg.sender], "you're not vote");

        return _issues[_issueId].ballots[msg.sender];
    }

    // function scores() public view returns(uint[] memory) {
    //     return _issues[_issueId].scores;
    // }
}