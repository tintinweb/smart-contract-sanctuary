/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Sign {
    address VERIFY_ADDRESS = 0x70B3f80B88EDc8893d3364038CEdD6A0244B4a80;

    function verifyURISignature(string memory uri, uint8 v, bytes32 r, bytes32 s) public view returns(bool) { 
        uint256 len = bytes(uri).length;
        bytes32 h = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", len, uri));
        return ecrecover(h, v, r, s) == VERIFY_ADDRESS;
    }
}