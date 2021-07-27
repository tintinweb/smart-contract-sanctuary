/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/solidity/contracts-v1/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/solidity/contracts-v1/Initializable.sol



pragma solidity >=0.4.24 <0.7.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    bool private initialized;

    /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
    bool private initializing;

    /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// File contracts/solidity/contracts-v1/Ownable.sol



pragma solidity 0.6.8;


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
contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initOwnable() internal virtual initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/solidity/contracts-v1/SafeMath.sol



pragma solidity 0.6.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/solidity/contracts-v1/Pausable.sol



pragma solidity 0.6.8;


contract Pausable is Ownable {
    mapping(uint256 => bool) isPaused;
    // 0 : createVault
    // 1 : mint
    // 2 : redeem
    // 3 : mintAndRedeem
    // 4 : migrateV1Tokens

    function onlyOwnerIfPaused(uint256 pauserId) public view virtual {
        require(!isPaused[pauserId] || msg.sender == owner(), "Paused");
    }

    function setPaused(uint256 pauserId, bool _isPaused)
        public
        virtual
        onlyOwner
    {
        isPaused[pauserId] = _isPaused;
    }
}


// File contracts/solidity/contracts-v1/IERC20.sol



pragma solidity 0.6.8;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/solidity/contracts-v1/IXToken.sol



pragma solidity 0.6.8;

interface IXToken is IERC20 {
    function owner() external returns (address);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function changeName(string calldata name) external;

    function changeSymbol(string calldata symbol) external;

    function setVaultAddress(address vaultAddress) external;

    function transferOwnership(address newOwner) external;
}


// File contracts/solidity/contracts-v1/IERC165.sol



pragma solidity ^0.6.0;

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


// File contracts/solidity/contracts-v1/IERC721.sol



pragma solidity ^0.6.2;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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


// File contracts/solidity/contracts-v1/ReentrancyGuard.sol



pragma solidity 0.6.8;

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
contract ReentrancyGuard is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the revault on every call to nonReentrant will be lower in
    // amount. Since revaults are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full revault coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function initReentrancyGuard() internal {
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

        // By storing the original value once again, a revault is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/solidity/contracts-v1/IERC721Receiver.sol



pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/solidity/contracts-v1/ERC721Holder.sol



pragma solidity ^0.6.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File contracts/solidity/contracts-v1/EnumerableSet.sol



pragma solidity 0.6.8;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(value)));
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint256(_at(set._inner, index)));
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}


// File contracts/solidity/contracts-v1/IXStore.sol



pragma solidity 0.6.8;






interface IXStore {
    struct FeeParams {
        uint256 ethBase;
        uint256 ethStep;
    }

    struct BountyParams {
        uint256 ethMax;
        uint256 length;
    }

    struct Vault {
        address xTokenAddress;
        address nftAddress;
        address manager;
        IXToken xToken;
        IERC721 nft;
        EnumerableSet.UintSet holdings;
        EnumerableSet.UintSet reserves;
        mapping(uint256 => address) requester;
        mapping(uint256 => bool) isEligible;
        mapping(uint256 => bool) shouldReserve;
        bool allowMintRequests;
        bool flipEligOnRedeem;
        bool negateEligibility;
        bool isFinalized;
        bool isClosed;
        FeeParams mintFees;
        FeeParams burnFees;
        FeeParams dualFees;
        BountyParams supplierBounty;
        uint256 ethBalance;
        uint256 tokenBalance;
        bool isD2Vault;
        address d2AssetAddress;
        IERC20 d2Asset;
        uint256 d2Holdings;
    }

    function isExtension(address addr) external view returns (bool);

    function randNonce() external view returns (uint256);

    function vaultsLength() external view returns (uint256);

    function xTokenAddress(uint256 vaultId) external view returns (address);

    function nftAddress(uint256 vaultId) external view returns (address);

    function manager(uint256 vaultId) external view returns (address);

    function xToken(uint256 vaultId) external view returns (IXToken);

    function nft(uint256 vaultId) external view returns (IERC721);

    function holdingsLength(uint256 vaultId) external view returns (uint256);

    function holdingsContains(uint256 vaultId, uint256 elem)
        external
        view
        returns (bool);

    function holdingsAt(uint256 vaultId, uint256 index)
        external
        view
        returns (uint256);

