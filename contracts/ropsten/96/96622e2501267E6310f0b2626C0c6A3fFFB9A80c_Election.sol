/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct Issue {
    bool open;  //เปิดคูหา
    mapping(address => bool) voted; //Addressนี้ มีการเลือกตั้งแล้วหรือยัง
    mapping(address => uint) ballots; //Address ที่ลงคะแนนไปแล้วสามารถเช็คย้อนหลังได้ว่า Vote เบอร์อะไรไป
    uint[] scores; //หมายเลขอะไรได้คะแนนเท่าไหร่แล้ว
}


contract Election {
    address _admin;
    mapping(uint => Issue) _issues;
    uint _issueId;
    uint _min;
    uint _max;

    event StatusChange(uint indexed issueId, bool open);
    event Vote(uint indexed issueId, address voter, uint indexed option);

    constructor(uint min, uint max) {
        //มีแค่คนๆ เดียวที่สามมารถสังปิด/เปิด ได้
        _admin = msg.sender;
        _min = min;
        _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "Unauthorized");
        _; //keyword 
    }

    function open() public onlyAdmin {
        require(!_issues[_issueId].open, "Election opening");
        _issueId++;
        _issues[_issueId].open = true;
        _issues[_issueId].scores = new uint[](_max+1);
        emit StatusChange(_issueId, true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open, "Election closed");
        _issues[_issueId].open = false;
        emit StatusChange(_issueId, false);
    }

    function vote(uint option) public {
        require(_issues[_issueId].open, "Election closed");
        require(!_issues[_issueId].voted[msg.sender], "you are voted");
        require(option >= _min && option <= _max, "Incorrect option");

        _issues[_issueId].scores[option]++;
        _issues[_issueId].voted[msg.sender] = true;
        _issues[_issueId].ballots[msg.sender] = option;
        emit Vote(_issueId, msg.sender, option);
    }

    function status() public view returns(bool open_) {
        return _issues[_issueId].open;
    }

    function ballot() public view returns(uint option) {
        require(_issues[_issueId].voted[msg.sender], "you are not vote");
        return _issues[_issueId].ballots[msg.sender];
    }

    function scores() public view returns(uint[] memory){
        return _issues[_issueId].scores;
    }
}