/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// > var msg = web3.sha3("hello")
// "0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8"

// > eth.accounts[0] -->
// "0x7156526fbd7a3c72969b54f64e42c10fbb768c8a"

// > var sig = eth.sign(eth.accounts[0], msg)
// "0x9242685bf161793cc25603c231bc2f568eb630ea16aa137d2664ac80388256084f8ae3bd7535248d0bd448298cc2e2071e56992d0774dc340c368ae950852ada1c"

// > var r = sig.substr(0,66)
// "0x9242685bf161793cc25603c231bc2f568eb630ea16aa137d2664ac8038825608"

// > var s = "0x" + sig.substr(66,64)
// "0x4f8ae3bd7535248d0bd448298cc2e2071e56992d0774dc340c368ae950852ada"

// > var v = 28
// 28

// > test.verify(msg,v,r,s)
// "0x33692ee5cbf7ecdb8ca43ec9e815c47f3db8cd11"


pragma solidity ^0.8.6;

contract test {

    bool public test0;
    bool public test1;
    bool public test10;
    bool public test100;
    bool public test1000;
    bool public testN;
    bool public testM;
    
    address public acc = 0x7156526fbD7a3C72969B54f64e42c10fbb768C8a;
    
    constructor() {}
    
    function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return (ecrecover(prefixedHash, v, r, s) == (acc));
    }

    function verify0(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        test0 = (ecrecover(prefixedHash, v, r, s) == (acc));
        
        return true;
    }
    
    function verify1(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 1; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (acc));
        }
        
        test1 = true;
        
        return true;
    }
    
    function verify10(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 10; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (acc));
        }
        
        test10 = true;
        
        return true;
    }

    function verify100(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 100; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (acc));
        }
        
        test100 = true;
        
        return true;
    }
    
    function verify1000(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < 1000; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (acc));
        }
        
        test1000 = true;
        
        return true;
    }
    
    function verifyN(uint N, bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < N; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v, r, s) == (acc));
        }
        
        testN = true;
        
        return true;
    }
    
    function verifyM(bytes32[] memory hash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        
        for (uint i = 0; i < hash.length; i++) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, v[i], r[i], s[i]) == (acc));
        }
        
        testM = true;
        
        return true;
    }

}