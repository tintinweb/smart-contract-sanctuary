/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// hevm: flattened sources of src/AutoLineJob.sol
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

////// src/AutoLineJob.sol
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

interface SequencerLike_2 {
    function isMaster(bytes32 network) external view returns (bool);
}

interface IlkRegistryLike_1 {
    function list() external view returns (bytes32[] memory);
}

interface AutoLineLike_1 {
    function vat() external view returns (address);
    function ilks(bytes32) external view returns (uint256, uint256, uint48, uint48, uint48);
    function exec(bytes32) external returns (uint256);
}

interface VatLike_2 {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
}

/// @title Trigger autoline updates based on thresholds
contract AutoLineJob is IJob {

    uint256 constant internal BPS = 10 ** 4;
    
    SequencerLike_2 public immutable sequencer;
    IlkRegistryLike_1 public immutable ilkRegistry;
    AutoLineLike_1 public immutable autoline;
    VatLike_2 public immutable vat;
    uint256 public immutable thi;                       // % above the previously exec'ed debt level
    uint256 public immutable tlo;                       // % below the previously exec'ed debt level

    // --- Errors ---
    error NotMaster(bytes32 network);
    error OutsideThreshold(uint256 line, uint256 nextLine);

    constructor(address _sequencer, address _ilkRegistry, address _autoline, uint256 _thi, uint256 _tlo) {
        sequencer = SequencerLike_2(_sequencer);
        ilkRegistry = IlkRegistryLike_1(_ilkRegistry);
        autoline = AutoLineLike_1(_autoline);
        vat = VatLike_2(autoline.vat());
        thi = _thi;
        tlo = _tlo;
    }

    function work(bytes32 network, bytes calldata args) external override {
        if (!sequencer.isMaster(network)) revert NotMaster(network);
        
        bytes32 ilk = abi.decode(args, (bytes32));

        (,,, uint256 line,) = vat.ilks(ilk);
        uint256 nextLine = autoline.exec(ilk);

        // Execution is not enough
        // We need to be over the threshold amounts
        (uint256 maxLine, uint256 gap,,,) = autoline.ilks(ilk);
        if (
            nextLine != maxLine &&
            nextLine < line + gap * thi / BPS &&
            nextLine + gap * tlo / BPS > line
        ) revert OutsideThreshold(line, nextLine);
    }

    function workable(bytes32 network) external view override returns (bool, bytes memory) {
        if (!sequencer.isMaster(network)) return (false, bytes("Network is not master"));
        
        bytes32[] memory ilks = ilkRegistry.list();
        for (uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];

            (uint256 Art, uint256 rate,, uint256 line,) = vat.ilks(ilk);
            uint256 debt = Art * rate;
            (uint256 maxLine, uint256 gap, uint48 ttl, uint48 last, uint48 lastInc) = autoline.ilks(ilk);
            uint256 nextLine = debt + gap;
            if (nextLine > maxLine) nextLine = maxLine;

            // Check autoline rules
            if (maxLine == 0) continue;                     // Ilk is not enabled
            if (last == block.number) continue;             // Already triggered this block
            if (line == nextLine ||                         // No change in line
                nextLine > line &&                          // Increase in line
                block.timestamp < lastInc + ttl) continue;  // TTL hasn't expired

            // Check if current debt level is inside our do-nothing range
            // Re-arranged to remove any subtraction (and thus underflow)
            // Exception if we are at the maxLine
            if (
                nextLine != maxLine &&
                nextLine < line + gap * thi / BPS &&
                nextLine + gap * tlo / BPS > line
            ) continue;

            // Good to adjust!
            return (true, abi.encode(ilk));
        }

        return (false, bytes("No ilks ready"));
    }

}