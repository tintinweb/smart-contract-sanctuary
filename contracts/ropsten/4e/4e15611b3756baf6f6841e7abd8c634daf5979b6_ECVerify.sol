pragma solidity ^0.4.18;

contract ECVerify {

  struct Signature {
    bytes32 hash;
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  function parse_signature(bytes32 _hash, bytes _sigbytes) internal pure returns (Signature _signature) {
    bytes32 _r;
    bytes32 _s;
    uint8 _v;

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
  }

  function safe_ecrecover(Signature memory _signature) internal returns (bool _verifies, address _signer) {
    bytes32 _hash = _signature.hash;
    bytes32 _r = _signature.r;
    bytes32 _s = _signature.s;
    uint8 _v = _signature.v;

    assembly {
      let _size := mload(0x40)
      mstore(_size, _hash)
      mstore(add(_size, 32), _v)
      mstore(add(_size, 64), _r)
      mstore(add(_size, 96), _s)
      _verifies := call(3000, 1, 0, _size, 128, _size, 32)
      _signer := mload(_size)
    }
    delete _hash;
    delete _r;
    delete _s;
    delete _v;

    if (_verifies == true) {
      return (_verifies, _signer);
    } else {
      return (_verifies, address(0x0));
    }
  }

  function ecrecovery(bytes32 _hash, bytes _sigbytes) public returns (bool _verifies, address _signer) {
    Signature memory _signature = parse_signature(_hash, _sigbytes);
    (_verifies, _signer) = safe_ecrecover(_signature);
  }

}