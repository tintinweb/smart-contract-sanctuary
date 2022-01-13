/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// hevm: flattened sources of src/AaveDirectJob.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.9 >=0.8.0;

////// src/interfaces/IJob.sol
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
/* pragma solidity >=0.8.0; */

/// @title Maker Keeper Network Job
/// @notice A job represents an independant unit of work that can be done by a keeper
interface IJob {

    /// @notice Executes this unit of work
    /// @dev Should revert iff workable() returns canWork of false
    /// @param network The name of the external keeper network
    /// @param args Custom arguments supplied to the job, should be copied from workable response
    function work(bytes32 network, bytes calldata args) external;

    /// @notice Ask this job if it has a unit of work available
    /// @dev This should never revert, only return false if nothing is available
    /// @dev This should normally be a view, but sometimes that's not possible
    /// @param network The name of the external keeper network
    /// @return canWork Returns true if a unit of work is available
    /// @return args The custom arguments to be provided to work() or an error string if canWork is false
    function workable(bytes32 network) external returns (bool canWork, bytes memory args);

}

////// src/AaveDirectJob.sol
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
/* pragma solidity 0.8.9; */

/* import {IJob} from "./interfaces/IJob.sol"; */

interface SequencerLike_1 {
    function isMaster(bytes32 network) external view returns (bool);
}

interface VatLike_1 {
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

interface LendingPoolLike_1 {
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

/// @title Trigger Aave D3M updates based on threshold
contract AaveDirectJob is IJob {

    uint256 constant internal RAY = 10 ** 27;
    
    SequencerLike_1 public immutable sequencer;
    DirectLike public immutable direct;
    VatLike_1 public immutable vat;
    address public immutable dai;
    bytes32 public immutable ilk;
    LendingPoolLike_1 public immutable pool;
    uint256 public immutable threshold;         // Threshold deviation to kick off exec [RAY units]

    // --- Errors ---
    error NotMaster(bytes32 network);
    error OutsideThreshold();

    constructor(address _sequencer, address _direct, uint256 _threshold) {
        sequencer = SequencerLike_1(_sequencer);
        direct = DirectLike(_direct);
        vat = VatLike_1(direct.vat());
        dai = direct.dai();
        ilk = direct.ilk();
        pool = LendingPoolLike_1(direct.pool());
        threshold = _threshold;
    }

    function isOutsideThreshold() internal view returns (bool) {
        // IMPORTANT: this function assumes Vat rate of this ilk will always be == 1 * RAY (no fees).
        // That's why this module converts normalized debt (art) to Vat DAI generated with a simple RAY multiplication or division
        // This module will have an unintended behaviour if rate is changed to some other value.

        (, uint256 daiDebt) = vat.urns(ilk, address(direct));
        uint256 _bar = direct.bar();
        if (_bar == 0) {
            return daiDebt > 1;     // Always attempt to close out if we have debt remaining
        }

        (,,,, uint256 currVarBorrow,,,,,,,) = pool.getReserveData(dai);

        uint256 deviation = currVarBorrow * RAY / _bar;
        if (deviation < RAY) {
            // Unwind case
            return daiDebt > 1 && (RAY - deviation) > threshold;
        } else if (deviation > RAY) {
            // Wind case
            (,,, uint256 line,) = vat.ilks(ilk);
            return (daiDebt + 1)*RAY < line && (deviation - RAY) > threshold;
        } else {
            // No change
            return false;
        }
    }

    function work(bytes32 network, bytes calldata) external override {
        if (!sequencer.isMaster(network)) revert NotMaster(network);
        if (!isOutsideThreshold()) revert OutsideThreshold();

        direct.exec();
    }

    function workable(bytes32 network) external view override returns (bool, bytes memory) {
        if (!sequencer.isMaster(network)) return (false, bytes("Network is not master"));
        if (!isOutsideThreshold()) return (false, bytes("Interest rate is in acceptable range"));

        return (true, "");
    }

}