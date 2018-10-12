pragma solidity ^0.4.18;

contract Auth {

    string public name;

    constructor() public{
        name = "Auth 1.0";
    }

    function verify(string _message, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
          bytes32 _messageHash = keccak256(abi.encodePacked(_message));
        address signer = ecrecover(_messageHash, _v, _r, _s);
        return signer;
    }

    function verifyHash(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        address signer = ecrecover(_message, _v, _r, _s);
        return signer;
    }

    function verifyHashWithPrefix(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _message));
        address signer = ecrecover(prefixedHash, _v, _r, _s);
        return signer;
    }
}