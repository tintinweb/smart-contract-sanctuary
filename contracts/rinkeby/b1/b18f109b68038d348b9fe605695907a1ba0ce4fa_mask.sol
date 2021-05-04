/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.8.0;

contract mask {
  function wrap1 (address _qualification, bytes32 _hash, uint256 _start, uint256 _end) public pure
  returns (uint256 packed1) {
    uint256 _packed1 = 0;
    _packed1 |= box(0, 160,  uint256(uint160(_qualification)));     // _qualification = 160 bits
    _packed1 |= box(160, 40, uint256(_hash) >> 216);                // hash = 40 bits (safe?)
    _packed1 |= box(200, 28, _start);                               // start_time = 28 bits
    _packed1 |= box(228, 28, _end);                                 // expiration_time = 28 bits
    return _packed1;
  }


  function box (uint16 position, uint16 size, uint256 data) public pure returns (uint256 boxed) {
    require(validRange(size, data), "Value out of range BOX");
    return data << (256 - size - position);
  }

  function unbox (uint256 base, uint16 position, uint16 size) public pure returns (uint256 unboxed) {
    require(validRange(256, base), "Value out of range UNBOX");
    return (base << position) >> (256 - size);
  }

  function validRange (uint16 size, uint256 data) public pure returns(bool ifValid) {
    assembly {
    // 2^size > data or size ==256
      ifValid := or(eq(size, 256), gt(shl(size, 1), data))
    }
  }

  function getVerification (address _qualification, bytes32 _hash,uint256 _start, uint256 _end, address to) public pure returns (bytes32 verification) {
    uint256 packed1 = wrap1(_qualification, _hash, _start, _end);
    return keccak256(abi.encodePacked(unbox(packed1, 160, 40), to));
  }


}