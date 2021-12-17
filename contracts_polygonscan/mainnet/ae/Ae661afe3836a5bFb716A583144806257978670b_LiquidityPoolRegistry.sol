// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/ILiquidityPoolRegistry.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/IAssetParameters.sol";

import "./LiquidityPoolFactory.sol";
import "./AssetParameters.sol";

contract LiquidityPoolRegistry is ILiquidityPoolRegistry, OwnableUpgradeable, AbstractDependant {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Math for uint256;

    LiquidityPoolFactory private liquidityPoolFactory;
    IRewardsDistribution private rewardsDistribution;
    IAssetParameters private assetParameters;
    IPriceManager private priceManager;

    EnumerableSet.Bytes32Set private _supportedAssets;

    bytes32 public constant GOVERNANCE_TOKEN_KEY = bytes32("NDG");

    mapping(bytes32 => address) public override liquidityPools;
    mapping(address => bool) public override existingLiquidityPools;

    function liquidityPoolRegistryInitialize() external initializer {
        __Ownable_init();
    }

    function setDependencies(Registry _registry) external override onlyInjectorOrZero {
        liquidityPoolFactory = LiquidityPoolFactory(_registry.getLiquidityPoolFactoryContract());
        assetParameters = IAssetParameters(_registry.getAssetParametersContract());
        priceManager = IPriceManager(_registry.getPriceManagerContract());
        rewardsDistribution = IRewardsDistribution(_registry.getRewardsDistributionContract());
    }

    function onlyExistingPool(bytes32 _assetKey) public view override returns (bool) {
        return liquidityPools[_assetKey] != address(0);
    }

    function getAllSupportedAssets() public view override returns (bytes32[] memory _resultArr) {
        uint256 _assetsCount = _supportedAssets.length();

        _resultArr = new bytes32[](_assetsCount);

        _resultArr = getSupportedAssets(0, _assetsCount);
    }

    function getAllLiquidityPools() external view override returns (address[] memory _resultArr) {
        uint256 _assetsCount = _supportedAssets.length();

        _resultArr = new address[](_assetsCount);

        _resultArr = getLiquidityPools(0, _assetsCount);
    }

    function getSupportedAssets(uint256 _offset, uint256 _limit)
        public
        view
        override
        returns (bytes32[] memory _resultArr)
    {
        uint256 _to = (_offset + _limit).min(_supportedAssets.length()).max(_offset);

        _resultArr = new bytes32[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            _resultArr[i] = _supportedAssets.at(i);
        }
    }

    function getAllowForIntegrationAssets()
        external
        view
        override
        returns (bytes32[] memory _resultArr, uint256 _assetsCount)
    {
        IAssetParameters _parameters = assetParameters;
        uint256 _allAssetsCount = _supportedAssets.length();

        _resultArr = new bytes32[](_allAssetsCount);

        uint256 _currentIndex;

        for (uint256 i = 0; i < _allAssetsCount; i++) {
            bytes32 _currentAssetKey = _supportedAssets.at(i);

            if (_parameters.isAllowForIntegration(_currentAssetKey)) {
                _resultArr[_currentIndex++] = _currentAssetKey;
            }
        }

        if (_currentIndex > 0) {
            _assetsCount = _currentIndex;
        }
    }

    function getLiquidityPools(uint256 _offset, uint256 _limit)
        public
        view
        override
        returns (address[] memory _resultArr)
    {
        bytes32[] memory _assetKeys = getSupportedAssets(_offset, _limit);

        _resultArr = new address[](_assetKeys.length);

        for (uint256 i = 0; i < _assetKeys.length; i++) {
            _resultArr[i] = liquidityPools[_assetKeys[i]];
        }
    }

    function getGovernanceLiquidityPool() external view override returns (address) {
        return liquidityPools[GOVERNANCE_TOKEN_KEY];
    }

    function getTotalMarketsSize() external view override returns (uint256 _totalMarketsSize) {
        bytes32[] memory _assetsKeys = getAllSupportedAssets();

        for (uint256 i = 0; i < _assetsKeys.length; i++) {
            ILiquidityPool _liquidityPool = ILiquidityPool(liquidityPools[_assetsKeys[i]]);
            _totalMarketsSize += _liquidityPool.getAmountInUSD(_liquidityPool.getTotalLiquidity());
        }
    }

    function getLiquidityPoolsInfo(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (LiquidityPoolInfo[] memory _resultArr)
    {
        IRewardsDistribution _rewardsDistributon = rewardsDistribution;

        bytes32[] memory _assetsKeys = getSupportedAssets(_offset, _limit);
        _resultArr = new LiquidityPoolInfo[](_assetsKeys.length);

        for (uint256 i = 0; i < _assetsKeys.length; i++) {
            bytes32 _currentKey = _assetsKeys[i];
            ILiquidityPool _currentLiquidityPool = ILiquidityPool(liquidityPools[_currentKey]);

            uint256 _marketSize = _currentLiquidityPool.getTotalLiquidity();
            uint256 _totalBorrowed = _currentLiquidityPool.getTotalBorrowedAmount();

            (uint256 _distrSupplyAPY, uint256 _distrBorrowAPY) =
                _rewardsDistributon.getAPY(_currentLiquidityPool);

            PoolAPYInfo memory _poolAPYInfo =
                PoolAPYInfo(
                    _currentLiquidityPool.getAPY(),
                    _currentLiquidityPool.getAnnualBorrowRate(),
                    _distrSupplyAPY,
                    _distrBorrowAPY
                );

            _resultArr[i] = LiquidityPoolInfo(
                _currentKey,
                _currentLiquidityPool.assetAddr(),
                _marketSize,
                _currentLiquidityPool.getAmountInUSD(_marketSize),
                _totalBorrowed,
                _currentLiquidityPool.getAmountInUSD(_totalBorrowed),
                _poolAPYInfo
            );
        }
    }

    function getDetailedLiquidityPoolInfo(bytes32 _assetKey)
        external
        view
        override
        returns (DetailedLiquidityPoolInfo memory)
    {
        ILiquidityPool _currentLiquidityPool = ILiquidityPool(liquidityPools[_assetKey]);
        IAssetParameters _parameters = assetParameters;

        uint256 _totalBorrowed = _currentLiquidityPool.getTotalBorrowedAmount();

        (uint256 _distrSupplyAPY, uint256 _distrBorrowAPY) =
            rewardsDistribution.getAPY(_currentLiquidityPool);

        IAssetParameters.LiquidityPoolParams memory _liquidityPoolParams =
            _parameters.getLiquidityPoolParams(_assetKey);

        PoolAPYInfo memory _poolAPYInfo =
            PoolAPYInfo(
                _currentLiquidityPool.getAPY(),
                _currentLiquidityPool.getAnnualBorrowRate(),
                _distrSupplyAPY,
                _distrBorrowAPY
            );

        return
            DetailedLiquidityPoolInfo(
                _currentLiquidityPool.getAmountInUSD(_totalBorrowed),
                _currentLiquidityPool.getAmountInUSD(
                    _currentLiquidityPool.getAvailableToBorrowLiquidity()
                ),
                _currentLiquidityPool.getBorrowPercentage(),
                _liquidityPoolParams,
                _poolAPYInfo
            );
    }

    function addLiquidityPool(
        address _assetAddr,
        bytes32 _assetKey,
        address _mainOracle,
        address _backupOracle,
        string calldata _tokenSymbol,
        bool _isCollateral
    ) external onlyOwner {
        require(_assetKey > 0, "LiquidityPoolRegistry: Unable to add an asset without a key.");
        require(
            _assetAddr != address(0),
            "LiquidityPoolRegistry: Unable to add an asset with a zero address."
        );
        require(
            !onlyExistingPool(_assetKey),
            "LiquidityPoolRegistry: Liquidity pool with such a key already exists."
        );

        address _poolAddr =
            liquidityPoolFactory.newLiquidityPool(_assetAddr, _assetKey, _tokenSymbol);

        liquidityPools[_assetKey] = _poolAddr;

        _supportedAssets.add(_assetKey);

        assetParameters.addLiquidityPoolAssetInfo(_assetKey, _isCollateral);

        existingLiquidityPools[_poolAddr] = true;

        priceManager.addOracle(_assetKey, _assetAddr, _mainOracle, _backupOracle);

        emit PoolAdded(_assetKey, _assetAddr, _poolAddr);
    }

    function withdrawReservedFunds(
        address _recipientAddr,
        bytes32 _assetKey,
        uint256 _amountToWithdraw,
        bool _isAllFunds
    ) external onlyOwner {
        require(onlyExistingPool(_assetKey), "LiquidityPoolRegistry: Pool doesn't exist.");

        if (!_isAllFunds) {
            require(
                _amountToWithdraw > 0,
                "LiquidityPoolRegistry: Amount to withdraw must be greater than zero."
            );
        }

        ILiquidityPool(liquidityPools[_assetKey]).withdrawReservedFunds(
            _recipientAddr,
            _amountToWithdraw,
            _isAllFunds
        );
    }

    function withdrawAllReservedFunds(
        address _recipientAddr,
        uint256 _offset,
        uint256 _limit
    ) external onlyOwner {
        bytes32[] memory _assetsKeys = getSupportedAssets(_offset, _limit);

        for (uint256 i = 0; i < _assetsKeys.length; i++) {
            ILiquidityPool(liquidityPools[_assetsKeys[i]]).withdrawReservedFunds(
                _recipientAddr,
                0,
                true
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

library PureParameters {
    enum Types {NOT_EXIST, UINT, ADDRESS, BYTES32, BOOL}

    struct Param {
        uint256 uintParam;
        address addressParam;
        bytes32 bytes32Param;
        bool boolParam;
        Types currentType;
    }

    function makeUintParam(uint256 _num) internal pure returns (Param memory) {
        return
            Param({
                uintParam: _num,
                currentType: Types.UINT,
                addressParam: address(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getUintFromParam(Param memory _param) internal pure returns (uint256) {
        require(_param.currentType == Types.UINT, "PureParameters: Parameter not contain uint.");

        return _param.uintParam;
    }

    function makeAdrressParam(address _address) internal pure returns (Param memory) {
        return
            Param({
                addressParam: _address,
                currentType: Types.ADDRESS,
                uintParam: uint256(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getAdrressFromParam(Param memory _param) internal pure returns (address) {
        require(
            _param.currentType == Types.ADDRESS,
            "PureParameters: Parameter not contain address."
        );

        return _param.addressParam;
    }

    function makeBytes32Param(bytes32 _hash) internal pure returns (Param memory) {
        return
            Param({
                bytes32Param: _hash,
                currentType: Types.BYTES32,
                addressParam: address(0),
                uintParam: uint256(0),
                boolParam: false
            });
    }

    function getBytes32FromParam(Param memory _param) internal pure returns (bytes32) {
        require(
            _param.currentType == Types.BYTES32,
            "PureParameters: Parameter not contain bytes32."
        );

        return _param.bytes32Param;
    }

    function makeBoolParam(bool _bool) internal pure returns (Param memory) {
        return
            Param({
                boolParam: _bool,
                currentType: Types.BOOL,
                addressParam: address(0),
                uintParam: uint256(0),
                bytes32Param: bytes32(0)
            });
    }

    function getBoolFromParam(Param memory _param) internal pure returns (bool) {
        require(_param.currentType == Types.BOOL, "PureParameters: Parameter not contain bool.");

        return _param.boolParam;
    }

    function paramExists(Param memory _param) internal pure returns (bool) {
        return (_param.currentType != Types.NOT_EXIST);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "./ILiquidityPool.sol";

interface IRewardsDistribution {
    struct LiquidityPoolInfo {
        uint256 rewardPerBlock;
        uint256 supplyCumulativeSum;
        uint256 borrowCumulativeSum;
        uint256 lastUpdate;
    }

    struct UserDistributionInfo {
        uint256 lastSupplyCumulativeSum;
        uint256 lastBorrowCumulativeSum;
        uint256 aggregatedReward;
    }

    /**
     * @notice Returns APY for a specific liquidity pool
     * @param _liquidityPool Required liquidity pool
     * @return _supplyAPY - current supply APY
     * @return _borrowAPY - current borrow APY
     */
    function getAPY(ILiquidityPool _liquidityPool)
        external
        view
        returns (uint256 _supplyAPY, uint256 _borrowAPY);

    /**
     * @notice Returns current user reward of Governance Tokens
     * @param _assetKey Asset key of the liquidity pool
     * @param _userAddr Address of the user
     * @param _liquidityPool Required liquidity pool
     * @return _userReward - current user reward
     */
    function getUserReward(
        bytes32 _assetKey,
        address _userAddr,
        ILiquidityPool _liquidityPool
    ) external view returns (uint256 _userReward);

    /**
     * @notice Function for updating cumulative sums. Can only be called from DefiCore
     * @param _userAddr Address of the user
     * @param _liquidityPool Required liquidity pool
     */
    function updateCumulativeSums(address _userAddr, ILiquidityPool _liquidityPool) external;

    /**
     * @notice Function for withdraw accumulated rewards. Can only be called from DefiCore
     * @dev Cumulative sums are updated before withdrawal
     * @param _assetKey Asset key of the liquidity pool
     * @param _userAddr Address of the user
     * @param _liquidityPool Required liquidity pool
     * @return _userReward - current user reward
     */
    function withdrawUserReward(
        bytes32 _assetKey,
        address _userAddr,
        ILiquidityPool _liquidityPool
    ) external returns (uint256 _userReward);

    /**
     * @notice Function to update rewards per block
     * @dev The passed arrays must be of the same length
     * @param _assetKeys Arrays of asset keys
     * @param _rewardsPerBlock Arrays of new rewards per block
     */
    function setupRewardsPerBlockBatch(
        bytes32[] calldata _assetKeys,
        uint256[] calldata _rewardsPerBlock
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IPriceManager {
    function addOracle(
        bytes32 _assetKey,
        address _assetAddr,
        address _newMainOracle,
        address _newBackupOracle
    ) external;

    function updatePrice(bytes32 _assetKey) external;

    function getPrice(bytes32 _assetKey, uint8 _assetDecimals)
        external
        view
        returns (uint256, uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "./IAssetParameters.sol";

interface ILiquidityPoolRegistry {
    event PoolAdded(bytes32 _assetKey, address _assetAddr, address _poolAddr);

    struct PoolAPYInfo {
        uint256 supplyAPY;
        uint256 borrowAPY;
        uint256 distrSupplyAPY;
        uint256 distrBorrowAPY;
    }

    struct LiquidityPoolInfo {
        bytes32 assetKey;
        address assetAddr;
        uint256 marketSize;
        uint256 marketSizeInUsd;
        uint256 totalBorrowBalance;
        uint256 totalBorrowBalanceInUsd;
        PoolAPYInfo apyInfo;
    }

    struct DetailedLiquidityPoolInfo {
        uint256 totalBorrowed;
        uint256 availableLiquidity;
        uint256 utilizationRatio;
        IAssetParameters.LiquidityPoolParams liquidityPoolParams;
        PoolAPYInfo apyInfo;
    }

    function getAllSupportedAssets() external view returns (bytes32[] memory _resultArr);

    function getAllLiquidityPools() external view returns (address[] memory _resultArr);

    function getSupportedAssets(uint256 _offset, uint256 _limit)
        external
        view
        returns (bytes32[] memory _resultArr);

    /**
     * @notice Returns the keys of all assets that allow for integration
     * @return _resultArr - keys array
     * @return _assetsCount - number of allow for integration assets
     */
    function getAllowForIntegrationAssets()
        external
        view
        returns (bytes32[] memory _resultArr, uint256 _assetsCount);

    function getLiquidityPools(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory _resultArr);

    /**
     * @notice Returns the address of the liquidity pool by the asset key
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return address of the liquidity pool
     */
    function liquidityPools(bytes32 _assetKey) external view returns (address);

    /**
     * @notice Indicates whether the address is a liquidity pool
     * @param _poolAddr Address of the liquidity pool
     * @return true if the passed address is a liquidity pool, false otherwise
     */
    function existingLiquidityPools(address _poolAddr) external view returns (bool);

    function onlyExistingPool(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Returns the address of the liquidity pool for the governance token
     * @return liquidity pool address for the governance token
     */
    function getGovernanceLiquidityPool() external view returns (address);

    function getTotalMarketsSize() external view returns (uint256 _totalMarketSize);

    function getLiquidityPoolsInfo(uint256 _offset, uint256 _limit)
        external
        view
        returns (LiquidityPoolInfo[] memory _resultArr);

    function getDetailedLiquidityPoolInfo(bytes32 _assetKey)
        external
        view
        returns (DetailedLiquidityPoolInfo memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ILiquidityPoolAdmin {
    function getUpgrader() external view returns (address);

    function getImplementationOfLiquidityPool(address _liquidityPoolAddress)
        external
        returns (address);

    function getCurrentLiquidityPoolsImplementation() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ILiquidityPool {
    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 normalizedAmount;
    }

    struct RepayBorrowVars {
        uint256 repayAmount;
        uint256 currentAbsoluteAmount;
        uint256 normalizedAmount;
        uint256 currentRate;
        address userAddr;
    }

    function liquidityPoolInitialize(
        address _assetAddr,
        bytes32 _assetKey,
        string memory _tokenSymbol
    ) external;

    function assetAddr() external view returns (address);

    function assetKey() external view returns (bytes32);

    function borrowInfos(address _userAddr)
        external
        view
        returns (uint256 _borrowAmount, uint256 _normalizedAmount);

    function integrationBorrowInfos(address _userAddr)
        external
        view
        returns (uint256 _borrowAmount, uint256 _normalizedAmount);

    function aggregatedBorrowedAmount() external view returns (uint256);

    function getTotalLiquidity() external view returns (uint256);

    function getTotalBorrowedAmount() external view returns (uint256);

    function getAggregatedLiquidityAmount() external view returns (uint256);

    function getCurrentLiquidityAmount(address _userAddr) external view returns (uint256);

    function getUserBorrowedAmount(address _userAddr, bool _isIntegration)
        external
        view
        returns (uint256);

    function getUserTotalBorrowedAmount(address _userAddr) external view returns (uint256);

    function getBorrowPercentage() external view returns (uint256);

    function getMaxToSupply(address _userAddr) external view returns (uint256);

    function getMaxToWithdraw(address _userAddr) external view returns (uint256 _maxToWithdraw);

    function getMaxToBorrow(address _userAddr, bool _isIntegration)
        external
        view
        returns (uint256);

    function getMaxToRepay(address _userAddr, bool _isIntegration) external view returns (uint256);

    function getAvailableToBorrowLiquidity() external view returns (uint256);

    function getAnnualBorrowRate() external view returns (uint256 _annualBorrowRate);

    function getAPY() external view returns (uint256);

    function convertAssetToNTokens(uint256 _assetAmount) external view returns (uint256);

    function convertNTokensToAsset(uint256 _nTokensAmount) external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function getAmountInUSD(uint256 _assetAmount) external view returns (uint256);

    function getAmountFromUSD(uint256 _usdAmount) external view returns (uint256);

    function getAssetPrice() external view returns (uint256);

    function getFreezeStatus() external view returns (bool);

    function getUnderlyingDecimals() external view returns (uint8);

    function getCurrentRate() external view returns (uint256);

    function getNewCompoundRate() external view returns (uint256);

    function updateCompoundRate() external returns (uint256);

    function addLiquidity(address _userAddr, uint256 _liquidityAmount) external;

    function withdrawLiquidityMax(address _userAddr) external;

    function withdrawLiquidity(address _userAddr, uint256 _liquidityAmount) external;

    function approveToBorrow(
        address _userAddr,
        uint256 _borrowAmount,
        address _borrowalAddr,
        uint256 _expectedAllowance
    ) external;

    function borrowFor(
        address _userAddr,
        address _delegator,
        uint256 _amountToBorrow
    ) external;

    function repayBorrowFor(
        address _userAddr,
        address _closureAddr,
        uint256 _repayAmount,
        bool _isMaxRepay
    ) external returns (uint256);

    function repayBorrowIntegration(
        address _userAddr,
        address _vaultTokenAddr,
        address _borrowerRouterAddr,
        uint256 _repayAmount,
        bool _isMaxRepay
    ) external returns (uint256);

    function delegateBorrow(
        address _userAddr,
        address _delegator,
        uint256 _amountToBorrow
    ) external;

    function liquidate(
        address _userAddr,
        address _liquidatorAddr,
        uint256 _liquidityAmount
    ) external;

    function withdrawReservedFunds(
        address _recipientAddr,
        uint256 _amountToWithdraw,
        bool _isAllFunds
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IAssetParameters {
    event UintParamUpdated(bytes32 _assetKey, bytes32 _paramKey, uint256 _newValue);
    event BoolParamUpdated(bytes32 _assetKey, bytes32 _paramKey, bool _newValue);

    struct InterestRateParams {
        uint256 basePercentage;
        uint256 firstSlope;
        uint256 secondSlope;
        uint256 utilizationBreakingPoint;
    }

    struct LiquidityPoolParams {
        uint256 collateralizationRatio;
        uint256 reserveFactor;
        uint256 liquidationDiscount;
        uint256 maxUtilizationRatio;
        bool isAvailableAsCollateral;
    }

    /**
     * @notice Shows whether the pool is frozen by the given key
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return true if the liquidation pool is frozen, false otherwise
     */
    function isPoolFrozen(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Shows the ability of an aset to be a collateral
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return true if the liquidation pool is frozen, false otherwise
     */
    function isAvailableAsCollateral(bytes32 _assetKey) external view returns (bool);

    function isAllowForIntegration(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Returns parameters for calculating interest rates on a loan
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return _params - structure object with parameters for calculating interest rates
     */
    function getInterestRateParams(bytes32 _assetKey)
        external
        view
        returns (InterestRateParams memory _params);

    /**
     * @notice Returns the maximum possible utilization ratio
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return maximum possible utilization ratio
     */
    function getMaxUtilizationRatio(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the discount for the liquidator in the desired pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return liquidation discount
     */
    function getLiquidationDiscount(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the minimum percentages of the parties for the distribution of governance tokens
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return _minSupplyPart the minimum part that goes to depositors
     * @return _minBorrowPart the minimum part that goes to borrowers
     */
    function getDistributionMinimums(bytes32 _assetKey)
        external
        view
        returns (uint256 _minSupplyPart, uint256 _minBorrowPart);

    /**
     * @notice Returns the collateralization ratio for the required pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return current collateralization ratio value
     */
    function getColRatio(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the integration collateralization ratio for the required pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return current integration collateralization ratio value
     */
    function getIntegrationColRatio(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the collateralization ratio for the required pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return current reserve factor value
     */
    function getReserveFactor(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the price of a token in dollars
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return asset price
     */
    function getAssetPrice(bytes32 _assetKey, uint8 _assetDecimals)
        external
        view
        returns (uint256);

    function getLiquidityPoolParams(bytes32 _assetKey)
        external
        view
        returns (LiquidityPoolParams memory);

    function addLiquidityPoolAssetInfo(bytes32 _assetKey, bool _isCollateral) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Upgrader {
    address private immutable _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "DependencyInjector: Not an owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function upgrade(address what, address to) external onlyOwner {
        TransparentUpgradeableProxy(payable(what)).upgradeTo(to);
    }

    function upgradeAndCall(
        address what,
        address to,
        bytes calldata data
    ) external onlyOwner {
        TransparentUpgradeableProxy(payable(what)).upgradeToAndCall(to, data);
    }

    function getImplementation(address what) external view onlyOwner returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(what).staticcall(hex"5c60da1b");
        require(success, "Upgader: Failed to get implementation.");

        return abi.decode(returndata, (address));
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint8 constant STANDARD_DECIMALS = 18;
uint256 constant ONE_TOKEN = 10**STANDARD_DECIMALS;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint8 constant PRICE_DECIMALS = 8;

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "../Registry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(Registry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./common/Upgrader.sol";
import "./common/AbstractDependant.sol";

contract Registry is AccessControl {
    Upgrader private immutable upgrader;

    mapping(bytes32 => address) private _contracts;
    mapping(address => bool) private _isProxy;

    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    bytes32 public constant SYSTEM_PARAMETERS_NAME = keccak256("SYSTEM_PARAMETERS");
    bytes32 public constant ASSET_PARAMETERS_NAME = keccak256("ASSET_PARAMETERS");
    bytes32 public constant DEFI_CORE_NAME = keccak256("DEFI_CORE");
    bytes32 public constant INTEREST_RATE_LIBRARY_NAME = keccak256("INTEREST_RATE_LIBRARY");
    bytes32 public constant LIQUIDITY_POOL_FACTORY_NAME = keccak256("LIQUIDITY_POOL_FACTORY");
    bytes32 public constant GOVERNANCE_TOKEN_NAME = keccak256("GOVERNANCE_TOKEN");
    bytes32 public constant REWARDS_DISTRIBUTION_NAME = keccak256("REWARDS_DISTRIBUTION");
    bytes32 public constant PRICE_MANAGER_NAME = keccak256("PRICE_MANAGER");
    bytes32 public constant ASSETS_REGISTRY_NAME = keccak256("ASSETS_REGISTRY");
    bytes32 public constant LIQUIDITY_POOL_REGISTRY_NAME = keccak256("LIQUIDITY_POOL_REGISTRY");
    bytes32 public constant LIQUIDITY_POOL_ADMIN_NAME = keccak256("LIQUIDITY_POOL_ADMIN");
    bytes32 public constant INTEGRATION_CORE_NAME = keccak256("INTEGRATION_CORE");

    bytes32 public constant BORROWER_ROUTER_FACTORY_NAME = keccak256("BORROWER_ROUTER_FACTORY");
    bytes32 public constant BORROWER_ROUTER_REGISTRY_NAME = keccak256("BORROWER_ROUTER_REGISTRY");

    event ContractAdded(bytes32 _name, address _contractAddress);
    event ProxyContractAdded(bytes32 _name, address _proxyAddress, address _implAddress);

    modifier onlyAdmin() {
        require(hasRole(REGISTRY_ADMIN_ROLE, msg.sender), "Registry: Caller is not an admin");
        _;
    }

    constructor() {
        _setupRole(REGISTRY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);

        upgrader = new Upgrader();
    }

    function getSystemParametersContract() external view returns (address) {
        return getContract(SYSTEM_PARAMETERS_NAME);
    }

    function getAssetParametersContract() external view returns (address) {
        return getContract(ASSET_PARAMETERS_NAME);
    }

    function getDefiCoreContract() external view returns (address) {
        return getContract(DEFI_CORE_NAME);
    }

    function getInterestRateLibraryContract() external view returns (address) {
        return getContract(INTEREST_RATE_LIBRARY_NAME);
    }

    function getLiquidityPoolFactoryContract() external view returns (address) {
        return getContract(LIQUIDITY_POOL_FACTORY_NAME);
    }

    function getGovernanceTokenContract() external view returns (address) {
        return getContract(GOVERNANCE_TOKEN_NAME);
    }

    function getRewardsDistributionContract() external view returns (address) {
        return getContract(REWARDS_DISTRIBUTION_NAME);
    }

    function getPriceManagerContract() external view returns (address) {
        return getContract(PRICE_MANAGER_NAME);
    }

    function getAssetsRegistryContract() external view returns (address) {
        return getContract(ASSETS_REGISTRY_NAME);
    }

    function getLiquidityPoolAdminContract() external view returns (address) {
        return getContract(LIQUIDITY_POOL_ADMIN_NAME);
    }

    function getIntegrationCoreContract() external view returns (address) {
        return getContract(INTEGRATION_CORE_NAME);
    }

    function getBorrowerRouterFactoryContract() external view returns (address) {
        return getContract(BORROWER_ROUTER_FACTORY_NAME);
    }

    function getBorrowerRouterRegistryContract() external view returns (address) {
        return getContract(BORROWER_ROUTER_REGISTRY_NAME);
    }

    function getLiquidityPoolRegistryContract() external view returns (address) {
        return getContract(LIQUIDITY_POOL_REGISTRY_NAME);
    }

    function getContract(bytes32 _name) public view returns (address) {
        require(_contracts[_name] != address(0), "Registry: This mapping doesn't exist");

        return _contracts[_name];
    }

    function hasContract(bytes32 _name) external view returns (bool) {
        return _contracts[_name] != address(0);
    }

    function getUpgrader() external view returns (address) {
        require(address(upgrader) != address(0), "Registry: Bad upgrader.");

        return address(upgrader);
    }

    function getImplementation(bytes32 _name) external view returns (address) {
        address _contractProxy = _contracts[_name];

        require(_contractProxy != address(0), "Registry: This mapping doesn't exist.");
        require(_isProxy[_contractProxy], "Registry: Not a proxy contract.");

        return upgrader.getImplementation(_contractProxy);
    }

    function injectDependencies(bytes32 _name) external onlyAdmin {
        address contractAddress = _contracts[_name];

        require(contractAddress != address(0), "Registry: This mapping doesn't exist.");

        AbstractDependant dependant = AbstractDependant(contractAddress);

        if (dependant.injector() == address(0)) {
            dependant.setInjector(address(this));
        }

        dependant.setDependencies(this);
    }

    function upgradeContract(bytes32 _name, address _newImplementation) external onlyAdmin {
        _upgradeContract(_name, _newImplementation, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradeContractAndCall(
        bytes32 _name,
        address _newImplementation,
        string calldata _functionSignature
    ) external onlyAdmin {
        _upgradeContract(_name, _newImplementation, _functionSignature);
    }

    function _upgradeContract(
        bytes32 _name,
        address _newImplementation,
        string memory _functionSignature
    ) internal {
        address _contractToUpgrade = _contracts[_name];

        require(_contractToUpgrade != address(0), "Registry: This mapping doesn't exist.");
        require(_isProxy[_contractToUpgrade], "Registry: Not a proxy contract.");

        if (bytes(_functionSignature).length > 0) {
            upgrader.upgradeAndCall(
                _contractToUpgrade,
                _newImplementation,
                abi.encodeWithSignature(_functionSignature)
            );
        } else {
            upgrader.upgrade(_contractToUpgrade, _newImplementation);
        }
    }

    function addContract(bytes32 _name, address _contractAddress) external onlyAdmin {
        require(_contractAddress != address(0), "Registry: Null address is forbidden.");
        require(_contracts[_name] == address(0), "Registry: Unable to change the contract.");

        _contracts[_name] = _contractAddress;

        emit ContractAdded(_name, _contractAddress);
    }

    function addProxyContract(bytes32 _name, address _contractAddress) external onlyAdmin {
        require(_contractAddress != address(0), "Registry: Null address is forbidden.");
        require(_contracts[_name] == address(0), "Registry: Unable to change the contract.");

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(_contractAddress, address(upgrader), "");

        _contracts[_name] = address(proxy);
        _isProxy[address(proxy)] = true;

        emit ProxyContractAdded(_name, address(proxy), _contractAddress);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./interfaces/ILiquidityPoolAdmin.sol";
import "./interfaces/ILiquidityPool.sol";

import "./Registry.sol";
import "./common/AbstractDependant.sol";

contract LiquidityPoolFactory is AbstractDependant {
    Registry private registry;
    ILiquidityPoolAdmin private liquidityPoolAdmin;
    address private liquidityPoolRegistry;

    function setDependencies(Registry _registry) external override onlyInjectorOrZero {
        registry = _registry;
        liquidityPoolAdmin = ILiquidityPoolAdmin(_registry.getLiquidityPoolAdminContract());
        liquidityPoolRegistry = registry.getLiquidityPoolRegistryContract();
    }

    modifier onlyLiquidityPoolRegistry() {
        require(
            liquidityPoolRegistry == msg.sender,
            "LiquidityPoolFactory: Caller not an AssetParameters."
        );
        _;
    }

    function newLiquidityPool(
        address _assetAddr,
        bytes32 _assetKey,
        string calldata _tokenSymbol
    ) external onlyLiquidityPoolRegistry returns (address) {
        ILiquidityPoolAdmin _liquidityPoolAdmin = liquidityPoolAdmin;

        TransparentUpgradeableProxy _proxy =
            new TransparentUpgradeableProxy(
                _liquidityPoolAdmin.getCurrentLiquidityPoolsImplementation(),
                _liquidityPoolAdmin.getUpgrader(),
                ""
            );

        ILiquidityPool(address(_proxy)).liquidityPoolInitialize(
            _assetAddr,
            _assetKey,
            _tokenSymbol
        );

        AbstractDependant(address(_proxy)).setDependencies(registry);
        AbstractDependant(address(_proxy)).setInjector(address(_liquidityPoolAdmin));

        return address(_proxy);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ILiquidityPoolRegistry.sol";
import "./interfaces/IAssetParameters.sol";
import "./interfaces/IPriceManager.sol";

import "./libraries/PureParameters.sol";
import "./libraries/DecimalsConverter.sol";

import "./common/Globals.sol";
import "./common/AbstractDependant.sol";

contract AssetParameters is IAssetParameters, OwnableUpgradeable, AbstractDependant {
    using PureParameters for PureParameters.Param;
    using MathUpgradeable for uint256;
    using DecimalsConverter for uint256;

    ILiquidityPoolRegistry private liquidityPoolRegistry;
    IPriceManager private priceManager;

    bytes32 public constant FREEZE_KEY = keccak256("FREEZE");
    bytes32 public constant ENABLE_COLLATERAL_KEY = keccak256("ENABLE_COLLATERAL");

    bytes32 public constant BASE_PERCENTAGE_KEY = keccak256("BASE_PERCENTAGE");
    bytes32 public constant FIRST_SLOPE_KEY = keccak256("FIRST_SLOPE");
    bytes32 public constant SECOND_SLOPE_KEY = keccak256("SECOND_SLOPE");
    bytes32 public constant UTILIZATION_BREAKING_POINT_KEY =
        keccak256("UTILIZATION_BREAKING_POINT");
    bytes32 public constant MAX_UTILIZATION_RATIO_KEY = keccak256("MAX_UTILIZATION_RATIO");
    bytes32 public constant LIQUIDATION_DISCOUNT_KEY = keccak256("LIQUIDATION_DISCOUNT");

    bytes32 public constant MIN_SUPPLY_DISTRIBUTION_PART_KEY =
        keccak256("MIN_SUPPLY_DISTRIBUTION_PART");
    bytes32 public constant MIN_BORROW_DISTRIBUTION_PART_KEY =
        keccak256("MIN_BORROW_DISTRIBUTION_PART");

    bytes32 public constant COL_RATIO_KEY = keccak256("COL_RATIO");
    bytes32 public constant INTEGRATION_COL_RATIO_KEY = keccak256("INTEGRATION_COL_RATIO");

    bytes32 public constant RESERVE_FACTOR_KEY = keccak256("RESERVE_FACTOR");
    bytes32 public constant ALLOW_FOR_INTEGRATION_KEY = keccak256("ALLOW_FOR_INTEGRATION");

    mapping(bytes32 => mapping(bytes32 => PureParameters.Param)) private _parameters;

    modifier onlyExist(bytes32 _assetKey) {
        require(
            liquidityPoolRegistry.onlyExistingPool(_assetKey),
            "AssetParameters: Asset doesn't exist."
        );
        _;
    }

    modifier onlyLiquidityPoolRegistry() {
        require(
            address(liquidityPoolRegistry) == msg.sender,
            "PriceManager: Caller not an LiquidityPoolRegistry."
        );
        _;
    }

    function assetParametersInitialize() external initializer {
        __Ownable_init();
    }

    function setDependencies(Registry _registry) external override onlyInjectorOrZero {
        liquidityPoolRegistry = ILiquidityPoolRegistry(
            _registry.getLiquidityPoolRegistryContract()
        );
        priceManager = IPriceManager(_registry.getPriceManagerContract());
    }

    function isPoolFrozen(bytes32 _assetKey) external view override returns (bool) {
        return _getParam(_assetKey, FREEZE_KEY).getBoolFromParam();
    }

    function isAvailableAsCollateral(bytes32 _assetKey) external view override returns (bool) {
        return _getParam(_assetKey, ENABLE_COLLATERAL_KEY).getBoolFromParam();
    }

    function isAllowForIntegration(bytes32 _assetKey) external view override returns (bool) {
        return _getParam(_assetKey, ALLOW_FOR_INTEGRATION_KEY).getBoolFromParam();
    }

    function getInterestRateParams(bytes32 _assetKey)
        external
        view
        override
        returns (InterestRateParams memory _params)
    {
        _params = InterestRateParams(
            _getParam(_assetKey, BASE_PERCENTAGE_KEY).getUintFromParam(),
            _getParam(_assetKey, FIRST_SLOPE_KEY).getUintFromParam(),
            _getParam(_assetKey, SECOND_SLOPE_KEY).getUintFromParam(),
            _getParam(_assetKey, UTILIZATION_BREAKING_POINT_KEY).getUintFromParam()
        );
    }

    function getMaxUtilizationRatio(bytes32 _assetKey) external view override returns (uint256) {
        return _getParam(_assetKey, MAX_UTILIZATION_RATIO_KEY).getUintFromParam();
    }

    function getLiquidationDiscount(bytes32 _assetKey) external view override returns (uint256) {
        return _getParam(_assetKey, LIQUIDATION_DISCOUNT_KEY).getUintFromParam();
    }

    function getDistributionMinimums(bytes32 _assetKey)
        external
        view
        override
        returns (uint256 _minSupplyPart, uint256 _minBorrowPart)
    {
        _minSupplyPart = _getParam(_assetKey, MIN_SUPPLY_DISTRIBUTION_PART_KEY).getUintFromParam();
        _minBorrowPart = _getParam(_assetKey, MIN_BORROW_DISTRIBUTION_PART_KEY).getUintFromParam();
    }

    function getColRatio(bytes32 _assetKey) external view override returns (uint256) {
        return _getParam(_assetKey, COL_RATIO_KEY).getUintFromParam();
    }

    function getIntegrationColRatio(bytes32 _assetKey) external view override returns (uint256) {
        return _getParam(_assetKey, INTEGRATION_COL_RATIO_KEY).getUintFromParam();
    }

    function getReserveFactor(bytes32 _assetKey) external view override returns (uint256) {
        return _getParam(_assetKey, RESERVE_FACTOR_KEY).getUintFromParam();
    }

    function getAssetPrice(bytes32 _assetKey, uint8 _assetDecimals)
        external
        view
        override
        returns (uint256)
    {
        (uint256 _price, uint8 _currentPriceDecimals) =
            priceManager.getPrice(_assetKey, _assetDecimals);

        return _price.convert(_currentPriceDecimals, PRICE_DECIMALS);
    }

    function getLiquidityPoolParams(bytes32 _assetKey)
        external
        view
        override
        returns (LiquidityPoolParams memory)
    {
        return
            LiquidityPoolParams(
                _getParam(_assetKey, COL_RATIO_KEY).getUintFromParam(),
                _getParam(_assetKey, RESERVE_FACTOR_KEY).getUintFromParam(),
                _getParam(_assetKey, LIQUIDATION_DISCOUNT_KEY).getUintFromParam(),
                _getParam(_assetKey, MAX_UTILIZATION_RATIO_KEY).getUintFromParam(),
                _getParam(_assetKey, ENABLE_COLLATERAL_KEY).getBoolFromParam()
            );
    }

    function addLiquidityPoolAssetInfo(bytes32 _assetKey, bool _isCollateral)
        external
        override
        onlyLiquidityPoolRegistry
    {
        _parameters[_assetKey][FREEZE_KEY] = PureParameters.makeBoolParam(false);
        emit BoolParamUpdated(_assetKey, FREEZE_KEY, false);

        _parameters[_assetKey][ENABLE_COLLATERAL_KEY] = PureParameters.makeBoolParam(
            _isCollateral
        );
        emit BoolParamUpdated(_assetKey, ENABLE_COLLATERAL_KEY, _isCollateral);
    }

    function freeze(bytes32 _assetKey) external onlyOwner onlyExist(_assetKey) {
        _parameters[_assetKey][FREEZE_KEY] = PureParameters.makeBoolParam(true);

        emit BoolParamUpdated(_assetKey, FREEZE_KEY, true);
    }

    function enableCollateral(bytes32 _assetKey) external onlyOwner onlyExist(_assetKey) {
        _parameters[_assetKey][ENABLE_COLLATERAL_KEY] = PureParameters.makeBoolParam(true);

        emit BoolParamUpdated(_assetKey, ENABLE_COLLATERAL_KEY, true);
    }

    function setupInterestRateModel(
        bytes32 _assetKey,
        uint256 _basePercentage,
        uint256 _firstSlope,
        uint256 _secondSlope,
        uint256 _utilizationBreakingPoint
    ) external onlyOwner onlyExist(_assetKey) {
        require(
            _basePercentage <= ONE_PERCENT * 3,
            "AssetParameters: The new value of the base percentage is invalid."
        );
        require(
            _firstSlope >= ONE_PERCENT * 3 && _firstSlope <= ONE_PERCENT * 20,
            "AssetParameters: The new value of the first slope is invalid."
        );
        require(
            _secondSlope >= ONE_PERCENT * 50 && _secondSlope <= DECIMAL,
            "AssetParameters: The new value of the second slope is invalid."
        );
        require(
            _utilizationBreakingPoint >= ONE_PERCENT * 60 &&
                _utilizationBreakingPoint <= ONE_PERCENT * 90,
            "AssetParameters: The new value of the utilization breaking point is invalid."
        );

        _parameters[_assetKey][BASE_PERCENTAGE_KEY] = PureParameters.makeUintParam(
            _basePercentage
        );
        emit UintParamUpdated(_assetKey, BASE_PERCENTAGE_KEY, _basePercentage);

        _parameters[_assetKey][FIRST_SLOPE_KEY] = PureParameters.makeUintParam(_firstSlope);
        emit UintParamUpdated(_assetKey, FIRST_SLOPE_KEY, _firstSlope);

        _parameters[_assetKey][SECOND_SLOPE_KEY] = PureParameters.makeUintParam(_secondSlope);
        emit UintParamUpdated(_assetKey, SECOND_SLOPE_KEY, _secondSlope);

        _parameters[_assetKey][UTILIZATION_BREAKING_POINT_KEY] = PureParameters.makeUintParam(
            _utilizationBreakingPoint
        );
        emit UintParamUpdated(
            _assetKey,
            UTILIZATION_BREAKING_POINT_KEY,
            _utilizationBreakingPoint
        );
    }

    function setupMaxUtilizationRatio(bytes32 _assetKey, uint256 _newValue)
        external
        onlyOwner
        onlyExist(_assetKey)
    {
        require(
            _newValue >= ONE_PERCENT * 94 && _newValue <= ONE_PERCENT * 97,
            "AssetParameters: The new value of the max utilization ratio is invalid."
        );

        _parameters[_assetKey][MAX_UTILIZATION_RATIO_KEY] = PureParameters.makeUintParam(
            _newValue
        );
        emit UintParamUpdated(_assetKey, MAX_UTILIZATION_RATIO_KEY, _newValue);
    }

    function setupLiquidationDiscount(bytes32 _assetKey, uint256 _newValue)
        external
        onlyOwner
        onlyExist(_assetKey)
    {
        require(
            _newValue <= ONE_PERCENT * 10,
            "AssetParameters: The new value of the liquidation discount is invalid."
        );

        _parameters[_assetKey][LIQUIDATION_DISCOUNT_KEY] = PureParameters.makeUintParam(_newValue);
        emit UintParamUpdated(_assetKey, LIQUIDATION_DISCOUNT_KEY, _newValue);
    }

    function setupDistributionsMinimums(
        bytes32 _assetKey,
        uint256 _minSupplyPart,
        uint256 _minBorrowPart
    ) external onlyOwner onlyExist(_assetKey) {
        require(
            _minSupplyPart >= ONE_PERCENT * 5 && _minSupplyPart <= ONE_PERCENT * 15,
            "AssetParameters: The new value of the minimum supply part is invalid."
        );
        require(
            _minBorrowPart >= ONE_PERCENT * 5 && _minBorrowPart <= ONE_PERCENT * 15,
            "AssetParameters: The new value of the minimum borrow part is invalid."
        );

        _parameters[_assetKey][MIN_SUPPLY_DISTRIBUTION_PART_KEY] = PureParameters.makeUintParam(
            _minSupplyPart
        );
        emit UintParamUpdated(_assetKey, MIN_SUPPLY_DISTRIBUTION_PART_KEY, _minSupplyPart);

        _parameters[_assetKey][MIN_BORROW_DISTRIBUTION_PART_KEY] = PureParameters.makeUintParam(
            _minBorrowPart
        );
        emit UintParamUpdated(_assetKey, MIN_BORROW_DISTRIBUTION_PART_KEY, _minBorrowPart);
    }

    function setupColRatio(bytes32 _assetKey, uint256 _newValue)
        external
        onlyOwner
        onlyExist(_assetKey)
    {
        require(
            _newValue >= ONE_PERCENT * 111 && _newValue <= ONE_PERCENT * 200,
            "AssetParameters: The new value of the collateralization ratio is invalid."
        );

        _parameters[_assetKey][COL_RATIO_KEY] = PureParameters.makeUintParam(_newValue);

        emit UintParamUpdated(_assetKey, COL_RATIO_KEY, _newValue);
    }

    function setupIntegrationColRatio(bytes32 _assetKey, uint256 _newValue)
        external
        onlyOwner
        onlyExist(_assetKey)
    {
        require(
            _newValue >= ONE_PERCENT * 105 && _newValue <= ONE_PERCENT * 200,
            "AssetParameters: The new value of the integration col ratio is invalid."
        );

        require(
            _newValue <= _getParam(_assetKey, COL_RATIO_KEY).getUintFromParam(),
            "AssetParameters: Integration col ratio must be less than or equal to col ratio"
        );

        _parameters[_assetKey][INTEGRATION_COL_RATIO_KEY] = PureParameters.makeUintParam(
            _newValue
        );

        emit UintParamUpdated(_assetKey, INTEGRATION_COL_RATIO_KEY, _newValue);
    }

    function setupReserveFactor(bytes32 _assetKey, uint256 _newValue)
        external
        onlyOwner
        onlyExist(_assetKey)
    {
        require(
            _newValue >= ONE_PERCENT * 10 && _newValue <= ONE_PERCENT * 20,
            "AssetParameters: The new value of the reserve factor is invalid."
        );

        _parameters[_assetKey][RESERVE_FACTOR_KEY] = PureParameters.makeUintParam(_newValue);

        emit UintParamUpdated(_assetKey, RESERVE_FACTOR_KEY, _newValue);
    }

    function setupAllowForIntegration(bytes32 _assetKey, bool _newValue)
        external
        onlyOwner
        onlyExist(_assetKey)
    {
        _parameters[_assetKey][ALLOW_FOR_INTEGRATION_KEY] = PureParameters.makeBoolParam(
            _newValue
        );

        emit BoolParamUpdated(_assetKey, ALLOW_FOR_INTEGRATION_KEY, _newValue);
    }

    function _getParam(bytes32 _assetKey, bytes32 _paramKey)
        internal
        view
        returns (PureParameters.Param memory)
    {
        require(
            PureParameters.paramExists(_parameters[_assetKey][_paramKey]),
            "AssetParameters: Param for this asset doesn't exist."
        );

        return _parameters[_assetKey][_paramKey];
    }
}