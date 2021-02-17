/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity ^0.5.17;

contract RandmodTest{
    
    uint randNonce = 0;
    function randMod(uint _modulus) public returns(uint) {
    randNonce++;
    return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _modulus;
  }
}