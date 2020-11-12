/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IChainlink {
    function latestAnswer() external view returns (uint256);
}


// for LINK-USDC(decimals=6) price convert

contract ChainlinkLINKUSDCPriceOracleProxy {
    address public chainlink = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;

    function getPrice() external view returns (uint256) {
        return IChainlink(chainlink).latestAnswer() / 100;
    }
}