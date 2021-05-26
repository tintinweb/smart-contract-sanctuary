/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

/*
 * Curio StableCoin System
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.2;

interface EACAggregatorProxy {
    function latestAnswer() external view returns (int256);
}

contract OracleProxy {
    EACAggregatorProxy immutable source;

    constructor(address _source) {
        source = EACAggregatorProxy(_source);
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