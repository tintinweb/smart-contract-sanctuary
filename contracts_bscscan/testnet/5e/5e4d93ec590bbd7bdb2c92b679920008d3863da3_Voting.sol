/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.6.1;

contract Voting {
    
  mapping (address => bool) public contestant;
  
  mapping (address => uint256) public votecount;
  
  address[] public contestantlist;
  
  mapping (address => address) public userVote;
    
  
  
  function register() public {
      
    require (contestant[msg.sender] == false, "Already Registered" );
    
    contestant[msg.sender] = true;
    contestantlist.push(msg.sender);
      
  }
  
  
  function castVote(address _contestant) public {
      
    require (contestant[_contestant] == true, "Not a contestant");  
    require (userVote[msg.sender] == 0x0000000000000000000000000000000000000000, "Already Voted");
    require (msg.sender != _contestant, "Cannot Self Vote");
    
    
    userVote[msg.sender] = _contestant;
    votecount[_contestant] +=1 ;
     
  }
  
  
  function removeVote() public {
      
    require (userVote[msg.sender] != 0x0000000000000000000000000000000000000000, "Not Voted");
    
    address candidate =  userVote[msg.sender];
    
    userVote[msg.sender] = 0x0000000000000000000000000000000000000000;
    votecount[candidate] -=1 ;
     
  } 
  
  function winner() public view returns(address _winner, uint256 _maxvote) {

     uint256 maxvote = 0; 
     uint256 currentwinner = 0;  
     uint256 i;

        for(i = 0; i < contestantlist.length; i++) {
            
            if(votecount[contestantlist[i]] > maxvote) {
                maxvote = votecount[contestantlist[i]]; 
                currentwinner = i;
            } 
        }
        
        return (contestantlist[currentwinner], maxvote);
      
   }
  
    
}