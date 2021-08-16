pragma solidity ^0.8.6;
import './ownable.sol';

contract Vote is Ownable{
    
    bool public votingIsOver;
    mapping (address=>form) private vote;
    address[] private alreadyVoted;
    struct form{
        uint16 region;
        bool firstQuestion;
        bool secondQuestion;
    }
    
    constructor(address _owner) {
        owner=_owner;
    }

    modifier notOver(){
        require(votingIsOver==false,"Sorry, but voting is over");
        _;
    }

    modifier notAlreadyVotedAndUser(){
        require(vote[msg.sender].region==0 && msg.sender==tx.origin);
        _;
    }

    function fillForm(uint16 region,bool firstQue, bool secondQue) external notOver notAlreadyVotedAndUser {  
        alreadyVoted.push(msg.sender);
        vote[msg.sender].firstQuestion=firstQue;
        vote[msg.sender].secondQuestion=secondQue;
        vote[msg.sender].region=region;
    }  

    function getAlreadyVoted()  external view returns(address[] memory){ 
        return(alreadyVoted);
    } 

    function getForm(address id)  external view returns(uint16,bool,bool){
        return(vote[id].region,vote[id].firstQuestion,vote[id].secondQuestion);
    }
    
    function howMuchVoted() external view returns(uint256) {
        return alreadyVoted.length;
    }

    function endVote() onlyOwner public {
        votingIsOver=true;
    }
}


interface VoteInterface{
    
    function getForm(address id) external view returns(uint16,bool,bool);
    function getAlreadyVoted() external view returns(address[] memory);
    function howMuchVoted() external view returns(uint16);
    
}


contract ProcessVotes is Ownable {

    constructor(address _owner) {
       owner=_owner;
    }

    VoteInterface voteContract;

    function setVoteContract(address _address) external onlyOwner{
        voteContract = VoteInterface(_address);
    }

    function getVoted() public view returns (address[] memory){
        return(voteContract.getAlreadyVoted());
    }

    function getFormByAddress(address id) public view returns (uint16 region,bool firstQuestion, bool secondQuestion){
        return(voteContract.getForm(id));
    }
    
    function receivedVotes() public view returns (uint256){
        return(voteContract.howMuchVoted());
    }

}

pragma solidity ^0.8.6;

abstract contract Ownable {
    
address internal owner;

modifier onlyOwner() {
require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
}

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
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