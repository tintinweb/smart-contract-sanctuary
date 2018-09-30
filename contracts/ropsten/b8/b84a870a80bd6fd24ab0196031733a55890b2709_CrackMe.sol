pragma solidity ^0.4.25;

contract CrackMe {

 event Won() ;
 event Try(bytes bCandidate);
 //bytes32 challenge=hex"fc4b2e93d9ec97f3942d6c2532d5953555b2748c679b25c26956a91622fdb3d0";
 bytes32 b32Salt=&#39;&#39;;
 bytes32 b32SaltedChallenge=&#39;&#39;;
 string sBadAnswer="Wrong answer!";
 
 constructor(bytes __bChallenge) public {
    b32Salt=keccak256(block.timestamp);
    b32SaltedChallenge=keccak256(__bChallenge)^b32Salt; // to xor with the salt sha3(block.timestamp)
 }
 
 function claimReward (bytes _bCandidate) public  {
     emit Try(_bCandidate);
     require( (keccak256(keccak256(_bCandidate)))^b32Salt == b32SaltedChallenge , sBadAnswer );
     emit Won();
     selfdestruct(msg.sender);
 }
 
 function () public payable {
 }
 
}