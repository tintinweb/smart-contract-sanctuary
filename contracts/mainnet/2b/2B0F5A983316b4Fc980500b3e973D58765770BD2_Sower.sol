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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEarlyBirdRegistry
/// @author Simon Fremaux (@dievardump)
interface IEarlyBirdRegistry {
    /// @notice allows anyone to register a new project that accepts Early Birds registrations
    /// @param open if the early bird registration is open or only creator can register addresses
    /// @param endRegistration unix epoch timestamp of registration closing
    /// @param maxRegistration the max registration count
    /// @return projectId the project Id (useful if called by a contract)
    function registerProject(
        bool open,
        uint256 endRegistration,
        uint256 maxRegistration
    ) external returns (uint256 projectId);

    /// @notice tells if a project exists
    /// @param projectId project id to check
    /// @return if the project exists
    function exists(uint256 projectId) external view returns (bool);

    /// @notice Helper to paginate all address registered for a project
    /// @param projectId the project id
    /// @param offset index where to start
    /// @param limit how many to grab
    /// @return list of registered addresses
    function listRegistrations(
        uint256 projectId,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory list);

    /// @notice Helper to know how many address registered to a project
    /// @param projectId the project id
    /// @return how many people registered
    function registeredCount(uint256 projectId) external view returns (uint256);

    /// @notice Helper to check if an address is registered for a project id
    /// @param check the address to check
    /// @param projectId the project id
    /// @return if the address was registered as an early bird
    function isRegistered(address check, uint256 projectId)
        external
        view
        returns (bool);

    /// @notice Allows a project creator to add early birds in Batch
    /// @dev msg.sender must be the projectId creator
    /// @param projectId to add to
    /// @param birds all addresses to add
    function registerBatchTo(uint256 projectId, address[] memory birds)
        external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@%,,,,,,,@#,@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/%,,**,***,*,,,*(#@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*%*,,**********,,/%%@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@*,************,/@(@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@(,**,********,/@/@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,%,,**********,,#*@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.%,,*********,*&(@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&*(#(,,******,,,,,&/@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,&@#,,,*****,***,*%,@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,(***,******************,%&&/&@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@*,**************************,/&(#@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@,%*******************************,*,#,/@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@#&***************************************#%*#@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@*&*******************************************/%(%%%((@
// @@@@@@@@@@@@@@@@@@@@@@@@ %*****************************************************#
// @@@@@@@@@@@@@@@@@@@@@&(%*************************************/&@(***************
// @@@@@@@@@@@@@@@@@@@#%%/***********%(#************************(//(((************#
// @@@@@@@@@@@@@@@@@@/(************@#&&#/***************************************//%
// @@@@@@@@@@@@@@@@#@**********&###@@@@&#&*************************************#/@@
// @@@@@@@@@@@@@@/%**********,%%@@@@@@@@*&************************************/#&@@
// @@@@@@@@@@@@%#/********/(#@@@@@@@@@@@@@(@%********************************&,@@@@
// @@@@@%#%####*********#(#@@@@@@@@@@@@@@@#@(******************************%&#@@@@@
// @@(@%/************@#@@@@@@@@@@@@@@@@@@@%@********************&*******@%,@@@@@@@@
// @/&//*////////*(@/@@@@@@@@@@@@@@@@@@@@&#/*////////////////**@%%(///%@@@@@@@@@@@@
// %(&/////////**%(&@@@@@@@@@@@@@@@@@@@@@(#//////////////////*/@*@@@@@@@@@@@@@@@@@@
// @@@*@@*//*#@&#@@@@@@@@@@@@@@@@@@@@@@@*@#*/////////////////*%@/@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#///////////////////%(%@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/%///////////////////@##@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#///////////////////(@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#///////////////////%,@@@@@@@@@@@@@@@@
// @@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(&#////////////////////@/@@@@@@@@@@@@@@@
// @@@,@@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@*&//////////////////////&%@@@@@@@@@@@@@@
// @@@@,@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#&//////////////////////(&(@@@@@@@@@@@@@@
// @@@@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@*///////////////////////%/#@@@@@@@@@@
// @@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@(/////////////////////////&&&@@@@@@@@@
// @@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@(////////////%%/////////////%(@@@@@@@@@
// @@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#(/////////////&/@#////////////(&*@@@@@@@@
// @@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@(((((((((((//#%&@#&/((((((((((((&*@@@@@@@@
// @@@@,@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@%@((((((((((((#(%@@@@(@((((((((((((&/@@@@@@@@
// @@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##((((((((((((&&@@@@#&@((((((((((((&,@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@%(((((((((((&/@@@@@@@(@((((((((((((&@&@@@@@@@
// @@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@%(#(#########(%%@@@@@@@@@#&(#########(&@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%###########@%%@@@@@@@@@/@%##########&/@@@@@@@@
// @@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@/&##########%&#@@@@@@@@@@@/@%###########@#@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%%%%%%%%%%@#@@@@@@@@@@@@@&%%%%%%%%%%%%@@#@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&%&%%%%%%%%%%&&#@@@@@@@@@@@@@@&@%%%%%%%%%%%@%@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@/@%%%%%%%%%%%%@#@@@@@@@@@@@@@@%@%%%%%%%%%%%&%@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@/@%%%%%%%%%%%%%&@/%@@@@@@@@@@@@@%%%%%%%%%%%%%@#@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@%&%%%%%%%%%%%@@&@@@@@@@@@%%%%%%%%%%%%%%%&@@#(
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&%%%%%%%%%%&&%@@@@@@&@%%%%%%%%%%%%%%%%%%%%
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##%#@@@@#@@@@@@@@@@@@@@@@@@@#%%%%%%%%%%%

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './Variety/IVariety.sol';
import './EarlyBirdRegistry/IEarlyBirdRegistry.sol';

/// @title Sower
/// @author Simon Fremaux (@dievardump)
contract Sower is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    event Collected(
        address indexed operator,
        address indexed variety,
        uint256 indexed count,
        uint256 value
    );

