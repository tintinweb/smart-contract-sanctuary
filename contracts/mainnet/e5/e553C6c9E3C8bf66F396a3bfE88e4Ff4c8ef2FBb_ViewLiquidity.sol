// SPDX-License-Identifier: MIT

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

pragma solidity ^0.7.3;

import "./Storage.sol";

import "./Assimilators.sol";

import "./ABDKMath64x64.sol";

library ViewLiquidity {
    using ABDKMath64x64 for int128;

    function viewLiquidity(Storage.Curve storage curve)
        external
        view
        returns (uint256 total_, uint256[] memory individual_)
    {
        uint256 _length = curve.assets.length;

        individual_ = new uint256[](_length);

        for (uint256 i = 0; i < _length; i++) {
            uint256 _liquidity = Assimilators.viewNumeraireBalance(curve.assets[i].addr).mulu(1e18);

            total_ += _liquidity;
            individual_[i] = _liquidity;
        }

        return (total_, individual_);
    }
}