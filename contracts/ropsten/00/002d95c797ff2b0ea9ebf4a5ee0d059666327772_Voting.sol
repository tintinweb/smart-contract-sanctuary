pragma solidity ^0.4.25;

contract Voting{
    address owner;
    mapping (uint256=>uint256) totalVoting;
    
    constructor() public{
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _owner) public onlyOwner returns(bool){
        owner = _owner;
        return true;
    }
    
    function likeVoting(uint256 videoNum) public onlyOwner returns(bool){
        totalVoting[videoNum] = totalVoting[videoNum] + 1;
        return true;
    }

    function starVoting(uint256 videoNum, uint8 star) public onlyOwner returns(bool) {
        if(star > 0 && star < 6){
            totalVoting[videoNum] = totalVoting[videoNum] + star;
            return true;
        }else{
            return false;
        }
    }

    function voteVoting(uint256 videoNum) onlyOwner public returns(bool){
        totalVoting[videoNum] = totalVoting[videoNum] + 3;
        return true;
    }
    
    function getVotingData(uint256 videoNum) public view returns(uint256){
        return totalVoting[videoNum];
    }
}