pragma solidity ^0.4.25;


contract ECRecoverDemo {
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function stringToBytes32(string memory source) pure public returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function ECRecoverWrapper(string _msg, uint8 v, bytes32 r, bytes32 s) pure public returns (address) {
        bytes32 bytes32_encoded_msg = stringToBytes32(_msg);
        //return 0x0;
        address addr = ecrecover(bytes32_encoded_msg, v, r, s);
        return addr;
    }
    
    function ECRecoverWrapperF(bytes32 _msg, uint8 v, bytes32 r, bytes32 s) pure public returns (address) {
        //return 0x0;
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _msg));
        address addr = ecrecover(prefixedHash, v, r, s);
        return addr;
    }
    
    // https://github.com/davidmichaelakers/ecrecover/blob/master/contracts/Test.sol
    function ecrecover1(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) constant returns(address) {
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      bytes32 prefixedHash = keccak256(prefix, msgHash);
      return ecrecover(prefixedHash, v, r, s);
    }
    
  function ecrecover2(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) constant returns (address) {
      return ecrecover(msgHash, v, r, s);
  }
 
  function ecrecover3(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) constant returns (address) {
        
    bool ret;
    address addr;

    assembly {
        let size := mload(0x40)
        mstore(size, msgHash)
        mstore(add(size, 32), v)
        mstore(add(size, 64), r)
        mstore(add(size, 96), s)
        ret := call(3000, 1, 0, size, 128, size, 32)
        addr := mload(size)
    }
    return addr;
  } 
}