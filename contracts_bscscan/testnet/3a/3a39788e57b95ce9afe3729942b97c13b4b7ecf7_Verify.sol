/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 

contract Verify  {
 
   mapping (address => bool) public whitelistedExchanger;

    constructor (address _importantAddress) {       
       whitelistedExchanger[_importantAddress] = true;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 
    function isValidData(uint256 _gAmount, string memory _walletAddress, bool _hasFee, uint256 _nonce, bytes memory sig, bytes memory walletSig) public view returns(bool){
        bytes32 message = keccak256(abi.encodePacked(_gAmount, _walletAddress, _hasFee, _nonce, sig));
        require(recoverSigner(message, walletSig)==_msgSender(),"Not signed by the user"); // verify that the wallet signed the message

        bytes32 signedMessage = keccak256(abi.encodePacked(_gAmount, _walletAddress, _hasFee, _nonce));
        require(whitelistedExchanger[recoverSigner(signedMessage, sig)]==true, "Not signed by the authority");

        return true;
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