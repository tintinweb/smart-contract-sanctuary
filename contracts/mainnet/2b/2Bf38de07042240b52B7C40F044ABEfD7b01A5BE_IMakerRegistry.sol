// Copyright (C) 2020  Argent Labs Ltd. <https://argent.xyz>

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

import "./MakerInterfaces.sol";
/**
 * @title IMakerRegistry
 * @notice Interface for the MakerRegistry
 */
interface IMakerRegistry {
    function collaterals(address _collateral) external view returns (bool exists, uint128 index, JoinLike join, bytes32 ilk);
    function addCollateral(JoinLike _joinAdapter) external;
    function removeCollateral(address _token) external;
    function getCollateralTokens() external view returns (address[] memory _tokens);
    function getIlk(address _token) external view returns (bytes32 _ilk);
    function getCollateral(bytes32 _ilk) external view returns (JoinLike _join, GemLike _token);
}