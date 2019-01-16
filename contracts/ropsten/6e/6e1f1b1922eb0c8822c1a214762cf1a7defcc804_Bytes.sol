pragma solidity ^0.4.25;

contract Bytes {
    
    function addressToBytes(address _address) external pure returns (bytes32) {
        bytes32 aux = bytes32(_address);
        return aux;
    }
    
    function intToBytes(uint _uint) external pure returns (bytes32) {
      bytes32 aux = bytes32(_uint);
      return aux;
    }
    
    function printAddress(address[3] _address) external pure returns (address[3]) {
        return _address;
    }
    
}