// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Verifier {
    mapping (address => bytes32) private addressToHash;

    function verify(string memory secretKey) external {
        addressToHash[msg.sender] = keccak256(abi.encodePacked(msg.sender, secretKey));
    }

    function getKeyHash(address _address) external view returns (bytes32) {
        return addressToHash[_address];
    }
}