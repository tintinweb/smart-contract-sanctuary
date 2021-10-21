/**
 *Submitted for verification at BscScan.com on 2021-10-21
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
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


// Dependency file: contracts/libs/WhitelistUpgradeable.sol

// pragma solidity 0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _whitelist;
    bool private _disable; // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted() {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns (bool) {
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


// Root file: contracts/HunnyMall.sol

pragma solidity 0.8.4;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

// import "contracts/libs/WhitelistUpgradeable.sol";

contract HunnyMall is WhitelistUpgradeable, ERC721HolderUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;

    uint256 private constant UNLOCK_CANCEL_BID_PERIOD = 7 days;

    address public feeAddress;
    uint256 public feePercent;

    enum Status {
        OPENING,
        CLOSED,
        DONE,
        FAILED
    }

    struct Listing {
        address tokenAddr;
        uint256 tokenId;
        address owner;
        uint256 price;
        bool onSale;
        Status status;
    }

    struct Offer {
        address buyer;
        uint256 amount;
        Status status;
        uint256 offeredAt;
    }

    Listing[] internal _listings;

    mapping(uint256 => Offer[]) internal _offers;

    /// @notice check where NFT token is supported to listing
    mapping(address => bool) public isSupported;

    event ListingOpened(
        uint256 indexed lid,
        address indexed tokenAddr,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        bool isOnSale
    );
    event ListingClosed(uint256 indexed lid, bool indexed accept, address buyer, uint256 price);

    event OfferOpened(uint256 indexed lid, uint256 indexed oid, address indexed buyer, uint256 price);
    event OfferClosed(uint256 indexed lid, uint256 indexed oid, address indexed buyer, uint256 price);
    event OfferRefunded(uint256 indexed lid, uint256 indexed oid, address indexed buyer, uint256 amount);
    event OnSaleBuy(uint256 indexed lid, address indexed buyer, uint256 indexed price);

    function initialize() external initializer {
        __Pausable_init();
        __ERC721Holder_init();
        __WhitelistUpgradeable_init();

        feePercent = 5; // 5%
        feeAddress = 0xe5F7E3DD9A5612EcCb228392F47b7Ddba8cE4F1a;
    }

    function listingTotal() public view returns (uint256) {
        return _listings.length;
    }

    function listingDetail(uint256 lid)
        public
        view
        returns (
            address tokenAddr,
            uint256 tokenId,
            address owner,
            uint256 price,
            bool onSale,
            Status status
        )
    {
        Listing memory listing = _listings[lid];
        return (listing.tokenAddr, listing.tokenId, listing.owner, listing.price, listing.onSale, listing.status);
    }

    function offerTotal(uint256 lid) public view returns (uint256) {
        return _offers[lid].length;
    }

    function offerDetail(uint256 lid, uint256 oid)
        public
        view
        returns (
            address buyer,
            uint256 amount,
            Status status,
            uint256 offeredAt
        )
    {
        Offer memory offer = _offers[lid][oid];
        return (offer.buyer, offer.amount, offer.status, offer.offeredAt);
    }

    /// @notice get lid of a token which is listing and open for sale/auction
    function lidByTokenId(address tokenAddr, uint256 tokenId) public view returns (bool isListing, uint256 lid) {
        for (uint256 i = 0; i < _listings.length; i++) {
            if (
                _listings[i].tokenAddr == tokenAddr &&
                _listings[i].tokenId == tokenId &&
                _listings[i].status == Status.OPENING
            ) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    /// @notice get amount need for a bid on a listing
    function needForBid(uint256 lid) public view returns (bool haveOffers, uint256 amount) {
        Listing memory listing = _listings[lid];

        uint256 totalOffer = _offers[lid].length;
        if (totalOffer == 0) return (false, listing.price);

        Offer memory lastOffer = _offers[lid][totalOffer - 1];

        if (lastOffer.status == Status.OPENING) {
            return (true, lastOffer.amount);
        } else {
            return (false, listing.price);
        }
    }

    /// @notice check latest offer can canceled or not
    function canCancelOffer(uint256 lid, address account) external view returns (bool) {
        uint256 totalOffer = _offers[lid].length;
        if (totalOffer == 0) return false;

        Offer storage lastOffer = _offers[lid][totalOffer - 1];
        return
            (lastOffer.offeredAt + UNLOCK_CANCEL_BID_PERIOD < block.timestamp) &&
            (account == lastOffer.buyer) &&
            (lastOffer.status == Status.OPENING);
    }

    /// @notice
    function latestBidOf(uint256 lid, address account) external view returns (bool have, uint256 amount) {
        have = false;
        amount = 0;

        uint256 totalOffer = _offers[lid].length;
        if (totalOffer > 0) {
            for (uint256 i = 0; i < totalOffer; i++) {
                if (_offers[lid][i].buyer == account) {
                    have = true;
                    amount = _offers[lid][i].amount;
                }
            }
        }
    }

    // Update fee percent
    function updateFeePercent(uint256 _feePercent) external onlyOwner {
        require(_feePercent < 100, "invalid fee");
        feePercent = _feePercent;
    }

    function setSupportedNft(address tokenAddr, bool support) external onlyOwner {
        isSupported[tokenAddr] = support;
    }

    function openListing(
        address tokenAddr,
        uint256 tokenId,
        uint256 price,
        bool onSale
    ) external whenNotPaused {
        require(isSupported[tokenAddr], "not supported nft");

        require(IERC721(tokenAddr).ownerOf(tokenId) == msg.sender, "only token owner");

        uint256 lid = newListing(tokenAddr, tokenId, msg.sender, price, onSale);

        IERC721(tokenAddr).transferFrom(msg.sender, address(this), tokenId);

        emit ListingOpened(lid, tokenAddr, tokenId, msg.sender, price, onSale);
    }

    // Open an offer for NFT
    function openOffer(uint256 lid, uint256 price) external payable whenNotPaused {
        Listing memory listing = _listings[lid];

        require(listing.status == Status.OPENING, "not open");
        require(msg.value == price && msg.value >= listing.price, "not amount");

        if (offerTotal(lid) > 0) {
            Offer storage lastOffer = _offers[lid][offerTotal(lid) - 1];

            if (lastOffer.status == Status.OPENING) {
                require(price > lastOffer.amount, "less bid amount");
                lastOffer.status = Status.FAILED;
                payable(lastOffer.buyer).transfer(lastOffer.amount);

                emit OfferRefunded(lid, offerTotal(lid) - 1, lastOffer.buyer, lastOffer.amount);
            }
        }

        // add new offer
        uint256 oid = newOffer(lid, msg.sender, price);
        emit OfferOpened(lid, oid, msg.sender, price);
    }

    // Buying NFT without make offer
    function onSaleBuy(uint256 lid) external payable whenNotPaused {
        Listing storage listing = _listings[lid];

        require(listing.onSale, "not on sale");
        require(listing.status == Status.OPENING, "not open");
        require(listing.price <= msg.value, "less amount");

        if (isWhitelist(listing.owner)) {
            // Transfer bnb to listing owner without charge fee
            payable(listing.owner).transfer(listing.price);
        } else {
            // Charge fee for dev
            uint256 feeAmount = listing.price.mul(feePercent).div(100);
            if (feeAmount != 0) {
                payable(feeAddress).transfer(feeAmount);
            }

            payable(listing.owner).transfer(listing.price.sub(feeAmount));
        }

        listing.status = Status.CLOSED;
        IERC721(listing.tokenAddr).transferFrom(address(this), msg.sender, listing.tokenId);

        emit OnSaleBuy(lid, msg.sender, listing.price);
    }

    function closeListing(uint256 lid, bool accept) external whenNotPaused {
        Listing storage listing = _listings[lid];
        uint256 totalOffer = _offers[lid].length;

        require(listing.owner == msg.sender, "only listing owner");

        if (!accept) {
            // Close listing without accept offer
            // and transfer nft back to owner

            // refund last offer
            if (totalOffer > 0) {
                Offer storage lastOffer = _offers[lid][totalOffer - 1];

                if (lastOffer.status == Status.OPENING) {
                    lastOffer.status = Status.FAILED;
                    payable(lastOffer.buyer).transfer(lastOffer.amount);

                    emit OfferRefunded(lid, totalOffer - 1, lastOffer.buyer, lastOffer.amount);
                }

                emit ListingClosed(lid, accept, address(0), 0);
            } else {
                emit ListingClosed(lid, accept, address(0), 0);
            }

            IERC721(listing.tokenAddr).transferFrom(address(this), listing.owner, listing.tokenId);
        } else {
            require(totalOffer > 0, "no offers");

            // Close listing and accept last offer
            Offer storage lastOffer = _offers[lid][totalOffer - 1];
            require(lastOffer.status == Status.OPENING, "no active offer");

            if (isWhitelist(listing.owner)) {
                // Transfer bnb to listing owner without charge fee
                payable(listing.owner).transfer(lastOffer.amount);
            } else {
                // Charge fee for dev
                uint256 feeAmount = lastOffer.amount.mul(feePercent).div(100);
                if (feeAmount != 0) {
                    payable(feeAddress).transfer(feeAmount);
                }

                // Transfer bnb to owner's list
                payable(listing.owner).transfer(lastOffer.amount.sub(feeAmount));
            }

            lastOffer.status = Status.DONE;

            IERC721(listing.tokenAddr).transferFrom(address(this), lastOffer.buyer, listing.tokenId);

            emit ListingClosed(lid, accept, lastOffer.buyer, lastOffer.amount);
        }

        listing.status = Status.CLOSED;
    }

    // Close offer and refund to bidder
    // in case emergency only
    function closeOffer(uint256 lid) external {
        uint256 totalOffer = _offers[lid].length;
        if (totalOffer == 0) return;

        Offer storage lastOffer = _offers[lid][totalOffer - 1];
        require(lastOffer.offeredAt + UNLOCK_CANCEL_BID_PERIOD < block.timestamp, "locked");
        require(msg.sender == lastOffer.buyer, "only buyer");

        lastOffer.status = Status.FAILED;
        payable(lastOffer.buyer).transfer(lastOffer.amount);

        emit OfferClosed(lid, totalOffer - 1, lastOffer.buyer, lastOffer.amount);
        emit OfferRefunded(lid, totalOffer - 1, lastOffer.buyer, lastOffer.amount);
    }

    // Stop all activity. Just in case upgrade or emergency!
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    // Resume all activity back to normal
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function newListing(
        address tokenAddr,
        uint256 tokenId,
        address owner,
        uint256 price,
        bool onSale
    ) private returns (uint256) {
        _listings.push(
            Listing({
                tokenAddr: tokenAddr,
                tokenId: tokenId,
                owner: owner,
                price: price,
                onSale: onSale,
                status: Status.OPENING
            })
        );

        return _listings.length - 1;
    }

    function newOffer(
        uint256 lid,
        address buyer,
        uint256 amount
    ) private returns (uint256) {
        _offers[lid].push(Offer({buyer: buyer, amount: amount, status: Status.OPENING, offeredAt: block.timestamp}));

        return _offers[lid].length - 1;
    }
}