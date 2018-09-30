pragma solidity ^0.4.25;

contract ChallengeABC {

 event Won() ;
 event Try(bytes32 bCandidate);
 //bytes32 challenge=hex"fc4b2e93d9ec97f3942d6c2532d5953555b2748c679b25c26956a91622fdb3d0";
 bytes32 bSalt=&#39;&#39;;
 bytes32 bSaltedChallenge=&#39;&#39;;
 string badAnswer="Wrong answer!";
 
 constructor(bytes32 __bChallenge) public {
    bSalt=keccak256(block.timestamp);
    bSaltedChallenge=__bChallenge^bSalt; // to xor with the salt sha3(block.timestamp)
 }
 
 function claimReward (bytes32 _bCandidate) public  {
     emit Try(_bCandidate);
     require( (keccak256(_bCandidate))^bSalt == bSaltedChallenge , badAnswer );
     emit Won();
     selfdestruct(msg.sender);
 }
 
 function () public payable {
 }
 
}