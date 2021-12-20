/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Issue {
    bool open;
    mapping(address => bool) voted;
    mapping(address => uint) ballot;
    uint[] scores;
}

contract Election {
    address _admin;
    mapping(uint => Issue) _issues;
    uint _issuesId;
    uint _max;
    uint _min;

    event StatusChange(uint indexed issuesId,bool open);
    event voted(uint indexed issuesId, address voter, uint indexed option);

    constructor(uint min,uint max) {
        _admin = msg.sender;
        _min = min;
        _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "unauthorized");
        _;
    }

    function open() public onlyAdmin {
        require(!_issues[_issuesId].open,"Election opening");
        
        _issuesId++;
        _issues[_issuesId].open = true;
        _issues[_issuesId].scores = new uint[](_max+1);
        emit StatusChange(_issuesId,true);
    }

    function close() public onlyAdmin {
        require(_issues[_issuesId].open,"Election closed");

        _issues[_issuesId].open = false;
        emit StatusChange(_issuesId,false);
    }

    function vote(uint option) public {
        require(_issues[_issuesId].open,"Election closed");
        require(!_issues[_issuesId].voted[msg.sender],"you are voted");
        require(option >= _min && option <= _max,"incorrect option");

        _issues[_issuesId].scores[option]++;
        _issues[_issuesId].voted[msg.sender] = true;
        _issues[_issuesId].ballot[msg.sender] = option;
        emit voted(_issuesId, msg.sender, option);
    }

    function status() public view returns(bool open_) {
        return _issues[_issuesId].open;
    }

    function ballot() public view returns(uint option) {
        require(_issues[_issuesId].voted[msg.sender],"you are not vote");
        return _issues[_issuesId].ballot[msg.sender];
    }

    function scores() public view returns(uint[] memory) {
        return _issues[_issuesId].scores;
    }
}