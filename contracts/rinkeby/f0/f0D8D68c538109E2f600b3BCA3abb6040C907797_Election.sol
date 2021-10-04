/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Issue{
    bool open;
    //check voted
    mapping(address => bool) voted;
    //check total vote
    mapping(address => uint) ballots;
    //score of number voting
    uint[] scores;
}

contract Election{
    //record voting
    mapping(uint => Issue) _issue;
    uint _issueID;
    uint _min;   
    uint _max;
    //create permission for admin to open and close voting
    address _admin;
    constructor(){
        _admin = msg.sender;
        _min =1;
        _max = 5;
    }
    //create permission
    modifier onlyAdmin{
        require(msg.sender == _admin, "unauthorized");
        _;
    }
    event StatusChange(uint indexed issueID, bool open);
    event Vote(uint indexed issueID, address voter, uint indexed option);
    function open() public onlyAdmin {
        //check voting is opening or not
        require(!_issue[_issueID].open, "Election opening");
        // when open voting then set vote id
        _issueID++;
        _issue[_issueID].open =true;
        _issue[_issueID].scores = new uint[](_max+1);
        emit StatusChange(_issueID, true);
    }
    function close()public onlyAdmin{
        require(_issue[_issueID].open, "Election closing");
        _issue[_issueID].open = false;
        emit StatusChange(_issueID, false);
    }
    function vote(uint option) public{
        require (_issue[_issueID].open, "Election is closing");
        require(!_issue[_issueID].voted[msg.sender], "you are voted");
        require(option>=_min && option <= _max, "incorrect option");
        //add vote
        _issue[_issueID].scores[option]++;
        //set status vote
        _issue[_issueID].voted[msg.sender] = true;
        //set whice optin user is voted
         _issue[_issueID].ballots[msg.sender] = option;
         emit Vote(_issueID, msg.sender, option);
    }
    function checkStatus() public view returns(bool Open){
        return _issue[_issueID].open;
    }
    // check who i vote for
    function ballot() public view returns(uint option){
        require(_issue[_issueID].voted[msg.sender], "you are not voted");
        return _issue[_issueID].ballots[msg.sender];
    }
    function scores() public view returns(uint[] memory){
        return _issue[_issueID].scores;
    }
}