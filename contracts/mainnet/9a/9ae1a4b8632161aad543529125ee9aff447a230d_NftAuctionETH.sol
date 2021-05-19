/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.6.6;


// SPDX-License-Identifier: MIT
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
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
/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT
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

    constructor () internal {
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
contract BidETHWrapper {
  using SafeMath for uint256;
  IERC20 public token;

  uint256 public constant MAX_FEE = 100;

  uint256 private _totalSupply;
  // Objects balances [id][address] => balance
  mapping(uint256 => mapping(address => uint256)) internal _balances;
  mapping(uint256 => uint256) private _totalDeposits;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function totalDeposits(uint256 id) public view returns (uint256) {
    return _totalDeposits[id];
  }

  function balanceOf(address account, uint256 id) public view returns (uint256) {
    return _balances[id][account];
  }

  function bid(uint256 id) public payable virtual {
    uint256 amount = msg.value;
    _totalSupply = _totalSupply.add(amount);
    _totalDeposits[id] = _totalDeposits[id].add(amount);
    _balances[id][msg.sender] = _balances[id][msg.sender].add(amount);
  }

  function withdraw(uint256 id) public virtual {
    uint256 amount = balanceOf(msg.sender, id);
    _totalSupply = _totalSupply.sub(amount);
    _totalDeposits[id] = _totalDeposits[id].sub(amount);
    _balances[id][msg.sender] = _balances[id][msg.sender].sub(amount);
    payable(msg.sender).transfer(amount);
  }

  function _emergencyWithdraw(address account, uint256 id) internal {
    uint256 amount = _balances[id][account];

    _totalSupply = _totalSupply.sub(amount);
    _totalDeposits[id] = _totalDeposits[id].sub(amount);
    _balances[id][account] = _balances[id][account].sub(amount);
    payable(account).transfer(amount);
  }

  function _end(
    uint256 id,
    address highestBidder,
    address beneficiary,
    address runner,
    uint256 fee,
    uint256 amount
  ) internal {
    uint256 accountDeposits = _balances[id][highestBidder];
    require(accountDeposits == amount);

    _totalSupply = _totalSupply.sub(amount);
    uint256 tokenFee = (amount.mul(fee)).div(MAX_FEE);

    _totalDeposits[id] = _totalDeposits[id].sub(amount);
    _balances[id][highestBidder] = _balances[id][highestBidder].sub(amount);
    payable(beneficiary).transfer(amount.sub(tokenFee));
    payable(runner).transfer(tokenFee);
  }
}

// SPDX-License-Identifier: MIT
/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, 
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
interface IERC1155Tradable {
  /**
   * @dev Creates a new token type and assigns _initialSupply to an address
   * @param _maxSupply max supply allowed
   * @param _initialSupply Optional amount to supply the first owner
   * @param _uri Optional URI for this token type
   * @param _data Optional data to pass if receiver is contract
   * @return tokenId The newly created token ID
   */
  function create(
    uint256 _maxSupply,
    uint256 _initialSupply,
    string calldata _uri,
    bytes calldata _data,
    address _beneficiary,
    uint256 _residualsFee,
    bool _residualsRequired
  ) external returns (uint256 tokenId);

  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes calldata _data
  ) external;
}

// SPDX-License-Identifier: MIT
/***********************************************************************
  Modified @openzeppelin/contracts/token/ERC1155/IERC1155.sol
  Allow overriding of some methods and use of some variables
  in inherited contract.
----------------------------------------------------------------------*/
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
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
  ) external payable;

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
  ) external payable;
}

