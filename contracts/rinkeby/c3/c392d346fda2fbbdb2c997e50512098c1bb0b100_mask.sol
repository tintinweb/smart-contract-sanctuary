/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.6.0;

contract mask {
  function wrap1 (address _token_addr, bytes32 _hash, uint256 _start, uint256 _end) public pure returns (uint256 packed1) {
    uint256 _packed1 = 0;
    _packed1 |= box(0, 160,  uint256(_token_addr));     // token_addr = 160 bits
    _packed1 |= box(160, 48, uint256(_hash) >> 208);    // hash = 48 bits (safe?)
    _packed1 |= box(208, 24, _start);                   // start_time = 24 bits
    _packed1 |= box(232, 24, _end);                     // expiration_time = 24 bits
    return _packed1;
  }

  function wrap2 (uint256 _total_tokens, uint256 _limit) public pure returns (uint256 packed2) {
    uint256 _packed2 = 0;
    _packed2 |= box(0, 128, _total_tokens);             // total_tokens = 128 bits ~= 3.4e38
    _packed2 |= box(128, 128, _limit);                  // limit = 128 bits
    return _packed2;
  }

  function box (uint16 position, uint16 size, uint256 data) public pure returns (uint256 boxed) {
    require(validRange(size, data), "Value out of range BOX");
    return data << (256 - size - position);
  }

  function unbox (uint256 base, uint16 position, uint16 size) public pure returns (uint256 unboxed) {
    require(validRange(256, base), "Value out of range UNBOX");
    return (base << position) >> (256 - size);
  }
  
  function validRange (uint16 size, uint256 data) public pure returns(bool) { 
    if (data > 2 ** uint256(size) - 1) {
        return false;
    }
    return true;
  }
  
  function toBytes (address a) public pure returns (bytes memory b) {
    assembly {
        let m := mload(0x40)
        a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
        mstore(0x40, add(m, 52))
        b := m
    }
}
  
  function getVerification (bytes32 _hash, address _token_addr, uint256 _start, uint256 _end, address to) public pure returns (bytes32 verification) {
    uint256 packed1 =  wrap1(_token_addr, _hash, _start, _end);
    return keccak256(abi.encodePacked(unbox(packed1, 160, 48), to));
  }
  
  function getValidation(address to) public pure returns (bytes32 validation) {
     return keccak256(toBytes(to)); 
  }

}