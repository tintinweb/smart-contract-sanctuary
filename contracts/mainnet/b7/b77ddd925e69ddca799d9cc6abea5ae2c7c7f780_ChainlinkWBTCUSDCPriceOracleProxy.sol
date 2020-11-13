/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IChainlink {
    function latestAnswer() external view returns (uint256);
}


// for WBTC(decimals=8)-USDC(decimals=6) price convert

contract ChainlinkWBTCUSDCPriceOracleProxy {
    address public chainlink = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

    function getPrice() external view returns (uint256) {
        return IChainlink(chainlink).latestAnswer() * (10**8);
    }
}