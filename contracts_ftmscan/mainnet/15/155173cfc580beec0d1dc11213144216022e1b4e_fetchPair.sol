/**
 *Submitted for verification at FtmScan.com on 2022-01-24
*/

pragma solidity ^0.8.7;

interface iUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract fetchPair {
    address factory = 0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3;
    address pair;

    function fetch(address _1, address _2) external {
        pair = iUniFactory(factory).getPair(_1, _2);
    }
}