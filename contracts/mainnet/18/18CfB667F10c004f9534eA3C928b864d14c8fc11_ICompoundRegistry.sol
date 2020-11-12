// Copyright (C) 2020 Argent Labs Ltd. <https://argent.xyz>

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
pragma solidity >=0.5.4 <0.7.0;

/**
 * @title ICompoundRegistry
 * @notice Interface for CompoundRegistry
 */
interface ICompoundRegistry {
    function addCToken(address _underlying, address _cToken) external;

    function removeCToken(address _underlying) external;

    function getCToken(address _underlying) external view returns (address);

    function listUnderlyings() external view returns (address[] memory);
}