/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Hi.sol

pragma solidity >=0.6.7 <0.7.0;

////// src/Hi.sol
/* pragma solidity ^0.6.7; */

contract Hi {
    function recover(bytes32 digest, uint8 v, bytes32 r, bytes32 s) external pure returns (address) {
        return ecrecover(digest, v, r, s);
    }
}