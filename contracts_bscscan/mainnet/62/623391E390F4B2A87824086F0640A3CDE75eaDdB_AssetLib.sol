// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

interface IAssetFactory {
    function notDefaultDexRouterToken(address) external view returns (address);

    function notDefaultDexFactoryToken(address) external view returns (address);

    function defaultDexRouter() external view returns (address);

    function defaultDexFactory() external view returns (address);

    function weth() external view returns (address);

    function isAddressDexRouter(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function getData(address[] calldata tokens)
        external
        view
        returns (bool[] memory isValidValue, uint256[] memory tokensPrices);

    function uploadData(address[] calldata tokens, uint256[] calldata values) external;

    function getTimestampsOfLastUploads(address[] calldata tokens)
        external
        view
        returns (uint256[] memory timestamps);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../pancake-swap/interfaces/IPancakeRouter02.sol";
import "../pancake-swap/interfaces/IPangolinRouter02.sol";
import "../pancake-swap/interfaces/IPancakeRouter02BNB.sol";
import "../pancake-swap/interfaces/IPancakeFactory.sol";
import "../pancake-swap/interfaces/IWETH.sol";

import "../interfaces/IOracle.sol";
import "../interfaces/IAssetFactory.sol";

library AssetLib {
    function checkIfTokensHavePair(address[] memory tokens, address assetFactory) public view {
        address defaultDexFactory = IAssetFactory(assetFactory).defaultDexFactory();
        address defaultDexRouter = IAssetFactory(assetFactory).defaultDexRouter();

        for (uint256 i = 0; i < tokens.length; ++i) {
            address dexFactory = IAssetFactory(assetFactory).notDefaultDexFactoryToken(tokens[i]);
            address dexRouter;
            address weth;
            if (dexFactory != address(0)) {
                dexRouter = IAssetFactory(assetFactory).notDefaultDexRouterToken(tokens[i]);
            } else {
                dexFactory = defaultDexFactory;
                dexRouter = defaultDexRouter;
            }
            weth = getWethFromDex(dexRouter);

            if (tokens[i] == weth) {
                continue;
            }
            bool isValid = checkIfAddressIsToken(tokens[i]);
            require(isValid == true, "Address is not token");

            address pair = IPancakeFactory(dexFactory).getPair(tokens[i], weth);
            require(pair != address(0), "Not have eth pair");
        }
    }

    function checkIfAddressIsToken(address token) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(token)
        }
        if (size == 0) {
            return false;
        }
        try IERC20Metadata(token).decimals() returns (uint8) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function initTokenToBuyInfo(
        address[] memory tokensToBuy,
        uint256 totalWeight,
        mapping(address => uint256) storage tokensDistribution,
        IOracle oracle
    ) external view returns (uint256[][5] memory, uint256[] memory) {
        /*
        tokenToBuyInfo
        0 - tokens to buy amounts
        1 - actual number to buy (tokens to buy amounts - tokensInAssetNow)
        2 - actual weight to buy
        3 - tokens decimals
        4 - is in asset already
         */
        uint256[][5] memory tokenToBuyInfo;
        for (uint256 i = 0; i < tokenToBuyInfo.length; ++i) {
            tokenToBuyInfo[i] = new uint256[](tokensToBuy.length);
        }

        (bool[] memory isValidValue, uint256[] memory tokensPrices) = oracle.getData(tokensToBuy);
        for (uint256 i = 0; i < tokensToBuy.length; ++i) {
            require(isValidValue[i] == true, "Oracle price error");

            tokenToBuyInfo[3][i] = IERC20Metadata(tokensToBuy[i]).decimals();

            uint256 tokenWeight = (tokensDistribution[tokensToBuy[i]] * totalWeight) / 1e4;
            tokenToBuyInfo[0][i] = (tokenWeight * (10**tokenToBuyInfo[3][i])) / tokensPrices[i];
        }

        return (tokenToBuyInfo, tokensPrices);
    }

    function initTokenToSellInfo(
        address[] memory tokensOld,
        IOracle oracle,
        mapping(address => uint256) storage totalTokenAmount
    ) external view returns (uint256[][3] memory, uint256) {
        uint256[][3] memory tokensOldInfo;
        for (uint256 i = 0; i < tokensOldInfo.length; ++i) {
            tokensOldInfo[i] = new uint256[](tokensOld.length);
        }

        (bool[] memory isValidValue, uint256[] memory tokensPrices) = oracle.getData(tokensOld);
        uint256 oldWeight;
        for (uint256 i = 0; i < tokensOld.length; ++i) {
            tokensOldInfo[0][i] = totalTokenAmount[tokensOld[i]];
            tokensOldInfo[2][i] = IERC20Metadata(tokensOld[i]).decimals();
            require(isValidValue[i] == true, "Oracle error");
            oldWeight += (tokensOldInfo[0][i] * tokensPrices[i]) / (10**tokensOldInfo[2][i]);
        }
        require(oldWeight != 0, "No value in asset");

        return (tokensOldInfo, oldWeight);
    }

    function checkAndWriteDistribution(
        address[] memory newTokensInAsset,
        uint256[] memory distribution,
        address[] memory oldTokens,
        mapping(address => uint256) storage tokensDistribution
    ) external {
        require(newTokensInAsset.length == distribution.length, "Input error");
        require(newTokensInAsset.length > 0, "Len error");
        uint256 totalPerc;
        for (uint256 i = 0; i < newTokensInAsset.length; ++i) {
            require(newTokensInAsset[i] != address(0), "Wrong token");
            require(distribution[i] > 0, "Zero distribution");
            for (uint256 j = i + 1; j < newTokensInAsset.length; ++j) {
                require(newTokensInAsset[i] != newTokensInAsset[j], "Input error");
            }
            tokensDistribution[newTokensInAsset[i]] = distribution[i];
            totalPerc += distribution[i];
        }
        require(totalPerc == 1e4, "Perc error");

        for (uint256 i = 0; i < oldTokens.length; ++i) {
            bool isFound = false;
            for (uint256 j = 0; j < newTokensInAsset.length && isFound == false; ++j) {
                if (newTokensInAsset[j] == oldTokens[i]) {
                    isFound = true;
                }
            }

            if (isFound == false) {
                tokensDistribution[oldTokens[i]] = 0;
            }
        }
    }

    function withdrawFromYForOwner(
        address[] memory tokensInAsset,
        uint256[] memory tokenAmounts,
        address sender,
        mapping(address => uint256) storage yVaultAmount,
        mapping(address => uint256) storage yVaultAmountInStaking
    ) external {
        require(tokenAmounts.length == tokensInAsset.length, "Invalid input");
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            if (tokenAmounts[i] != 0) {
                uint256 yAmount = yVaultAmount[tokensInAsset[i]];
                require(yAmount >= tokenAmounts[i], "Not enough y balance");
                yAmount -= tokenAmounts[i];
                yVaultAmount[tokensInAsset[i]] = yAmount;
                yVaultAmountInStaking[tokensInAsset[i]] += tokenAmounts[i];

                safeTransfer(tokensInAsset[i], sender, tokenAmounts[i]);
            }
        }
    }

