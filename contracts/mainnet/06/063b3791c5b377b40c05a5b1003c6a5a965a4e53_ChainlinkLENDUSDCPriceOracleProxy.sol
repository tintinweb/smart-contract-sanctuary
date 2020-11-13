/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


interface IChainlink {
    function latestAnswer() external view returns (uint256);
}


// for LEND-USDC(decimals=6) price convert

contract ChainlinkLENDUSDCPriceOracleProxy {
    using SafeMath for uint256;

    address public lendEth = 0xc9dDB0E869d931D031B24723132730Ecf3B4F74d;
    address public EthUsd = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function getPrice() external view returns (uint256) {
        uint256 lendEthPrice = IChainlink(lendEth).latestAnswer();
        uint256 EthUsdPrice = IChainlink(EthUsd).latestAnswer();
        return lendEthPrice.mul(EthUsdPrice).div(10**20);
    }
}