/**
 *Submitted for verification at Etherscan.io on 2020-11-24
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract ElectionManager{
    
    struct Election{
        uint id;
        uint total;
        string name;
        uint optionsCount;
        string[] options;
        string json;
        uint[] optionVotes;
        mapping(address => uint) userVotes;
    }

    struct VoteOption{
        string name;
        uint id;
    }

    mapping(address => bool) public voters;

    mapping(address => bool) public admins;
    address[] public adminsList;

    mapping(uint => Election) public elections;


    uint public lastElectionId = 1;
    uint public lastAdminId = 1;

    uint256 public voteFee = 0.01 ether;

    event NewElection(string name, uint id);
    event UserVote(address user, uint electionId, 
        string electionName, uint vote, string voteName);


    constructor(){
        admins[msg.sender] = true;
        adminsList.push(msg.sender);
    }

    receive () external payable {

    }

    modifier isAdmin(){
        require(admins[msg.sender]);
        _;
    }

    modifier isVoter(){
        require(voters[msg.sender]);
        _;
    }

    function adminAddVoter(address _addr) isAdmin public{
        voters[_addr] = true;
    }

    function adminRemoveVoter(address _addr) isAdmin public{
        voters[_addr] = false;
    }

    function adminAddAdmin(address _addr) isAdmin public{
        admins[_addr] = true;
        lastAdminId++;
        adminsList.push(_addr);
    }

    function adminSetVoteFee(uint256 _fee) isAdmin public{
        voteFee = _fee;
    }

    function adminAddElection(string memory _name, string[] memory _options, string memory _json) isAdmin public{
        Election storage e = elections[lastElectionId++];
        e.name = _name;
        e.id = lastElectionId;
        e.json = _json;
        for(uint i = 0; i< _options.length; i++){
            e.options.push(_options[i]);
            e.optionVotes.push(0);
        }
        emit NewElection(_name, lastElectionId-1);
    }

    function vote(uint _electionId, uint _vote) isVoter public{
        require(elections[_electionId].id > 0, "Invalid Election");
        require(elections[_electionId].userVotes[msg.sender] <= 0, "Already voted");
        elections[_electionId].total += 1;
        elections[_electionId].optionVotes[_vote-1] += 1;
        elections[_electionId].userVotes[msg.sender] = _vote;

        if(voteFee > 0){
            payable(msg.sender).transfer(voteFee);    
        }

        emit UserVote(msg.sender, _electionId, 
            elections[_electionId].name, 
            _vote, elections[_electionId].options[_vote-1]);
    }

    function userVote(address _addr, uint _electionId) public view returns(uint vote){
        vote = elections[_electionId].userVotes[_addr];
    }

    function getAdmins() public view returns(address[] memory _admins){
        _admins = adminsList;
    }

    function electionInfo(uint _id) public view returns(
        string[] memory _options,
        uint[] memory _optionVotes,
        uint _total,
        string memory _name,
        string memory _json
    ){
        _options = elections[_id].options;
        _total = elections[_id].total;
        _name = elections[_id].name;
        _optionVotes = elections[_id].optionVotes;
        _json = elections[_id].json;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}