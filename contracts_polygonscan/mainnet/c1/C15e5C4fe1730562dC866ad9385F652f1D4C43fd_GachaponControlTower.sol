// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Contains all the variables and functions regarding the management of supported currencies.
/// @author KirienzoEth for DokiDoki
contract CurrenciesManager is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet internal _supportedCurrenciesSet;

  event CurrencySupportChanged(address indexed _currency, bool indexed _isSupported);

  /// @notice Add support for an ERC20 token to be used as currency when creating a gachapon machine
  function addCurrencySupport(address _currency) public onlyOwner {
    // Avoid user wasting gas
    require(EnumerableSet.contains(_supportedCurrenciesSet, _currency) == false, "This currency is already supported");
    // Add support for the currency
    EnumerableSet.add(_supportedCurrenciesSet, _currency);

    emit CurrencySupportChanged(_currency, EnumerableSet.contains(_supportedCurrenciesSet, _currency));
  }

  /// @notice Remove support for an ERC20 token
  function removeCurrencySupport(address _currency) public onlyOwner {
    // Avoid user wasting gas
    require(EnumerableSet.contains(_supportedCurrenciesSet, _currency) == true, "This currency is already not supported");
    // Remove support for the currency
    EnumerableSet.remove(_supportedCurrenciesSet, _currency);

    emit CurrencySupportChanged(_currency, EnumerableSet.contains(_supportedCurrenciesSet, _currency));
  }

  /// @notice Returns an array containing the addresses of all ERC20 tokens this deployer supports
  function supportedCurrencies() external view returns(address[] memory) {
    uint _currenciesSetLength = EnumerableSet.length(_supportedCurrenciesSet);
    address[] memory _currenciesArray = new address[](_currenciesSetLength);
    for(uint _i = 0; _i < _currenciesSetLength; _i++) {
      _currenciesArray[_i] = EnumerableSet.at(_supportedCurrenciesSet, _i);
    }

    return _currenciesArray;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IGachaponFactory.sol";
import "../interfaces/IGachapon.sol";
import "./TreasuryManager.sol";
import "./CurrenciesManager.sol";
import "./GachaponOperator.sol";
import "./VRFManager.sol";

/// @title A contract to deploy and manage gachapon machines.
/// @author KirienzoEth for DokiDoki
contract GachaponControlTower is TreasuryManager, CurrenciesManager, GachaponOperator, VRFManager {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes4 constant private INTERFACE_ID_ERC1155 = 0xd9b67a26;
  bytes4 constant private INTERFACE_ID_ERC721 = 0x80ac58cd;
  /// @notice Amount of gachapons deployed by this contract
  uint public gachaponAmount;
  /// @dev Gachapon deployed at the specified index
  mapping(uint => IGachapon) public gachapons;
  /// @dev Address of the contract that will deploy the gachapon, gachapon contract will always implement the IGachapon interface
  IGachaponFactory public gachaponFactory;

  event GachaponCreated(address indexed _factory, string _title, address _gachapon, address indexed _currency);
  event GachaponFactoryChanged(address _previous, address indexed _current);

  constructor() {
    addAddressToAuthorizedOperators(msg.sender);
  }

  /// @notice Will create a new gachapon machine with the provided title, collection and currency
  /// @dev Collection must implement ERC1155 or ERC721 interface and the currency ERC20, machine ownership will be set to msg.sender
  function createGachapon(string memory _machineTitle, IERC20 _currency) public {
    // Make sure the current index is not already in use to not overwrite it
    assert(address(gachapons[gachaponAmount]) == address(0));
    // Make sure the gachapon factory contract is set
    require(address(gachaponFactory) != address(0), "No gachapon factory contract is set");
    // Make sure the team's treasury address is set
    require(teamTreasuryAddress != address(0), "Team treasury address must be set");
    // Make sure the DAO's treasury address is set
    require(daoTreasuryAddress != address(0), "DAO treasury address must be set");
    // Make sure the tokenomics manager address is set
    require(tokenomicsManagerAddress != address(0), "Tokenomics manager address must be set");
    // Make sure not to create a machine using a currency that we don't support
    require(EnumerableSet.contains(_supportedCurrenciesSet, address(_currency)), "Currency is not supported");
    // Make sure only authorized addresses can create a gachapon
    require(authorizedOperators[msg.sender], "You are not authorized to create a gachapon");

    // Create the new gachapon machine
    IGachapon _gachapon = gachaponFactory.createGachapon(_machineTitle, address(_currency));
    // Save the gachapon machine in the mapping with the current index
    gachapons[gachaponAmount] = _gachapon;
    // Transfer the ownership to the deployer's address
    gachapons[gachaponAmount].transferOwnership(msg.sender);

    emit GachaponCreated(address(gachaponFactory), _machineTitle, address(_gachapon), address(_currency));
    // Increment the index for the next time a gachapon is created
    gachaponAmount++;
  }

  /// @notice Set address of the contract creating the gachapon machines
  /// @dev Contract MUST implement IGachaponFactory interface
  function setGachaponFactory(address _gachaponFactory) public onlyOwner {
    address _previous = address(gachaponFactory);
    // Set new gachapon factory address
    gachaponFactory = IGachaponFactory(_gachaponFactory);

    emit GachaponFactoryChanged(_previous, address(gachaponFactory));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/IDeployerControlledState.sol";
import "./OperatorsManager.sol";

/// @title Contract to allow deployers to operate gachapons
/// @author KirienzoEth for DokiDoki
contract GachaponOperator is OperatorsManager {
  /// @notice Ban a gachapon
  /// @dev Banned gachapons can't be played anymore
  /// @param _gachapon Address of the targeted gachapon
  function ban(address _gachapon) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).ban();
  }

  /// @notice Unban a gachapon
  /// @param _gachapon Address of the targeted gachapon
  function unban(address _gachapon) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).unban();
  }

  /// @notice Set the DAO's share at `_rate` / 1000
  /// @param _gachapon Address of the targeted gachapon
  function setDaoRate(address _gachapon, uint16 _rate) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).setDaoRate(_rate);
  }

  /// @notice Set the tokenomics' share at `_rate` / 1000
  /// @param _gachapon Address of the targeted gachapon
  function setTokenomicsRate(address _gachapon, uint16 _rate) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).setTokenomicsRate(_rate);
  }
  
  /// @notice Set the artist's share at `_rate` / 1000
  /// @param _gachapon Address of the targeted gachapon
  function setArtistRate(address _gachapon, uint16 _rate) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).setArtistRate(_rate);
  }
  
  /// @notice Set the addresses and rate of their respective shares of the artist's profits / 1000
  /// @param _gachapon Address of the targeted gachapon
  /// @param _addresses Array of addresses that will receive a share of the artsit's profits, must be unique
  /// @param _rates Rates for each address, must be equal to 1000
  function setArtistProfitsSharing(address _gachapon, address[] memory _addresses, uint16[] memory _rates) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).setArtistProfitsSharing(_addresses, _rates);
  }
  
  /// @notice Will send all the oracle tokens in the gachapon to the treasury address
  /// @param _gachapon Address of the targeted gachapon
  function withdrawOracleTokens(address _gachapon) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).withdrawOracleTokens();
  }
  
  /// @dev Only use this when the oracle failed to answer for a request ID
  /// @dev NEVER USE OUTSIDE OF THIS SCENARIO
  /// @param _gachapon Address of the targeted gachapon
  /// @param _requestId request ID of the round to cancel
  function retryRound(address _gachapon, bytes32 _requestId) external onlyFromControlTower {
    IDeployerControlledState(_gachapon).retryRound(_requestId);
  }

  modifier onlyFromControlTower {
    require(authorizedOperators[msg.sender], "Only authorized adresses can perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contains all the variables and functions regarding the management of addresses authorized to deploy and manage gachapons.
/// @author KirienzoEth for DokiDoki
contract OperatorsManager is Ownable {
  /// @notice Is address authorized to create and manage gachapons
  mapping(address => bool) public authorizedOperators;

  event OperatorAuthorizationChanged(address indexed _address, bool indexed _isAuthorized);

  /// @notice Add the address to the list of operators
  function addAddressToAuthorizedOperators(address _address) public onlyOwner {
    require(authorizedOperators[_address] == false, "This address is already authorized");
    authorizedOperators[_address] = true;

    emit OperatorAuthorizationChanged(_address, authorizedOperators[_address]);
  }

  /// @notice Remove the address from the operators
  function removeAddressFromAuthorizedOperators(address _address) public onlyOwner {
    require(authorizedOperators[_address] == true, "This address is already unauthorized");
    authorizedOperators[_address] = false;

    emit OperatorAuthorizationChanged(_address, authorizedOperators[_address]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITreasuryManager.sol";

/// @title Contains all the variables and functions regarding treasury address management.
/// @author KirienzoEth for DokiDoki
contract TreasuryManager is Ownable, ITreasuryManager {
  /// @inheritdoc ITreasuryManager
  address public override teamTreasuryAddress;
  /// @inheritdoc ITreasuryManager
  address public override daoTreasuryAddress;
  /// @inheritdoc ITreasuryManager
  address public override tokenomicsManagerAddress;

  event TeamTreasuryAddressChanged(address indexed _address);
  event DAOTreasuryAddressChanged(address indexed _address);
  event TokenomicsManagerAddressChanged(address indexed _address);
  
  /// @notice Set address of the team's treasury
  function setTeamTreasuryAddress(address _address) public onlyOwner {
    teamTreasuryAddress = _address;

    emit TeamTreasuryAddressChanged(_address);
  }

  /// @notice Set address of the DAO's treasury
  function setDaoTreasuryAddress(address _address) public onlyOwner {
    daoTreasuryAddress = _address;

    emit DAOTreasuryAddressChanged(_address);
  }

  /// @notice Set address of the tokenomics manager
  function setTokenomicsManagerAddress(address _address) public onlyOwner {
    tokenomicsManagerAddress = _address;

    emit TokenomicsManagerAddressChanged(_address);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IOracleManager.sol";

/// @title Contract to manage the different addresses and values used by the VRF oracle
/// @author KirienzoEth for DokiDoki
contract VRFManager is IOracleManager, Ownable {
  bytes32 override public oracleKeyHash;
  uint256 override public oracleFee;
  address override public oracleToken;
  address override public oracleVRFCoordinator;

  function setOracleKeyHash(bytes32 _keyHash) external onlyOwner {
    oracleKeyHash = _keyHash;
  }

  function setOracleFee(uint256 _fee) external onlyOwner {
    oracleFee = _fee;
  }

  function setOracleToken(address _token) external onlyOwner {
    oracleToken = _token;
  }

  function setOracleVRFCoordinator(address _coordinator) external onlyOwner {
    oracleVRFCoordinator = _coordinator;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @author KirienzoEth for DokiDoki
/// @title Contract managing the prize pool of the gachapon
contract PrizePoolManager is Ownable, IERC1155Receiver {
  using ERC165Checker for address;

  struct Nft {
    address collection;
    uint256 id;
    uint256 amount;
  }

  /// @dev Interface id of the IERC1155 interface for the ERC165Checker
  bytes4 constant private INTERFACE_ID_ERC1155 = 0xd9b67a26;
  /// @dev All the nfts that were ever added to this gachapon
  mapping(uint => Nft) internal nfts;
  /// @notice The number of different nfts in the gachapon
  uint public nftsAmount;
  /// @notice Is the gachapon locked forever
  /// @dev This is set to true whenever the owner removes NFTs from the prize pool
  bool public isLockedForever = false;

  /// @dev Contains every nft available as a prize, anything above the index '_prizePoolSize - 1' is invalid
  mapping(uint => uint) internal _prizePool;
  /// @notice The number prizes remaining
  uint internal _prizePoolSize;
  /// @dev Get the index of the nft from its collection and tokenId
  mapping(address => mapping(uint => uint)) internal _collectionToTokenIdToIndex;

  EnumerableSet.AddressSet internal _collectionsSet;

  event NftAdded(address indexed _collection, uint _id, uint _amount);
  event NftsAdded(address indexed _collection, uint[] _ids, uint[] _amounts);
  event NftRemoved(address indexed _collection, uint _id, uint _amount);

  function registerNft(address _collection, uint _id, uint _amount) private {
    require(!isLockedForever, "You cannot add more NFTs to an unusable machine");
    require(EnumerableSet.contains(_collectionsSet, _collection) || EnumerableSet.length(_collectionsSet) == 0, "Gachapon only support one collection");

    EnumerableSet.add(_collectionsSet, _collection);
    // If the nft was never previously added
    if (_prizePoolSize == 0 || nfts[_collectionToTokenIdToIndex[_collection][_id]].id != _id) {
      // Store the index of the nft in the nfts array
      _collectionToTokenIdToIndex[_collection][_id] = nftsAmount;
      // Store the reference to the nft
      nfts[nftsAmount] = Nft(_collection, _id, _amount);
      // Increase the number of nfts in the machine
      nftsAmount++;
    } else {
      // Increase the amount of copies of the nft present in the machine
      nfts[_collectionToTokenIdToIndex[_collection][_id]].amount += _amount;
    }

    // Add all the copies to the prize pool
    for (uint _i = 0; _i < _amount; _i++) {
      _prizePool[_i + _prizePoolSize] = _collectionToTokenIdToIndex[_collection][_id];
    }
    
    // Increase the number of nft in the prize pool
    _prizePoolSize += _amount;
  }

  /// @notice Remove `_amount` of token ID `_id`, doing this will lock the gachapon forever
  /// @dev Doing this will put the prize pool in an invalid state
  function removeNft(address _collection, uint _id, uint _amount) external onlyOwner {
    require(_amount > 0, "You need to remove at least 1 nft");
    require(EnumerableSet.contains(_collectionsSet, _collection), "This collection is not in the gachapon");
    require(_prizePoolSize > 0 && nfts[_collectionToTokenIdToIndex[_collection][_id]].id == _id, "This token ID is not in the gachapon");
    require(nfts[_collectionToTokenIdToIndex[_collection][_id]].amount >= _amount , "There is not enough of this nft in the gachapon");

    // Make the gachapon unusable
    isLockedForever = true;
    // Reduce the supply of said nft
    nfts[_collectionToTokenIdToIndex[_collection][_id]].amount -= _amount;
    // Reduce the number of remaining prizes
    _prizePoolSize -= _amount;
    // Send nfts to the owner
    IERC1155(_collection).safeTransferFrom(address(this), msg.sender, _id, _amount, "");

    emit NftRemoved(_collection, _id, _amount);
  }

  /// @inheritdoc IERC1155Receiver
  function onERC1155Received(
      address,
      address _from,
      uint256 _id,
      uint256 _value,
      bytes calldata
  ) override external returns (bytes4) {
    require(msg.sender.supportsInterface(INTERFACE_ID_ERC1155), "Only accessible with method safeTransferFrom from your ERC1155 collection");
    require(_from == owner(), "Only the owner can add nfts");

    registerNft(msg.sender, _id, _value);
    emit NftAdded(msg.sender, _id, _value);

    return this.onERC1155Received.selector;
  }

  /// @inheritdoc IERC1155Receiver
  function onERC1155BatchReceived(
      address,
      address _from,
      uint256[] calldata _ids,
      uint256[] calldata _values,
      bytes calldata
  ) override external returns (bytes4) {
    require(msg.sender.supportsInterface(INTERFACE_ID_ERC1155), "Only accessible with method safeBatchTransferFrom from your ERC1155 collection");
    require(_from == owner(), "Only the owner can add nfts");

    // For each token id in the batch
    for (uint _i = 0; _i < _ids.length; _i++) {
      registerNft(msg.sender, _ids[_i], _values[_i]);
    }
    
    emit NftsAdded(msg.sender, _ids, _values);

    return this.onERC1155BatchReceived.selector;
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) override external pure returns (bool) {
    return interfaceId == INTERFACE_ID_ERC1155;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title Interface exposing the gachapon methods that are only callable from the GachaponControlTower
/// @author KirienzoEth for DokiDoki
interface IDeployerControlledState {
  /// @notice Ban the gachapon
  function ban() external;
  /// @notice Unban the gachapon
  function unban() external;

  /// @notice Set the cut of the artist to `_rate` / 1000, the sum of all the rates can't exceed 1000
  function setArtistRate(uint16 _rate) external;
  /// @notice Set the cut of the token mechanics to `_rate` / 1000, the sum of all the rates can't exceed 1000
  function setTokenomicsRate(uint16 _rate) external;
  /// @notice Set the cut of the DAO to `_rate` / 1000, the sum of all the rates can't exceed 1000
  function setDaoRate(uint16 _rate) external;
  /// @notice Set the addresses and rate of their respective shares of the artist's profits / 1000
  /// @param _addresses Array of addresses that will receive a share of the artsit's profits, must be unique
  /// @param _rates Rates for each address, must be equal to 1000
  function setArtistProfitsSharing(address[] memory _addresses, uint16[] memory _rates) external;
  /// @notice Will send all the oracle tokens in the gachapon to the treasury address
  function withdrawOracleTokens() external;
  /// @dev Only use this when the oracle failed to answer for a request ID
  /// @dev NEVER USE OUTSIDE OF THIS SCENARIO
  function retryRound(bytes32) external;

  event ArtistRateChanged(uint16 _rate);
  event ArtistProfitsSharingChanged(address[] _addresses, uint16[] _rates);
  event TokenomicsRateChanged(uint16 _rate);
  event DaoRateChanged(uint16 _rate);
  event BanStatusChanged(bool _isBanned);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../gachapon/PrizePoolManager.sol";

/// @title Interface implemented by all gachapons created by the GachaponControlTower
/// @author KirienzoEth for DokiDoki
interface IGachapon {
  /// @dev Undefined = Round doesn't exist, Pending = waiting for oracle response, Unclaimed = oracle answered, Completed = Prizes were withdrawn
  enum RoundStatus { Undefined, Pending, Unclaimed, Completed, Cancelled }
  struct Round {
    bytes32 id; // request id.
    address player; // address of player.
    RoundStatus status; // status of the round.
    uint8 times; // how many times of this round;
    uint256[10] prizes; // Prizes obtained in this round.
  }

  /// @notice Get the state of a round
  function getRound(bytes32 _roundId) external returns (Round memory);
  /// @notice Get the token address of the currency used by this gachapon
  function currency() external returns (address);
  /// @notice Play the gachapon `_times` times
  function play(uint8 _times) external;
  /// @notice Claim the prizes won in a round
  function claimPrizes(bytes32 _roundId) external;
  /// @notice Transferring ownership also change the artist's address
  function transferOwnership(address _newOwner) external;
  /// @notice Get the nft at index `_index`
  function getNft(uint256 _index) external returns(PrizePoolManager.Nft memory);
  /// @notice Return the number of prizes that are still available
  function getRemaningPrizesAmount() external returns(uint256);

  /// @dev Player paid and oracle was contacted, refer to plays(_playId) to check if the prizes were distributed or not
  event RoundStarted(bytes32 indexed _requestId, address indexed _player, uint8 _times);
  /// @dev Oracle answered and the drawn prizes were stored, numbers in _prizes are indexes of the variable 'nfts'
  event RoundCompleted(bytes32 indexed _requestId, address indexed _player, uint8 _times, uint256[10] _prizes);
  /// @dev Oracle didn't answer and we need to try again
  event RoundCancelled(bytes32 _requestId);
  /// @dev Stored prizes were sent to the user
  event PrizesClaimed(bytes32 indexed _requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IGachapon.sol";

interface IGachaponFactory {
  /// @notice Deploy a new Gachapon contract and returns its address
  /// @dev Deployed gachapon will always implement the IGachapon interface
  function createGachapon(string memory _machineTitle, address _currency) external returns (IGachapon);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IOracleManager {
  /// @notice Get the oracle key hash
  function oracleKeyHash() external returns(bytes32);
  /// @notice Get how much a call tro the VRF oracle costs in WEI
  function oracleFee() external returns(uint256);
  /// @notice Get the oracle currency address
  function oracleToken() external returns(address);
  /// @notice Get the address of the VRF coordinator
  function oracleVRFCoordinator() external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ITreasuryManager {
  /// @notice Address of the wallet of the doki team funds
  function teamTreasuryAddress() external returns(address);
  /// @notice Address of the wallet of the DAO treasury
  function daoTreasuryAddress() external returns(address);
  /// @notice Address of the wallet managing buybacks\burns
  function tokenomicsManagerAddress() external returns(address);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}