/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IChainlink {
    function latestAnswer() external view returns (uint256);
}


// for SNX-USDC(decimals=6) price convert

contract ChainlinkSNXUSDCPriceOracleProxy {
    address public chainlink = 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699;

    function getPrice() external view returns (uint256) {
        return IChainlink(chainlink).latestAnswer() / 100;
    }
}