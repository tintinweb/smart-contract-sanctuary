pragma solidity ^0.4.25;


contract ECRecoverDemo {
    
  bytes32 public msgHash;
    
  // this function is pure because it modifies no state and it references no contract fields
  // IE, it only depends on the function arguments.
  function ecrecoverWrapper(bytes32 _msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
      return ecrecover(_msgHash, v, r, s);
  }
  
  // This function has view (not pure) because it references a contract field -msgHash- in the
  // function body.
  function ecrecoverWrapperView(uint8 v, bytes32 r, bytes32 s) public view returns (address) {
      return ecrecover(msgHash, v, r, s);
  }
  
  function setMsgHash(bytes32 _msgHash) public {
      msgHash = _msgHash;
  }
}