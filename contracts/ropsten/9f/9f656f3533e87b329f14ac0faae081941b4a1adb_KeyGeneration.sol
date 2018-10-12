pragma solidity ^0.4.24; // Specify compiler version

contract KeyGeneration {
    function GeneratePublicKey(string _privateKey1, string _privateKey2) pure public returns (bytes32 publicKey) {
        return keccak256(abi.encodePacked(_privateKey1, _privateKey2));
    }
}