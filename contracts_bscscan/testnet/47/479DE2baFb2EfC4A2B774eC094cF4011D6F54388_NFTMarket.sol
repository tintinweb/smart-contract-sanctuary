// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract NFTMarket {
    using SafeMath for uint256;

    address public nonFungibleTokenAddress;
    address public busdTokenAddress;
    uint256 private orderId;

    uint256 oneday = 86400;

    struct Offer {
        bool isForSale;
        uint256 itemId;
        address seller;
        uint256 minValue; // in busd
        address onlySellTo; // specify to sell only to a specific person
        uint256 from; // auction start Time
        uint256 to; // auction end time
        uint256 amount; // amount
    }

    struct Bid {
        bool hasBid;
        uint256 orderId;
        uint256 itemIndex;
        address bidder;
        uint256 value;
    }

    // A record of items that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public itemsOfferedForSale;

    // A record of the highest bid
    mapping(uint256 => Bid) public itemBids;

    mapping(address => uint256) public pendingWithdrawals;

    mapping(address => mapping(uint256 => uint256)) pendingItems;

    event ItemNoLongerForSale(uint256 orderId, uint256 itemId);
    event ItemOffered(
        uint256 orderId,
        address seller,
        uint256 itemId,
        uint256 minValue,
        address toAddress,
        uint256 amount
    );
    event NewBidEntered(
        uint256 orderId,
        uint256 itemId,
        uint256 value,
        address fromAddress
    );
    event BidWithdrawn(
        uint256 orderId,
        uint256 itemId,
        uint256 value,
        address fromAddress
    );
    event ItemBought(
        uint256 orderId,
        uint256 itemId,
        uint256 amount,
        uint256 value,
        address fromAddress,
        address toAddress
    );

    constructor(address busdToken_, address nonFungibleToken_) public {
        require(nonFungibleToken_ != address(0));
        nonFungibleTokenAddress = nonFungibleToken_;
        busdTokenAddress = busdToken_;
    }

    function nextOrderId() public view returns (uint256) {
        return orderId.add(1);
    }

    function itemNoLongerForSale(uint256 orderId_) public {
        Offer memory offer = itemsOfferedForSale[orderId_];
        require(msg.sender == offer.seller, "You don't offer this token.");
        require(offer.amount > 0, "The order has no longer for sale.");
        _itemNoLongerForSale(orderId_);
    }

    function _itemNoLongerForSale(uint256 orderId_) internal {
        Offer memory offer = itemsOfferedForSale[orderId_];
        require(
            pendingItems[offer.seller][offer.itemId] >= offer.amount,
            "You don't own this token."
        );

        pendingItems[offer.seller][offer.itemId] = pendingItems[offer.seller][
            offer.itemId
        ]
            .sub(offer.amount);

        itemsOfferedForSale[orderId_] = Offer(
            false,
            offer.itemId,
            msg.sender,
            0,
            address(0),
            0,
            0,
            0
        );
        emit ItemNoLongerForSale(orderId_, offer.itemId);
    }

    function offerItemForSale(
        uint256 itemId,
        uint256 minSalePriceInWei,
        bool isForSale,
        uint256 durationDays,
        uint256 amount
    ) public {
        IERC1155 token = IERC1155(nonFungibleTokenAddress);
        require(amount > 0, "Amount gt 0");
        require(
            token.balanceOf(msg.sender, itemId) -
                pendingItems[msg.sender][itemId] >=
                amount,
            "You don't own this token amount."
        );
        require(
            token.isApprovedForAll(msg.sender, address(this)) == true,
            "Approve this token first."
        );
        uint256 from = block.timestamp;
        orderId = nextOrderId();
        itemsOfferedForSale[orderId] = Offer(
            isForSale,
            itemId,
            msg.sender,
            minSalePriceInWei,
            address(0),
            from,
            from + durationDays * oneday,
            amount
        );
        pendingItems[msg.sender][itemId] = pendingItems[msg.sender][itemId].add(
            amount
        );
        emit ItemOffered(
            orderId,
            msg.sender,
            itemId,
            minSalePriceInWei,
            address(0),
            amount
        );
    }

    function offerItemForSaleToAddress(
        uint256 itemId,
        uint256 minSalePriceInWei,
        address toAddress,
        uint256 durationDays,
        uint256 amount
    ) public {
        IERC1155 token = IERC1155(nonFungibleTokenAddress);
        require(
            token.balanceOf(msg.sender, itemId) -
                pendingItems[msg.sender][itemId] >=
                amount,
            "You don't own this token amount."
        );
        require(
            token.isApprovedForAll(msg.sender, address(this)) == true,
            "Approve this token first."
        );
        uint256 from = block.timestamp;
        orderId = nextOrderId();
        itemsOfferedForSale[orderId] = Offer(
            true,
            itemId,
            msg.sender,
            minSalePriceInWei,
            toAddress,
            from,
            from + durationDays * oneday,
            amount
        );
        pendingItems[msg.sender][itemId] = pendingItems[msg.sender][itemId].add(
            amount
        );
        emit ItemOffered(
            orderId,
            msg.sender,
            itemId,
            minSalePriceInWei,
            toAddress,
            amount
        );
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "You deposit nothing!");
        IERC20 token = IERC20(busdTokenAddress);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "BUSD transfer failed"
        );
        pendingWithdrawals[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        require(
            amount <= pendingWithdrawals[msg.sender],
            "amount larger than that pending to withdraw"
        );
        pendingWithdrawals[msg.sender] -= amount;
        IERC20 token = IERC20(busdTokenAddress);
        require(token.transfer(msg.sender, amount), "BUSD transfer failed");
    }

    function buyItem(uint256 orderId_, uint256 amount) public {
        Offer memory offer = itemsOfferedForSale[orderId_];
        require(offer.isForSale, "This item not actually for sale.");
        require(
            offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender,
            "this item not supposed to be sold to this user"
        );
        require(amount >= offer.minValue, "You didn't send enough BUSD.");

        IERC1155 nft = IERC1155(nonFungibleTokenAddress);
        require(
            nft.balanceOf(offer.seller, offer.itemId) > 0,
            "Seller no longer owner of this item."
        );

        IERC20 busd = IERC20(busdTokenAddress);
        require(
            busd.transferFrom(msg.sender, address(this), amount),
            "BUSD transfer failed"
        );

        address seller = offer.seller;
        nft.safeTransferFrom(
            seller,
            msg.sender,
            offer.itemId,
            offer.amount,
            ""
        );

        _itemNoLongerForSale(orderId_);
        pendingWithdrawals[seller] += amount;
        emit ItemBought(
            orderId_,
            offer.itemId,
            offer.amount,
            amount,
            seller,
            msg.sender
        );

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = itemBids[orderId_];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            itemBids[orderId_] = Bid(
                false,
                orderId_,
                offer.itemId,
                address(0),
                0
            );
        }
    }

    function enterBid(uint256 orderId_, uint256 amount) public {
        require(
            pendingWithdrawals[msg.sender] >= amount,
            "Please deposit enough busd before bid!"
        );
        Offer memory offer = itemsOfferedForSale[orderId_];

        Bid memory existing = itemBids[orderId_];
        require(
            amount > existing.value,
            "The new bid should be larger than existing bids"
        );

        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }

        // Lock the current bid
        pendingWithdrawals[msg.sender] -= amount;

        itemBids[orderId_] = Bid(
            true,
            orderId_,
            offer.itemId,
            msg.sender,
            amount
        );
        emit NewBidEntered(orderId_, offer.itemId, amount, msg.sender);
    }

    function acceptBid(uint256 orderId_) public {
        IERC1155 nft = IERC1155(nonFungibleTokenAddress);
        Offer memory offer = itemsOfferedForSale[orderId_];
        require(
            nft.balanceOf(msg.sender, offer.itemId) >= offer.amount,
            "You don't own this token."
        );
        require(
            nft.isApprovedForAll(msg.sender, address(this)) == true,
            "Approve this token first."
        );

        address seller = msg.sender;
        Bid memory bid = itemBids[orderId_];
        require(bid.value > 0, "Nobody bid for this item yet.");

        nft.safeTransferFrom(
            seller,
            bid.bidder,
            offer.itemId,
            offer.amount,
            ""
        );

        pendingItems[msg.sender][offer.itemId] = pendingItems[msg.sender][
            offer.itemId
        ]
            .sub(offer.amount);

        itemsOfferedForSale[orderId_] = Offer(
            false,
            offer.itemId,
            bid.bidder,
            0,
            address(0),
            0,
            0,
            0
        );
        uint256 amount = bid.value;
        itemBids[orderId_] = Bid(false, orderId_, offer.itemId, address(0), 0);
        pendingWithdrawals[seller] += amount;
        emit ItemBought(
            orderId_,
            offer.itemId,
            offer.amount,
            bid.value,
            seller,
            bid.bidder
        );
    }

    function withdrawBid(uint256 orderId_) public {
        Bid memory bid = itemBids[orderId_];
        require(bid.bidder == msg.sender, "You don't have a bid for it.");
        emit BidWithdrawn(orderId_, bid.itemIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        itemBids[orderId_] = Bid(false, orderId_, bid.itemIndex, address(0), 0);
        // Refund the bid money
        pendingWithdrawals[msg.sender] += amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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