    event EarlyBirdSessionAdded(uint256 sessionId, uint256 projectId);
    event EarlyBirdSessionRemoved(uint256 sessionId, uint256 projectId);

    event VarietyAdded(address variety);
    event VarietyChanged(address variety);
    event VarietyEmpty(address variety);

    event DonationRecipientAdded(address recipient);
    event DonationRecipientRemoved(address recipient);

    struct VarietyData {
        uint8 maxPerCollect; // how many can be collected at once. 0 == no limit
        bool active; // if Variety is active or not
        bool curated; // curated Varieties can only be minted by Variety creator
        address location; // address of the Variety contract
        address creator; // creator of the variety (in case the contract opens to more creators)
        uint256 price; // price of collecting
        uint256 available; // how many are available
        uint256 reserve; // how many are reserve for creator
        uint256 earlyBirdUntil; // earlyBird limit timestamp
        uint256 earlyBirdSessionId; // earlyBirdSessionId
    }

    // main donation, we start with nfDAO
    address public mainDonation = 0x37133cda1941449cde7128f0C964C228F94844a8;

    // Varieties list
    mapping(address => VarietyData) public varieties;

    // list of known varieties address
    EnumerableSet.AddressSet internal knownVarieties;

    // list of address to whom I would like to donate
    EnumerableSet.AddressSet internal donations;

    // last generated seed
    bytes32 public lastSeed;

    // address who used their EarlyBird access
    mapping(uint256 => mapping(address => bool)) internal _earlyBirdsConsumed;

    // the early bird registry
    address public earlyBirdRegistry;

    // because I messed up the EarlyBird registration before the launch
    // I have to use EarlyBirdSession containing one or more EarlyBirgProjectID.
    mapping(uint256 => EnumerableSet.UintSet) internal earlyBirdSessions;

    constructor() {
        // Gitcoin Gnosis
        _addDonationRecipient(0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6);

        // WOCA
        _addDonationRecipient(0xCCa88b952976DA313Fb928111f2D5c390eE0D723);

        // Hardhat deploy / Jolly Roger
        _addDonationRecipient(0xF0D7a8198D75e10517f035CF11b928e9E2aB20f4);
    }