    function checkAndWriteWhitelist(
        address[] memory tokenWhitelist,
        address assetFactory,
        EnumerableSet.AddressSet storage tokenWhitelistSet
    ) external {
        checkIfTokensHavePair(tokenWhitelist, assetFactory);
        for (uint256 i = 0; i < tokenWhitelist.length; ++i) {
            require(tokenWhitelist[i] != address(0), "No zero address");
            for (uint256 j = 0; j < i; ++j) {
                require(tokenWhitelist[i] != tokenWhitelist[j], "Whitelist error");
            }
            EnumerableSet.add(tokenWhitelistSet, tokenWhitelist[i]);
        }
    }

    function changeWhitelist(
        address token,
        bool value,
        address assetFactory,
        EnumerableSet.AddressSet storage set
    ) external {
        require(token != address(0), "Token error");

        if (value) {
            address[] memory temp = new address[](1);
            temp[0] = token;
            checkIfTokensHavePair(temp, assetFactory);
            require(EnumerableSet.add(set, token), "Wrong value");
        } else {
            require(EnumerableSet.remove(set, token), "Wrong value");
        }
    }

    function sellTokensInAssetNow(
        address[] memory tokensInAssetNow,
        uint256[][3] memory tokensInAssetNowInfo,
        address weth,
        address assetFactory,
        mapping(address => uint256) storage totalTokenAmount
    ) external returns (uint256 availableWeth) {
        for (uint256 i = 0; i < tokensInAssetNow.length; ++i) {
            {
                address temp = tokensInAssetNow[i];
                if (totalTokenAmount[temp] == 0) {
                    totalTokenAmount[temp] = tokensInAssetNowInfo[0][i];
                }
            }

            if (tokensInAssetNowInfo[1][i] == 0) continue;

            if (tokensInAssetNow[i] == address(0)) {
                IWETH(weth).deposit{value: tokensInAssetNowInfo[1][i]}();
                availableWeth += tokensInAssetNowInfo[1][i];
            } else if (tokensInAssetNow[i] == address(weth)) {
                availableWeth += tokensInAssetNowInfo[1][i];
            } else if (tokensInAssetNow[i] != address(weth)) {
                availableWeth += safeSwap(
                    [tokensInAssetNow[i], weth],
                    tokensInAssetNowInfo[1][i],
                    assetFactory,
                    0
                );
            }
            {
                address temp = tokensInAssetNow[i];
                totalTokenAmount[temp] -= tokensInAssetNowInfo[1][i];
            }
        }
    }

