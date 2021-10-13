pragma solidity ^0.8.0;

contract Event_test {



    function bytesToBytes32( bytes memory b, uint offset) public pure returns (bytes32) {
    bytes32 out;

    for (uint i = 0; i < 32; i++) {
    out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
  }
  return out;
}
    
    
}