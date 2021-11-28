/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Issue {
    bool open;  // คูหาเปิด/ปิด
    mapping(address => bool) voted;
    mapping(address => uint) ballots;
    uint[] scores;
}

contract Election {
    address _admin; // ผู้ที่มีสิทธิ์เปิดปิดคูหาได้
    mapping(uint256 => Issue) _issues;  // เลือกตั้งครั้งที่...
    uint _issueId;
    uint _min;
    uint _max;

    event StatusChanged(uint indexed issueId, bool open);
    event Vote(uint indexed issueId, uint indexed votedNumber);

    // default min = 1, max = 5 (เลือกตั้งครั้งที่ 1 - 5)
    constructor(uint min, uint max) { 
        _admin = msg.sender; 
        _min = min;
        _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "unauthorised ");
        _;
    }

    function open() public onlyAdmin {
        require(!_issues[_issueId].open, "The election already be opened!");

        _issueId++;
        _issues[_issueId].open = true;
        _issues[_issueId].scores = new uint[](_max + 1);

        emit StatusChanged(_issueId, true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open, "The election already closed.");

        _issues[_issueId].open = false;

        emit StatusChanged(_issueId, false);
    }

    function vote(uint number) public {
        require(_issues[_issueId].open, "The election already be closed!");
        require(!_issues[_issueId].voted[msg.sender], "Voting can be performed just once!");
        require(number >= _min && number <= _max, "Incorrect number");

        _issues[_issueId].ballots[msg.sender] = number;
        _issues[_issueId].scores[number]++;
        _issues[_issueId].voted[msg.sender] = true;
        
        emit Vote(_issueId, number);
    }

    function checkStatus() public view returns(bool isOpened) {
        return _issues[_issueId].open;
    }

    function showMyBallot() public view returns(uint issueId, uint number) {
        require(_issues[_issueId].voted[msg.sender], "Your ballot has not been created yet.");
        return (_issueId, _issues[_issueId].ballots[msg.sender]);
    }

    function showScores() public view returns(uint[] memory) {
        return _issues[_issueId].scores;
    }
}