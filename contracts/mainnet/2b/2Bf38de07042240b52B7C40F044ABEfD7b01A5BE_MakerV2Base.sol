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

import "./BaseFeature.sol";
import "./IMakerRegistry.sol";
import "./MakerInterfaces.sol";
import "./DSMath.sol";

/**
 * @title MakerV2Base
 * @notice Common base to MakerV2Invest and MakerV2Loan.
 * @author Olivier VDB - <olivier@argent.xyz>
 */
abstract contract MakerV2Base is DSMath, BaseFeature {

    bytes32 constant private NAME = "MakerV2Manager";

    // The address of the (MCD) DAI token
    GemLike internal daiToken;
    // The address of the SAI <-> DAI migration contract
    address internal scdMcdMigration;
    // The address of the Dai Adapter
    JoinLike internal daiJoin;
    // The address of the Vat
    VatLike internal vat;

    using SafeMath for uint256;

    // *************** Constructor ********************** //

    constructor(
        ILockStorage _lockStorage,
        ScdMcdMigrationLike _scdMcdMigration,
        IVersionManager _versionManager
    )
        BaseFeature(_lockStorage, _versionManager, NAME)
        public
    {
        scdMcdMigration = address(_scdMcdMigration);
        daiJoin = _scdMcdMigration.daiJoin();
        daiToken = daiJoin.dai();
        vat = daiJoin.vat();
    }

    /**
     * @inheritdoc IFeature
     */
    function getRequiredSignatures(address, bytes calldata) external view override returns (uint256, OwnerSignature) {
        return (1, OwnerSignature.Required);
    }
}