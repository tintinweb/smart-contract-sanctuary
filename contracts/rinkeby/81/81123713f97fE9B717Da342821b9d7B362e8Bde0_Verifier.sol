pragma solidity ^0.8.10;

contract Verifier
{
    function verify(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s, address signer) pure public returns(bool) {
        return ecrecover(messageHash, v, r, s) == signer;
    }
}