    /// @notice Allows collector to collect up to varietyData.maxPerCollect tokens from variety.
    /// @param count the number of tokens to collect
    /// @param variety the variety to collect from
    function plant(uint256 count, address variety)
        external
        payable
        nonReentrant
    {
        require(count > 0, '!count');

        VarietyData storage varietyData = _getVariety(variety);

        // curated varieties have to be created in a specific way, with the seed, only by creator
        require(varietyData.curated == false, "Can't plant this Variety.");

        // varieties can be paused or out of stock
        require(varietyData.active == true, 'Variety paused or out of seeds.');

        // if we are in an earlyBird phase
        if (varietyData.earlyBirdUntil >= block.timestamp) {
            require(
                isUserInEarlyBirdSession(
                    msg.sender,
                    varietyData.earlyBirdSessionId
                ),
                'Not registered for EarlyBirds'
            );

            require(
                _earlyBirdsConsumed[varietyData.earlyBirdSessionId][
                    msg.sender
                ] == false,
                'Already used your EarlyBird'
            );

            // set early bird as consumed
            _earlyBirdsConsumed[varietyData.earlyBirdSessionId][
                msg.sender
            ] = true;

            require(count == 1, 'Early bird can only grab one');
        }

        require(
            // verifies that there are enough tokens available for this variety
            (varietyData.available - varietyData.reserve) >= count &&
                // and that the user doesn't request more than what is allowed in one tx
                (varietyData.maxPerCollect == 0 ||
                    uint256(varietyData.maxPerCollect) >= count),
            'Too many requested.'
        );

        address operator = msg.sender;

        require(msg.value == varietyData.price * count, 'Value error.');

        _plant(varietyData, count, operator);
    }

    /// @notice Owner function to be able to get varieties from the reserve
    /// @param count how many the owner wants
    /// @param variety from what variety
    /// @param recipient might be a giveaway? recipient can be someone else than owner
    function plantFromReserve(
        uint256 count,
        address variety,
        address recipient
    ) external {
        require(count > 0, '!count');

        VarietyData storage varietyData = _getVariety(variety);

        // curated varieties have to be created in a specific way, with the seed, only by creator
        require(varietyData.curated == false, "Can't plant this Variety.");

        // verify that caller is the variety creator
        // or there is no variety creator and the caller is current owner
        require(
            msg.sender == varietyData.creator ||
                (varietyData.creator == address(0) && msg.sender == owner()),
            'Not Variety creator.'
        );

        require(
            varietyData.reserve >= count && varietyData.available >= count,
            'Not enough reserve.'
        );

        varietyData.reserve -= count;

        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        _plant(varietyData, count, recipient);
    }

    /// @notice Some Varieties can not generate aesthetic output with random seeds.
    ///         Those are "curated Varieties" that only the creator can mint from with curated seeds
    ///         The resulting Seedlings will probably be gifted or sold directly on Marketplaces
    ///         (direct sale or auction)
    /// @param variety the variety to create from
    /// @param recipient the recipient of the creation
    /// @param seeds the seeds to create
    function plantFromCurated(
        address variety,
        address recipient,
        bytes32[] memory seeds
    ) external {
        require(seeds.length > 0, '!count');

        VarietyData storage varietyData = _getVariety(variety);

        // verify this variety is indeed a curated one
        require(varietyData.curated == true, 'Variety not curated.');

        // verify that caller is the variety creator
        // or there is no variety creator and the caller is current owner
        require(
            msg.sender == varietyData.creator ||
                (varietyData.creator == address(0) && msg.sender == owner()),
            'Not Variety creator.'
        );

        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        _plantSeeds(varietyData, recipient, seeds);
    }

    /// @notice Helper to list all Varieties
    /// @return list of varieties
    function listVarieties() external view returns (VarietyData[] memory list) {
        uint256 count = knownVarieties.length();
        list = new VarietyData[](count);
        for (uint256 i; i < count; i++) {
            list[i] = varieties[knownVarieties.at(i)];
        }
    }

