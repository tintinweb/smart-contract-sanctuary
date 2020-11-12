/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IChainlink {
    function latestAnswer() external view returns (uint256);
}


// for COMP-USDC(decimals=6) price convert

contract ChainlinkCOMPUSDCPriceOracleProxy {
    address public chainlink = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;

    function getPrice() external view returns (uint256) {
        return IChainlink(chainlink).latestAnswer() / 100;
    }
}