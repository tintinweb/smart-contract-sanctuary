// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract IpfsHash {
    string public ipfsHash; // an IPFS hash, without Qm, to make bytes32

    event IpfsHashChanged(string indexed newipfsHash);

    constructor() {
        ipfsHash = "QmaqmF2EL4cWvGdU4sfa8PG4W5iyTwuVGf6bMerxvCdvZf";
    }

    function changeIpfsHash(string memory _ipfsHash) public {
        ipfsHash = _ipfsHash;
        emit IpfsHashChanged(ipfsHash);
    }
}