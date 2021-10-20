//
//   _____ _          _____ _ _ _       _
//  |_   _| |_ ___   |   __| |_| |_ ___| |_ ___ ___
//    | | |   | -_|  |  |  | | |  _|  _|   | -_|_ -|
//    |_| |_|_|___|  |_____|_|_|_| |___|_|_|___|___|
//
//
// The Glitches
// A free to mint 5k PFP project, focused on diversity and inclusion. We are community oriented.
//
// Twitter: https://twitter.com/theglitches_
//
// Project by:      @daniel100eth
// Art by:          @maxwell_step
// Code by:         @altcryp
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';


contract GlitchMarketplace is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private orderIds;
    Counters.Counter private tradeIds;

    bool public active = true;
    uint256 royalty = 5;
    address royaltyAddress;

    IERC721 Glitch;

    struct Order {
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    struct Trade {
        address seller;
        address buyer;
        uint256 tokenId_1;
        uint256 tokenId_2;
        bool isActive;
        string memo;
        uint256 responses;
    }

    struct Status {
        uint256 forSale;
        uint256 forTrade;
        uint256 forTradeResponse;
    }

    uint256 public activeOrders;
    mapping (uint256 => Order) public Orders;

    uint256 public activeTrades;
    mapping (uint256 => Trade) public Trades;
    mapping (uint256 => mapping(uint256 => uint256)) public TradeResponses;  // maps trade id to token ids

    event TradeEvent(uint256 tradeId, uint256 tokenId_1, uint256 tokenId_2, address seller, address buyer);
    event TradeListedEvent(uint256 tradeId, uint256 tokenId_1, string memo, address seller);
    event SaleEvent(uint256 orderId, uint256 tokenId, uint256 amount, address seller, address buyer);
    event SaleListedEvent(uint256 orderId, uint256 tokenId, uint256 amount, address seller);

    // Constructor
    constructor(address glitchAddress, address _royaltyAddress) {
        Glitch = IERC721(glitchAddress);
        royaltyAddress = _royaltyAddress;
    }

    // List
    function list(uint256 tokenId, uint256 price) public {
        require(active, "Transfers are not active.");
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to list.");
        require(Glitch.isApprovedForAll(msg.sender, address(this)), "You must approve tokens first.");
        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale == 0, "Glitch is already for sale.");
        require(status.forTrade == 0, "Glitch is already for trade.");
        require(status.forTradeResponse == 0, "Glitch is already for trade response.");

        orderIds.increment();
        Orders[orderIds.current()] = Order(msg.sender, address(0), tokenId, price, true);
        activeOrders++;

        emit SaleListedEvent(orderIds.current(), tokenId, price, msg.sender);
    }

    function changePrice(uint256 tokenId, uint256 price) public {
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to change price.");
        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale > 0, "Glitch is not for sale.");

        Orders[status.forSale].price = price;
    }

    // Buy
    function buy(uint256 orderId) public payable {
        require(active, "Transfers are not active.");
        require(Orders[orderId].isActive, "Order is not active.");
        require(msg.value == Orders[orderId].price, "Price is not correct.");

        Order memory order = Orders[orderId];
        order.buyer = msg.sender;
        order.isActive = false;
        Orders[orderId] = order;
        activeOrders--;

        uint256 royaltyAmount = order.price.mul(royalty).div(100);

        Glitch.safeTransferFrom(order.seller, order.buyer, order.tokenId);
        payable(order.seller).transfer(order.price.sub(royaltyAmount));

        emit SaleEvent(orderId, order.tokenId, order.price, order.seller, order.buyer);
    }

    // TradeSeek
    function tradeSeek(uint256 tokenId, string memory memo) public {
        require(active, "Transfers are not active.");
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to trade.");
        require(Glitch.isApprovedForAll(msg.sender, address(this)), "You must approve tokens first.");

        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale == 0, "Glitch is already for sale.");
        require(status.forTrade == 0, "Glitch is already for trade.");
        require(status.forTradeResponse == 0, "Glitch is already for trade response.");

        tradeIds.increment();
        Trades[tradeIds.current()] = Trade(msg.sender, address(0), tokenId, 0, true, memo, 0);
        activeTrades++;

        emit TradeListedEvent(tradeIds.current(), tokenId, memo, msg.sender);
    }

    // TradeResponse
    function tradeResponse(uint256 tradeId, uint256 tokenId) public {
        require(active, "Transfers are not active.");
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to trade.");
        require(Glitch.isApprovedForAll(msg.sender, address(this)), "You must approve tokens first.");
        require(Trades[tradeId].isActive, "Trade is no longer active.");

        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale == 0, "Glitch is already for sale.");
        require(status.forTrade == 0, "Glitch is already for trade.");
        require(status.forTradeResponse == 0, "Glitch is already for trade response.");

        Trades[tradeId].responses++;
        TradeResponses[tradeId][Trades[tradeId].responses] = tokenId;
    }

    // TradeAccept
    function tradeAccept(uint256 tradeId, uint256 responseId) public {
        require(active, "Transfers are not active.");
        require(Trades[tradeId].seller == msg.sender, "You are not the seller.");
        require(Glitch.ownerOf(Trades[tradeId].tokenId_1) == msg.sender, "You must be owner to trade.");
        require(Trades[tradeId].isActive, "Trade is no longer active.");

        uint256 tradeTokenId = TradeResponses[tradeId][responseId];
        Trade memory trade = Trades[tradeId];

        require(Glitch.isApprovedForAll(Trades[tradeId].seller, address(this)), "Seller is not approved.");
        require(Glitch.isApprovedForAll(Glitch.ownerOf(tradeTokenId), address(this)), "Buyer is not approved.");

        trade.tokenId_2 = tradeTokenId;
        trade.buyer = Glitch.ownerOf(tradeTokenId);
        trade.isActive = false;
        Trades[tradeId] = trade;
        activeTrades--;

        Glitch.safeTransferFrom(trade.seller, trade.buyer, trade.tokenId_1);
        Glitch.safeTransferFrom(trade.buyer, trade.seller, trade.tokenId_2);

        emit TradeEvent(tradeId, trade.tokenId_1, trade.tokenId_2, trade.seller, trade.buyer);
    }

    // Cancel Listing
    function cancelListing(uint256 orderId) public {
        require(Orders[orderId].seller == msg.sender, "You are not the seller.");
        Orders[orderId].isActive = false;
        activeOrders--;
    }

    // Cancel TradeSeek
    function cancelTradeSeek(uint256 tradeId) public {
        require(Trades[tradeId].seller == msg.sender, "You are not the seller.");
        Trades[tradeId].isActive = false;
        activeTrades--;
    }

    // Cancel TradeResponse
    function cancelTradeResponse(uint256 tradeId, uint256 tokenId) public {
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to cancel trade.");
        for(uint256 i = 0; i <= Trades[tradeId].responses; i++) {
            if(TradeResponses[tradeId][i] == tokenId) {
                TradeResponses[tradeId][i] = 0;
            }
        }
    }

    // Get Active Orders
    function getActiveOrders() view public returns(uint256[] memory result) {
        result = new uint256[](activeOrders);
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= orderIds.current(); t++) {
            if (Orders[t].isActive) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    // Get Active Trades
    function getActiveTrades() view public returns(uint256[] memory result) {
        result = new uint256[](activeTrades);
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= tradeIds.current(); t++) {
            if (Trades[t].isActive) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function getGlitchStatus(uint256 tokenId) public view returns (Status memory status) {
        status = Status(0, 0, 0);

        // Check active active orders
        for (uint256 t = 1; t <= orderIds.current(); t++) {
            if (Orders[t].tokenId == tokenId && Orders[t].isActive) {
                status.forSale = t;
            }
        }

        // Check active trades
        for (uint256 t = 1; t <= tradeIds.current(); t++) {
            if (Trades[t].tokenId_1 == tokenId && Trades[t].isActive) {
                status.forTrade= t;
            } else {
                for(uint256 k=1; k<=Trades[t].responses; k++) {
                    if(TradeResponses[t][k] == tokenId && Trades[t].isActive) {
                        status.forTradeResponse = t;
                    }
                }
            }
        }
    }

    function setRoyalty(uint256 _royalty) public onlyOwner {
        royalty = _royalty;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setActive(bool _active) public onlyOwner {
        active = _active;
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {
        require(payable(royaltyAddress).send(address(this).balance));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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