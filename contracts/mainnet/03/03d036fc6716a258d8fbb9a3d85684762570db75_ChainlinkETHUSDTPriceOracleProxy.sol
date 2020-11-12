/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IChainlink {
    function latestAnswer() external view returns (uint256);
}


// for WETH-USDT(decimals=6) price convert

contract ChainlinkETHUSDTPriceOracleProxy {
    address public chainlink = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46;

    function getPrice() external view returns (uint256) {
        return 10**24 / IChainlink(chainlink).latestAnswer();
    }
}