/**
 *Submitted for verification at polygonscan.com on 2021-10-07
*/

// Dependency file: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// solhint-disable-next-line compiler-version
// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// pragma solidity ^0.8.0;
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// Dependency file: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// Dependency file: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


// pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// Dependency file: @openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}


// Dependency file: @openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol


// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Dependency file: contracts/marketplace/utils/State.sol


// pragma solidity 0.8.4;


// import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

abstract contract State {
    using SafeMathUpgradeable for uint256;

    enum Status {
        OPENING,
        CLOSED,
        DONE,
        FAILED
    }

    struct Listing {
        uint256 token;
        address owner;
        uint256 price;
        bool onSale;
        Status status;
    }

    struct Offer {
        address buyer;
        uint256 amount;
        Status status;
    }

    Listing[] internal _listings;

    mapping (uint256 => Offer[]) internal _offers;
}


// Dependency file: contracts/marketplace/utils/Getter.sol


// pragma solidity 0.8.4;


// import "contracts/marketplace/utils/State.sol";

abstract contract Getter is State {
    function listingTotal() public view returns (uint256) {
        return _listings.length;
    }

    function listingDetail(uint256 lid) public view returns (
        uint256 token,
        address owner,
        uint256 price,
        bool onSale,
        Status status
    ) {
        return (
            listingToken(lid),
            listingOwner(lid),
            listingPrice(lid),
            listingOnSale(lid),
            listingStatus(lid)
        );
    }

    function listingToken(uint256 lid) public view returns (uint256) {
        return _listings[lid].token;
    }

    function listingOwner(uint256 lid) public view returns (address) {
        return _listings[lid].owner;
    }

    function listingPrice(uint256 lid) public view returns (uint256) {
        return _listings[lid].price;
    }

    function listingOnSale(uint256 lid) public view returns (bool) {
        return _listings[lid].onSale;
    }

    function listingStatus(uint256 lid) public view returns (Status) {
        return _listings[lid].status;
    }

    function offerTotal(uint256 lid) public view returns (uint256) {
        return _offers[lid].length;
    }

    function offerDetail(uint256 lid, uint256 oid) public view returns (
        address buyer,
        uint256 amount,
        Status status
    ) {
        return (
            offerBuyer(lid, oid),
            offerAmount(lid, oid),
            offerStatus(lid, oid)
        );
    }

    function offerBuyer(uint256 lid, uint256 oid) public view returns (address) {
        return _offers[lid][oid].buyer;
    }

    function offerAmount(uint256 lid, uint256 oid) public view returns (uint256) {
        return _offers[lid][oid].amount;
    }

    function offerStatus(uint256 lid, uint256 oid) public view returns (Status) {
        return _offers[lid][oid].status;
    }

    function myOfferAmount(address account, uint256 lid) public view returns (uint256) {
        for (uint256 i = 0; i < offerTotal(lid); i++) {
            if (offerBuyer(lid, i) == account) {
                return offerAmount(lid, i);
            }
        }
        return 0;
    }
}


// Dependency file: contracts/marketplace/utils/Setter.sol


// pragma solidity 0.8.4;


// import "contracts/marketplace/utils/Getter.sol";

abstract contract Setter is Getter {
    function newListing(uint256 token, address owner, uint256 price, bool onSale) internal returns (uint256) {
        _listings.push(Listing({
            token: token,
            owner: owner,
            price: price,
            onSale: onSale,
            status: Status.OPENING
        }));

        return _listings.length - 1;
    }

    function destroyListing(uint256 lid) internal {
        _listings[lid].status = Status.CLOSED;
    }

    function newOffer(uint256 lid, address buyer, uint256 amount) internal returns (uint256) {
        _offers[lid].push(Offer({
            buyer: buyer,
            amount: amount,
            status: Status.OPENING
        }));

        return _offers[lid].length - 1;
    }

    function destroyOffer(uint256 lid, uint256 oid, bool accept) internal {
        if (accept) {
            _offers[lid][oid].status = Status.DONE;
        } else {
            _offers[lid][oid].status = Status.FAILED;
        }
    }

    function updateOfferAmount(uint256 lid, uint256 oid, uint256 price) internal {
        _offers[lid][oid].amount = _offers[lid][oid].amount + price;
    }
}


// Dependency file: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


// Dependency file: contracts/libs/WhitelistUpgradeable.sol

// pragma solidity 0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping (address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns(bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint256[49] private __gap;
}


// Root file: contracts/marketplace/HunnyMall.sol


pragma solidity 0.8.4;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

// import "contracts/marketplace/utils/Setter.sol";
// import "contracts/libs/WhitelistUpgradeable.sol";

