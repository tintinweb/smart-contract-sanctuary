/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity ^0.6.4;

contract Hh{
      mapping(address => uint) nonce;
      
      
      function _msgSender1() public view returns (address ret) {
        address sender = msg.sender;
            assembly {
                sender := shr(96,calldataload(sub(calldatasize(),20)))
            }
        
        return sender;
    }
   
    function _msgSender(address _adr) public  pure returns (address) {
        
            assembly {
                _adr := shr(96,calldataload(sub(calldatasize(),20)))
            }
    }

      
function getSigner(bytes32 _hash, bytes memory _signature) public pure returns (address){
    bytes32 r;
    bytes32 s;
    uint8 v;
   // if (_signature.length != 65) {
     // return address(0);
   // }
    assembly {
      r := mload(add(_signature, 32))
      s := mload(add(_signature, 64))
      v := byte(0, mload(add(_signature, 96)))
    }
    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return address(0);
    } else {
      return ecrecover(keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
      ), v, r, s);
    }
}
  function getAddress(bytes memory b) public pure returns (address a) {
        if (b.length < 36) return address(0);
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            a := and(mask, mload(add(b, 36)))
            // 36 is the offset of the first parameter of the data, if encoded properly.
            // 32 bytes for the length of the bytes array, and 4 bytes for the function signature.
        }
    }
    
function claimed(address claimedSender,address listOwner,address destination,bytes memory data, 
uint8 sigV,bytes32 sigR,bytes32 sigS) public view returns (address) {
    bytes32 h = keccak256(abi.encodePacked(byte(0x19), byte(0), this, listOwner, nonce[claimedSender], destination, data));
      
        address addressFromSig = ecrecover(h, sigV, sigR, sigS);
        return addressFromSig;
}

}