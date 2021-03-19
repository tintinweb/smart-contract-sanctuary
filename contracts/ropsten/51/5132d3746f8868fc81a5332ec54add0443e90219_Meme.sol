/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.5.0;

contract Meme {
 
  address payable abc;
  struct reciever 
    {
        string memeHash;
        uint id;
        address sndr;
        uint j;
    }

   mapping(address=>reciever[]) public imageData;
   mapping(address=>uint) public counter;
 
   
   
   function set(string memory _hash, uint _id) public{
    reciever memory images;
    images.memeHash = _hash;
    images.id = _id;
    images.sndr = msg.sender;
    counter[msg.sender] =  _id+1;
    
    
    imageData[msg.sender].push(images);
   }
   
//   function getSize () public returns(uint){
//       return (imageData.reciever.length);
//   }
}