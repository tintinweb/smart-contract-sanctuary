/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.7.0;

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
    constructor () {
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
}

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.7.0;

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

    constructor () {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/introspection/IERC165.sol



pragma solidity ^0.7.0;

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



pragma solidity ^0.7.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.7.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: contracts/LCX_Auction.sol

pragma solidity ^0.7.6;







contract LSCX_Auction is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /******************
    CONFIG
    ******************/
    uint16 private transactionFee = 3000;
    uint16[] private feePercentages;
    address[] private feeAddresses;
    uint256 private step = 5000; //5000 wei minimum step

    /******************
    EVENTS
    ******************/
    event AuctionCreated(
        uint256 auctionId,
        address indexed wallet,
        uint256 moment
    );

    event AuctionCancelled(
        uint256 indexed auctionId,
        address indexed wallet,
        uint256 moment
    );

    event BidMade(
        uint256 indexed auctionId,
        uint256 indexed amount,
        address indexed wallet,
        uint256 moment
    );

    event DirectBought(
        uint256 indexed auctionId,
        uint256 indexed amount,
        address indexed wallet,
        uint256 moment
    );

    event AuctionClaimed(
        uint256 indexed auctionId,
        uint256 indexed amount,
        address indexed wallet,
        uint256 moment
    );

    /******************
    INTERNAL ACCOUNTING
    *******************/
    Counters.Counter private auctionId;

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid) public highestBidByAuction;

    struct Auction {
        address erc721address;
        uint256 erc721tokenId;
        address erc20address;
        address owner;
        uint256 auctionMinimumPrice;
        uint256 directBuyPrice;
        bool directlyBought;
        uint256 endDate;
        bool claimed;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 moment;
    }

    /******************
    PUBLIC FUNCTIONS
    *******************/
    constructor() {
        feePercentages = [100];
        feeAddresses = [_msgSender()];
    }

    /**
        @dev User creates a new auction.
     */
    function createAuction(
        address _erc721address,
        uint256 _erc721tokenId,
        address _erc20address,
        uint256 _minimumBidPrice,
        uint256 _directBuyPrice,
        uint256 _duration
    ) public returns (uint256) {
        IERC721(_erc721address).transferFrom(
            _msgSender(),
            address(this),
            _erc721tokenId
        );

        uint256 currentTime = _getTime();
        uint256 auctionIndex = auctionId.current();
        auctionId.increment();

        auctions[auctionIndex] = Auction({
            erc721address: _erc721address,
            erc721tokenId: _erc721tokenId,
            erc20address: _erc20address,
            owner: _msgSender(),
            auctionMinimumPrice: _minimumBidPrice,
            directBuyPrice: _directBuyPrice,
            directlyBought: false,
            endDate: currentTime + _duration,
            claimed: false
        });

        emit AuctionCreated(auctionIndex, _msgSender(), currentTime);

        return auctionIndex;
    }

    /**
        @dev User adds a bid for given auction.
     */
    function bid(uint256 _auctionId, uint256 _amount)
        public
        nonReentrant
        nonEndedAuction(_auctionId)
        biddableAuction(_auctionId)
        requiredBidAmount(_auctionId, _amount)
    {
        IERC20(auctions[_auctionId].erc20address).transferFrom(
            _msgSender(),
            address(this),
            _amount
        );

        _refundLastBid(_auctionId);

        uint256 currentTime = _getTime();
        highestBidByAuction[_auctionId] = Bid({
            bidder: _msgSender(),
            amount: _amount,
            moment: currentTime
        });

        emit BidMade(_auctionId, _amount, _msgSender(), currentTime);
    }

    /**
        @dev User performs a direct buy for given auction.
            Fees are stored to later distribution in order to save transactions.
     */

    function directBuy(uint256 _auctionId)
        public
        nonReentrant
        buyableAuction(_auctionId)
        nonEndedAuction(_auctionId)
    {
        require(
            IERC20(auctions[_auctionId].erc20address).balanceOf(_msgSender()) >
                auctions[_auctionId].directBuyPrice,
            "LSCXAuction: User has not enough balance."
        );

        uint256 price = auctions[_auctionId].directBuyPrice;
        uint256 feeAmount = price.mul(transactionFee).div(10000);
        uint256 priceWithoutFee = price.sub(feeAmount);

        IERC20(auctions[_auctionId].erc20address).transferFrom(
            _msgSender(),
            address(this),
            feeAmount
        );
        IERC20(auctions[_auctionId].erc20address).transferFrom(
            _msgSender(),
            auctions[_auctionId].owner,
            priceWithoutFee
        );
        IERC721(auctions[_auctionId].erc721address).transferFrom(
            address(this),
            _msgSender(),
            auctions[_auctionId].erc721tokenId
        );

        auctions[_auctionId].directlyBought = true;

        emit DirectBought(_auctionId, price, _msgSender(), _getTime());
    }

    /**
         @dev NFT owner cancels an auction that is not finished nor bid.
     */
    function cancel(uint256 _auctionId)
        public
        nonEndedAuction(_auctionId)
        nonBidAuction(_auctionId)
    {
        require(
            auctions[_auctionId].owner == _msgSender(),
            "LSCXAuction: Only NFT owner can cancel auction."
        );

        uint256 currentTime = _getTime();
        IERC721(auctions[_auctionId].erc721address).transferFrom(
            address(this),
            _msgSender(),
            auctions[_auctionId].erc721tokenId
        );
        auctions[_auctionId].endDate = currentTime;

        emit AuctionCancelled(
            _auctionId,
            _msgSender(),
            currentTime
        );
    }

    /**
        @dev Bidder claims the NFT of the finised auction.
     */
    function claimToken(uint256 _auctionId) public {
        Auction memory auction = auctions[_auctionId];
        Bid memory highestBid = highestBidByAuction[_auctionId];
        uint256 currentTime = _getTime();
        require(
            auction.directlyBought == false,
            "LSCXAuction: Auction was directly bought."
        );
        require(
            auction.endDate < currentTime,
            "LSCXAuction: Auction has not ended."
        );
        require(
            highestBid.bidder == _msgSender() || highestBid.bidder == address(0),
            "LSCXAuction: Caller is not highest bidder."
        );

        uint256 price = highestBid.amount;
        uint256 feeAmount = price.mul(transactionFee).div(10000);
        uint256 priceWithoutFee = price.sub(feeAmount);

        IERC20(auction.erc20address).transfer(auction.owner, priceWithoutFee);
        IERC721(auction.erc721address).transferFrom(
            address(this),
            _msgSender(),
            auction.erc721tokenId
        );
        auctions[_auctionId].claimed = true;
        
        emit AuctionClaimed(_auctionId, price, _msgSender(), currentTime);
    }

    /**
        @dev Owner changes fee. Value must be multiplied by 100, e.g: 25% == 2500.
    */
    function setBuyingFee(uint16 _transactionFee) public onlyOwner {
        require(
            _transactionFee < 5000,
            "LSCXAuction: Fee must be lower than 50%"
        );
        transactionFee = _transactionFee;
    }

    /**
        @dev Owner assigns feeing addresses
     */
    function setFeeingAddresses(
        uint16[] memory _feePercentages,
        address[] memory _feeAddresses
    ) public onlyOwner {
        require(
            _feeAddresses.length == _feePercentages.length,
            "LSCXAuction: FeePercentages and FeeAddresses must be same size."
        );
        uint16 totalPercentages = 0;
        for (uint256 index = 0; index < _feePercentages.length; index++) {
            totalPercentages += _feePercentages[index];
        }
        require(
            totalPercentages == 100,
            "LSCXAuction: FeePercentages must sum 100"
        );

        feeAddresses = _feeAddresses;
        feePercentages = _feePercentages;
    }

    /**
        @dev Distributes current feed amount to configured feeAddresses.
      */
    function distributeFees(address[] memory erc20addresses) public onlyOwner {
        for (
            uint256 erc20addressIndex = 0;
            erc20addressIndex < erc20addresses.length;
            erc20addressIndex++
        ) {
            for (uint256 index = 0; index < feeAddresses.length; index++) {
                uint256 total = IERC20(erc20addresses[erc20addressIndex]).balanceOf(address(this));

                uint256 amountForAddress = total
                    .mul(feePercentages[index])
                    .div(1000);
                IERC20(erc20addresses[erc20addressIndex]).transfer(
                    feeAddresses[index],
                    amountForAddress
                );
            }
        }
    }

    /******************
    PRIVATE FUNCTIONS
    *******************/
    /**
        @dev If given auction has a bid, it returns bid amount to bidder.
     */
    function _refundLastBid(uint256 _auctionId) private {
        Bid memory lastBid = highestBidByAuction[_auctionId];
        if (lastBid.amount > 0) {
            IERC20(auctions[_auctionId].erc20address).transfer(
                lastBid.bidder,
                lastBid.amount
            );
        }
    }

    function _getTime() public view returns (uint256) {
        return block.timestamp;
    }

    /******************
    MODIFIERS
    *******************/
    modifier requiredBidAmount(uint256 _auctionId, uint256 _amount) {
        uint256 currentPrice = highestBidByAuction[_auctionId].amount != 0
            ? highestBidByAuction[_auctionId].amount
            : auctions[_auctionId].auctionMinimumPrice;

        require(
            _amount > (currentPrice.add(step)),
            "LSCXAuction: Insufficient amount for bid, step not surpassed."
        );
        _;
    }

    modifier nonBidAuction(uint256 _auctionId) {
        require(
            highestBidByAuction[_auctionId].bidder == address(0),
            "LSCXAuction: Auction has bidders."
        );
        _;
    }

    modifier nonEndedAuction(uint256 _auctionId) {
        require(
            auctions[_auctionId].directlyBought == false &&
                auctions[_auctionId].endDate > _getTime(),
            "LSCXAuction: Auction has ended."
        );
        _;
    }

    modifier buyableAuction(uint256 _auctionId) {
        require(auctions[_auctionId].directBuyPrice != 0);
        _;
    }

    modifier biddableAuction(uint256 _auctionId) {
        require(auctions[_auctionId].auctionMinimumPrice != 0);
        _;
    }
}