// SPDX-License-Identifier: MIT
contract NftAuctionETH is Ownable, ReentrancyGuard, BidETHWrapper, IERC1155Receiver {
  using SafeMath for uint256;

  address public nftsAddress;
  address public runner;

  // info about a particular auction
  struct AuctionInfo {
    address beneficiary;
    uint256 fee;
    uint256 auctionStart;
    uint256 auctionEnd;
    uint256 originalAuctionEnd;
    uint256 endedAt;
    uint256 extension;
    uint256 nft;
    address highestBidder;
    uint256 highestBid;
    uint256 startBidWei;
    uint256 bidStepWei;
    uint256 buyNowPriceWei;
    bool auctionEnded;
  }

  mapping(uint256 => AuctionInfo) public auctionsById;
  uint256[] public auctions;

  // Events that will be fired on changes.
  event BidPlaced(address indexed user, uint256 indexed id, uint256 amount);
  event Withdrawn(address indexed user, uint256 indexed id, uint256 amount);
  event Ended(address indexed user, uint256 indexed id, uint256 amount);
  event RunnerFeeChanged(uint256 indexed id, uint256 fee);

  constructor(address _runner, address _nftsAddress) public {
    runner = _runner;
    nftsAddress = _nftsAddress;
  }

  function auctionStart(uint256 id) public view returns (uint256) {
    return auctionsById[id].auctionStart;
  }

  function beneficiary(uint256 id) public view returns (address) {
    return auctionsById[id].beneficiary;
  }

  function auctionEnd(uint256 id) public view returns (uint256) {
    return auctionsById[id].auctionEnd;
  }

  function nftTokenId(uint256 id) public view returns (uint256) {
    return auctionsById[id].nft;
  }

  function highestBidder(uint256 id) public view returns (address) {
    return auctionsById[id].highestBidder;
  }

  function highestBid(uint256 id) public view returns (uint256) {
    return auctionsById[id].highestBid;
  }

  function isEndedByTime(uint256 id) public view returns (bool) {
    return now >= auctionsById[id].auctionEnd;
  }

  function ended(uint256 id) public view returns (bool) {
    return auctionsById[id].auctionEnded;
  }

  function bidStepWei(uint256 id) public view returns (uint256) {
    return auctionsById[id].bidStepWei;
  }

  function startBidWei(uint256 id) public view returns (uint256) {
    return auctionsById[id].startBidWei;
  }

  function buyNowPriceWei(uint256 id) public view returns (uint256) {
    return auctionsById[id].buyNowPriceWei;
  }

  function endedAt(uint256 id) public view returns (uint256) {
    return auctionsById[id].endedAt;
  }

  function runnerFee(uint256 id) public view returns (uint256) {
    return auctionsById[id].fee;
  }

  function setRunnerAddress(address account) public onlyOwner {
    runner = account;
  }

  function create(
    uint256 id,
    address beneficiaryAddress,
    uint256 fee,
    uint256 start,
    uint256 duration,
    uint256 extension, // in minutes
    uint256 _startBidWei,
    uint256 _bidStepWei,
    uint256 _buyNowPriceWei,
    address _tokenBeneficiary,
    uint256 _tokenResidualsFee,
    bool _tokenResidualsRequired
  ) public onlyOwner {
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary == address(0), "NftAuction::create: auction already created");
    require(_bidStepWei > 0, "NftAuction::create: bid step = 0");
    require(_buyNowPriceWei > _bidStepWei, "NftAuction::create: buy now price too small");

    auction.beneficiary = beneficiaryAddress;
    auction.fee = fee;
    auction.auctionStart = start;
    auction.auctionEnd = start.add(duration * 1 days);
    auction.originalAuctionEnd = start.add(duration * 1 days);
    auction.extension = extension * 60;
    auction.startBidWei = _startBidWei;
    auction.bidStepWei = _bidStepWei;
    auction.buyNowPriceWei = _buyNowPriceWei;

    auctions.push(id);

    uint256 tokenId =
      IERC1155Tradable(nftsAddress).create(
        1,
        1,
        "",
        "",
        _tokenBeneficiary,
        _tokenResidualsFee,
        _tokenResidualsRequired
      );
    require(tokenId > 0, "NftAuction::create: ERC1155 create did not succeed");
    auction.nft = tokenId;
  }

  function bid(uint256 id) public payable override nonReentrant {
    uint256 amount = msg.value;
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary != address(0), "NftAuction::bid: auction does not exist");
    require(now >= auction.auctionStart, "NftAuction::bid: auction has not started");
    require(now <= auction.auctionEnd, "NftAuction::bid: auction has ended");
    require(!auction.auctionEnded, "NftAuction::bid: auction has ended");

    uint256 newAmount = amount.add(balanceOf(msg.sender, id));
    if (auction.highestBid == 0) {
      require(newAmount >= auction.startBidWei, "NftAuction::bid: start bid too small");
    }
    require(newAmount >= auction.highestBid.add(auction.bidStepWei), "NftAuction::bid: bid too small");

    auction.highestBidder = msg.sender;
    auction.highestBid = newAmount;

    if (auction.extension > 0 && auction.auctionEnd.sub(now) <= auction.extension) {
      auction.auctionEnd = now.add(auction.extension);
    }

    super.bid(id);
    emit BidPlaced(msg.sender, id, amount);

    if (auction.highestBid >= auction.buyNowPriceWei) {
      end(id);
    }
  }

  function withdraw(uint256 id) public override nonReentrant {
    AuctionInfo storage auction = auctionsById[id];
    uint256 amount = balanceOf(msg.sender, id);
    require(auction.beneficiary != address(0), "NftAuction::withdraw: auction does not exist");
    require(amount > 0, "NftAuction::withdraw: cannot withdraw 0");

    require(
      auction.highestBidder != msg.sender,
      "NftAuction::withdraw: you are the highest bidder and cannot withdraw"
    );

    super.withdraw(id);
    emit Withdrawn(msg.sender, id, amount);
  }

  function emergencyWithdraw(uint256 id) public onlyOwner {
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary != address(0), "NftAuction::emergencyWithdraw: auction does not exist");
    require(now >= auction.auctionEnd, "NftAuction::emergencyWithdraw: the auction has not ended");
    require(!auction.auctionEnded, "NftAuction::emergencyWithdraw: auction ended and item sent");

    _emergencyWithdraw(auction.highestBidder, id);
    emit Withdrawn(auction.highestBidder, id, auction.highestBid);
  }

  function emergencyCancel(uint256 id, address bidder) public onlyOwner {
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary != address(0), "NftAuction::emergencyCancel: auction does not exist");
    require(auction.highestBidder != bidder, "NftAuction::emergencyCancel: address is highest bidder");

    uint256 _amount = balanceOf(bidder, id);
    require(_amount > 0, "NftAuction::emergencyCancel: cannot withdraw 0");
    _emergencyWithdraw(bidder, id);
    emit Withdrawn(bidder, id, _amount);
  }

  function end(uint256 id) internal {
    AuctionInfo storage auction = auctionsById[id];
    auction.auctionEnded = true;
    auction.endedAt = now;
    _end(id, auction.highestBidder, auction.beneficiary, runner, auction.fee, auction.highestBid);
    IERC1155(nftsAddress).safeTransferFrom(address(this), auction.highestBidder, auction.nft, 1, "");
    emit Ended(auction.highestBidder, id, auction.highestBid);
  }

  function close(uint256 id) public nonReentrant {
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary != address(0), "NftAuction::end: auction does not exist");
    require(now >= auction.auctionEnd, "NftAuction::end: the auction has not ended");
    require(!auction.auctionEnded, "NftAuction::end: auction already ended");
    end(id);
  }

  function setEndTime(uint256 id, uint256 endTimestamp) external onlyOwner {
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary != address(0), "NftAuction::setEndTime: auction does not exist");
    require(now <= auction.auctionEnd, "NftAuction::setEndTime: auction has ended");
    require(!auction.auctionEnded, "NftAuction::setEndTime: auction closed");
    require(auction.auctionStart < endTimestamp, "NftAuction::setEndTime: before start");

    auction.auctionEnd = endTimestamp;
    auction.originalAuctionEnd = endTimestamp;
  }

  function setRunnerFee(uint256 id, uint256 _fee) external onlyOwner {
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary != address(0), "NftAuction::setRunnerFee: auction does not exist");
    require(now <= auction.auctionEnd, "NftAuction::setRunnerFee: auction has ended");
    require(!auction.auctionEnded, "NftAuction::setRunnerFee: auction closed");
    require(_fee <= MAX_FEE, "NftAuction::setRunnerFee: fee too high");

    auction.fee = _fee;
    emit RunnerFeeChanged(id, _fee);
  }

  function setStartBid(uint256 id, uint256 _startBidWei) external onlyOwner {
    AuctionInfo storage auction = auctionsById[id];
    require(auction.beneficiary != address(0), "NftAuction::setStartBid: auction does not exist");
    require(now <= auction.auctionStart, "NftAuction::setStartBid: auction started");
    require(_startBidWei <= auction.buyNowPriceWei, "NftAuction::setStartBid: price less than startBid");
    require(_startBidWei > 0, "NftAuction::setStartBid: startBid == 0");

    auction.startBidWei = _startBidWei;
  }

  function onERC1155Received(
    address _operator,
    address, // _from
    uint256, // _id
    uint256, // _amount
    bytes memory // _data
  ) public override returns (bytes4) {
    require(msg.sender == address(nftsAddress), "NftAuction::onERC1155Received:: invalid token address");
    require(_operator == address(this), "NftAuction::onERC1155Received:: operator must be auction contract");

    // Return success
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address _operator,
    address, // _from,
    uint256[] memory, // _ids,
    uint256[] memory, // _amounts,
    bytes memory // _data
  ) public override returns (bytes4) {
    require(msg.sender == address(nftsAddress), "NftAuction::onERC1155BatchReceived:: invalid token address");
    require(_operator == address(this), "NftAuction::onERC1155BatchReceived:: operator must be auction contract");

    // Return success
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
   *
   * INTERFACE_SIGNATURE_ERC1155TokenReceiver =
   * bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
   * ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
   */
  function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
    return
      interfaceID == 0x01ffc9a7 || // ERC-165 support
      interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support
  }
}