    /// @notice Adds a new variety to the list
    /// @param newVariety the variety to be added
    /// @param price the collection cost
    /// @param maxPerCollect how many can be collected at once; 0 == no limit
    /// @param active if the variety is active or not
    /// @param creator variety creator
    /// @param available variety supply
    /// @param reserve variety reserve for variety creator
    /// @param curated if the variety is curated; if yes only creator can mint from it
    function addVariety(
        address newVariety,
        uint256 price,
        uint8 maxPerCollect,
        bool active,
        address creator,
        uint256 available,
        uint256 reserve,
        bool curated
    ) external onlyOwner {
        require(
            !knownVarieties.contains(newVariety),
            'Variety already exists.'
        );
        knownVarieties.add(newVariety);

        varieties[newVariety] = VarietyData({
            maxPerCollect: maxPerCollect,
            price: price,
            active: active,
            creator: creator,
            location: newVariety,
            available: available,
            reserve: reserve,
            curated: curated,
            earlyBirdUntil: 0,
            earlyBirdSessionId: 0
        });

        emit VarietyAdded(newVariety);
    }

    /// @notice Allows to toggle a variety active state
    /// @param variety the variety address
    /// @param isActive if active or not
    function setActive(address variety, bool isActive) public onlyOwner {
        VarietyData storage varietyData = _getVariety(variety);
        require(
            !isActive || varietyData.available > 0,
            "Can't activate empty variety."
        );
        varietyData.active = isActive;
        emit VarietyChanged(variety);
    }

    /// @notice Allows to change the max per collect for a variety
    /// @param variety the variety address
    /// @param maxPerCollect new max per collect
    function setMaxPerCollect(address variety, uint8 maxPerCollect)
        external
        onlyOwner
    {
        VarietyData storage varietyData = _getVariety(variety);
        varietyData.maxPerCollect = maxPerCollect;
        emit VarietyChanged(variety);
    }

    /// @notice activate EarlyBird for a Variety.
    ///         When earlyBird, only registered address can plant
    /// @param varieties_ the varieties address
    /// @param earlyBirdDuration duration of Early Bird from now on
    /// @param earlyBirdSessionId the session id containing projects to check on the EarlyBirdRegistry
    /// @param activateVariety if the variety must be automatically activated (meaning early bird starts now)
    function activateEarlyBird(
        address[] memory varieties_,
        uint256 earlyBirdDuration,
        uint256 earlyBirdSessionId,
        bool activateVariety
    ) external onlyOwner {
        require(
            earlyBirdSessions[earlyBirdSessionId].length() > 0,
            'Session id empty'
        );

        for (uint256 i; i < varieties_.length; i++) {
            VarietyData storage varietyData = _getVariety(varieties_[i]);
            varietyData.earlyBirdUntil = block.timestamp + earlyBirdDuration;
            varietyData.earlyBirdSessionId = earlyBirdSessionId;

            if (activateVariety) {
                setActive(varieties_[i], true);
            } else {
                emit VarietyChanged(varieties_[i]);
            }
        }
    }

    /// @notice sets early bird registry
    /// @param earlyBirdRegistry_ the registry
    function setEarlyBirdRegistry(address earlyBirdRegistry_)
        external
        onlyOwner
    {
        require(earlyBirdRegistry_ != address(0), 'Wrong address.');
        earlyBirdRegistry = earlyBirdRegistry_;
    }

    /// @notice Allows to add an early bird project id to an "early bird session"
    /// @dev an early bird session is a group of early bird registrations projects
    /// @param sessionId the session to add to
    /// @param projectIds the projectIds (containing registration in EarlyBirdRegistry) to add
    function addEarlyBirdProjectToSession(
        uint256 sessionId,
        uint256[] memory projectIds
    ) external onlyOwner {
        require(sessionId > 0, "Session can't be 0");
        for (uint256 i; i < projectIds.length; i++) {
            require(
                IEarlyBirdRegistry(earlyBirdRegistry).exists(projectIds[i]),
                'Unknown early bird project'
            );
            earlyBirdSessions[sessionId].add(projectIds[i]);
            emit EarlyBirdSessionAdded(sessionId, projectIds[i]);
        }
    }

