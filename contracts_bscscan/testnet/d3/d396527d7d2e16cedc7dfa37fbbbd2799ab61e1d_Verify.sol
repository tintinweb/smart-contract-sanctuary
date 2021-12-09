/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

pragma solidity ^0.5.0;
contract Verify {
 
   mapping (address => bool) public whitelistedExchanger;

   constructor (address _importantAddress) public{       
       whitelistedExchanger[_importantAddress] = true;
   }
  
   function isValidData(uint256 _number, string memory _word, bytes memory sig) public view returns(bool){
       bytes32 message = keccak256(abi.encodePacked(_number, _word));
       return (whitelistedExchanger[recoverSigner(message, sig)]);
   }

   function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}