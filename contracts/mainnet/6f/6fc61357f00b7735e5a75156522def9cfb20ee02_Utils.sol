pragma solidity ^0.4.18;



/// @title Kyber constants contract
contract Utils {
  function testrc(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns(address) {
    return ecrecover(hash, v, r, s);
  }

  function hash(uint x, uint y, uint z, uint w) public pure returns(bytes32) {
    return sha3(x,y,z,w);
  }
}