    /// @notice Allows to remove an early bird project id from an "early bird session"
    /// @dev an early bird session is a group of early bird registrations projects
    /// @param sessionId the session to remove from
    /// @param projectIds the projectIds (containing registration in EarlyBirdRegistry) to remove
    function removeEarlyBirdProjectFromSession(
        uint256 sessionId,
        uint256[] memory projectIds
    ) external onlyOwner {
        require(sessionId > 0, "Session can't be 0");

        for (uint256 i; i < projectIds.length; i++) {
            earlyBirdSessions[sessionId].remove(projectIds[i]);
            emit EarlyBirdSessionRemoved(sessionId, projectIds[i]);
        }
    }

    /// @notice Helper to know if a user is in any of the early bird list for current session
    /// @param user the user to test
    /// @param sessionId the session to test for
    /// @return if the user is registered or not
    function isUserInEarlyBirdSession(address user, uint256 sessionId)
        public
        view
        returns (bool)
    {
        // get all earlyBirdIds attached to the earlyBirdSession
        EnumerableSet.UintSet storage session = earlyBirdSessions[sessionId];
        uint256 count = session.length();

        for (uint256 i; i < count; i++) {
            // if the address is registered to any of those projectId
            if (
                IEarlyBirdRegistry(earlyBirdRegistry).isRegistered(
                    user,
                    session.at(i)
                )
            ) {
                return true;
            }
        }

        // else it's not an early bird
        return false;
    }

    /// @notice Helper to list all donation recipients
    /// @return list of donation recipients
    function listDonations() external view returns (address[] memory list) {
        uint256 count = donations.length();
        list = new address[](count);
        for (uint256 i; i < count; i++) {
            list[i] = donations.at(i);
        }
    }

    /// @notice Allows to add a donation recipient
    /// @param recipient the recipient
    function addDonationRecipient(address recipient) external onlyOwner {
        _addDonationRecipient(recipient);
    }

    /// @notice Allows to remove a donation recipient
    /// @param recipient the recipient
    function removeDonationRecipient(address recipient) external onlyOwner {
        _removeDonationRecipient(recipient);
    }

    /// @notice Set mainDonation donation address
    /// @param newMainDonation the new address
    function setNewMainDonation(address newMainDonation) external onlyOwner {
        mainDonation = newMainDonation;
    }

