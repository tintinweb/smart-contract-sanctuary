/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

/*

    Copyright 2021 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IChainlink {
    function latestAnswer() external view returns (uint256);
}


// for COMP-USDC(decimals=6) price convert

contract ChainlinkEURUSDPriceOracleProxy {
    address public chainlink = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1;

    function getPrice() external view returns (uint256) {
        return IChainlink(chainlink).latestAnswer() / 100;
    }
}