/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity >=0.8.4;

// It's black hole contract, anyone can never ever get you tokens back once
// transfer into this contract.
contract BlackHole {
    fallback() payable external {
        // do nothing
    }
}