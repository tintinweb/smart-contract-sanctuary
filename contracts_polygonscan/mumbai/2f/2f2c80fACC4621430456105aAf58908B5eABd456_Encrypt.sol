pragma solidity ^0.8.0;

contract Encrypt {
    mapping(address => string) public signerKeys;

    constructor() {}

    function setSignerKey(string calldata signerKey) public {
        signerKeys[msg.sender] = signerKey;
    }
}