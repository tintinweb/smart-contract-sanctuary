/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.6.8;

contract Test {
    function calc(int24 i, int24 j) external pure returns (int24 k) {
        return i / j * j;
    }
}