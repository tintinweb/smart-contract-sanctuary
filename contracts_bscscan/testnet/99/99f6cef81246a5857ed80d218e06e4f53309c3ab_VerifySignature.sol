/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract VerifySignature {
    function getMessageHash(uint timestamp, string memory result) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(timestamp, result));
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verifySigner(
        address _signer,
        uint timestamp, string memory result, 
        bytes32 r, bytes32 s, uint8 v
    )
        public pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(timestamp, result);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return ecrecover(ethSignedMessageHash, v, r, s) == _signer;
    }

}