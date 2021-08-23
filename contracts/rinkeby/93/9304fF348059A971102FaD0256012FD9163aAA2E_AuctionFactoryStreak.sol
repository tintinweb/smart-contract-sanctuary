pragma solidity ^0.8.0;

import "../openzepplin-contracts/utils/math/SafeMath.sol";
import "../openzepplin-contracts/token/ERC20/IERC20.sol";
import "../openzepplin-contracts/token/ERC1155/IERC1155.sol";
import "../openzepplin-contracts/token/ERC721/IERC721.sol";
import "./AuctionStreak.sol";


contract AuctionFactoryStreak {
  using SafeMath for uint;

  struct AuctionParameters {
    uint startingBid;
    uint bidStep;
    uint startTimestamp;
    uint endTimestamp;
    uint overtimeSeconds;
    uint feeRate;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  bytes32 public name = "AuctionFactoryStreak";
  address owner;
  IERC20 public erc20StreakContract;
  IERC721 public erc721StreakContract;
  IERC1155 public erc1155StreakContract;
  mapping(address => AuctionParameters) public auctionParameters;

  event AuctionCreated(address indexed auctionContract, address indexed beneficiary, uint indexed tokenId);
  event BidPlaced (address indexed bidder, uint bid, address indexed auctionContract);
  event FundsClaimed (address indexed claimer, address withdrawalAccount, uint withdrawalAmount, address indexed auctionContract);
  event ItemClaimed (address indexed claimer, address indexed auctionContract);
  event AuctionCancelled (address indexed auctionContract);

  constructor(address _erc20StreakAddress, address _erc721StreakContract, address _erc1155StreakContract) {
    owner = msg.sender;
    erc20StreakContract = IERC20(_erc20StreakAddress);
    erc721StreakContract = IERC721(_erc721StreakContract);
    erc1155StreakContract = IERC1155(_erc1155StreakContract);
  }

  function createAuction(
    address beneficiary,
    uint tokenId,
    uint bidStep,
    uint startingBid,
    uint startTimestamp,
    uint endTimestamp,
    bool acceptERC20,
    bool isErc1155,
    uint quantity,
    uint feeRate,
    uint overtimeSeconds
  )
  onlyOwner
  external
  {
    require(beneficiary != address(0));
    require(bidStep > 0);
    require(startingBid >= 0);
    require(startTimestamp < endTimestamp);
    require(startTimestamp >= block.timestamp);
    require(feeRate <= 100);
    if (isErc1155) {
      require(quantity > 0);
    }

    AuctionStreak newAuction = new AuctionStreak(
      msg.sender,
      beneficiary,
      acceptERC20,
      isErc1155,
      tokenId,
      quantity,
      address(erc20StreakContract),
      address(erc721StreakContract),
      address(erc1155StreakContract)
    );

    auctionParameters[address(newAuction)] = AuctionParameters(
      startingBid,
      bidStep,
      startTimestamp,
      endTimestamp,
      overtimeSeconds,
      feeRate
    );

    if (isErc1155) {
      erc1155StreakContract.safeTransferFrom(msg.sender, address(newAuction), tokenId, quantity, "");
    } else {
      erc721StreakContract.safeTransferFrom(msg.sender, address(newAuction), tokenId);
    }

    emit AuctionCreated(address(newAuction), beneficiary, tokenId);
  }

  function placeBid(
    address auctionAddress
  )
  payable
  external
  {
    AuctionStreak auction = AuctionStreak(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(block.timestamp >= parameters.startTimestamp);
    require(block.timestamp < parameters.endTimestamp);
    require(!auction.cancelled());
    require(!auction.acceptERC20());
    require(msg.sender != auction.controller());
    require(msg.sender != auction.beneficiary());
    require(msg.value > 0);

    // calculate the user's total bid
    uint totalBid = auction.fundsByBidder(msg.sender) + msg.value;

    if (auction.highestBid() == 0) {
      // reject if user did not overbid
      require(totalBid >= parameters.startingBid);
    } else {
      // reject if user did not overbid
      require(totalBid >= auction.highestBid() + parameters.bidStep);
    }

    auction.handlePayment{value:msg.value}();
    auction.placeBid(msg.sender, totalBid);

    // if bid was placed within specified number of blocks before the auction's end
    // extend auction time
    if (parameters.overtimeSeconds > parameters.endTimestamp - block.timestamp) {
      auctionParameters[auctionAddress].endTimestamp += parameters.overtimeSeconds;
    }

    emit BidPlaced(msg.sender, totalBid, auctionAddress);
  }

  function placeBidERC20(address auctionAddress, uint amount)
  external
  {
    AuctionStreak auction = AuctionStreak(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(block.timestamp >= parameters.startTimestamp);
    require(block.timestamp < parameters.endTimestamp);
    require(!auction.cancelled());
    require(auction.acceptERC20());
    require(msg.sender != auction.controller());
    require(msg.sender != auction.beneficiary());
    require(amount > 0);

    // calculate the user's total bid
    uint totalBid = auction.fundsByBidder(msg.sender) + amount;

    if (auction.highestBid() == 0) {
      // reject if user did not overbid
      require(totalBid >= parameters.startingBid);
    } else {
      // reject if user did not overbid
      require(totalBid >= auction.highestBid() + parameters.bidStep);
    }

    require(erc20StreakContract.transferFrom(msg.sender, auctionAddress, amount));
    auction.placeBid(msg.sender, totalBid);

    // if bid was placed within specified number of blocks before the auction's end
    // extend auction time
    if (parameters.overtimeSeconds > parameters.endTimestamp - block.timestamp) {
      auctionParameters[auctionAddress].endTimestamp += parameters.overtimeSeconds;
    }

    emit BidPlaced(msg.sender, totalBid, auctionAddress);
  }

  function claimFunds(address auctionAddress)
  external
  {
    AuctionStreak auction = AuctionStreak(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(auction.cancelled() || block.timestamp >= parameters.endTimestamp);

    address withdrawalAccount;
    uint withdrawalAmount;
    bool beneficiaryClaimedFunds;
    bool controllerClaimedFunds;

    if (auction.cancelled()) {
      // if the auction was cancelled, everyone should be allowed to withdraw their funds
      withdrawalAccount = msg.sender;
      withdrawalAmount = auction.fundsByBidder(withdrawalAccount);
    } else {
      // the auction finished without being cancelled

      // reject when auction winner claims funds
      require(msg.sender != auction.highestBidder());

      // everyone except auction winner should be allowed to withdraw their funds
      if (msg.sender == auction.beneficiary()) {
        require(parameters.feeRate < 100 && !auction.beneficiaryClaimedFunds());
        withdrawalAccount = auction.highestBidder();
        withdrawalAmount = auction.highestBid().mul(100 - parameters.feeRate).div(100);
        beneficiaryClaimedFunds = true;
      } else if (msg.sender == auction.controller()) {
        require(parameters.feeRate > 0 && !auction.controllerClaimedFunds());
        withdrawalAccount = auction.highestBidder();
        withdrawalAmount = auction.highestBid().mul(parameters.feeRate).div(100);
        controllerClaimedFunds = true;
      } else {
        withdrawalAccount = msg.sender;
        withdrawalAmount = auction.fundsByBidder(withdrawalAccount);
      }
    }

    // reject when there are no funds to claim
    require(withdrawalAmount != 0);

    auction.withdrawFunds(msg.sender, withdrawalAccount, withdrawalAmount, beneficiaryClaimedFunds, controllerClaimedFunds);

    emit FundsClaimed(msg.sender, withdrawalAccount, withdrawalAmount, auctionAddress);
  }

  function claimItem(address auctionAddress)
  external
  {
    AuctionStreak auction = AuctionStreak(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(!auction.itemClaimed());
    require(auction.cancelled() || block.timestamp >= parameters.endTimestamp);

    if (auction.cancelled()
      || (auction.highestBidder() == address(0) && block.timestamp >= parameters.endTimestamp)) {
      require(msg.sender == auction.beneficiary());
    } else {
      require(msg.sender == auction.highestBidder());
    }

    auction.transferItem(msg.sender);

    emit ItemClaimed(msg.sender, auctionAddress);
  }

  function cancelAuction(address auctionAddress)
  onlyOwner
  external
  {
    AuctionStreak auction = AuctionStreak(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(!auction.cancelled());
    require(block.timestamp < parameters.endTimestamp);

    auction.cancelAuction();
    emit AuctionCancelled(auctionAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
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

pragma solidity ^0.8.0;

import "../openzepplin-contracts/token/ERC721/IERC721Receiver.sol";
import "../openzepplin-contracts/token/ERC1155/IERC1155Receiver.sol";
import "../openzepplin-contracts/token/ERC20/IERC20.sol";
import "../openzepplin-contracts/token/ERC721/IERC721.sol";
import "../openzepplin-contracts/token/ERC1155/IERC1155.sol";

contract AuctionStreak is IERC721Receiver, IERC1155Receiver {
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  address public owner;
  address public controller;
  address public beneficiary;
  address public highestBidder;

  uint public tokenId;
  uint public quantity;
  uint public highestBid;

  bool public cancelled;
  bool public itemClaimed;
  bool public controllerClaimedFunds;
  bool public beneficiaryClaimedFunds;
  bool public acceptERC20;
  bool public isErc1155;

  IERC20 erc20StreakContract;
  IERC721 erc721StreakContract;
  IERC1155 erc1155StreakContract;

  mapping(address => uint256) public fundsByBidder;

  constructor(
    address _controller,
    address _beneficiary,
    bool _acceptERC20,
    bool _isErc1155,
    uint _tokenId,
    uint _quantity,
    address erc20StreakAddress,
    address erc721StreakAddress,
    address erc1155StreakAddress
  ) {
    owner = msg.sender;
    controller = _controller;
    beneficiary = _beneficiary;
    acceptERC20 = _acceptERC20;
    isErc1155 = _isErc1155;
    tokenId = _tokenId;
    quantity = _quantity;

    if (acceptERC20) {
      erc20StreakContract = IERC20(erc20StreakAddress);
    }

    if (isErc1155) {
      erc1155StreakContract = IERC1155(erc1155StreakAddress);
    } else {
      erc721StreakContract = IERC721(erc721StreakAddress);
    }
  }

  function placeBid(address bidder, uint totalAmount)
  onlyOwner
  external
  {
    fundsByBidder[bidder] = totalAmount;

    if (bidder != highestBidder) {
      highestBidder = bidder;
    }

    highestBid = totalAmount;
  }

  function handlePayment()
  payable
  onlyOwner
  external
  {}

  function withdrawFunds(
    address claimer,
    address withdrawalAccount,
    uint withdrawalAmount,
    bool _beneficiaryClaimedFunds,
    bool _controllerClaimedFunds
  )
  onlyOwner
  external
  {
    fundsByBidder[withdrawalAccount] -= withdrawalAmount;
    if (_beneficiaryClaimedFunds) {
      beneficiaryClaimedFunds = true;
    }
    if (_controllerClaimedFunds) {
      controllerClaimedFunds = true;
    }
    // send the funds
    if (acceptERC20) {
      require(erc20StreakContract.transfer(claimer, withdrawalAmount));
    } else {
      (bool sent, ) = claimer.call{value: withdrawalAmount}("");
      require(sent);
    }
  }

  function transferItem(
    address claimer
  )
  onlyOwner
  external
  {
    if (isErc1155) {
      erc1155StreakContract.safeTransferFrom(address(this), claimer, tokenId, quantity, "");
    } else {
      erc721StreakContract.safeTransferFrom(address(this), claimer, tokenId);
    }

    itemClaimed = true;
  }

  function cancelAuction()
  onlyOwner
  external
  {
    cancelled = true;
  }

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata data)
  external
  pure
  override
  returns (bytes4)
  {
    return this.onERC721Received.selector;
  }

  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data)
  external
  pure
  override
  returns(bytes4)
  {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data)
  external
  pure
  override
  returns(bytes4)
  {
    return this.onERC1155BatchReceived.selector;
  }

  /**
 * @dev See {IERC165-supportsInterface}.
 */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC721Receiver).interfaceId
    || interfaceId == type(IERC1155Receiver).interfaceId;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}