/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct Issue{
    bool open;
    mapping(address=>bool) voted;
    mapping(address=>uint) ballots;
    uint[] scores;
}

contract Election{
    
    address _admin;
    mapping(uint=>Issue) _issues;
    uint _issueID;
    uint _min;
    uint _max;
    
    event StatusChange(uint indexed issueID,bool open);
    event Vote(uint indexed issueID,address voter,uint indexed option);
    
    constructor(uint min,uint max){
        _admin=msg.sender;
       _min=min;
       _max=max;
        
    }
    
    modifier onlyAdmin{
        require(msg.sender==_admin,"unauthorized");
        _;
    }
    
    function open() public onlyAdmin{
        require(!_issues[_issueID].open,"Elcetion opening");
        
        _issueID++;
        _issues[_issueID].open=true;
        _issues[_issueID].scores=new uint[](_max+1);
        emit StatusChange(_issueID,true); 
    }
    
    function close()public onlyAdmin{
        require(_issues[_issueID].open,"Election closed");
        
        _issues[_issueID].open=false;
        emit StatusChange(_issueID,false); 
    }
    
    function vote(uint option) public{
        require(_issues[_issueID].open,"Election closed");
        require(!_issues[_issueID].voted[msg.sender],"You are voted");
        require(option>=_min&&option<=_max,"incorrect option");
        
        _issues[_issueID].scores[option]++;
        _issues[_issueID].voted[msg.sender]=true;
        _issues[_issueID].ballots[msg.sender]=option;
        
        emit Vote(_issueID,msg.sender,option);
    }
    
    function status() public view returns(bool open_){
        return _issues[_issueID].open;
        
    }
    function ballot() public view returns(uint option_){
        require(_issues[_issueID].voted[msg.sender],"You are not vote");
        
        return _issues[_issueID].ballots[msg.sender];
        
    }
     function scoreView() public view returns(uint[] memory){
        
        
        return _issues[_issueID].scores;
        
    }
    
}