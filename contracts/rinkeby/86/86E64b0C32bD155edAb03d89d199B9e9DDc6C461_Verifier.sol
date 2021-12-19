// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Verifier {
    mapping (address => bytes32) private addressToHash;
    mapping (uint => bool) public whitelist;

    function addWhitelist(uint[] calldata tokenIds) external {
        for (uint i=0; i < tokenIds.length; i++) {
            whitelist[i] = true;
        }
    }

    function verify(string memory secretKey) external {
        addressToHash[msg.sender] = keccak256(abi.encodePacked(msg.sender, secretKey));
    }

    function getKeyHash(address _address) external view returns (bytes32) {
        return addressToHash[_address];
    }
}