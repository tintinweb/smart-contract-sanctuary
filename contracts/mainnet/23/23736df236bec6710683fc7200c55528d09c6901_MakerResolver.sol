// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

address constant MCD_MANAGER = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import {
    _getMakerRawVaultDebt,
    _getMakerVaultCollateralBalance
} from "../../functions/dapps/FMaker.sol";

contract MakerResolver {
    /// @dev Return Debt in wad of the vault associated to the vaultId.
    function getMakerVaultDebt(uint256 _vaultId) public view returns (uint256) {
        return _getMakerRawVaultDebt(_vaultId);
    }

    /// @dev Return Collateral in wad of the vault associated to the vaultId.
    function getMakerVaultCollateralBalance(uint256 _vaultId)
        public
        view
        returns (uint256)
    {
        return _getMakerVaultCollateralBalance(_vaultId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import {MCD_MANAGER} from "../../constants/CMaker.sol";
import {IMcdManager} from "../../interfaces/dapps/Maker/IMcdManager.sol";
import {IVat} from "../../interfaces/dapps/Maker/IVat.sol";
import {RAY, sub, mul} from "../../vendor/DSMath.sol";

function _getMakerVaultDebt(uint256 _vaultId) view returns (uint256 wad) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 rad = sub(mul(art, rate), dai);
    wad = rad / RAY;

    wad = mul(wad, RAY) < rad ? wad + 1 : wad;
}

function _getMakerRawVaultDebt(uint256 _vaultId) view returns (uint256 tab) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);

    uint256 rad = mul(art, rate);

    tab = rad / RAY;
    tab = mul(tab, RAY) < rad ? tab + 1 : tab;
}

function _getMakerVaultCollateralBalance(uint256 _vaultId)
    view
    returns (uint256)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    IVat vat = IVat(manager.vat());
    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (uint256 ink, ) = vat.urns(ilk, urn);

    return ink;
}

function _getVaultData(IMcdManager manager, uint256 vault)
    view
    returns (bytes32 ilk, address urn)
{
    ilk = manager.ilks(vault);
    urn = manager.urns(vault);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IMcdManager {
    function ilks(uint256) external view returns (bytes32);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IVat {
    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);
}

// "SPDX-License-Identifier: AGPL-3.0-or-later"
/// math.sol -- mixin for inline numerical wizardry

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

pragma solidity 0.7.4;

function add(uint x, uint y) pure returns (uint z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}
function sub(uint x, uint y) pure returns (uint z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}
function mul(uint x, uint y) pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function min(uint x, uint y) pure returns (uint z) {
    return x <= y ? x : y;
}
function max(uint x, uint y) pure returns (uint z) {
    return x >= y ? x : y;
}
function imin(int x, int y) pure returns (int z) {
    return x <= y ? x : y;
}
function imax(int x, int y) pure returns (int z) {
    return x >= y ? x : y;
}

uint constant WAD = 10 ** 18;
uint constant RAY = 10 ** 27;

//rounds to zero if x*y < WAD / 2
function wmul(uint x, uint y) pure returns (uint z) {
    z = add(mul(x, y), WAD / 2) / WAD;
}
//rounds to zero if x*y < WAD / 2
function rmul(uint x, uint y) pure returns (uint z) {
    z = add(mul(x, y), RAY / 2) / RAY;
}
//rounds to zero if x*y < WAD / 2
function wdiv(uint x, uint y) pure returns (uint z) {
    z = add(mul(x, WAD), y / 2) / y;
}
//rounds to zero if x*y < RAY / 2
function rdiv(uint x, uint y) pure returns (uint z) {
    z = add(mul(x, RAY), y / 2) / y;
}

// This famous algorithm is called "exponentiation by squaring"
// and calculates x^n with x as fixed-point and n as regular unsigned.
//
// It's O(log n), instead of O(n) for naive repeated multiplication.
//
// These facts are why it works:
//
//  If n is even, then x^n = (x^2)^(n/2).
//  If n is odd,  then x^n = x * x^(n-1),
//   and applying the equation for even x gives
//    x^n = x * (x^2)^((n-1) / 2).
//
//  Also, EVM division is flooring and
//    floor[(n-1) / 2] = floor[n / 2].
//
function rpow(uint x, uint n) pure returns (uint z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = rmul(x, x);

        if (n % 2 != 0) {
            z = rmul(z, x);
        }
    }
}