    function reservesLength(uint256 vaultId) external view returns (uint256);

    function reservesContains(uint256 vaultId, uint256 elem)
        external
        view
        returns (bool);

    function reservesAt(uint256 vaultId, uint256 index)
        external
        view
        returns (uint256);

    function requester(uint256 vaultId, uint256 id)
        external
        view
        returns (address);

    function isEligible(uint256 vaultId, uint256 id)
        external
        view
        returns (bool);

    function shouldReserve(uint256 vaultId, uint256 id)
        external
        view
        returns (bool);

    function allowMintRequests(uint256 vaultId) external view returns (bool);

    function flipEligOnRedeem(uint256 vaultId) external view returns (bool);

    function negateEligibility(uint256 vaultId) external view returns (bool);

    function isFinalized(uint256 vaultId) external view returns (bool);

    function isClosed(uint256 vaultId) external view returns (bool);

    function mintFees(uint256 vaultId) external view returns (uint256, uint256);

    function burnFees(uint256 vaultId) external view returns (uint256, uint256);

    function dualFees(uint256 vaultId) external view returns (uint256, uint256);

    function supplierBounty(uint256 vaultId)
        external
        view
        returns (uint256, uint256);

    function ethBalance(uint256 vaultId) external view returns (uint256);

    function tokenBalance(uint256 vaultId) external view returns (uint256);

    function isD2Vault(uint256 vaultId) external view returns (bool);

    function d2AssetAddress(uint256 vaultId) external view returns (address);

    function d2Asset(uint256 vaultId) external view returns (IERC20);

    function d2Holdings(uint256 vaultId) external view returns (uint256);

    function setXTokenAddress(uint256 vaultId, address _xTokenAddress) external;

    function setNftAddress(uint256 vaultId, address _assetAddress) external;

    function setManager(uint256 vaultId, address _manager) external;

    function setXToken(uint256 vaultId) external;

    function setNft(uint256 vaultId) external;

    function holdingsAdd(uint256 vaultId, uint256 elem) external;

    function holdingsRemove(uint256 vaultId, uint256 elem) external;

    function reservesAdd(uint256 vaultId, uint256 elem) external;

    function reservesRemove(uint256 vaultId, uint256 elem) external;

    function setRequester(uint256 vaultId, uint256 id, address _requester)
        external;

    function setIsEligible(uint256 vaultId, uint256 id, bool _bool) external;

    function setShouldReserve(uint256 vaultId, uint256 id, bool _shouldReserve)
        external;

    function setAllowMintRequests(uint256 vaultId, bool isAllowed) external;

    function setFlipEligOnRedeem(uint256 vaultId, bool flipElig) external;

    function setNegateEligibility(uint256 vaultId, bool negateElig) external;

    function setIsFinalized(uint256 vaultId, bool _isFinalized) external;

    function setIsClosed(uint256 vaultId, bool _isClosed) external;

    function setMintFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        external;

    function setBurnFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        external;

    function setDualFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        external;

    function setSupplierBounty(uint256 vaultId, uint256 ethMax, uint256 length)
        external;

    function setEthBalance(uint256 vaultId, uint256 _ethBalance) external;

    function setTokenBalance(uint256 vaultId, uint256 _tokenBalance) external;

    function setIsD2Vault(uint256 vaultId, bool _isD2Vault) external;

    function setD2AssetAddress(uint256 vaultId, address _assetAddress) external;

    function setD2Asset(uint256 vaultId) external;

    function setD2Holdings(uint256 vaultId, uint256 _d2Holdings) external;

    ////////////////////////////////////////////////////////////

    function setIsExtension(address addr, bool _isExtension) external;

    function setRandNonce(uint256 _randNonce) external;

    function addNewVault() external returns (uint256);
}


// File contracts/solidity/contracts-v1/Address.sol



pragma solidity 0.6.8;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive vaults via
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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


// File contracts/solidity/contracts-v1/SafeERC20.sol



