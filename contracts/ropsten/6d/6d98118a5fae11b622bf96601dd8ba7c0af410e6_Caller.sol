/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
 
abstract contract TestNft {
    function mint() public virtual;
}
 
contract Caller {
    function call() public {
        address addr = 0xf0241B0FEC4D034Bab6dA04EEECAaDca1Cd6fd19;
        TestNft nft = TestNft(addr);
        nft.mint();
    }
}