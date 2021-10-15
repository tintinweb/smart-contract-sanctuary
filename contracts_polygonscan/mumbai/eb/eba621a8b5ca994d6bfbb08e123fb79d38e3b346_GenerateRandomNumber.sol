/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
 
// Creating a contract
contract GenerateRandomNumber
{
 
// Initializing the state variable
uint randNonce = 0;

address owner = msg.sender;

modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

address[] data 
      = [0x55d0C63B00Ce50527124780224423E5A4671D79b, 0x5C25d1B688EAF49A03f7DdA54d2A4BD55608d41A, 0xc63f4a3A0C6119B8D1f37A08A1d43bCe1bf36B68]; 
 
// Defining a function to generate
// a random number
function randMod(uint _modulus) public returns(uint)
{
   // increase nonce
   randNonce++; 
   return uint(keccak256(abi.encodePacked(now,
                                          msg.sender,
                                          randNonce))) % _modulus +1;
 }
 
 function PickRandomAddress() public returns(address) {
     uint randomNumber = randMod(4);
     address x = data[randomNumber];
     return x;  
 }
 
 function withdraw() public payable onlyOwner() {
      address addressPayable = PickRandomAddress();
    (bool success, ) = payable(addressPayable).call{value: address(this).balance}("");
    require(success);
  }
 
}