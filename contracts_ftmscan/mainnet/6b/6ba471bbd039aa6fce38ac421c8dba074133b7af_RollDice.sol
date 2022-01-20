/**
 *Submitted for verification at FtmScan.com on 2022-01-20
*/

pragma solidity 0.8.0;


contract RollDice{

    uint public randNonce;

    function randMod(uint _modulus) public returns(uint){
   // increase nonce
    randNonce++; 
    return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }

}