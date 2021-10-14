/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/math/SafeMath.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC20/IERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC721/IERC721.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC721/IERC721Receiver.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC1155/IERC1155.sol";

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

contract TriathonAuction is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    //using SafeERC20 for IERC20;
    
    struct PoolMetaInfo {
        // pool 
        address creator;                    // address of pool creator
        //bytes16 name;                     // pool name   

        // sell
        address token0;                     // address of the token to sell
        uint token0Type;                    // NFT token type: 721 or 1155                    
        uint token0Id;                      // token id of token0 if 721
        uint token0Amount;                  // amount of token of token0

        // buy
        address token1;                     // address of buy token , 0 -> ETH, others -> ERC20 token.
        uint initialPrice;                  // minimum amount of token1 that creator want to swap the amout of token to be used to buy the nft.
     
        // time period
        uint startAt;                       // the timestamp in seconds the pool started

        // bid
        uint moreBidPriceInPercent;         // minimum incremental amount of token1, in percent.
        uint moreBidTime;                   // how many seconds the pool will be added by last bid
    }

    struct PoolStatus {
        uint status;                        // Note: this status is set by txs, so it is not correct all the time, to use 'getPoolStatus' to get the real status.
        uint currPrice;
        uint timeToLive;                    // how long this pool will be alive
        uint reservedReward;
        address lastBidder;
    }
    
    struct BidInfo {
        address bidder;
        uint price;
        uint time;
        uint reward;
    }
    
    // NFT type: 721 or 1155
    uint    internal constant TypeErc721                = 0;
    uint    internal constant TypeErc1155               = 1;
    
    // pool status
    uint    internal constant POOL_UNSTARTED            = 0; // pool not exist
    uint    internal constant POOL_OPEN                 = 1; // pool created
    uint    internal constant POOL_BIDDING              = 2; // pool have bidder
    uint    internal constant POOL_DATED                = 3; // bider exist, but the last bidder havn't take out the nft
    uint    internal constant POOL_CLOSED               = 4; // the last bidder have taken out the nft.
    uint    internal constant POOL_CANCELED             = 5; // creater cancel the pool when there are no bidder
    uint    internal constant POOL_PASSED               = 6; // when the time is off, and no bidder, auction aborted.
    uint    internal constant POOL_RETRIEVALED          = 7; // pool is passed, and nft is retrievaled by creator.

    // BID meta info TODO TODO TODO
    uint    internal constant BID_PERIOD                = 5 minutes;//6 hours;
    uint    internal constant BID_ADD_PERIOD            = 1 minutes; //5 minutes;
    uint    internal constant BID_ADD_PERCENT           = 10; // 10%
    
    address public _trias;
    address public _rewardReceiver;
    address public _loot;
    
    PoolMetaInfo[] public pools;                 // poolId -> PoolMetaInfo
    PoolStatus[] public poolsStatus;             // poolId -> PoolStatus
    mapping(uint => BidInfo[]) public bids;      // poolId -> BidInfo[]
    mapping(uint => mapping(address => uint)) public bidderReward; // poolId -> bidder address -> reward


    //event Created(Pool pool);
    event Created(uint poolId, address creator, address token0, uint token0Type, uint token0Id, uint token0Amount, address token1, uint initialPrice);
    event Bid(address sender, uint poolId, uint amount1);
    event Claimed(address sender, uint poolId);


    constructor(address trias_, address team_, address loot_)  {
        _trias = trias_;
        _rewardReceiver = team_;
        _loot = loot_;
    }
    
    function create(uint tokenId, uint amount) external {
        _create(_loot, TypeErc721, tokenId, 1, _trias, amount, BID_PERIOD, BID_ADD_PERIOD, BID_ADD_PERCENT);
    }
    
    function _create(address token0, uint nftType,uint token0Id, uint token0Amount, address token1, uint token1Amount, uint bidPeriod, uint moreTime, uint incrPercent) internal {
        //require(bytes(name).length <= 16, "the length of name is too long");
        require(token0Amount != 0 && token1Amount != 0, "the value of token0 or token1 is zero");
        require(nftType == TypeErc721 || nftType == TypeErc1155, "wrong nft type");
        if (nftType == TypeErc721) {
            require(token0Amount == 1, "numer of nft721 must be 1.");
        }

        // 1. transfer token0 to this
        if (nftType == TypeErc721) {
            IERC721(token0).safeTransferFrom(_msgSender(), address(this), token0Id);
        } else {
            IERC1155(token0).safeTransferFrom(_msgSender(), address(this), token0Id, token0Amount, "");
        }

        // 2. creator pool
        PoolMetaInfo memory pool;
        pool.creator = _msgSender();
        pool.token0 = token0;
        pool.token0Type = nftType;
        pool.token0Id = token0Id;
        pool.token0Amount = token0Amount;
        pool.token1 = token1;
        pool.initialPrice = token1Amount;
        pool.moreBidPriceInPercent = incrPercent;
        pool.moreBidTime = moreTime;
        pool.startAt = block.timestamp;
        
        PoolStatus memory pst;
        pst.status = POOL_OPEN;
        pst.timeToLive = bidPeriod;
        pst.currPrice = token1Amount;

        // 3. add to pools
        pools.push(pool);
        poolsStatus.push(pst);

        emit Created(pools.length - 1, pool.creator, pool.token0, pool.token0Type, pool.token0Id, pool.token0Amount, pool.token1, pool.initialPrice);
    }

    function cancel(uint poolId) external {
        _cancel(poolId);
    }
    
    function _cancel(uint poolId) internal isPoolExist(poolId) {
        require(_msgSender() == pools[poolId].creator, "not allowd to cancel other people's pool");
        require(getPoolStatus(poolId) == POOL_OPEN, "the status of this pool is not POOL_OPEN");
        
        // 1 give back token0
        if (pools[poolId].token0Type == TypeErc721) {
            IERC721(pools[poolId].token0).safeTransferFrom(address(this), pools[poolId].creator, pools[poolId].token0Id);
        } else {
            IERC1155(pools[poolId].token0).safeTransferFrom(address(this), pools[poolId].creator, pools[poolId].token0Id, pools[poolId].token0Amount, "");
        }
        
        // 2. change status
        poolsStatus[poolId].status = POOL_CANCELED;
    }
    
    function bid(uint poolId) external isPoolOpen(poolId) {
        require(pools[poolId].creator != _msgSender(), "creator can't bid the pool created by self");
        
        PoolMetaInfo memory pool = pools[poolId];
        PoolStatus storage pst = poolsStatus[poolId];
        
        uint bidderNumber = bids[poolId].length;
        
        // 1. transfer token0 to this
        address token1 = pool.token1;
        uint token1Amount = pst.currPrice.add(pst.currPrice.mul(pool.moreBidPriceInPercent).div(100));
        IERC20(token1).transferFrom(_msgSender(), address(this), token1Amount);

        // 2. calculate the reward
        uint premium = token1Amount.sub(pst.currPrice);
        
        uint teamReward = premium.mul(20).div(100);         // 20%
        uint createrReward = premium.mul(24).div(100);      // 24%
        uint lastBidderReward = premium.mul(40).div(100);   // 40%
        uint newReservedReward = premium.sub(teamReward).sub(createrReward).sub(lastBidderReward);  // 16%;
        
        // 3. transfer reward to every participator
        IERC20(token1).transfer(pool.creator, createrReward);        // to creater  24%
        IERC20(token1).transfer(_rewardReceiver, teamReward);        // to team     20%
        if (bidderNumber != 0) {                                     // to last bidder 16%, if no bidder, to the creater.
            IERC20(token1).transfer(pst.lastBidder, lastBidderReward);      
        } else {
            IERC20(token1).transfer(_rewardReceiver, lastBidderReward);
        }

        // 4. update pool info
        pst.currPrice = token1Amount;
        pst.reservedReward = pst.reservedReward.add(newReservedReward);
        pst.timeToLive = pst.timeToLive.add(pool.moreBidTime);
        pst.lastBidder = _msgSender();
        if (pst.status == POOL_OPEN) {
            pst.status = POOL_BIDDING;
        }
        
        // 5. update bids
        if (bidderNumber != 0) {   // update lastBidder's reward.
            bids[poolId][bidderNumber - 1].reward = lastBidderReward;
            
            bidderReward[poolId][pst.lastBidder] = lastBidderReward;
        }
        BidInfo memory newBid;
        newBid.bidder = _msgSender();
        newBid.price = token1Amount;
        newBid.time = block.timestamp;
        bids[poolId].push(newBid);

        emit Bid(msg.sender, poolId, token1Amount);
    }
    
    
    function claim(uint256 poolId) external isPoolDated(poolId) {
        PoolStatus storage pst = poolsStatus[poolId];
        require(msg.sender == pst.lastBidder, "only the last bidder can claim.");
        
        PoolMetaInfo memory pool = pools[poolId];
        // 1. give back nft
        if (pools[poolId].token0Type == TypeErc721) {
            IERC721(pool.token0).safeTransferFrom(address(this), msg.sender, pool.token0Id);
        } else {
            IERC1155(pool.token0).safeTransferFrom(address(this), msg.sender, pool.token0Id, pool.token0Amount, "");
        }
        
        // 2. give back reward
        IERC20(pool.token1).transfer(_msgSender(), pst.reservedReward);
        
        // 3. update pool status
        pst.reservedReward = 0;
        pst.status = POOL_CLOSED;
        
        emit Claimed(msg.sender, poolId);
    }
    
    function retrieval(uint256 poolId) external isPoolExist(poolId) {
        address creator = pools[poolId].creator;
        require(_msgSender() == creator, "you cannot access to this.");
        require(getPoolStatus(poolId) == POOL_PASSED, "the status of the pool must be passed.");

        // 1 give back token0
        if (pools[poolId].token0Type == TypeErc721) {
            IERC721(pools[poolId].token0).safeTransferFrom(address(this), creator, pools[poolId].token0Id);
        } else {
            IERC1155(pools[poolId].token0).safeTransferFrom(address(this), creator, pools[poolId].token0Id, pools[poolId].token0Amount, "");
        }
        
        // 2. change status
        poolsStatus[poolId].status = POOL_RETRIEVALED;
    }
    
    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return this.onERC1155Received.selector;
    }
    
    function getPoolStatus(uint poolId) public view isPoolExist(poolId) returns(uint status) {
        if (poolId >= pools.length) {
            status = POOL_UNSTARTED;
        } else {
            PoolMetaInfo memory pool = pools[poolId];
            PoolStatus memory pst = poolsStatus[poolId];
            uint st = pst.status;
            if (st == POOL_OPEN) {
                if (pool.startAt + pst.timeToLive >= block.timestamp) {
                    status = POOL_OPEN;
                } else {
                    status = POOL_PASSED;
                }
            } else if (st == POOL_BIDDING) {
                if (pool.startAt + pst.timeToLive >= block.timestamp) {
                    status = POOL_BIDDING;
                } else {
                    status = POOL_DATED;
                }
            } else if (st == POOL_CLOSED) {
                status = POOL_CLOSED;
            } else if (st == POOL_CANCELED) {
                status = POOL_CANCELED;
            } else if (st == POOL_RETRIEVALED) {
                status = POOL_RETRIEVALED;
            }
        }
    }
    
    function getBidderReward(uint poolId, address bidder) external view isPoolExist(poolId) returns (uint) {
        PoolStatus memory pst = poolsStatus[poolId];
        if (bidder == pst.lastBidder) {
            return pst.reservedReward;
        } else {
            return bidderReward[poolId][bidder];
        }
    }
    
    function getAllERC20TokenBack(address token1) external onlyOwner()  {
        uint256 balance = IERC20(_trias).balanceOf(address(this));
        if (balance != 0) {
            IERC20(token1).transfer(_rewardReceiver, balance);
        }
    }
    
    function getERC721TokenBack(address token0, uint256 token0Id) external onlyOwner()  {
        if  (IERC721(token0).ownerOf(token0Id) == address(this)) {
            IERC721(token0).safeTransferFrom(address(this), _rewardReceiver, token0Id);
        }
    }
    
        // pool has created.
    modifier isPoolExist(uint poolId) {
        require(poolId < pools.length, "this poolId is invalid");
        _;
    }
    
    // pool is open or bidding
    modifier isPoolOpen(uint poolId) {
        require(poolId < pools.length 
                && (getPoolStatus(poolId) == POOL_OPEN || getPoolStatus(poolId) == POOL_BIDDING), 
            "this pool is not open or bidding");
        _;
    }

    // pool is dated.
    modifier isPoolDated(uint poolId) {
        require(poolId < pools.length && getPoolStatus(poolId) == POOL_DATED,
            "this pool is not dated");
        _;
    }

}