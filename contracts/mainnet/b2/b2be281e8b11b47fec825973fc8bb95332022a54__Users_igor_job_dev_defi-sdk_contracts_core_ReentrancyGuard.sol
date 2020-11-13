// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

contract ReentrancyGuard {

    uint256 internal constant UNLOCKED = 1;
    uint256 internal constant LOCKED = 2;

    uint256 internal guard_;

    constructor () internal {
        guard_ = UNLOCKED;
    }

    modifier nonReentrant() {
        require(guard_ == UNLOCKED, "RG: locked");

        guard_ = LOCKED;

        _;

        guard_ = UNLOCKED;
    }
}