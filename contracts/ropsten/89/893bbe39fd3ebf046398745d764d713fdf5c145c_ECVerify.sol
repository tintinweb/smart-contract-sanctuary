pragma solidity ^0.4.18;

contract ECVerify {

  struct Signature {
    bytes32 hash;
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  function parse_signature(bytes32 _hash, bytes _sigbytes) pure public returns (bytes32 r, bytes32 s, uint8 v) {
    bytes32 _r;
    bytes32 _s;
    uint8 _v;
    
    Signature memory _signature;

    assembly {
      _r := mload(add(_sigbytes, 32))
      _s := mload(add(_sigbytes, 64))
      _v := byte(0, mload(add(_sigbytes, 96)))
    }
    if (_v < 27) {
      _v += 27;
    }
    if ((_v == 27) || (_v == 28)) {
      _signature.hash = _hash;
      _signature.r = _r;
      _signature.s = _s;
      _signature.v = _v;
    } else {
      _signature.hash = 0x0;
      _signature.r = 0x0;
      _signature.s = 0x0;
      _signature.v = 0;
    }
    delete _sigbytes;
    
    return (_signature.r, _signature.s, _signature.v);
  }
}