// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;

import "./IGelatoCondition.sol";

abstract contract GelatoConditionsStandard is IGelatoCondition {
    string internal constant OK = "OK";
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {

    /// @notice GelatoCore calls this to verify securely the specified Condition securely
    /// @dev Be careful only to encode a Task's condition.data as is and not with the
    ///  "ok" selector or _taskReceiptId, since those two things are handled by GelatoCore.
    /// @param _taskReceiptId This is passed by GelatoCore so we can rely on it as a secure
    ///  source of Task identification.
    /// @param _conditionData This is the Condition.data field developers must encode their
    ///  Condition's specific parameters in.
    /// @param _cycleId For Tasks that are executed as part of a cycle.
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256 _cycleId)
        external
        view
        returns(string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import {
    GelatoConditionsStandard
} from "@gelatonetwork/core/contracts/conditions/GelatoConditionsStandard.sol";
import {wmul, wdiv} from "../../../vendor/DSMath.sol";
import {GelatoBytes} from "../../../lib/GelatoBytes.sol";
import {
    IInstaMakerResolver
} from "../../../interfaces/InstaDapp/resolvers/IInstaMakerResolver.sol";

/// @title ConditionMakerVaultUnsafe
/// @notice Condition tracking Maker vault collateralization safety requirements.
/// @author Gelato Team
contract ConditionMakerVaultUnsafe is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    /// @notice Convenience function for off-chain _conditionData encoding
    /// @dev Use the return for your Task's Condition.data field off-chain.
    /// @return The encoded payload for your Task's Condition.data field.
    function getConditionData(
        uint256 _vaultId,
        address _priceOracle,
        bytes calldata _oraclePayload,
        uint256 _minColRatio
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.isVaultUnsafe.selector,
                _vaultId,
                _priceOracle,
                _oraclePayload,
                _minColRatio
            );
    }

    /// @notice Standard GelatoCore system function
    /// @dev A standard interface for GelatoCore to read Conditions
    /// @param _conditionData The data you get from `getConditionData()`
    /// @return OK if the Condition is there, else some error message.
    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (
            uint256 _vaultID,
            address _priceOracle,
            bytes memory _oraclePayload,
            uint256 _minColRatio
        ) = abi.decode(_conditionData[4:], (uint256, address, bytes, uint256));

        return
            isVaultUnsafe(_vaultID, _priceOracle, _oraclePayload, _minColRatio);
    }

    /// @notice Specific implementation of this Condition's ok function
    /// @dev The price oracle must return a uint256 WAD (10**18) value.
    /// @param _vaultId The id of the Maker vault
    /// @param _priceOracle The price oracle contract to supply the collateral price
    ///  e.g. Maker's ETH/USD oracle for ETH collateral pricing.
    /// @param _oraclePayload The data for making the staticcall to the oracle's read
    ///  method e.g. the selector for MakerOracle's read fn.
    /// @param _minColRatio The minimum collateral ratio measured in the price
    /// of the collateral as specified by the _priceOracle.
    /// @return OK if the Maker Vault is unsafe, otherwise some error message.
    function isVaultUnsafe(
        uint256 _vaultId,
        address _priceOracle,
        bytes memory _oraclePayload,
        uint256 _minColRatio
    ) public view virtual returns (string memory) {
        (bool success, bytes memory returndata) =
            _priceOracle.staticcall(_oraclePayload);

        if (!success) {
            returndata.revertWithError(
                "ConditionMakerVaultUnsafe.isVaultUnsafe:oracle:"
            );
        }

        uint256 colPriceInWad = abi.decode(returndata, (uint256));

        IInstaMakerResolver.VaultData memory vault =
            IInstaMakerResolver(0x0A7008B38E7015F8C36A49eEbc32513ECA8801E5)
                .getVaultById(_vaultId);

        uint256 colRatio =
            wdiv(wmul(vault.collateral, colPriceInWad), vault.debt);

        return colRatio < _minColRatio ? OK : "MakerVaultNotUnsafe";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IInstaMakerResolver {
    struct VaultData {
        uint256 id;
        address owner;
        string colType;
        uint256 collateral;
        uint256 art;
        uint256 debt;
        uint256 liquidatedCol;
        uint256 borrowRate;
        uint256 colPrice;
        uint256 liquidationRatio;
        address vaultAddress;
    }

    function getVaultById(uint256 id) external view returns (VaultData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
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

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    return x <= y ? x : y;
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    return x >= y ? x : y;
}

function imin(int256 x, int256 y) pure returns (int256 z) {
    return x <= y ? x : y;
}

function imax(int256 x, int256 y) pure returns (int256 z) {
    return x >= y ? x : y;
}

uint256 constant WAD = 10**18;
uint256 constant RAY = 10**27;

//rounds to zero if x*y < WAD / 2
function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
}

//rounds to zero if x*y < WAD / 2
function rmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
}

//rounds to zero if x*y < WAD / 2
function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
}

//rounds to zero if x*y < RAY / 2
function rdiv(uint256 x, uint256 y) pure returns (uint256 z) {
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
function rpow(uint256 x, uint256 n) pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = rmul(x, x);

        if (n % 2 != 0) {
            z = rmul(z, x);
        }
    }
}

