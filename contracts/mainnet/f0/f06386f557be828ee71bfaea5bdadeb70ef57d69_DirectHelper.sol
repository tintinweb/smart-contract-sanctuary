/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
}

interface DirectLike {
    function vat() external view returns (address);
    function pool() external view returns (address);
    function dai() external view returns (address);
    function adai() external view returns (address);
    function stableDebt() external view returns (address);
    function variableDebt() external view returns (address);
    function bar() external view returns (uint256);
    function ilk() external view returns (bytes32);
    function exec() external;
}

interface LendingPoolLike {
    function getReserveData(address asset) external view returns (
        uint256,    // Configuration
        uint128,    // the liquidity index. Expressed in ray
        uint128,    // variable borrow index. Expressed in ray
        uint128,    // the current supply rate. Expressed in ray
        uint128,    // the current variable borrow rate. Expressed in ray
        uint128,    // the current stable borrow rate. Expressed in ray
        uint40,
        address,    // address of the adai interest bearing token
        address,    // address of the stable debt token
        address,    // address of the variable debt token
        address,    // address of the interest rate strategy
        uint8
    );
}

// Helper functions for keeper bots
contract DirectHelper {

    // --- Math ---
    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DssDirectDepositAaveDai/overflow");
    }
    uint256 constant RAY  = 10 ** 27;
    function _rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, RAY) / y;
    }

    // Use this to determine whether exec() should be called based on your interest rate deviation threshold
    // This assumes normal operation, culled / global shutdown should be handled externally
    // Also assumes no liquidity issues
    function shouldExec(
        address _direct,
        uint256 interestRateTolerance
    ) public view returns (bool) {
        // IMPORTANT: this function assumes Vat rate of this ilk will always be == 1 * RAY (no fees).
        // That's why this module converts normalized debt (art) to Vat DAI generated with a simple RAY multiplication or division
        // This module will have an unintended behaviour if rate is changed to some other value.

        DirectLike direct = DirectLike(_direct);
        VatLike vat = VatLike(direct.vat());
        address dai = direct.dai();
        bytes32 ilk = direct.ilk();
        LendingPoolLike pool = LendingPoolLike(direct.pool());

        (, uint256 daiDebt) = vat.urns(ilk, address(direct));
        uint256 _bar = direct.bar();
        if (_bar == 0) {
            return daiDebt > 1;     // Always attempt to close out if we have debt remaining
        }

        (,,,, uint256 currVarBorrow,,,,,,,) = pool.getReserveData(dai);

        uint256 deviation = _rdiv(currVarBorrow, _bar);
        if (deviation < RAY) {
            // Unwind case
            return daiDebt > 1 && (RAY - deviation) > interestRateTolerance;
        } else if (deviation > RAY) {
            // Wind case
            (,,, uint256 line,) = vat.ilks(ilk);
            return (daiDebt + 1)*RAY < line && (deviation - RAY) > interestRateTolerance;
        } else {
            // No change
            return false;
        }
    }

    function conditionalExec(
        address _direct,
        uint256 interestRateTolerance
    ) external {
        require(shouldExec(_direct, interestRateTolerance), "DirectHelper/not-ready");
        
        DirectLike(_direct).exec();
    }

}