    /// @notice This function allows Sower to answer to a seed change request
    ///         in the event where a seed would produce errors of rendering
    ///         1) this function can only be called by Sower if the token owner
    ///         asked for a new seed (see Variety contract)
    ///         2) this function will only be called if there is a rendering error
    /// @param tokenId the tokenId that needs update
    function updateTokenSeed(address variety, uint256 tokenId)
        external
        onlyOwner
    {
        require(knownVarieties.contains(variety), 'Unknown variety.');
        IVariety(variety).changeSeedAfterRequest(tokenId);
    }

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "I don't think so.");

        uint256 count = donations.length();

        // forces mainDonation and donations to not be empty
        // Code is law.
        require(
            mainDonation != address(0) && count > 0,
            'You have to give in order to get.'
        );

        bool success;

        // 10% of current balance
        uint256 ten = address(this).balance / 10;

        // send 10% to mainDonation address
        (success, ) = mainDonation.call{value: ten}('');
        require(success, '!success');

        // share 10% between all other donation recipients
        uint256 parts = ten / count;
        for (uint256 i; i < count; i++) {
            (success, ) = donations.at(i).call{value: parts}('');
            require(success, '!success');
        }

        // send the rest to sender; use call since it might be a contract someday
        (success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, '!success');
    }

    /// @dev Receive function for royalties
    receive() external payable {}

    /// @dev Internal collection method
    /// @param varietyData the varietyData
    /// @param count how many to collect
    /// @param operator Seedlings recipient
    function _plant(
        VarietyData storage varietyData,
        uint256 count,
        address operator
    ) internal {
        bytes32 seed = lastSeed;
        bytes32[] memory seeds = new bytes32[](count);
        bytes32 blockHash = blockhash(block.number - 1);
        uint256 timestamp = block.timestamp;

        // generate next seeds
        for (uint256 i; i < count; i++) {
            seed = _nextSeed(seed, timestamp, operator, blockHash);
            seeds[i] = seed;
        }

        // saves lastSeed before planting
        lastSeed = seed;

        _plantSeeds(varietyData, operator, seeds);
    }

    /// @dev Allows to plant a list of seeds
    /// @param varietyData the variety data
    /// @param collector the recipient of the Seedling
    /// @param seeds the seeds to plant
    function _plantSeeds(
        VarietyData storage varietyData,
        address collector,
        bytes32[] memory seeds
    ) internal {
        IVariety(varietyData.location).plant(collector, seeds);
        uint256 count = seeds.length;

        varietyData.available -= count;
        if (varietyData.available == 0) {
            varietyData.active = false;
            emit VarietyEmpty(varietyData.location);
        }

        emit Collected(collector, varietyData.location, count, msg.value);

        // if Variety has a creator that is not contract owner, send them the value directly
        if (
            varietyData.creator != address(0) &&
            msg.value > 0 &&
            varietyData.creator != owner()
        ) {
            (bool success, ) = varietyData.creator.call{value: msg.value}('');
            require(success, '!success');
        }
    }

    /// @dev Calculate next seed using a few on chain data
    /// @param currentSeed the current seed
    /// @param timestamp current block timestamp
    /// @param operator current operator
    /// @param blockHash last block hash
    /// @return a new bytes32 seed
    function _nextSeed(
        bytes32 currentSeed,
        uint256 timestamp,
        address operator,
        bytes32 blockHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    currentSeed,
                    timestamp,
                    operator,
                    blockHash,
                    block.coinbase,
                    block.difficulty,
                    tx.gasprice
                )
            );
    }

    /// @notice Returns a variety, throws if does not exist
    /// @param variety the variety to get
    function _getVariety(address variety)
        internal
        view
        returns (VarietyData storage)
    {
        require(knownVarieties.contains(variety), 'Unknown variety.');
        return varieties[variety];
    }

    /// @dev Allows to add a donation recipient to the list of donations
    /// @param recipient the recipient
    function _addDonationRecipient(address recipient) internal {
        donations.add(recipient);
        emit DonationRecipientAdded(recipient);
    }

    /// @dev Allows to remove a donation recipient from the list of donations
    /// @param recipient the recipient
    function _removeDonationRecipient(address recipient) internal {
        donations.remove(recipient);
        emit DonationRecipientRemoved(recipient);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title IVariety interface
/// @author Simon Fremaux (@dievardump)
interface IVariety is IERC721 {
    /// @notice mint `seeds.length` token(s) to `to` using `seeds`
    /// @param to token recipient
    /// @param seeds each token seed
    function plant(address to, bytes32[] memory seeds)
        external
        returns (uint256);

    /// @notice this function returns the seed associated to a tokenId
    /// @param tokenId to get the seed of
    function getTokenSeed(uint256 tokenId) external view returns (bytes32);

    /// @notice This function allows an owner to ask for a seed update
    ///         this can be needed because although I test the contract as much as possible,
    ///         it might be possible that one token does not render because the seed creates
    ///         error or even "out of gas" computation. That's why this would allow an owner
    ///         in such case, to request for a seed change that will then be triggered by Sower
    /// @param tokenId id to regenerate seed for
    function requestSeedChange(uint256 tokenId) external;

    /// @notice This function allows Sower to answer to a seed change request
    ///         in the event where a seed would produce errors of rendering
    ///         1) this function can only be called by Sower if the token owner
    ///         asked for a new seed
    ///         2) this function will only be called if there is a rendering error
    ///         or, Vitalik Buterin forbid, a duplicate
    /// @param tokenId id to regenerate seed for
    function changeSeedAfterRequest(uint256 tokenId) external;
}

