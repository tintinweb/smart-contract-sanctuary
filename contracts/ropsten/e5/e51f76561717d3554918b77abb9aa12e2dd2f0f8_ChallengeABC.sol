pragma solidity ^0.4.25;

contract ChallengeABC {
 
 event Won() ;
 bytes32 challenge=hex"fc4b2e93d9ec97f3942d6c2532d5953555b2748c679b25c26956a91622fdb3d0" ;
 string badAnswer="Wrong answer!" ;
 
 function claimReward (string s) public  {
     require ( keccak256(keccak256(s)) == keccak256(challenge) , badAnswer) ;
     emit Won() ;
     selfdestruct(msg.sender);
 }
 

 
 function () public payable {}
 
}