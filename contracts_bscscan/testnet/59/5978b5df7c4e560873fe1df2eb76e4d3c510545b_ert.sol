/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;


contract ert{
    
    address private ow;
    uint32 public voting_Start_Time;
    uint public time_limit = 2 hours;
    uint public totalvote;
    
    constructor(){
        ow = msg.sender;
        voting_Start_Time = uint32(block.timestamp);
        add(address(1), "Jit1", "BJP", "B");
        add(address(2), "Jit2", "AAA", "A");
        add(address(3), "Jit3", "XXX", "C");
        
    }
    struct candidat{
        string name;
        string party;
        int8 vote;
        string symbole;
    }

    modifier onlyOwner {
        require(
            msg.sender == ow,
            "Only owner can call this function."
        );
        _;
    }
    
    mapping (address => candidat) public callcandid;
    mapping(address => bool) hasVoted;
    
    address[] public _candidates;
    
    function add(address addcandidate,string memory _name,string memory _party,string memory _symbole) public onlyOwner returns (bool) {
        callcandid[addcandidate].name = _name;
        callcandid[addcandidate].party = _party;
        callcandid[addcandidate].symbole = _symbole;
        _candidates.push(addcandidate);
        return true;
    }
    
    
    event E1(string data);
    event E2(uint i);
    event E3(uint i);
    event E4(uint i);
    function remove(address _address) public onlyOwner returns(bool){
        delete callcandid[_address];
        emit E1("Going inside for loop");
        for (uint i=0; i < _candidates.length;i++) {
            emit E2(i);
            if (_candidates[i] ==_address){
                delete _candidates[i];
                return true;
            }
        }
        return false;
    } 
    
    function candidatevote(address _address) public view returns (int8){
        int8 a = callcandid[_address].vote;
        return a;
    }
    
    function vote(address _address) public  returns (string memory){
        require(!hasVoted[msg.sender], "Can not vote again"); 
        require(block.timestamp <= uint(voting_Start_Time)+ time_limit && block.timestamp > uint(voting_Start_Time), "voting linl is end...");
        totalvote++;
        callcandid[_address].vote++;
        string memory a = "you vote is add";
        hasVoted[msg.sender] = true;
        return a;
    }
}