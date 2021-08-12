/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.4.24;
// adapted from https://github.com/austintgriffith/bouncer-proxy/blob/master/BouncerProxy/BouncerProxy.sol
// Blind proxy - forward everything
contract Proxy {
constructor() public {}
mapping(address => uint) public nonce;
function getHash(address signer, address destination, uint value, bytes data) public view returns(bytes32){
    return keccak256(abi.encodePacked(address(this), signer, destination, value, data, nonce[signer]));
  }
function forward(bytes sig, address signer, address destination, uint value, bytes data) public {
      //the hash contains all of the information about the meta transaction to be called
      bytes32 _hash = getHash(signer, destination, value, data);
      //increment the hash so this tx can't run again
      nonce[signer]++;
      //they must prove they are who they say they are
      require(signer == getSigner(_hash, sig),"Proxy::forward Incorrect Signature");
      //execute the transaction with all the given parameters
      require(executeCall(destination, value, data));
      emit Forwarded(sig, signer, destination, value, data, _hash);
  }
  event Forwarded (bytes sig, address signer, address destination, uint value, bytes data,bytes32 _hash);
function executeCall(address to, uint256 value, bytes data) internal returns (bool success) {
    assembly {
       success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
    }
  }
function getSigner(bytes32 _hash, bytes _signature) internal pure returns (address){
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (_signature.length != 65) {
      return address(0);
    }
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
}