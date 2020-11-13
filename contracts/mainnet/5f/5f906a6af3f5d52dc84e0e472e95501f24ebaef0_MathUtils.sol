// SPDX-License-Identifier: AGPL-3.0-only

/*
    StringUtils.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;


library MathUtils {

    uint constant private _EPS = 1e6;

    event UnderflowError(
        uint a,
        uint b
    );    

    function boundedSub(uint256 a, uint256 b) internal returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            emit UnderflowError(a, b);
            return 0;
        }
    }

    function boundedSubWithoutEvent(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return 0;
        }
    }

    function muchGreater(uint256 a, uint256 b) internal pure returns (bool) {
        assert(uint(-1) - _EPS > b);
        return a > b + _EPS;
    }

    function approximatelyEqual(uint256 a, uint256 b) internal pure returns (bool) {
        if (a > b) {
            return a - b < _EPS;
        } else {
            return b - a < _EPS;
        }
    }
}