    function buyTokensInAssetRebase(
        address[] memory tokensToBuy,
        uint256[][5] memory tokenToBuyInfo,
        uint256[2] memory tokenToBuyInfoGlobals,
        address weth,
        address assetFactory,
        uint256 availableWeth,
        mapping(address => uint256) storage totalTokenAmount
    ) external returns (uint256[] memory outputAmounts) {
        outputAmounts = new uint256[](tokensToBuy.length);
        if (tokenToBuyInfoGlobals[0] == 0 || availableWeth == 0) {
            return outputAmounts;
        }
        uint256 restWeth = availableWeth;
        for (uint256 i = 0; i < tokensToBuy.length && tokenToBuyInfoGlobals[1] > 0; ++i) {
            uint256 wethToSpend;
            // if actual weight to buy = 0
            if (tokenToBuyInfo[2][i] == 0) {
                continue;
            }
            if (tokenToBuyInfoGlobals[1] > 1) {
                wethToSpend = (availableWeth * tokenToBuyInfo[2][i]) / tokenToBuyInfoGlobals[0];
            } else {
                wethToSpend = restWeth;
            }
            require(wethToSpend > 0 && wethToSpend <= restWeth, "Internal error");

            restWeth -= wethToSpend;
            --tokenToBuyInfoGlobals[1];

            outputAmounts[i] = safeSwap([weth, tokensToBuy[i]], wethToSpend, assetFactory, 1);

            {
                address temp = tokensToBuy[i];
                totalTokenAmount[temp] += outputAmounts[i];
            }
        }

        require(restWeth == 0, "Internal error");

        return outputAmounts;
    }

    function transferTokenAndSwapToWeth(
        address tokenToPay,
        uint256 amount,
        address sender,
        address weth,
        address assetFactory
    ) external returns (address, uint256) {
        tokenToPay = transferFromToGoodToken(tokenToPay, sender, amount, weth);
        uint256 totalWeth;
        if (tokenToPay == weth) {
            totalWeth = amount;
        } else {
            totalWeth = safeSwap([tokenToPay, weth], amount, assetFactory, 0);
        }

        return (tokenToPay, totalWeth);
    }

    function transferFromToGoodToken(
        address token,
        address user,
        uint256 amount,
        address weth
    ) public returns (address) {
        if (token == address(0)) {
            require(msg.value == amount, "Value error");
            token = weth;
            IWETH(weth).deposit{value: amount}();
        } else {
            require(msg.value == 0, "Value error");
            AssetLib.safeTransferFrom(token, user, amount);
        }
        return token;
    }

    function checkCurrency(
        address currency,
        address weth,
        EnumerableSet.AddressSet storage tokenWhitelistSet
    ) external view {
        address currencyToCheck;
        if (currency == address(0)) {
            currencyToCheck = weth;
        } else {
            currencyToCheck = currency;
        }
        require(EnumerableSet.contains(tokenWhitelistSet, currencyToCheck), "Not allowed currency");
    }

