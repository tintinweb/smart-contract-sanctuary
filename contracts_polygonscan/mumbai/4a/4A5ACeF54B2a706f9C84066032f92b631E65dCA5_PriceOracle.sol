// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// ==================== Internal Imports ====================

import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../lib/AddressArrayUtil.sol";

import { IOracle } from "../interfaces/IOracle.sol";
import { IController } from "../interfaces/IController.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IOracleAdapter } from "../interfaces/IOracleAdapter.sol";

/**
 * @title PriceOracle
 * @author Matrix
 *
 * @dev Returns the price for any given asset pair. Price is retrieved either directly from an oracle,
 * calculated using common asset pairs, or uses external data to calculate price.
 * @notice Prices are returned in preciseUnits (i.e. 18 decimals of precision)
 */
contract PriceOracle is Ownable, IPriceOracle {
    using PreciseUnitMath for uint256;
    using AddressArrayUtil for address[];

    // ==================== Variables ====================

    IController internal immutable _controller;

    // asset1 -> asset2 -> IOracle Interface
    mapping(address => mapping(address => IOracle)) internal _oracles;

    // Token address of the bridge asset that prices are derived from if the specified pair price is missing
    address internal _masterQuoteAsset;

    // IOracleAdapters used to return prices of third party protocols (e.g. Uniswap, Compound, Balancer)
    address[] internal _adapters;

    // ==================== Events ====================

    event AddPair(address indexed asset1, address indexed asset2, address indexed oracle);
    event RemovePair(address indexed asset1, address indexed asset2, address indexed oracle);
    event EditPair(address indexed asset1, address indexed asset2, address indexed newOracle);
    event AddAdapter(address indexed adapter);
    event RemoveAdapter(address indexed adapter);
    event EditMasterQuoteAsset(address indexed newMasterQuote);

    // ==================== Constructor function ====================

    /**
     * @param controller          Address of controller contract
     * @param masterQuoteAsset    Address of asset that can be used to link unrelated asset pairs
     * @param adapters            List of adapters used to price assets created by other protocols
     * @param assets1             List of first asset in pair, index i maps to same index in assetTwos and oracles
     * @param assets2             List of second asset in pair, index i maps to same index in assetOnes and oracles
     * @param oracles             List of oracles, index i maps to same index in assetOnes and assetTwos
     */
    constructor(
        IController controller,
        address masterQuoteAsset,
        address[] memory adapters,
        address[] memory assets1,
        address[] memory assets2,
        IOracle[] memory oracles
    ) {
        uint256 count = assets1.length;
        require(count == assets2.length, "PO0a");
        require(count == oracles.length, "PO0b");

        _controller = controller;
        _masterQuoteAsset = masterQuoteAsset;
        _adapters = adapters;

        for (uint256 i = 0; i < count; i++) {
            _oracles[assets1[i]][assets2[i]] = oracles[i];
        }
    }

    // ==================== External functions ====================

    function getController() external view returns (address) {
        return address(_controller);
    }

    function getOracle(address asset1, address asset2) external view returns (address) {
        return address(_oracles[asset1][asset2]);
    }

    function getMasterQuoteAsset() external view returns (address) {
        return _masterQuoteAsset;
    }

    function getAdapters() external view returns (address[] memory) {
        return _adapters;
    }

    /**
     * @dev SYSTEM-ONLY PRIVELEGE: Find price of passed asset pair, if possible. The steps it takes are:
     *  1) Check to see if a direct or inverse oracle of the pair exists,
     *  2) If not, use masterQuoteAsset to link pairs together (i.e. BTC/ETH and ETH/USDC could be used to calculate BTC/USDC).
     *  3) If not, check oracle adapters in case one or more of the assets needs external protocol data to price.
     *  4) If all steps fail, revert.
     *
     * @param asset1      Address of first asset in pair
     * @param asset2      Address of second asset in pair
     *
     * @return uint256    Price of asset pair to 18 decimals of precision
     */
    function getPrice(address asset1, address asset2) external view returns (uint256) {
        require(_controller.isSystemContract(msg.sender), "PO1a");

        (bool priceFound, uint256 price) = _getDirectOrInversePrice(asset1, asset2);

        if (!priceFound) {
            (priceFound, price) = _getPriceFromMasterQuote(asset1, asset2);

            if (!priceFound) {
                (priceFound, price) = _getPriceFromAdapters(asset1, asset2);

                if (!priceFound) {
                    revert("PO1b");
                }
            }
        }

        return price;
    }

    /**
     * @dev GOVERNANCE FUNCTION: Add new asset pair oracle.
     *
     * @param asset1    Address of first asset in pair
     * @param asset2    Address of second asset in pair
     * @param oracle    Address of asset pair's oracle
     */
    function addPair(
        address asset1,
        address asset2,
        IOracle oracle
    ) external onlyOwner {
        require(address(_oracles[asset1][asset2]) == address(0), "PO2");

        _oracles[asset1][asset2] = oracle;

        emit AddPair(asset1, asset2, address(oracle));
    }

    /**
     * @dev GOVERNANCE FUNCTION: Edit an existing asset pair's oracle.
     *
     * @param asset1    Address of first asset in pair
     * @param asset2    Address of second asset in pair
     * @param oracle    Address of asset pair's new oracle
     */
    function editPair(
        address asset1,
        address asset2,
        IOracle oracle
    ) external onlyOwner {
        require(address(_oracles[asset1][asset2]) != address(0), "PO3");

        _oracles[asset1][asset2] = oracle;

        emit EditPair(asset1, asset2, address(oracle));
    }

    /**
     * @dev GOVERNANCE FUNCTION: Remove asset pair's oracle.
     *
     * @param asset1    Address of first asset in pair
     * @param asset2    Address of second asset in pair
     */
    function removePair(address asset1, address asset2) external onlyOwner {
        address oldOracle = address(_oracles[asset1][asset2]);
        require(oldOracle != address(0), "PO4");

        delete _oracles[asset1][asset2];

        emit RemovePair(asset1, asset2, oldOracle);
    }

    /**
     * @dev GOVERNANCE FUNCTION: Add new oracle adapter.
     *
     * @param adapter    Address of new adapter
     */
    function addAdapter(address adapter) external onlyOwner {
        require(!_adapters.containItem(adapter), "PO5");

        _adapters.push(adapter);

        emit AddAdapter(adapter);
    }

    /**
     * @dev GOVERNANCE FUNCTION: Remove oracle adapter.
     *
     * @param adapter    Address of adapter to remove
     */
    function removeAdapter(address adapter) external onlyOwner {
        require(_adapters.containItem(adapter), "PO6");

        _adapters.removeItem(adapter);

        emit RemoveAdapter(adapter);
    }

    /**
     * @dev GOVERNANCE FUNCTION: Change the master quote asset.
     *
     * @param newMasterQuoteAsset    New address of master quote asset
     */
    function editMasterQuoteAsset(address newMasterQuoteAsset) external onlyOwner {
        _masterQuoteAsset = newMasterQuoteAsset;

        emit EditMasterQuoteAsset(newMasterQuoteAsset);
    }

    // ==================== Internal functions ====================

    /**
     * @dev Check if direct or inverse oracle exists. If so return that price along with boolean
     * indicating it exists. Otherwise return boolean indicating oracle doesn't exist.
     *
     * @param asset1      Address of first asset in pair
     * @param asset2      Address of second asset in pair
     *
     * @return bool       Boolean indicating if oracle exists
     * @return uint256    Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getDirectOrInversePrice(address asset1, address asset2) internal view returns (bool, uint256) {
        IOracle oracle = _oracles[asset1][asset2];
        if (address(oracle) != address(0)) {
            return (true, oracle.read());
        }

        oracle = _oracles[asset2][asset1];

        return (address(oracle) != address(0)) ? (true, _calculateInversePrice(oracle)) : (false, 0);
    }

    /**
     * @dev Try to calculate asset pair price by getting each asset in the pair's price relative to
     * master quote asset. Both prices must exist otherwise function returns false and no price.
     *
     * @param asset1      Address of first asset in pair
     * @param asset2      Address of second asset in pair
     *
     * @return bool       Boolean indicating if oracle exists
     * @return uint256    Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getPriceFromMasterQuote(address asset1, address asset2) internal view returns (bool, uint256) {
        (bool foundPrice1, uint256 asset1Price) = _getDirectOrInversePrice(asset1, _masterQuoteAsset);
        if (!foundPrice1) {
            return (false, 0);
        }

        (bool foundPrice2, uint256 asset2Price) = _getDirectOrInversePrice(asset2, _masterQuoteAsset);

        return foundPrice2 ? (true, asset1Price.preciseDiv(asset2Price)) : (false, 0);
    }

    /**
     * @dev Scan adapters to see if one or more of the assets needs external protocol data to be priced.
     * If does not exist return false and no price.
     *
     * @param asset1      Address of first asset in pair
     * @param asset2      Address of second asset in pair
     *
     * @return bool       Boolean indicating if oracle exists
     * @return uint256    Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getPriceFromAdapters(address asset1, address asset2) internal view returns (bool, uint256) {
        for (uint256 i = 0; i < _adapters.length; i++) {
            (bool foundPrice, uint256 price) = IOracleAdapter(_adapters[i]).getPrice(asset1, asset2);

            if (foundPrice) {
                return (true, price);
            }
        }

        return (false, 0);
    }

    /**
     * @dev Calculate inverse price of passed oracle. The inverse price is 1 (or 1e18) / inverse price
     *
     * @param inverseOracle    Address of oracle to invert
     *
     * @return uint256         Inverted price of asset pair to 18 decimal precision
     */
    function _calculateInversePrice(IOracle inverseOracle) internal view returns (uint256) {
        uint256 inverseValue = inverseOracle.read();

        return PreciseUnitMath.preciseUnit().preciseDiv(inverseValue);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title PreciseUnitMath
 * @author Matrix
 *
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from dYdX's BaseMath library.
 */
library PreciseUnitMath {
    // ==================== Constants ====================

    // The number One in precise units.
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;

    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    // ==================== Internal functions ====================

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down), both a and b are numbers with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISE_UNIT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero), both a and b are numbers with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / PRECISE_UNIT_INT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up), both a and b are numbers with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b - 1) / PRECISE_UNIT + 1;
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM0");

        return (a * PRECISE_UNIT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "PM1");

        return (a * PRECISE_UNIT_INT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM2");

        return a > 0 ? ((a * PRECISE_UNIT - 1) / b + 1) : 0;
    }

    // int256(5) / int256(2) == (2, 1)
    // int256(5) / int256(-2) == (-2, 1)
    // int256(-5) / int256(2) == (-2, -1)
    // int256(-5) / int256(-2) == (2, -1)

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseMulFloor(int256 a, int256 b) internal pure returns (int256 result) {
        int256 numerator = a * b;
        result = numerator / PRECISE_UNIT_INT;
        if ((numerator < 0) && (numerator % PRECISE_UNIT_INT != 0)) {
            result--;
        }
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
     * returned. When `b` is 0, method reverts with divide-by-zero error.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM3");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1
        if ((numerator ^ b > 0) && (numerator % b != 0)) {
            result++;
        }
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseDivFloor(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM4");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1
        if ((numerator ^ b < 0) && (numerator % b != 0)) {
            result--;
        }
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(
        uint256 a,
        uint256 b,
        uint256 range
    ) internal pure returns (bool) {
        if (a >= b) {
            return a - b <= range;
        } else {
            return b - a <= range;
        }
    }

    /**
     * @dev Returns the absolute value of int256 `a` as a uint256
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title AddressArrayUtil
 * @author Matrix
 *
 * @dev Utility functions to handle Address Arrays
 */
library AddressArrayUtil {
    // ==================== Internal functions ====================

    /**
     * @dev Check the array whether contains duplicate elements.
     *
     * @param array    The input array to search.
     *
     * @return bool    Whether array has duplicate elements.
     */
    function hasDuplicateValue(address[] memory array) internal pure returns (bool) {
        if (array.length > 1) {
            uint256 lastIndex = array.length - 1;
            for (uint256 i = 0; i < lastIndex; i++) {
                address value = array[i];
                for (uint256 j = i + 1; j < array.length; j++) {
                    if (value == array[j]) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * @dev Search element in array
     *
     * @param array     The input array to search.
     * @param value     The element to search.
     *
     * @return index    The first element's position in array, start from 0.
     * @return found    Whether find element in array.
     */
    function indexOfValue(address[] memory array, address value) internal pure returns (uint256 index, bool found) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }

        return (type(uint256).max, false);
    }

    /**
     * @dev Search element in array
     *
     * @param array     The input array to search.
     * @param item      The element to search.
     *
     * @return index    The first element's position in array, start from 0.
     * @return found    Whether find element in array.
     */
    function indexOfItem(address[] storage array, address item) internal view returns (uint256 index, bool found) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == item) {
                return (i, true);
            }
        }

        return (type(uint256).max, false);
    }

    /**
     * @dev search element in array.
     *
     * @param array    The input array to search.
     * @param value    The element to search.
     *
     * @return bool    Whether value is in array.
     */
    function containValue(address[] memory array, address value) internal pure returns (bool) {
        (, bool found) = indexOfValue(array, value);
        return found;
    }

    /**
     * @dev search element in array.
     *
     * @param array    The input array to search.
     * @param item     The element to search.
     *
     * @return bool    Whether value is in array.
     */
    function containItem(address[] storage array, address item) internal view returns (bool) {
        (, bool found) = indexOfItem(array, item);
        return found;
    }

    /**
     * @dev remove the first specified element, and keep order of other elements.
     *
     * @param array    The input array to search.
     * @param value    The element to remove.
     */
    function removeValue(address[] memory array, address value) internal pure returns (address[] memory) {
        (uint256 index, bool found) = indexOfValue(array, value);
        require(found, "A0");

        address[] memory result = new address[](array.length - 1);
        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }

        for (uint256 i = index + 1; i < array.length; i++) {
            result[index] = array[i];
            index = i;
        }

        return result;
    }

    /**
     * @dev remove the first specified element, and keep order of other elements.
     *
     * @param array    The input array to search.
     * @param item     The element to remove.
     */
    function removeItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOfItem(array, item);
        require(found, "A1");

        for (uint256 right = index + 1; right < array.length; right++) {
            array[index] = array[right];
            index = right;
        }

        array.pop();
    }

    /**
     * @dev Remove the first specified element from array, not keep order of other elements.
     *
     * @param array    The input array to search.
     * @param item     The element to remove.
     */
    function quickRemoveItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOfItem(array, item);
        require(found, "A2");

        array[index] = array[array.length - 1]; // to save gas we not check index == array.length - 1
        array.pop();
    }

    /**
     * @dev Combine two arrays.
     *
     * @param array1        The first input array.
     * @param array2        The second input array.
     *
     * @return address[]    The new array which is array1 + array2
     */
    function merge(address[] memory array1, address[] memory array2) internal pure returns (address[] memory) {
        address[] memory result = new address[](array1.length + array2.length);
        for (uint256 i = 0; i < array1.length; i++) {
            result[i] = array1[i];
        }

        uint256 index = array1.length;
        for (uint256 j = 0; j < array2.length; j++) {
            result[index++] = array2[j];
        }

        return result;
    }

    /**
     * @dev Validate that address and uint array lengths match.
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of uint
     */
    function validateArrayPairs(address[] memory array1, uint256[] memory array2) internal pure {
        require(array1.length == array2.length, "A3");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bool array lengths match.
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bool
     */
    function validateArrayPairs(address[] memory array1, bool[] memory array2) internal pure {
        require(array1.length == array2.length, "A4");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and string array lengths match.
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of strings
     */
    function validateArrayPairs(address[] memory array1, string[] memory array2) internal pure {
        require(array1.length == array2.length, "A5");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address array lengths match, and calling address array are not empty
     * and not contain duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of addresses
     */
    function validateArrayPairs(address[] memory array1, address[] memory array2) internal pure {
        require(array1.length == array2.length, "A6");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bytes
     */
    function validateArrayPairs(address[] memory array1, bytes[] memory array2) internal pure {
        require(array1.length == array2.length, "A7");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate address array is not empty and contains no duplicate elements.
     *
     * @param array    Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory array) internal pure {
        require(array.length > 0, "A8a");
        require(!hasDuplicateValue(array), "A8b");
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IOracle
 * @author Matrix
 *
 * @dev Interface for operating with any external Oracle that returns
 * uint256 or an adapting contract that converts oracle output to uint256.
 */
interface IOracle {
    // ==================== External functions ====================

    /**
     * @return    Current price of asset represented in uint256, typically a preciseUnit where 10^18 = 1.
     */
    function read() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IMatrixValuer } from "../interfaces/IMatrixValuer.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title Position
 * @author Matrix
 */
interface IController {
    // ==================== Events ====================

    event AddFactory(address indexed factory);
    event RemoveFactory(address indexed factory);
    event AddFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFeeRecipient(address newFeeRecipient);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event AddResource(address indexed resource, uint256 id);
    event RemoveResource(address indexed resource, uint256 id);
    event AddMatrix(address indexed matrixToken, address indexed factory);
    event RemoveMatrix(address indexed matrixToken);

    // ==================== External functions ====================

    function isMatrix(address matrixToken) external view returns (bool);

    function isFactory(address addr) external view returns (bool);

    function isModule(address addr) external view returns (bool);

    function isResource(address addr) external view returns (bool);

    function isSystemContract(address contractAddress) external view returns (bool);

    function getFeeRecipient() external view returns (address);

    function getModuleFee(address module, uint256 feeType) external view returns (uint256);

    function getFactories() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getResources() external view returns (address[] memory);

    function getResource(uint256 id) external view returns (address);

    function getMatrixs() external view returns (address[] memory);

    function getIntegrationRegistry() external view returns (IIntegrationRegistry);

    function getPriceOracle() external view returns (IPriceOracle);

    function getMatrixValuer() external view returns (IMatrixValuer);

    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external;

    function addMatrix(address matrixToken) external;

    function removeMatrix(address matrixToken) external;

    function addFactory(address factory) external;

    function removeFactory(address factory) external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function addResource(address resource, uint256 id) external;

    function removeResource(uint256 id) external;

    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFeeRecipient(address newFeeRecipient) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IPriceOracle
 * @author Matrix
 *
 * @dev Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    // ==================== External functions ====================

    function getPrice(address asset1, address asset2) external view returns (uint256);

    function getMasterQuoteAsset() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IOracleAdapter
 * @author Matrix
 *
 * @dev Interface for calling an oracle adapter.
 */
interface IOracleAdapter {
    // ==================== External functions ====================

    /**
     * @param asset1     First asset in pair
     * @param asset2     Second asset in pair
     *
     * @return bool      Boolean indicating if oracle exists
     * @return uint256   Current price of asset represented in uint256
     */
    function getPrice(address asset1, address asset2) external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IMatrixToken } from "../interfaces/IMatrixToken.sol";

/**
 * @title IMatrixValuer
 * @author Matrix
 */
interface IMatrixValuer {
    // ==================== External functions ====================

    function calculateMatrixTokenValuation(IMatrixToken matrixToken, address quoteAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/*
 * @title IIntegrationRegistry
 * @author Matrix
 */
interface IIntegrationRegistry {
    // ==================== Events ====================

    event AddIntegration(address indexed module, address indexed adapter, string integrationName);
    event RemoveIntegration(address indexed module, address indexed adapter, string integrationName);
    event EditIntegration(address indexed module, address newAdapter, string integrationName);

    // ==================== External functions ====================

    function getIntegrationAdapter(address module, string memory id) external view returns (address);

    function getIntegrationAdapterWithHash(address module, bytes32 id) external view returns (address);

    function isValidIntegration(address module, string memory id) external view returns (bool);

    function addIntegration(address module, string memory id, address wrapper) external; // prettier-ignore

    function batchAddIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function editIntegration(address module, string memory name, address adapter) external; // prettier-ignore

    function batchEditIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function removeIntegration(address module, string memory name) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMatrixToken
 * @author Matrix
 *
 * @dev Interface for operating with MatrixToken.
 */
interface IMatrixToken is IERC20 {
    // ==================== Enums ====================

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    // ==================== Structs ====================

    /**
     * @dev The base definition of a MatrixToken Position.
     *
     * @param unit             Each unit is the # of components per 10^18 of a MatrixToken
     * @param module           If not in default state, the address of associated module
     * @param component        Address of token in the Position
     * @param positionState    Position ENUM. Default is 0; External is 1
     * @param data             Arbitrary data
     */
    struct Position {
        int256 unit;
        address module;
        address component;
        uint8 positionState;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's external position details including virtual unit and any auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency updating all units at once
                                            via the positionMultiplier. Virtual units are achieved by dividing a "real" value by the "positionMultiplier"
     * @param externalPositionModules   External modules attached to each external position. Each module maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getManager() external view returns (address);

    function getLocker() external view returns (address);

    function getComponents() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getModuleState(address module) external view returns (ModuleState);

    function getPositionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(address component) external view returns (int256);

    function getDefaultPositionRealUnit(address component) external view returns (int256);

    function getExternalPositionRealUnit(address component, address positionModule) external view returns (int256);

    function getExternalPositionModules(address component) external view returns (address[] memory);

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory);

    function isExternalPositionModule(address component, address module) external view returns (bool);

    function isComponent(address component) external view returns (bool);

    function isInitializedModule(address module) external view returns (bool);

    function isPendingModule(address module) external view returns (bool);

    function isLocked() external view returns (bool);

    function setManager(address manager) external;

    function addComponent(address component) external;

    function removeComponent(address component) external;

    function editDefaultPositionUnit(address component, int256 realUnit) external;

    function addExternalPositionModule(address component, address positionModule) external;

    function removeExternalPositionModule(address component, address positionModule) external;

    function editExternalPositionUnit(address component, address positionModule, int256 realUnit) external; // prettier-ignore

    function editExternalPositionData(address component, address positionModule, bytes calldata data) external; // prettier-ignore

    function invoke(address target, uint256 value, bytes calldata data) external returns (bytes memory); // prettier-ignore

    function invokeSafeApprove(address token, address spender, uint256 amount) external; // prettier-ignore

    function invokeSafeTransfer(address token, address to, uint256 amount) external; // prettier-ignore

    function invokeExactSafeTransfer(address token, address to, uint256 amount) external; // prettier-ignore

    function invokeWrapWETH(address weth, uint256 amount) external;

    function invokeUnwrapWETH(address weth, uint256 amount) external;

    function editPositionMultiplier(int256 newMultiplier) external;

    function mint(address account, uint256 quantity) external;

    function burn(address account, uint256 quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function initializeModule() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}