// Copyright (C) 2019  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;

import "./MakerV2Base.sol";
import "./MakerV2Invest.sol";
import "./MakerV2Loan.sol";

/**
 * @title MakerV2Manager
 * @notice Module to lock/unlock MCD DAI into/from Maker's Pot,
 * migrate old CDPs and open and manage new CDPs.
 * @author Olivier VDB - <olivier@argent.xyz>
 */
contract MakerV2Manager is MakerV2Base, MakerV2Invest, MakerV2Loan {

    // *************** Constructor ********************** //

    constructor(
        ILockStorage _lockStorage,
        ScdMcdMigrationLike _scdMcdMigration,
        PotLike _pot,
        JugLike _jug,
        IMakerRegistry _makerRegistry,
        IUniswapFactory _uniswapFactory,
        IVersionManager _versionManager
    )
        MakerV2Base(_lockStorage, _scdMcdMigration, _versionManager)
        MakerV2Invest(_pot)
        MakerV2Loan(_jug, _makerRegistry, _uniswapFactory)
        public
    {
    }

}