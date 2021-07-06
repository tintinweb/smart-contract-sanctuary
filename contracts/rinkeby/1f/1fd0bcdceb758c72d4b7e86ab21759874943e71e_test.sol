/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.8.6;

contract test {

    bool test0;
    bool test1;
    bool test10;
    bool test100;
    bool test1000;
    
    constructor() {}
    
    function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return (ecrecover(prefixedHash, v, r, s) == (msg.sender));
    }

    function verify0(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        test0 = (ecrecover(prefixedHash, v, r, s) == (msg.sender));
        
        return true;
    }
    
    function verify1(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 1; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (msg.sender));
        }
        
        test1 = true;
        
        return true;
    }
    
    function verify10(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 10; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (msg.sender));
        }
        
        test10 = true;
        
        return true;
    }

    function verify100(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 100; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (msg.sender));
        }
        
        test100 = true;
        
        return true;
    }
    
    function verify1000(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 1000; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (msg.sender));
        }
        
        test1000 = true;
        
        return true;
    }

}