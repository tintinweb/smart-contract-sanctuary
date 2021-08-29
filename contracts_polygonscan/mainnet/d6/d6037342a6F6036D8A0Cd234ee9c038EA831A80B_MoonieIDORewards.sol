/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/structs/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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


// File contracts/ethereum/MoonieIDORewards.sol


pragma solidity 0.8.4;




contract MoonieIDORewards is Ownable {
    IERC721Enumerable private _moonieNft;

    address[] private winners = [
        0x20aBC8fDeB737c921a20dB6dd7a8e9672747a490,
        0x295C383010aDb6A003a0532cbAd7a24034b811eF,
        0x9fc0F1B5da628372A876be4f53B55984a21d8b59,
        0xA6469F22Ce723BBf467759b2db4223f58a13B2e6,
        0xfEc58763fcd5Df39dD78a454a8304F41209fD1b8,
        0x14647514341497a167F1a5aC421cC845E1a8fB38,
        0x0B5381Bd292dA77e10132fD662215D4f142992E2,
        0xea24876090A92eB87F84d695bd0c1896a90C5847,
        0x73050f3368bFC79fD57F7FAE54dcB00cB9E68774,
        0x0E1a02DD01420fF1b6eCcACB4bC6b7F040C68528,
        0x0A370bA8F31D76766ABCB0D53abc1d7a6905c476,
        0xCf93e9bC892d0C85c20aad150220b12182777186,
        0x02bbF6e30eF9d2976e75E3a9948B2886cBdb264a,
        0xDD63764F29f11Cd8d495F938E34fD3521707989b,
        0x726a437dD5984F75599AA750f347F6d675b2E70c,
        0x48E4caedbD6da7D29745c35EaF8A65239bB49908,
        0xF5b78E0B2BF2bCC9079721872FaEe4D20b7e708e,
        0xB11de539F5dC9E628B1Bc67fC5F0f27C758562c0,
        0xd2782E7289E3BF11D4d0D74a2422694Ac0aCF3F4,
        0x70497AC11Ff3AbC0502B6C4471abc9f13DDE712a,
        0xe0B54aa5E28109F6Aa8bEdcff9622D61a75E6B83,
        0xE3AFafcABd0d9377C1eEC69356E4Ab32eb1f0Af6,
        0x3B82388aFF8A58Dc48A6eC1183BBA0e146158D1C,
        0x4c610Db504e83E993cDFFEa085B7F61f95B1aa5a,
        0xE161663eDFd3cbC26E237729eAb4fE88c193fCAe,
        0x1701723F0E9a7387e780EdB6E2411660553d37f2,
        0x11AAC794702C40938A740Bb514c93b0DC76eef4f,
        0xA289A97eBE80539c2F69414Bdd2935dDc7f0178A,
        0x47D56f4cD7cE98C4655Ccc9E109d20fCeC929B9e,
        0x93Ef9A1ff4DDB775f456fAEBc3fEe1E085D6EEfE,
        0x5F25A7372cEC2E1EF6724ca3D2e7C052F06A7c8c,
        0x2a2af08d1d828cebF5412853E122b60A64CD510F,
        0x01C144f3b7662a34bbF9B38BcD952D10202F8945,
        0x12CAFb982a462822d21C29152D6730E5bb8C3315,
        0x83389a63E1e648286C28eD0b2Cdb01593d3F70B4,
        0x529b965a0710A07AFAa6dD758c4005fc1901a3Ec,
        0xf47Ec7c789b52a82F5Ca312244ddafd1A91EE55C,
        0x358462f384Fdf46bB4632A8814d68278439624d6,
        0x678b6C168E0Bb3Af696dd467560FF2630BD53662,
        0x68e5F4183790805ac7D9D7346994b83b87a7d588,
        0x9Ab7A17025E0f429e1708c60F06b7cF83E165CCf,
        0xB347dD642E9b20Be829abD986a3c16D3e5Cf1FFc,
        0x505dd135f952b83228261752A328DA461F5b9A28,
        0x0315483c35d2c1EA9d5BE576b0F795Ae8CD0d4DE,
        0x0775867d9dFf549e3010C85E1366aF227B50C69F,
        0x14B3b7F4E7f9042411a1553e09b832F9bbEA1eE5,
        0xf1085d194e64b6446a533de4Fb537b873ae2bC06,
        0x5BcBC7792f92754031402bB50141ADEe5b0A6D6A,
        0xB899AAFd7B86d8adF7453fa9E1cd3e38572f10BD,
        0x12c2A7Ea09Fb9531f65229D93869284Ff8b22EB3,
        0x9BC7e714980e6C59544886a9203258c326A76DdB,
        0x4fbEde53b59D1a2Ab85F785ad76E1dcD66A1546A,
        0x6B9695bab373b5753D018F336A1B89eE27e89c9B,
        0x5CC8618d2e4Af89C3f69ACE85990bfccD939eBfE,
        0x4c1E900cb9083329fC930B9Eb8fdDc1905F197b5,
        0xBbb9eDbbb0864088f42Cf23235871bf6573118B5,
        0xdec2375ee602B5B990A0Db476A65A2df577F870B,
        0xB9324c02Ae29d6fD63A2c51fd6b402E042a445b2,
        0x768aA5B15B8f6514EF58C8FF7aaa8BcC16918697,
        0x3e765bF0C4125d064bA8da8440846cEDF0Eb4787,
        0x7d4385039aB7b776A6BeE1895c3f30639fD6e791,
        0xBdE1b08071421AAB08BbB3133097A589891c25F5,
        0xC32dBcD413f853610eE479C43A894828d127d0b2,
        0x398A52805EbE4Fc369ff940a5C65a813EE6CF06F,
        0x44813A2F433d4634B98A5501c29bf0Ef4FFDFC16,
        0x967d643E5e9F6F515ca515B7c63c18cf50806A3B,
        0x4dBEd5055bC2Ee7194f4bFB0Ab7E94231e9D4921,
        0xfA0dBF099166D190c82b2e58ca3e357CF697919d,
        0x18f6Da528A5fC7a1BA1C6C1E36284903Ed050Af0,
        0x4cb72456e82aeDd8b1ef0F08D03Cc6bFf96c6291,
        0x587C2FA9802D26628B54e994b73B7D9A0B072408,
        0xAf94Fe0769Cc2fcDDae4050C3a9f992E6aac63A7,
        0xa69E94B2d4f87309fcbb8c767E2e8654B71b53E6,
        0xD786f08272974D650a8Ac4b8b72b4eFfB558B8D4,
        0x5D9E720a1c16B98ab897165803C4D96E8060b8E4,
        0x4F17E2Fe0b2688636282884066f2CBc8b741a1A8,
        0x0b5BF868795f853d3DCBda02bc5468fb033AB6a0,
        0x3631F4735436fa043B3e6cFC34F075b4B6071646,
        0x53a67bc3E279b35Bb288E09d3D6C194cE802e398,
        0xeC358f8A5B5309d6Ba07f4b830E960Cef782Ab58,
        0x5b762f508E20F611BD877dB6a093b9e2E3757489,
        0x1bcef7C5211e1E2823E4083ca212371F92237eF9,
        0xAD5222897267AF4920ba210db2e3781C8B51AadE,
        0xC95141416EB8876f43AA6446B113fc6E8fBbe3e1,
        0x079A13288f70B52D927A345C004376c500414121,
        0xF0c8953df924FcC59E718A8D51B3baa29C0807b6,
        0x7EFB9007074BBe3047c607531e77D6eF840D8FD5,
        0xD31e15811507f9e6308A0d9DbB3b0aaA60D69c4f,
        0xb9E2D974b4d8234b7e8239e10aEe24D8a23D43a4,
        0x17d14B8c40301a72Ff55D81f86783E2061627Da0,
        0x2b266DCfc4f2ABfd4431c6633F5D4F53E7016022,
        0xC1fDD350EE6a242C468EaAF644d302188BbdbC5A,
        0xEa1B78c3A96E363A5E5645AcC26d918b78e45e4F,
        0xcd9BD96Ba7DA690eF222B7fdd6446C327Db0a8d4,
        0x2Ecf9904932Bb3D2A3A384742E5A33001A6e458C,
        0x48FDDcfb47b32da5fA724d5c028DC3c15EdC6525,
        0xe48e1fa5217e11387973B13c78BFa2C3eBf87646,
        0x1CB0845EE6b89AD7A82E26f89596cAEc6E8AB43e,
        0x840b4E751bd88d80CA3934Ff480672E054953447,
        0x858013142255cad3FD5137bDf4a7A40348Cb4D4a,
        0x89a7F0C7F8B601eCbC370356117a8FA3930c1Ac9,
        0x1C45F59Cc6aA20fDCe07126eDc3dc4fB1C3271C2,
        0x7Fb5257422994f0Ac71CFC9fcf2c309d477DD8aD,
        0xf17C55E0e902e89D4dbAD6Bd4e0f29D93bb6856b,
        0x60800e362277dCf15FaC04A95FD8E968B164664c,
        0x473da276DB7C097342B015aE60339e3462fC4375,
        0xA2Eb8615E851ceFC583D875794897362448d5989,
        0xD9470586e47b06F68DFb4df76B37044AA0CEBF22,
        0xe0E649B07532F000bF403e3b88BAAcF8fFA24450,
        0xB63D18845fc1Fc9a698e0F3D84812821beA33DAa,
        0xD710620f43801e3B9666a047BAaB1ddb1f4Cd460,
        0x74D2d10BfB961fE0ee3aD45784B504839eFc1CCF,
        0xF35898487FeF1E67bD0dE9Ce997b6F4f1bA0F74E,
        0xc4D7BdB232a95CC9D148F5aB8F045045de9Ec162,
        0xF41536Bb052EAA7ee0ae26ce7857cFC3Da45440A,
        0x791183498e62e0d7722497291cbAaB615A367577,
        0xa298c1d1e6e70B712ea9E450C0F6C24f339B632e,
        0xA51D2919ef13b7FBfD6a6b5a8C1D55D912A01d10,
        0x3EA82cEa86CCAE0Ff762516480e2e573b146AD73,
        0x229829F1662a45350DDf73282998Eac7bbb8FCfe
    ];

    uint256[] tokenIds = [
        6000,
        6001,
        6002,
        6003,
        6004,
        6005,
        6006,
        6007,
        6008,
        6009,
        6010,
        6011,
        6012,
        6013,
        6014,
        6015,
        6016,
        6017,
        6018,
        6019,
        6020,
        6021,
        6022,
        6023,
        6024,
        6025,
        6026,
        6027,
        6028,
        6029,
        6030,
        6031,
        6032,
        6033,
        6034,
        6035,
        6036,
        6037,
        6038,
        6039,
        6040,
        6041,
        6042,
        6043,
        6044,
        6045,
        6046,
        6047,
        6048,
        6049,
        6050,
        6051,
        6052,
        6053,
        6054,
        6055,
        6056,
        6057,
        6058,
        6059,
        6060,
        6061,
        6062,
        6063,
        6064,
        6065,
        6066,
        6067,
        6068,
        6069,
        6070,
        6071,
        6072,
        6073,
        6074,
        6075,
        6076,
        6077,
        6078,
        6079,
        6080,
        6081,
        6082,
        6083,
        6084,
        6085,
        6086,
        6087,
        6088,
        6089,
        6090,
        6091,
        6092,
        6093,
        6094,
        6095,
        6096,
        6097,
        6098,
        6099,
        6100,
        6101,
        6102,
        6103,
        6104,
        6105,
        6106,
        6107,
        6108,
        6109,
        6110,
        6111,
        6112,
        6113,
        6114,
        6115,
        6116,
        6117,
        6118,
        6119
    ];

    constructor(address moonieNft_) Ownable() {
        _moonieNft = IERC721Enumerable(moonieNft_);
    }

    function sendRewards() external onlyOwner {
        for (uint256 i = 0; i < 120; i++) {
            _moonieNft.safeTransferFrom(address(this), winners[i], tokenIds[i]);
        }
    }

    function withdraw(uint256 tokenId) external onlyOwner {
        _moonieNft.safeTransferFrom(address(this), owner(), tokenId);
    }
}