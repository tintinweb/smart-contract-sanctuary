/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity >=0.5.16;


contract Verification{
    
    function getMessageHash(string memory _message) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_message));
    }
    
    function recover(string memory _message, bytes  memory signature)
    public
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    
    bytes32 messageHash = getMessageHash( _message);

    if (signature.length != 65) {
      return (address(0));
    }

    assembly {
      r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
    }    
    if(v==0 || v==1){
        v=v+27;
    }
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(messageHash, v, r, s);
    }
  }
  
   function getEthSignedMessageHash(bytes32 hash)
    public
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
  
}