/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// File: verified-sources/0x81339f8299c30f7cef009cf8d65cffc44973f92b/sources/contracts/artifacts/Moderator.sol


pragma solidity ^0.8.0;
contract Moderator{
     address private owner;
     bool private isPollOpen;

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        isPollOpen = false;
    }
     
     Candidate[] private candidates;
     
     struct Candidate{
      address cAddress;
      uint256 votes;
     }
     
    function addCandidates(address _wallet) public onlyOwner{
        bool present = false;
        
          for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].cAddress == _wallet) {
               present = true;
            }
          }
        
        if (!present){
         candidates.push(Candidate({cAddress:_wallet, votes:0}));   
        }
        if (candidates.length > 1){
            isPollOpen = true;
        }
         
     }


    
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }
    
    function getCandidateCount() public view returns(uint count) {
        return candidates.length;
    }
    
    function getOwnerAdd() public view returns (address o){
        return owner;
    }
    
    function vote(uint i)public {
        
        if (i <= candidates.length ){
            candidates[i-1].votes++; 
        }
    }
    
    function closePoll() public onlyOwner{
        if (isPollOpen == true){
            isPollOpen = false;
        }
    }
    
    function listCandidates() public view returns ( Candidate[]  memory a ) {
        return candidates;
    }
    
    function getWinner() public onlyOwner view returns (Candidate memory ){
        
        bytes32  result;
        Candidate memory maxVoted ;
        if (isPollOpen == false && candidates.length>0){
         
        maxVoted = candidates[0];
          for (uint i = 1; i < candidates.length; i++) {
           
           if (candidates[i].votes == maxVoted.votes){
               result = "tie";
           }
           
            if (candidates[i].votes > maxVoted.votes) {
               maxVoted = candidates[i];
             
            }
          }
        }
          return maxVoted;
    }

}