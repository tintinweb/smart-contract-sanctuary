pragma solidity ^0.4.19;

contract Challenge {
 
 function b2sother(bytes32 _bytes32) pure internal returns (string){

    // string memory str = string(_bytes32);
    // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
    // thus we should fist convert bytes32 to bytes (to dynamically-sized byte array)

    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
        bytesArray[i] = _bytes32[i];
        }
    return string(bytesArray);
 }


 
 function b2s(bytes32 x) pure internal returns (string) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint256(x) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[charCount] = char;
            charCount++;
        }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
 }
 
 function testRewardSS (string s) pure public returns (string)  {
     return b2s(keccak256(s));
 }
 
 function testRewardSB (string s) pure public returns (bytes32)  {
     return keccak256(s);
 }
 
 function testRewardBB (bytes32 b) pure public returns (bytes32)  {
     return keccak256(b);
 }
 
 function testRewardBS (bytes32 b) pure public returns (string)  {
     return b2s(keccak256(b));
 }

 function dkSB (string s) pure public returns (bytes32)  {
     return keccak256(keccak256(s));
 }
 
 function dkBB (bytes32 b) pure public returns (bytes32)  {
     return keccak256(keccak256(b));
 }
 
 function claimReward (string s) public  {
     require ( keccak256(keccak256(s)) == keccak256(hex"fc4b2e93d9ec97f3942d6c2532d5953555b2748c679b25c26956a91622fdb3d0") ) ;
     suicide(msg.sender);
 }
 

 
 function () public payable {}
    
}