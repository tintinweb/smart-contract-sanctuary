// SPDX-License-Identifier: AGPL-3.0-only

/*
    IDelegatableToken.sol - SKALE Manager
    Copyright (C) 2019-Present SKALE Labs
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

/**
 * @dev Interface of Delegatable Token operations.
 */
interface IDelegatableToken {
    /**
     * @dev Updates and returns the amount of locked tokens of a given account (`wallet`).
     */
    function getAndUpdateLockedAmount(address wallet) external returns (uint);
    /**
     * @dev Updates and returns the amount of delegated tokens of a given account (`wallet`).
     */
    function getAndUpdateDelegatedAmount(address wallet) external returns (uint);
    /**
     * @dev Updates and returns the amount of slashed tokens of a given account (`wallet`).
     */
    function getAndUpdateSlashedAmount(address wallet) external returns (uint);
}