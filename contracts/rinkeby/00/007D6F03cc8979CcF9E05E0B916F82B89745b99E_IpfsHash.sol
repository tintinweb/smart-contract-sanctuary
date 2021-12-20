// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract IpfsHash {
    bytes32 public ipfsHash;

    event IpfsHashChanged(bytes32 indexed newipfsHash);

    constructor() {
        ipfsHash = "";
    }

    function changeIpfsHash(bytes32 _ipfsHash) public {
        ipfsHash = _ipfsHash;
        emit IpfsHashChanged(ipfsHash);
    }
}