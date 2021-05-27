/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

/*
 * Curio StableCoin System
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity 0.7.2;

interface ChainlinkPriceOracle {
    function latestAnswer() external view returns (int256);
}

contract OracleProxy {
    ChainlinkPriceOracle immutable source;

    constructor(address _source) {
        source = ChainlinkPriceOracle(_source);
    }

    function peek() external view returns (bytes32 wut, bool ok) {
        int256 latestAnswer = source.latestAnswer();
        if (latestAnswer > 0) {
            uint256 answer = uint256(bytes32(latestAnswer));
            return (bytes32(answer * 1e10 / 1100000), true);
        } else {
            return (0, false);
        }
    }
}