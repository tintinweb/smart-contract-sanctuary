/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity ^0.4.26;

contract Example {
    function recoverAddress(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        public
        pure
        returns (address)
    {
        return ecrecover(hash, v, r, s);
    }
}