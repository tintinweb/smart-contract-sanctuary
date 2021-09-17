/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol

pragma solidity ^0.8.4;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File: @openzeppelin/contracts/utils/Context.sol

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
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/finance/PaymentSplitter.sol




/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}



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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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


// File: @openzeppelin/contracts/access/Ownable.sol



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


// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// File: @openzeppelin/contracts/token/ERC721/ERC721.sol




// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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




// File: @openzeppelin/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}



// File: llamas.sol


contract LLamasNFT is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  // Max limit of existing tokens
  uint256 public constant TOKEN_LIMIT = 10000;

  // Linear price of 1 token
  uint256 private _tokenPrice;

  // Maximum amount of tokens to be bought in one transaction / mint
  uint256 private _maxTokensAtOnce = 20;

  // flag for public sale - sale where anybody can buy multiple tokens
  bool public publicSale = false;

  // flag for team sale - sale where team can buy before currect amount of existing tokens is < 100
  bool public teamSale = false;

  // flag for private sale - sale for only whitelisted addreses
  bool public privateSale = false;

  // random nonce/seed
  uint internal nonce = 0;

  // list of existing ids of tokens
  uint[TOKEN_LIMIT] internal indices;

  // mapping of addreses available to buy in teamSale phase
  mapping(address => bool) private _teamSaleAddresses;

  // split of shares when withdrawing eth from contract
  uint256[] private _teamShares = [100];
  address[] private _team = [0xb76655Be2bCb0976a382fe76d8B23871BF01c0c4];

  // whitelisted list of addresses for privateSale phase
  
  mapping(address => bool) private _whitelist;

  constructor()
    PaymentSplitter(_team, _teamShares)
    ERC721("LLamas", "BLL")

  {

    // sets the token price in wei
    setTokenPrice(70000000000000000);

    // sets the team addresses flags in array
    _teamSaleAddresses[0xb76655Be2bCb0976a382fe76d8B23871BF01c0c4] = true;

    _whitelist[0x029e13C1dCde8972361C9552Ced69b97596e0E86] = true;
    _whitelist[0x03e9D4E610a5D5B03dd9966F129F40E11fF06b89] = true;
    _whitelist[0x7654DE9CF76926cB8c6B3A829bdf95D5f9100B61] = true;
    _whitelist[0x7D35D1103813AadD881C76037f30EE2E4d5B3325] = true;
    _whitelist[0x38a93Cc8e0147170B44cf27BD67836fF3fBdeE48] = true;
    _whitelist[0x9c5632467758c080A2f7D291956414aCa84A7BCb] = true;
    _whitelist[0x2B1632e4EF7cde52531E84998Df74773cA5216b7] = true;
    _whitelist[0xBcF525E92BC84656882B75a186619c4a50b03d5F] = true;
    _whitelist[0x035C081395042bBC61B940B4B85234e3D37c4186] = true;
    _whitelist[0x05D0F873141fe3a65E80f2182Fe0bA4CD4E168C1] = true;
    _whitelist[0xC8D7F51a5d0437711E39e8B1a89Af4a852a7A891] = true;
    _whitelist[0xD3F0ddBdBC1CCe779fE0eAf9EdC96d1C620eE8cD] = true;
    _whitelist[0xbE72d4A70C047Adc435bE93B7E8cCDe6FE431F58] = true;
    _whitelist[0x42175856652185ddDBD5477fBb1f7f4FC446847D] = true;
    _whitelist[0x4C5656F3bcc4DA91d5104De25025F4BF09201e60] = true;
    _whitelist[0xFb054de87c048fE9f9D859afE6059d023529E0d8] = true;
    _whitelist[0xCEf950dC7b61961E89FF060b26482205F313BD57] = true;
    _whitelist[0xb147702f8812C7a81924DE215dA7a44E0E6cFf64] = true;
    _whitelist[0x722634CF4a1d0F48739697b3300930a71f22f4fe] = true;
    _whitelist[0xa430aB2Df2BFAa87bE60b86420eE0cC117DD6D76] = true;
    _whitelist[0xBBcbb0047a102199bff24c7b95623373178f83d3] = true;
    _whitelist[0x3C09615Ea652D8AFA8612c2D09426719cb442fE8] = true;
    _whitelist[0x2fE5cD57117336e63878EA049aF2f2Ac3d857e57] = true;
    _whitelist[0x957ca9055635477eA68b78ae9bF2cf7aE3252833] = true;
    _whitelist[0x201cFe3B7C02eb647CAd519A6f5Ea627a4803cda] = true;
    _whitelist[0x3099e74D6C209e3a183beF13ee7087Ae20F350e5] = true;
    _whitelist[0x68cBA53e658a0A77B354A6C5DD189a59733B4758] = true;
    _whitelist[0xD9FB3d78B125db44D8021b005993551f5086e0B8] = true;
    _whitelist[0xcD639eB3AE00946cD236BB5e6d921f5432Fe7b9C] = true;
    _whitelist[0xf68B4Cd8b53C9a43AEA62B25d9935c23dAF9D40E] = true;
    _whitelist[0x0978879DE5960D95941ed5FfDC008B26A7E177Fe] = true;
    _whitelist[0x52b0891E15fEfb5d19c59C7d599f9Bb745bfA2fd] = true;
    _whitelist[0xCF796eCb4e15D3216725D4AFeef8Aa01b2f46f4d] = true;
    _whitelist[0x9765F6af0BeE4561e5Ffe18780736a6BDc51c420] = true;
    _whitelist[0xeA8D9643DE809EF963b264f394aDC203344E67BB] = true;
    _whitelist[0x9119564400A6d7E23Af620AbCC0Dc7eeBFe632A3] = true;
    _whitelist[0xCEAc4ea3F49E8Ea0336453F9b54B0780f1158159] = true;
    _whitelist[0x9804371e8674Dab7BA977D5bB272c3bf50b1137d] = true;
    _whitelist[0x0Cf3f236476bD56cbC014AA7546bae55a27154d6] = true;
    _whitelist[0xb256138ee3Fb9D8a56987AbAbDdFBe5A149A897f] = true;
    _whitelist[0x762c9AbBaB93692A2e53524a3eD9d6b9428a6b82] = true;
    _whitelist[0x179680bb7EA9c2e27DFFf0D16C520759D7048BC0] = true;
    _whitelist[0x79e9511E8DF91c5222A6EA81A43840795693973F] = true;
    _whitelist[0x9EbcA0cF940B3Ad8B2Cb4678e85F26e8b017e850] = true;
    _whitelist[0xfcDaA90a3CE72FA35FDfBBc24665138F503Fe4ed] = true;
    _whitelist[0x4cec1074e2A72E6943a13CE16dA7589388bf94C7] = true;
    _whitelist[0xf582164beA85324Bf97e4a304F0f6192b381276b] = true;
    _whitelist[0xa25243821277b10dff17a3276a51A772Fd68C9de] = true;
    _whitelist[0xd9f0A526F15912C60943F0808Ea46e00b62D1eae] = true;
    _whitelist[0x1D8c7bF2118cb6a88b13Dc0aa1d8f64f9DffB598] = true;
    _whitelist[0xCFB6DebE0258A11c43513Df32eA625764Cb7cDD9] = true;
    _whitelist[0x8CECa142D8ca90F797B755C81Ab202EaAe619b79] = true;
    _whitelist[0x006d036995855fF88df665FbBfA66605b682E8e7] = true;
    _whitelist[0x383B8Ce36b2164e32Fd98bb0D0B79a5390ab19Eb] = true;
    _whitelist[0xEd0DC4DB4B139b2C0021a82D7db1bD1FCdF83c0b] = true;
    _whitelist[0x69451E47B352a37Fa15a0899Ea60Cfc99E3c5915] = true;
    _whitelist[0x458903440fAd43948a9e9ACC1d4E9668f1FC77d0] = true;
    _whitelist[0x3fEd56778B37F183ADC7ed07c2eBf28cA91118d7] = true;
    _whitelist[0x8b3261a6b59c3D94933C1f8e4e15C94C4A564512] = true;
    _whitelist[0xCc1aC009F0225ABCEa66072B97edF96137742d4E] = true;
    _whitelist[0xf624658f60Da0A1f7a202E307cf9209963ae509A] = true;
    _whitelist[0xE1359aBA98218c69156c6973eE25589822Ce8E08] = true;
    _whitelist[0x2AC6f6702F5D685a69258283DB04b8BF8494f58C] = true;
    _whitelist[0x917B2c81eA107beC5bb5e829bC3d1331Ab452DB6] = true;
    _whitelist[0x34D868b1F6Db4C00BA465E2D608C12F83ad2d225] = true;
    _whitelist[0xD25FaF6A63C974601473E2cA8CB46b49a15C5CA0] = true;
    _whitelist[0x530c404621E8fc4CD65021fd8ba80a3fb9D7d597] = true;
    _whitelist[0x2881ca468741d2343F27e71b163C56ebcABF6038] = true;
    _whitelist[0x8512c40a4D94435ee88128b1f87fBB9951A07D20] = true;
    _whitelist[0x38bc6A83E1E97f8Ec0C12e2c94D2f765E816E09A] = true;
    _whitelist[0x8Eac5C15640aeBbd17b6e2b97C0FdAEE8e739111] = true;
    _whitelist[0x36301378d96b776911b7033FD21fdfA7e067aAb4] = true;
    _whitelist[0x4808fd40E3A5C30f0B2aef4aE7591bb3e1248Dff] = true;
    _whitelist[0xe0123335BdE05195E0D78F79C9B2776493fa916c] = true;
    _whitelist[0x2aa07DcaC1cF21AEbeBD32f710a2aE9Ab735536c] = true;
    _whitelist[0x8a555b5cEDef44A3ac97537424Cc8Cccbbb0c888] = true;
    _whitelist[0xedda234360729872F5a282aBfAb670b69DeaAEBD] = true;
    _whitelist[0x537F61Cd25Be053e77AE413e2378B7c6b15240C8] = true;
    _whitelist[0x963c7772893Ca86A1f19596b782329f61Bf2C381] = true;
    _whitelist[0x008648cE2aFcc850fc3faF17aA1442Cc7a239715] = true;
    _whitelist[0xAF011986eDFDea5A67A500200B65deD21Fa4C686] = true;
    _whitelist[0x2F0830b9cC296e5BAeF35381A78E77F42A1fE4Ad] = true;
    _whitelist[0xb98CE65602E749445E96a0B33dE43d56F0B8d460] = true;
    _whitelist[0x17E80B4E239298C4c23F5445b5017D7d91D22FE5] = true;
    _whitelist[0xbf7E9a69360A4F8C7c366b643f7dF02085cC546c] = true;
    _whitelist[0xb48328Ae5A475a92BADa6664a3288Bb96Bdd1969] = true;
    _whitelist[0x9a837c9233BB02B44f60BF99bc14Bbf6223069B8] = true;
    _whitelist[0x5e3124878da0Fb4E54092E2F33eB368C3dd3Cefe] = true;
    _whitelist[0x00d2D252Afa94f8CE0D79B251fb6861c9b5A9b58] = true;
    _whitelist[0xAe329AC91fd7D524cF5207A9696F3d9d37301021] = true;
    _whitelist[0x8b975F76989a92A29A9D4A588d9f24c80cEC29B7] = true;
    _whitelist[0x389417B6d10A1b2Ae729A50A9D9D3cFb30e86CF3] = true;
    _whitelist[0x8177F311D969DE32A094277A2EC4E910B5030d14] = true;
    _whitelist[0x6616C85aC95f560939F5822eBD9cC1EeADCc5ab8] = true;
    _whitelist[0x458903440fAd43948a9e9ACC1d4E9668f1FC77d0] = true;
    _whitelist[0x7D25B261fF288e9a73bb3B6F251DCf0aF2b53EC3] = true;
    _whitelist[0x530c404621E8fc4CD65021fd8ba80a3fb9D7d597] = true;
    _whitelist[0xD05814eEA9ABD145a794bae0B66Dc2952d098088] = true;
    _whitelist[0x7e4dBBf9E5b114C7DA42546beeBB893Ad22591da] = true;
    _whitelist[0xa750A35FC3Fae4A8eE8b425626f43633918E49eA] = true;
    _whitelist[0xd447042Ba0c989bFE031ef3059e2E62d4D46af5b] = true;
    _whitelist[0x0b1c5EeCa70c9548813eB56135d9D56d1260527b] = true;
    _whitelist[0x6b8341856cfE21d8c3db54e4C669D7000153dBeD] = true;
    _whitelist[0x80130F105E4FBc55413311b873358d21F7f5f092] = true;
    _whitelist[0x91717c88899b50389B45A14f6d5fab4579DA23f4] = true;
    _whitelist[0xDA33e938871CbA5302D9Bca4D514d7443deF11EE] = true;
    _whitelist[0x1785a72fB2cf94aFceAd2556B230D37726409053] = true;
    _whitelist[0x587D1b427bE813b75aa419bA0b70ec9BE3Ab0649] = true;
    _whitelist[0x7562BC7D2217Cb67da89Bf14fc5A7A7F53Fc5Bca] = true;
    _whitelist[0xB1B9898FEA45E5c36D5d482e5557F4812918e9fe] = true;
    _whitelist[0xd1a168a6032D497c0907FF73E584B72DD78458e4] = true;
    _whitelist[0xd6748f744A2C16e54A565535154B8cF9cEA74E0a] = true;
    _whitelist[0x072Ad02937ffca4c8a14636984dC4753Db32ba03] = true;
    _whitelist[0x07af133080433BEd729835dd97Bc2f6992718Ccb] = true;
    _whitelist[0xAc7683272757bF7E115F71c310376466834bB57f] = true;
    _whitelist[0x9e74CC8d85415dB34Cd1Bc190043795325b924Fc] = true;
    _whitelist[0xA42f9A54B2aCAc96B15cD39ce273aD5dD161EfBF] = true;
    _whitelist[0xc6F37fD79af8e95a195BF48059Ab070C32DfF01E] = true;
    _whitelist[0x895f88737925411FA81892cC32eA8d0c9442C19b] = true;
    _whitelist[0xe2AF5c5e44355e1f1D8A70991a6647518599a284] = true;
    _whitelist[0x8A77EB24e9AF1fb16a80158dc0A85A3fb2DeF2f4] = true;
    _whitelist[0x1625173F02c6860b20eB495A5126606802ae8Ec7] = true;
    _whitelist[0x0D2DD5413533550ACbd8372e992F5794038979eD] = true;
    _whitelist[0x1511AFBE08e6abBf4e78Fb8A72877019500b7a2c] = true;
    _whitelist[0xDDE1B9F12e6FF68f35eC164Dc4A269beca33679b] = true;
    _whitelist[0x96D876F20C88b3D0D59dFe382A8458940E019156] = true;
    _whitelist[0xa7E54945D497477AA73d345d931345E3bE4C36E8] = true;
    _whitelist[0x19DF6e91fFd996A6872045427e5Bb9B0D3F2C8eE] = true;
    _whitelist[0x181c41a7693BAa7185ACc10c58f92AE972D27F34] = true;
    _whitelist[0xCE23372e0E1DC284aeBF9EB9d73219561a674699] = true;
    _whitelist[0xF1821c8BedEBB48D097A1478935E7c6cBE7AAf49] = true;
    _whitelist[0x330E16147b17DA236E0b031Fa04C84638ffcD405] = true;
    _whitelist[0xE775F54eE8321eA5B63901BBd868D4431E8A9A74] = true;
    _whitelist[0xb97FEe8A37f3c9868182A212fe39C8c1d3fEa075] = true;
    _whitelist[0xDF1e78916545E4C9866a2ad90FeD46714EDF2F72] = true;
    _whitelist[0x6ad2AB741f034C51d682933b50a91bE501Af7e7d] = true;
    _whitelist[0x3eAE8FD75D4f6E055C5EFA3B669754Fdbf58D060] = true;
    _whitelist[0xA54Ab0080e044e4f6CB0Cd3731F38fDE0DDd44E0] = true;
    _whitelist[0x55fc421a0693f50774e6D2276943D7B27b55DA76] = true;
    _whitelist[0x2c4FcadfB0d04d8161beDc0709f7c1E0b969CE54] = true;
    _whitelist[0xc3217122093326794359d5A2A4a130dF4fA50D77] = true;
    _whitelist[0x51E414A12bE1c3B421939fd09C6fd12FA7957D83] = true;
    _whitelist[0xb90629AC708ba20C38C1699609E5d030c446F24B] = true;
    _whitelist[0x9671742089039566c87C3FB66AF325A50c15aC69] = true;
    _whitelist[0xbD5764383846BbD5aABc92Ab9c9C2f9BbfA15a55] = true;
    _whitelist[0x5A58087F6D0cCDf9B9555B578bae73a5B0332f82] = true;
    _whitelist[0xA77B839447281217A49cCD4aF6379Dc4f672c832] = true;
    _whitelist[0x7dD27E97ac36e7dC89C9f95f480e878E53514a9a] = true;
    _whitelist[0xB11Ab9115B1Db2833b231f1683DA8DE84C53B11d] = true;
    _whitelist[0x04BdB0611506446179474E0a1fAe2c3a8C6C5eC5] = true;
    _whitelist[0x229C75F67b0d960E1Bd080bF8A37275c3f3e80f0] = true;
    _whitelist[0x3DbF250520B7157A5DA413dB29a387b9471D3194] = true;
    _whitelist[0xe80De17Dd3fa25e11bEDa818305BfcF44146114A] = true;
    _whitelist[0xd3de261a4b9353B46085690FCE768d08b7784D22] = true;
    _whitelist[0x90dEAd4A1e56447d9b87579Fd8dD0b90DADE8080] = true;
    _whitelist[0x4533c00F0a7511caE12f7737C5C2e0E6c0B220d9] = true;
    _whitelist[0x3765A185327c36B72F3b5e2a86F6510d904231e9] = true;
    _whitelist[0x017aA94D2A204D8fc9cf221282A8717D847A1471] = true;
    _whitelist[0x697bf45762E24C0A4C77fD01ca1e7994F11e3b1A] = true;
    _whitelist[0x1aDd9Eaa7768b810B553373C68D38744FB7084E5] = true;
    _whitelist[0x91fe37289c08872eAfd60289A4c8078B705d0cd0] = true;
    _whitelist[0x17C6E9984ee2A4f1196e8E9FCb28E6fBca3E4B67] = true;
    _whitelist[0x8ACd9Cc99d622FDE692F0f6eBB6C840C41D7DF08] = true;
    _whitelist[0x23cF4B4a4CaC1f84ecd591fBf0d9caa0E073A6a2] = true;
    _whitelist[0x0311045C7A75Fd96B17f6DBE9b716A1db3A2B214] = true;
    _whitelist[0x362A42B2764EBbfDAD9A9DfDF39ca98EFDCE11E8] = true;
    _whitelist[0x7d2207D8EC461713010FAC07ffd061F41a03a464] = true;
    _whitelist[0x858c050E98489DA8Fb270ef161a7674a5014B181] = true;
    _whitelist[0x602D2a713ECe658a76989F4CED1bD6179544E7aA] = true;
    _whitelist[0x054c35BFD839D9f0E177b265b0db5AdB03B2d250] = true;
    _whitelist[0x40119fD73a4c3c6cAf9DD5B0078f6c13E1133c61] = true;
    _whitelist[0x7f95a004aB29CB14E5681A6b9dC059288298F7b1] = true;
    _whitelist[0x95c831817818B9b90cea66dd486585FbFf07B418] = true;
    _whitelist[0x51D20Bf945A5311F8aFD7a40a513dD901e4A43DE] = true;
    _whitelist[0x827bF5006a21275919879182c8Fb5F7287C1dBB4] = true;
    _whitelist[0x2860A7DA61701aE54E5b0BC0b378eeb4beEaec97] = true;
    _whitelist[0x2C95cf4Df95566dcb123C8A7D3f0853Fe8C32cbA] = true;
    _whitelist[0xb8D6f563A2bb1d024f075c13c38d8D8137eAc0E1] = true;
    _whitelist[0x713CA8b65595C5218cAA3b2881BE4f33180fd3b5] = true;
    _whitelist[0xf842cbA57ff4BE4d1F0B3aAf9103BD5b07a278F9] = true;
    _whitelist[0x1678b7713f80d0ec034d78A2Fb648a620d8b0B66] = true;
    _whitelist[0xB27Fce88e619E23B09Cf28504748cED0CDe3ACFC] = true;
    _whitelist[0xAAC943D660a09A30Cc258860dcf92fd1282fc8D3] = true;
    _whitelist[0xDFeFa15487CB2dbE60D5D2cE2ec0387b02b1F710] = true;
    _whitelist[0xA66aFf46584a486492254C533187d51C183BA170] = true;
    _whitelist[0xECdfD44D10C03DD817C92C81382bE8a1a25A133b] = true;
    _whitelist[0xD834c68dC7e2e6B3b5b30c59F73c73ce965aC5Aa] = true;
    _whitelist[0xDf6eaf2db3Dc6c5731244F49ff08225313a8661a] = true;
    _whitelist[0x7B2705FAbC2B058d20626b2d3839409F6484053d] = true;
    _whitelist[0xAF1bFA2B6B61f4093320358E3CD0a4fA5DeDc9c4] = true;
    _whitelist[0x51bc01FC23e21B2B8Bf5d0a952868C62e459697f] = true;
    _whitelist[0x23f8b57912d04877EAa1f1E319180107ec7f4149] = true;
    }


  // Required overrides from parent contracts
  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  // return of metadata json uri
  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  // Required overrides from parent contracts
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // Required overrides from parent contracts
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }


  // _tokenPrice getter
  function getTokenPrice() public view returns(uint256) {
    return _tokenPrice;
  }


  // _tokenPrice setter
  function setTokenPrice(uint256 _price) public onlyOwner {
    _tokenPrice = _price;
  }

  // _paused - pause toggles availability of certain methods that are extending "whenNotPaused" or "whenPaused"
  function togglePaused() public onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }


  // _maxTokensAtOnce getter
  function getMaxTokensAtOnce() public view returns (uint256) {
    return _maxTokensAtOnce;
  }

  // _maxTokensAtOnce setter
  function setMaxTokensAtOnce(uint256 _count) public onlyOwner {
    _maxTokensAtOnce = _count;
  }


  // enables public sale and sets max token in tx for 20
  function enablePublicSale() public onlyOwner {
    publicSale = true;
    setMaxTokensAtOnce(20);
  }

  // disables public sale
  function disablePublicSale() public onlyOwner {
    publicSale = false;
    setMaxTokensAtOnce(1);
  }

  // toggles teamSale
  function toggleTeamSale() public onlyOwner {
    teamSale = !teamSale;
  }


  // toggles privateSale ( whitelist )
  function togglePrivateSale() public onlyOwner {
    privateSale = !privateSale;
  }


  // Token URIs base
  function _baseURI() internal override pure returns (string memory) {
    return "ipfs://QmWPzChN8ucQDtK79D3AAYmZBTFcrxSVkkRSoRX1fXNYvY/";
  }

  // adds address from parameter to array of whitelisted addreses
  function addToWhitelist(address[] memory _addresses) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
        _whitelist[_addresses[i]] = true;        
    }
  }

  // Pick a random index
  function randomIndex() internal returns (uint256) {
    uint256 totalSize = TOKEN_LIMIT - totalSupply();
    uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint256 value = 0;

    if (indices[index] != 0) {
      value = indices[index];
    } else {
      value = index;
    }

    if (indices[totalSize - 1] == 0) {
      indices[index] = totalSize - 1;
    } else {
      indices[index] = indices[totalSize - 1];
    }

    nonce++;

    return value.add(1);
  }


  // Minting single or multiple tokens
  function _mintWithRandomTokenId(address _to) private {
    uint _tokenID = randomIndex();
    _safeMint(_to, _tokenID);
  }

  // public method for minting 1 Token if sender is in whitelist and privatesale is enabled
  function mintWhitelistToken(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(1) <= TOKEN_LIMIT, "Purchase would exceed max supply of Llamas");
    require(getTokenPrice().mul(_amount) == msg.value, "Insufficient funds to purchase");
    require(privateSale, "Private sale must be active to mint token for whitelisted addresses");
    require(_whitelist[address(msg.sender)], "Address not whitelisted");
    require (_amount <= 10, "Only 10 tokens per address allowed");
    require (balanceOf(msg.sender) <= 10, "Only 10 tokens per address allowed");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }

  // public method for minting multiple tokens if public sale is enable
  function mintPublicMultipleTokens(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOKEN_LIMIT, "Purchase would exceed max supply of Llamas");
    require(publicSale, "Public sale must be active to mint multiple tokens at once");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) == msg.value, "Insufficient funds to purchase");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }

  // public method for teammembers for minting multiple tokens if teamsale is enabled and existing tokens amount are less than 100
  function mintTeamMultipleTokens(uint256 _amount) public payable nonReentrant {
    require(teamSale, "Team sale must be active to mint as a team member");
    require(totalSupply() < 100, "Exceeded tokens allocation for team members");
    require(_teamSaleAddresses[address(msg.sender)], "Not a team member");

    for(uint256 i = 0; i < _amount; i++) {
      _mintWithRandomTokenId(msg.sender);
    }
  }
}