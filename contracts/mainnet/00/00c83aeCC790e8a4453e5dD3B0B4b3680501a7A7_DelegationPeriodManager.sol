// SPDX-License-Identifier: AGPL-3.0-only

/*
    DelegationPeriodManager.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev
    @author Vadim Yavorsky

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

import "../Permissions.sol";

/**
 * @title Delegation Period Manager
 * @dev This contract handles all delegation offerings. Delegations are held for
 * a specified period (months), and different durations can have different
 * returns or `stakeMultiplier`. Currently, only delegation periods can be added.
 */
contract DelegationPeriodManager is Permissions {

    /**
     * @dev Emitted when a new delegation period is specified.
     */
    event DelegationPeriodWasSet(
        uint length,
        uint stakeMultiplier
    );

    mapping (uint => uint) public stakeMultipliers;

    /**
     * @dev Creates a new available delegation period and return in the network.
     * Only the owner may set new delegation period and returns in the network.
     *
     * Emits a DelegationPeriodWasSet event.
     *
     * @param monthsCount uint delegation duration in months
     * @param stakeMultiplier uint return for delegation
     */
    function setDelegationPeriod(uint monthsCount, uint stakeMultiplier) external onlyOwner {
        stakeMultipliers[monthsCount] = stakeMultiplier;

        emit DelegationPeriodWasSet(monthsCount, stakeMultiplier);
    }

    /**
     * @dev Checks whether given delegation period is allowed.
     *
     * @param monthsCount uint delegation duration in months
     * @return bool True if delegation period is allowed
     */
    function isDelegationPeriodAllowed(uint monthsCount) external view returns (bool) {
        return stakeMultipliers[monthsCount] != 0 ? true : false;
    }

    /**
     * @dev Initial delegation period and multiplier settings.
     */
    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);
        stakeMultipliers[3] = 100;  // 3 months at 100
        stakeMultipliers[6] = 150;  // 6 months at 150
        stakeMultipliers[12] = 200; // 12 months at 200
    }
}