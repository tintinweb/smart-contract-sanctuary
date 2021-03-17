/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.5.0;

contract Meme {
 
  address payable abc;
  struct reciever 
    {
        string memeHash;
        uint id;
        address sndr;
    }

   mapping(address=>reciever[]) public imageData;
   
   function set(string memory _hash, uint _id) public{
    reciever memory images;
    images.memeHash = _hash;
    images.id = _id;
    images.sndr = msg.sender;
    
    imageData[msg.sender].push(images);
   }
}