pragma solidity 0.6.8;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value)
        internal
    {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value)
        internal
    {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value)
        internal
    {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IXTokenFactory {
  function createXToken(string calldata name, string calldata symbol) external returns (address);
  event NewXToken(address _xTokenAddress);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

interface KittyCore {
    function transfer(address _to, uint256 _tokenId) external;
}

interface KittyCoreAlt {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

pragma solidity 0.6.8;

contract NFTX is Pausable, ReentrancyGuard, ERC721Holder, IERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewVault(uint256 indexed vaultId, address sender);
    event Mint(
        uint256 indexed vaultId,
        uint256[] nftIds,
        uint256 d2Amount,
        address sender
    );
    event Redeem(
        uint256 indexed vaultId,
        uint256[] nftIds,
        uint256 d2Amount,
        address sender
    );
    event MintRequested(
        uint256 indexed vaultId,
        uint256[] nftIds,
        address sender
    );

    IXStore public store;

    mapping(uint256 => bool) public isVault1155;

    mapping(uint256 => uint256) public rangeStart;
    mapping(uint256 => uint256) public rangeEnd;

    function initialize(address storeAddress) public initializer {
        initOwnable();
        initReentrancyGuard();
        store = IXStore(storeAddress);
    }

    /* function onlyManager(uint256 vaultId) internal view {
        
    } */

    function onlyPrivileged(uint256 vaultId) internal view {
        if (store.isFinalized(vaultId)) {
            require(msg.sender == owner(), "Not owner");
        } else {
            require(msg.sender == store.manager(vaultId), "Not manager");
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        override
        view
        returns (bool)
    {}

    function isEligible(uint256 vaultId, uint256 nftId)
        public
        view
        virtual
        returns (bool)
    {
        if (rangeEnd[vaultId] > 0) {
            if (nftId >= rangeStart[vaultId] && nftId <= rangeEnd[vaultId]) {
                return true;
            }
        }
        return
            store.negateEligibility(vaultId)
                ? !store.isEligible(vaultId, nftId)
                : store.isEligible(vaultId, nftId);
    }

    function vaultSize(uint256 vaultId) public view virtual returns (uint256) {
        return
            store.isD2Vault(vaultId)
                ? store.d2Holdings(vaultId)
                : store.holdingsLength(vaultId);
                // Updated here to fix length bug.
    }

    function _getPseudoRand(uint256 modulus)
        internal
        virtual
        returns (uint256)
    {
        store.setRandNonce(store.randNonce().add(1));
        return
            uint256(
                keccak256(abi.encodePacked(now, msg.sender, store.randNonce()))
            ) %
            modulus;
    }

    function createVault(
        string memory name,
        string memory symbol,
        address _assetAddress,
        bool _isD2Vault
    ) public virtual nonReentrant returns (uint256) {
        onlyOwnerIfPaused(0);
        IXTokenFactory xTokenFactory = IXTokenFactory(
            0xE7ac17cE2550f3a0B4fE3616515975eb093CEfea
        );
        address xTokenAddress = xTokenFactory.createXToken(name, symbol);
        uint256 vaultId = store.addNewVault();
        store.setXTokenAddress(vaultId, xTokenAddress);
        store.setXToken(vaultId);
        if (!_isD2Vault) {
            store.setNftAddress(vaultId, _assetAddress);
            store.setNft(vaultId);
            store.setNegateEligibility(vaultId, true);
        } else {
            store.setD2AssetAddress(vaultId, _assetAddress);
            store.setD2Asset(vaultId);
            store.setIsD2Vault(vaultId, true);
        }
        store.setManager(vaultId, msg.sender);
        emit NewVault(vaultId, msg.sender);
        return vaultId;
    }

    // function depositETH(uint256 vaultId) public payable virtual {
    //     store.setEthBalance(vaultId, store.ethBalance(vaultId).add(msg.value));
    // }

    // function requestMint(uint256 vaultId, uint256[] memory nftIds)
    //     public
    //     payable
    //     virtual
    //     nonReentrant
    // {
    //     onlyOwnerIfPaused(1);
    //     require(store.allowMintRequests(vaultId), "1");
    //     for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
    //         if (vaultId > 6 && vaultId < 10) {
    //             KittyCoreAlt kittyCoreAlt =
    //                 KittyCoreAlt(store.nftAddress(vaultId));
    //             kittyCoreAlt.transferFrom(msg.sender, address(this), nftIds[i]);
    //         } else {
    //             store.nft(vaultId).safeTransferFrom(
    //                 msg.sender,
    //                 address(this),
    //                 nftIds[i]
    //             );
    //         }
    //         store.setRequester(vaultId, nftIds[i], msg.sender);
    //     }
    //     emit MintRequested(vaultId, nftIds, msg.sender);
    // }

    function revokeMintRequests(uint256 vaultId, uint256[] memory nftIds)
        public
        virtual
        nonReentrant
    {
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            require(
                store.requester(vaultId, nftIds[i]) == msg.sender,
                "Not requester"
            );
            store.setRequester(vaultId, nftIds[i], address(0));
            if (vaultId > 6 && vaultId < 10) {
                KittyCore kittyCore = KittyCore(store.nftAddress(vaultId));
                kittyCore.transfer(msg.sender, nftIds[i]);
            } else {
                store.nft(vaultId).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftIds[i]
                );
            }
        }
    }

    function approveMintRequest(uint256 vaultId, uint256[] memory nftIds)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            address requester = store.requester(vaultId, nftIds[i]);
            require(requester != address(0), "No request");
            require(
                store.nft(vaultId).ownerOf(nftIds[i]) == address(this),
                "Not owner"
            );
            store.setRequester(vaultId, nftIds[i], address(0));
            store.setIsEligible(vaultId, nftIds[i], true);
            store.holdingsAdd(vaultId, nftIds[i]);
            store.xToken(vaultId).mint(requester, 10**18);
        }
    }

   function _mint(uint256 vaultId, uint256[] memory nftIds, bool isDualOp)
        internal
        virtual
    {
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(isEligible(vaultId, nftId), "1");
            
            if (isVault1155[vaultId]) {
                IERC1155 nft = IERC1155(store.nftAddress(vaultId));
                nft.safeTransferFrom(msg.sender, address(this), nftId, 1, "");
            } else {
                require(
                    store.nft(vaultId).ownerOf(nftId) != address(this),
                    "2"
                );
                store.nft(vaultId).transferFrom(msg.sender, address(this), nftId);
                require(
                    store.nft(vaultId).ownerOf(nftId) == address(this),
                    "3"
                );
            }
            
            store.holdingsAdd(vaultId, nftId);
        }
        store.xToken(vaultId).mint(msg.sender, nftIds.length.mul(10**18));
    }

    function _mintD2(uint256 vaultId, uint256 amount)
        internal
        virtual
    {
        store.d2Asset(vaultId).safeTransferFrom(
            msg.sender,
            address(this),
            amount.mul(1000)
        );
        store.xToken(vaultId).mint(msg.sender, amount);
        store.setD2Holdings(
            vaultId,
            store.d2Holdings(vaultId).add(amount.mul(1000))
        );
    }

    function _redeem(uint256 vaultId, uint256 numNFTs, bool isDualOp)
        internal
        virtual
    {
        for (uint256 i = 0; i < numNFTs; i = i.add(1)) {
            uint256[] memory nftIds = new uint256[](1);
            uint256 rand = _getPseudoRand(store.holdingsLength(vaultId));
            nftIds[0] = store.holdingsAt(vaultId, rand);
            _redeemHelper(vaultId, nftIds, isDualOp);
            emit Redeem(vaultId, nftIds, 0, msg.sender);
        }
    }

    function _redeemD2(uint256 vaultId, uint256 amount)
        internal
        virtual
    {
        store.xToken(vaultId).burnFrom(msg.sender, amount);
        store.d2Asset(vaultId).safeTransfer(msg.sender, amount.mul(1000));
        store.setD2Holdings(
            vaultId,
            store.d2Holdings(vaultId).sub(amount.mul(1000))
        );
    }

    function _redeemHelper(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool isDualOp
    ) internal virtual {
        store.xToken(vaultId).burnFrom(msg.sender, nftIds.length.mul(10**18));
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(store.holdingsContains(vaultId, nftId), "1");
            if (store.holdingsContains(vaultId, nftId)) {
                store.holdingsRemove(vaultId, nftId);
            }
            if (store.flipEligOnRedeem(vaultId)) {
                bool isElig = store.isEligible(vaultId, nftId);
                store.setIsEligible(vaultId, nftId, !isElig);
            }
            if (isVault1155[vaultId]) {
                IERC1155 nft = IERC1155(store.nftAddress(vaultId));
                nft.safeTransferFrom(address(this), msg.sender, nftId, 1, "");
            } else if (vaultId > 6 && vaultId < 10) {
                KittyCore kittyCore = KittyCore(store.nftAddress(vaultId));
                kittyCore.transfer(msg.sender, nftId);
            } else {
                store.nft(vaultId).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftId
                );
            }
        }
    }

    function mint(uint256 vaultId, uint256[] memory nftIds, uint256 d2Amount)
        public
        payable
        virtual
        nonReentrant
    {
        onlyOwnerIfPaused(1);
        if (store.isD2Vault(vaultId)) {
            _mintD2(vaultId, d2Amount);
        } else {
            _mint(vaultId, nftIds, false);
        }
        emit Mint(vaultId, nftIds, d2Amount, msg.sender);
    }

    function redeem(uint256 vaultId, uint256 amount)
        public
        payable
        virtual
        nonReentrant
    {
        onlyOwnerIfPaused(2);
        if (!store.isD2Vault(vaultId)) {
            _redeem(vaultId, amount, false);
        } else {
            _redeemD2(vaultId, amount);
        }
    }
    
    function setIsEligible(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool _boolean
    ) public virtual {
        onlyPrivileged(vaultId);
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            store.setIsEligible(vaultId, nftIds[i], _boolean);
        }
    }

    function setNegateEligibility(uint256 vaultId, bool shouldNegate)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        require(
            store
                .holdingsLength(vaultId)
                .add(store.d2Holdings(vaultId)) ==
                0,
            "1"
        );
        store.setNegateEligibility(vaultId, shouldNegate);
    }
    
    function setIs1155(
        uint256 vaultId,
        bool _boolean
    ) public virtual {
        onlyPrivileged(vaultId);
        isVault1155[vaultId] = _boolean;
    }

    // function setAllowMintRequests(uint256 vaultId, bool isAllowed)
    //     public
    //     virtual
    // {
    //     onlyPrivileged(vaultId);
    //     store.setAllowMintRequests(vaultId, isAllowed);
    // }

    function setFlipEligOnRedeem(uint256 vaultId, bool flipElig)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        store.setFlipEligOnRedeem(vaultId, flipElig);
    }

    function setManager(uint256 vaultId, address newManager) public virtual {
        onlyPrivileged(vaultId);
        store.setManager(vaultId, newManager);
    }

    function finalizeVault(uint256 vaultId) public virtual {
        onlyPrivileged(vaultId);
        if (!store.isFinalized(vaultId)) {
            store.setIsFinalized(vaultId, true);
        }
    }

    function closeVault(uint256 vaultId) public virtual {
        onlyPrivileged(vaultId);
        if (!store.isFinalized(vaultId)) {
            store.setIsFinalized(vaultId, true);
        }
        store.setIsClosed(vaultId, true);
    }
}

