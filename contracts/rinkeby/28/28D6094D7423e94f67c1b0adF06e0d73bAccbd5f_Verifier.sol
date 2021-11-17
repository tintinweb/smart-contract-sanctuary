// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Verifier {
    mapping (address => bytes32) private addressToKey;

    function verify(string memory secretKey) external {
        addressToKey[msg.sender] = keccak256(abi.encodePacked(msg.sender, secretKey));
    }

    function getKeyHash(address _address) external view returns (bytes32) {
        return addressToKey[_address];
    }
}