contract HunnyMall is WhitelistUpgradeable, ERC721HolderUpgradeable, PausableUpgradeable, Setter {
    using SafeMath for uint256;

    IERC721 public hunnyNft;

    address public feeAddress;
    uint256 public feePercent;

    event ListingOpened(uint256 indexed lid, uint256 indexed token, address indexed owner);
    event ListingClosed(uint256 indexed lid, bool indexed accept, address buyer, uint256 price);

    event OfferOpened(uint256 indexed lid, uint256 indexed oid, address indexed buyer, uint256 price);
    event OfferClosed(uint256 indexed lid, uint256 indexed oid, address indexed buyer);
    event OfferRefunded(uint256 indexed lid, uint256 indexed oid, address indexed buyer, uint256 amount);

    event OnSaleBuy(uint256 indexed lid, address indexed buyer, uint256 indexed price);
    event FeePercentUpdated(address indexed owner, uint256 oldFeePercent, uint256 newFeePercent);

    function initialize() external initializer {
        __Pausable_init();
        __ERC721Holder_init();
        __WhitelistUpgradeable_init();

        hunnyNft = IERC721(0x8D591C4B8512Cd5764A53719379d005Bb63F7b94);

        feePercent = 5; // 5%
        feeAddress = 0xe5F7E3DD9A5612EcCb228392F47b7Ddba8cE4F1a;

        emit FeePercentUpdated(msg.sender, 0, feePercent);
    }

    // Update fee percent
    function updateFeePercent(uint256 _feePercent) external onlyOwner {
        emit FeePercentUpdated(msg.sender, feePercent, _feePercent);

        feePercent = _feePercent;
    }

    // Transfer NFT token from seller to HunnyMall for sell
    function openListing(uint256 token, uint256 price, bool onSale) external canOpenListing(token) whenNotPaused {
        uint256 lid = newListing(token, msg.sender, price, onSale);

        hunnyNft.safeTransferFrom(msg.sender, address(this), token);

        emit ListingOpened(lid, token, msg.sender);
    }

    // Open an offer for NFT
    function openOffer(uint256 lid, uint256 price) external payable canOpenOffer(lid, price) whenNotPaused {
        if (offerTotal(lid) > 0) {
            // refund last offer
            uint256 lastOffer = offerTotal(lid) - 1;
            
            require(price > offerAmount(lid, lastOffer), "bid amount too small");
            
            payable(offerBuyer(lid, lastOffer)).transfer(offerAmount(lid, lastOffer));
            _offers[lid][lastOffer].status = Status.FAILED;

            emit OfferRefunded(lid, lastOffer, _offers[lid][lastOffer].buyer, _offers[lid][lastOffer].amount);
        }

        // the first offer
        uint256 oid = newOffer(lid, msg.sender, price);
        emit OfferOpened(lid, oid, msg.sender, price);
    }

    // Buying NFT without make offer
    function onSaleBuy(uint256 lid) external payable canOnSaleBuy(lid) whenNotPaused {
        uint256 price = listingPrice(lid);
        require(price <= msg.value, "Error: insufficient amount");

        // Check whitelist
        if (isWhitelist(listingOwner(lid))) {
            // Transfer bnb to listing owner without charge fee
            payable(listingOwner(lid)).transfer(price);
        } else {
            // Charge fee for dev
            uint256 feeAmount = price.mul(feePercent).div(100);
            if (feeAmount != 0) {
                payable(feeAddress).transfer(feeAmount);
            }

            // Transfer bnb to owner's list
            payable(listingOwner(lid)).transfer(price.sub(feeAmount));
        }

        // Transfer hunny nft to buyer
        hunnyNft.transferFrom(address(this), msg.sender, listingToken(lid));

        // Close listing and set offers state
        destroyListing(lid);

        for (uint256 i = 0; i < offerTotal(lid); i++) {
            destroyOffer(lid, i, false);
        }
        emit OnSaleBuy(lid, msg.sender, listingPrice(lid));
    }

    // Close listing and accept offer or not
    function closeListing(uint256 lid, bool accept) external canCloseListing(lid, accept) whenNotPaused {
        if (!accept) {
            // Close listing without accept offer
            // and transfer nft back to owner

            // refund last offer
            if (offerTotal(lid) > 0) {
                uint256 lastOffer = offerTotal(lid) - 1;
                payable(offerBuyer(lid, lastOffer)).transfer(offerAmount(lid, lastOffer));
                _offers[lid][lastOffer].status = Status.FAILED;
                emit ListingClosed(lid, accept, _offers[lid][lastOffer].buyer, _offers[lid][lastOffer].amount);
                emit OfferRefunded(lid, lastOffer, _offers[lid][lastOffer].buyer, _offers[lid][lastOffer].amount);
            } else {
                emit ListingClosed(lid, accept, address(0), 0);
            }

            hunnyNft.transferFrom(address(this), listingOwner(lid), listingToken(lid));
        } else {
            // Close listing and accept last offer
            uint256 lastOffer = offerTotal(lid) - 1;
            _offers[lid][lastOffer].status = Status.DONE;

            payable(listingOwner(lid)).transfer(offerAmount(lid, lastOffer));

            hunnyNft.transferFrom(address(this),  _offers[lid][lastOffer].buyer, listingToken(lid));

            emit ListingClosed(lid, accept, _offers[lid][lastOffer].buyer, _offers[lid][lastOffer].amount);
        }

        destroyListing(lid);
    }

    // Close offer and refund to bidder
    // in case emergency only
    function closeOffer(uint256, uint256) external {
        // will update logic later
    }

    // Stop all activity. Just in case upgrade or emergency!
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    // Resume all activity back to normal
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    modifier canOpenListing(uint256 token) {
        require(hunnyNft.ownerOf(token) == msg.sender, "Error: only token owner");
        _;
    }

    modifier canOpenOffer(uint256 lid, uint256 price) {
        require(listingStatus(lid) == Status.OPENING, "Error: listing is not open");
        require(msg.value >= price, "Error: insufficient amount");
        _;
    }

    modifier canOnSaleBuy(uint256 lid) {
        require(listingStatus(lid) == Status.OPENING, "Error: listing is not open");
        require(listingOnSale(lid), "Error: is not on sale");
        _;
    }

    modifier canCloseListing(uint256 lid, bool accept) {
        require(listingOwner(lid) == msg.sender, "Error: only listing owner");

        if (accept) {
            require(offerTotal(lid) > 0, "Error: offer is not exist");
        }
        _;
    }

    modifier canCloseOffer(uint256 lid, uint256 oid) {
        require(offerBuyer(lid, oid) == msg.sender, "Error: only offer owner");
        require(listingStatus(lid) != Status.OPENING, "Error: listing is opening");
        require(offerStatus(lid, oid) != Status.OPENING, "Error: offer is opening");
        _;
    }
}