interface INFTXVaultFactory {
  // Read functions.
  function numVaults() external view returns (uint256);
  function zapContract() external view returns (address);
  function feeDistributor() external view returns (address);
  function eligibilityManager() external view returns (address);
  function vault(uint256 vaultId) external view returns (address);
  function vaultsForAsset(address asset) external view returns (address[] memory);
}

interface INFTXVault {
    function assetAddress() external returns (address);
    function vaultFactory() external returns (address);
    function eligibilityStorage() external returns (address);

    function is1155() external returns (bool);
    function allowAllItems() external returns (bool);

    function vaultId() external returns (uint256);
    function mintFee() external returns (uint256);
    function randomRedeemFee() external returns (uint256);
    function targetRedeemFee() external returns (uint256);

    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function redeem(uint256 amount, uint256[] calldata specificIds)
        external
        returns (uint256[] memory);
}

interface WrappedPunks {
    function burn(uint256 punkIndex) external;
}

contract NFTXv12Migration is NFTX {

    // v1 ID -> v2 Vault
    mapping(uint256 => address) public migrationPair;
    mapping(uint256 => bool) public isFullyMigrated;

    function migrateVaultToV2(uint256 v1VaultId, uint256 v2VaultId, uint256 count) external onlyOwner {
        // Safeguards.
        if (v1VaultId == 3) {
            revert("Migration not allowed");
        }
        uint256 totalHoldings = store.holdingsLength(v1VaultId);
        require(totalHoldings > 0, "Empty vault");
        require(count != 0, "Count cannot be 0");
        if (count > totalHoldings) {
            count = totalHoldings;
        }

        // Make sure we're not overriding an existing migration.
        address v2Vault = INFTXVaultFactory(0xBE86f647b167567525cCAAfcd6f881F1Ee558216).vault(v2VaultId);
        address v2Addr = migrationPair[v1VaultId];
        require(v2Addr == address(0) || v2Addr == v2Vault, "Cannot overwrite migration pair");

        // Approveand migrate the assets.
        address assetAddr = INFTXVault(v2Vault).assetAddress();
        uint256[] memory ids = new uint256[](count);
        uint256[] memory amounts = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = store.holdingsAt(v1VaultId, i);
            ids[i] = tokenId;
            amounts[i] = 1;
            approveERC721(assetAddr, v2Vault, tokenId);
        }
        for (uint256 i = 0; i < ids.length; i++) {
            store.holdingsRemove(v1VaultId, ids[i]);
        }
        uint256 v2BalBefore = IERC20(v2Vault).balanceOf(address(this));
        INFTXVault(v2Vault).mint(ids, amounts);

        // Ensure we got the right amount back.
        uint256 v2BalAfter = IERC20(v2Vault).balanceOf(address(this));
        require(v2BalAfter-v2BalBefore == count * 10**18, "Received less than expected v2");
        migrationPair[v1VaultId] = v2Vault;
        if (store.holdingsLength(v1VaultId) == 0) {
            isFullyMigrated[v1VaultId] = true;
        }
    }

    function targetRedeem(uint256 v1VaultId, uint256[] calldata specificIds) external onlyOwner {
        _redeemHelper(v1VaultId, specificIds, false);
        emit Redeem(v1VaultId, specificIds, 0, msg.sender);
    }

    function targetWithdraw(uint256 v1VaultId, uint256[] calldata specificIds) external onlyOwner {
        for (uint256 i = 0; i < specificIds.length; i = i.add(1)) {
            uint256 nftId = specificIds[i];
            require(store.holdingsContains(v1VaultId, nftId), "1");
            if (store.holdingsContains(v1VaultId, nftId)) {
                store.holdingsRemove(v1VaultId, nftId);
            }
            if (v1VaultId > 6 && v1VaultId < 10) {
                KittyCore kittyCore = KittyCore(store.nftAddress(v1VaultId));
                kittyCore.transfer(msg.sender, nftId);
            } else {
                store.nft(v1VaultId).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftId
                );
            }
        }
    }

    function forceMigrationComplete(uint256 v1VaultId) external onlyOwner {
        isFullyMigrated[v1VaultId] = true;
    }

    function migrateV1Tokens(uint256 v1VaultId) external {
        onlyOwnerIfPaused(4);
        require(isFullyMigrated[v1VaultId], "This vault has not been migrated");
        IXToken xToken = store.xToken(v1VaultId);
        uint256 bal = xToken.balanceOf(msg.sender);
        require(bal > 0, "0");
        xToken.burnFrom(msg.sender, bal);
        IERC20 v2Token = IERC20(migrationPair[v1VaultId]);
        v2Token.transfer(msg.sender, bal);
    }

    function approveERC721(address assetAddr, address to, uint256 tokenId) internal virtual {
        address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
        address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
        // unwrap punks
        bytes memory data;
        if (assetAddr == kitties) {
            // Cryptokitties.
            data = abi.encodeWithSignature("approve(address,uint256)", to, tokenId);
        } else if (assetAddr == punks) {
            // Burn the wrapped punk.
            WrappedPunks(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).burn(tokenId);
            // CryptoPunks.
            data = abi.encodeWithSignature("offerPunkForSaleToAddress(uint256,uint256,address)", tokenId, 0, to);
        } else {
            if (IERC721(assetAddr).isApprovedForAll(address(this), to)) {
                return;
            }
            // Default.
            data = abi.encodeWithSignature("setApprovalForAll(address,bool)", to, true);
        }
        (bool success, bytes memory resultData) = address(assetAddr).call(data);
        require(success, string(resultData));
    }
}