    function buyTokensMint(
        uint256 totalWeth,
        address[] memory tokensInAsset,
        address[2] memory wethAndAssetFactory,
        mapping(address => uint256) storage tokensDistribution,
        mapping(address => uint256) storage totalTokenAmount
    ) external returns (uint256[] memory buyAmounts, uint256[] memory oldDistribution) {
        buyAmounts = new uint256[](tokensInAsset.length);
        oldDistribution = new uint256[](tokensInAsset.length);
        uint256 restWeth = totalWeth;
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 wethToThisToken;
            if (i < tokensInAsset.length - 1) {
                wethToThisToken = (totalWeth * tokensDistribution[tokensInAsset[i]]) / 1e4;
            } else {
                wethToThisToken = restWeth;
            }
            require(wethToThisToken > 0 && wethToThisToken <= restWeth, "Internal error");

            restWeth -= wethToThisToken;

            oldDistribution[i] = totalTokenAmount[tokensInAsset[i]];

            buyAmounts[i] = safeSwap(
                [wethAndAssetFactory[0], tokensInAsset[i]],
                wethToThisToken,
                wethAndAssetFactory[1],
                1
            );

            totalTokenAmount[tokensInAsset[i]] = oldDistribution[i] + buyAmounts[i];
        }
    }

    function getMintAmount(
        address[] memory tokensInAsset,
        uint256[] memory buyAmounts,
        uint256[] memory oldDistribution,
        uint256 totalSupply,
        uint256 decimals,
        IOracle oracle,
        uint256 initialPrice
    ) public view returns (uint256 mintAmount) {
        uint256 totalPriceInAsset;
        uint256 totalPriceUser;
        (bool[] memory isValidValue, uint256[] memory tokensPrices) = oracle.getData(tokensInAsset);
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            require(isValidValue[i] == true, "Oracle error");
            uint256 decimalsToken = IERC20Metadata(tokensInAsset[i]).decimals();
            totalPriceInAsset += (oldDistribution[i] * tokensPrices[i]) / (10**decimalsToken);
            totalPriceUser += (buyAmounts[i] * tokensPrices[i]) / (10**decimalsToken);
        }

        if (totalPriceInAsset == 0 || totalSupply == 0) {
            return (totalPriceUser * 10**decimals) / initialPrice;
        } else {
            return (totalSupply * totalPriceUser) / totalPriceInAsset;
        }
    }

    function safeSwap(
        address[2] memory path,
        uint256 amount,
        address assetFactory,
        uint256 forWhatTokenDex
    ) public returns (uint256) {
        if (path[0] == path[1]) {
            return amount;
        }

        address dexRouter = getTokenDexRouter(assetFactory, path[forWhatTokenDex]);
        checkAllowance(path[0], dexRouter, amount);

        address[] memory _path = new address[](2);
        _path[0] = path[0];
        _path[1] = path[1];
        uint256[] memory amounts =
            IPancakeRouter02(dexRouter).swapExactTokensForTokens(
                amount,
                0,
                _path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );

        return amounts[1];
    }

    function redeemAndTransfer(
        uint256[2] memory amountAndTotalSupply,
        address[4] memory userCurrencyToPayWethFactory,
        mapping(address => uint256) storage totalTokenAmount,
        address[] memory tokensInAsset,
        uint256[] memory feePercentages
    )
        public
        returns (
            uint256 feeTotal,
            uint256[] memory inputAmounts,
            uint256 outputAmountTotal
        )
    {
        inputAmounts = new uint256[](tokensInAsset.length);
        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            inputAmounts[i] =
                (totalTokenAmount[tokensInAsset[i]] * amountAndTotalSupply[0]) /
                amountAndTotalSupply[1];

            uint256 outputAmount =
                swapToCurrency(
                    tokensInAsset[i],
                    userCurrencyToPayWethFactory[1],
                    inputAmounts[i],
                    [userCurrencyToPayWethFactory[2], userCurrencyToPayWethFactory[3]]
                );

            uint256 fee = (outputAmount * feePercentages[i]) / 1e4;
            outputAmountTotal += outputAmount - fee;
            feeTotal += fee;

            totalTokenAmount[tokensInAsset[i]] -= inputAmounts[i];
        }

        if (userCurrencyToPayWethFactory[1] == address(0)) {
            IWETH(userCurrencyToPayWethFactory[2]).withdraw(outputAmountTotal);
            safeTransfer(address(0), userCurrencyToPayWethFactory[0], outputAmountTotal);
        } else {
            safeTransfer(
                userCurrencyToPayWethFactory[1],
                userCurrencyToPayWethFactory[0],
                outputAmountTotal
            );
        }
    }

    function depositToY(
        address[] memory tokensInAsset,
        uint256[] memory tokenAmountsOfY,
        address sender,
        address assetFactory,
        address weth,
        mapping(address => uint256) storage yVaultAmountInStaking,
        mapping(address => uint256) storage yVaultAmount
    ) external {
        require(tokensInAsset.length == tokenAmountsOfY.length, "Input error 1");

        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 amountInStaking = yVaultAmountInStaking[tokensInAsset[i]];
            require(amountInStaking >= tokenAmountsOfY[i], "Trying to send more");
            amountInStaking -= tokenAmountsOfY[i];
            yVaultAmountInStaking[tokensInAsset[i]] = amountInStaking;
            yVaultAmount[tokensInAsset[i]] += tokenAmountsOfY[i];

            safeTransferFrom(tokensInAsset[i], sender, tokenAmountsOfY[i]);
        }
    }

    function getFeePercentagesRedeem(
        address[] memory tokensInAsset,
        mapping(address => uint256) storage totalTokenAmount,
        mapping(address => uint256) storage xVaultAmount
    ) external view returns (uint256[] memory feePercentages) {
        feePercentages = new uint256[](tokensInAsset.length);

        for (uint256 i = 0; i < tokensInAsset.length; ++i) {
            uint256 totalAmount = totalTokenAmount[tokensInAsset[i]];
            uint256 xAmount = xVaultAmount[tokensInAsset[i]];

            if (xAmount >= (1500 * totalAmount) / 1e4) {
                feePercentages[i] = 200;
            } else if (
                xAmount < (1500 * totalAmount) / 1e4 && xAmount >= (500 * totalAmount) / 1e4
            ) {
                uint256 xAmountPertcentage = (xAmount * 1e4) / totalAmount;
                feePercentages[i] = 600 - (400 * (xAmountPertcentage - 500)) / 1000;
            } else {
                revert("xAmount percentage error");
            }
        }
    }

    function swapToCurrency(
        address inputCurrency,
        address outputCurrency,
        uint256 amount,
        address[2] memory wethAndAssetFactory
    ) internal returns (uint256) {
        require(inputCurrency != address(0), "Internal error");
        if (inputCurrency != outputCurrency) {
            uint256 outputAmount;
            if (outputCurrency == wethAndAssetFactory[0] || outputCurrency == address(0)) {
                outputAmount = safeSwap(
                    [inputCurrency, wethAndAssetFactory[0]],
                    amount,
                    wethAndAssetFactory[1],
                    0
                );
            } else {
                outputAmount = safeSwap(
                    [inputCurrency, wethAndAssetFactory[0]],
                    amount,
                    wethAndAssetFactory[1],
                    0
                );
                outputAmount = safeSwap(
                    [wethAndAssetFactory[0], outputCurrency],
                    outputAmount,
                    wethAndAssetFactory[1],
                    1
                );
            }
            return outputAmount;
        } else {
            return amount;
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            require(msg.value == amount, "Value error");
        } else {
            (bool success, bytes memory data) =
                token.call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferFrom failed"
            );
        }
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) public {
        if (to == address(this)) {
            return;
        }
        if (token == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success, "Transfer eth failed");
        } else {
            (bool success, bytes memory data) =
                token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "Transfer token failed"
            );
        }
    }

    function checkAllowance(
        address token,
        address to,
        uint256 amount
    ) public {
        uint256 allowance = IERC20(token).allowance(address(this), to);

        if (amount > allowance) {
            (bool success, bytes memory data) =
                token.call(abi.encodeWithSelector(0x095ea7b3, to, type(uint256).max));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "Token approve failed"
            );
        }
    }

    function getWethFromDex(address dexRouter) public view returns (address) {
        try IPancakeRouter02(dexRouter).WETH() returns (address weth) {
            return weth;
        } catch (bytes memory) {} // solhint-disable-line no-empty-blocks

        try IPangolinRouter02(dexRouter).WAVAX() returns (address weth) {
            return weth;
        } catch (bytes memory) {} // solhint-disable-line no-empty-blocks

        try IPancakeRouter02BNB(dexRouter).WBNB() returns (address weth) {
            return weth;
        } catch (bytes memory) {
            return address(0);
        }
    }

    function getTokenDexRouter(address factory, address token) public view returns (address) {
        address customDexRouter = IAssetFactory(factory).notDefaultDexRouterToken(token);

        if (customDexRouter != address(0)) {
            return customDexRouter;
        } else {
            return IAssetFactory(factory).defaultDexRouter();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01BNB {
    function factory() external view returns (address);

    function WBNB() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityBNB(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountBNB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityBNB(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountBNB);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityBNBWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountBNB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactBNBForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactBNB(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForBNB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapBNBForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeRouter01BNB.sol";

interface IPancakeRouter02BNB is IPancakeRouter01BNB {
    function removeLiquidityBNBSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountBNB);

    function removeLiquidityBNBWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountBNB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactBNBForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForBNBSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPangolinRouter02 {
    function WAVAX() external view returns (address);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}