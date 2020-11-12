// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

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

import "./IWallet.sol";

/**
 * @title Storage
 * @notice Base contract for the storage of a wallet.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract Storage {

    /**
     * @notice Throws if the caller is not an authorised module.
     */
    modifier onlyModule(address _wallet) {
        require(IWallet(_wallet).authorised(msg.sender), "TS: must be an authorized module to call this method");
        _;
    }
}