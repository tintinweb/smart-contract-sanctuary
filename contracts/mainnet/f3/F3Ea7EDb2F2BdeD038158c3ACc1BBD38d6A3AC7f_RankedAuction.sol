// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IERC20Permit} from './interfaces/IERC20Permit.sol';
import {AdminPausableUpgradeSafe} from './misc/AdminPausableUpgradeSafe.sol';
import {WETHBase} from './misc/WETHBase.sol';
import {VersionedInitializable} from './aave-upgradeability/VersionedInitializable.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Errors} from './libraries/Errors.sol';

/**
 * @title RankedAuction contract.
 * @author Aito
 *
 * @notice A simple auction contract that just stores bids and relies on an external entity to manage the auctioning
 * logic.
 */
contract RankedAuction is
    VersionedInitializable,
    AdminPausableUpgradeSafe,
    WETHBase,
    ReentrancyGuard
{
    using SafeERC20 for IERC20Permit;
    using SafeMath for uint256;

    uint256 public constant RANKEDAUCTION_REVISION = 0x1;

    mapping(uint256 => DataTypes.RankedAuctionData) internal _auctionsById;
    mapping(address => mapping(uint256 => uint256)) internal _bids;
    mapping(address => mapping(uint256 => bool)) internal _outbid;
    mapping(address => bool) internal _currencyWhitelisted;

    uint256 internal _auctionCounter;
    uint40 internal _overtimeWindow;

    /**
     * @notice Emitted upon contract initialization.
     *
     * @param weth The WETH address whitelisted.
     * @param overtimeWindow The overtime window set.
     */
    event Initialized(address weth, uint256 overtimeWindow);

    /**
     * @notice Emitted when a new bid is placed or when an account's bid is increased.
     *
     * @param auctionId The auction identifier.
     * @param bidder The bidder address.
     * @param spender The address spending currency.
     * @param amount The bid amount.
     */
    event BidSubmitted(uint256 indexed auctionId, address bidder, address spender, uint256 amount);

    /**
     * @notice Emitted when the minimum price is updated by the admin.
     *
     * @param auctionId The auction identifier.
     * @param minimumPrice The auction's new minimum price.
     */
    event MinimumPriceUpdated(uint256 indexed auctionId, uint256 minimumPrice);

    /**
     * @notice Emitted when an outbid bid is withdrawn.
     *
     * @param auctionId The auction identifier.
     * @param bidder The address of the bidder who withdrew.
     * @param amount The amount withdrew.
     */
    event BidWithdrew(uint256 indexed auctionId, address indexed bidder, uint256 indexed amount);

    /**
     * @notice Emitted when an auction is created.
     *
     * @param auctionId The auction identifier.
     * @param currency The auction's underlying bid currency.
     * @param minPrice The minimum starting price of the auction.
     * @param maxWinners The expected maximum amount of NFT winners.
     * @param recipient The funds recipient.
     * @param startTimestamp The starting timestamp.
     * @param endTimestamp The ending timestamp.
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed currency,
        uint256 indexed minPrice,
        uint256 maxWinners,
        address recipient,
        uint40 startTimestamp,
        uint40 endTimestamp
    );

    /**
     * @notice Emitted when funds are received by the recipient.
     *
     * @param auctionId The auction identifier.
     * @param recipient The recipient address.
     * @param amount The amount received.
     */
    event FundsReceived(
        uint256 indexed auctionId,
        address indexed recipient,
        address[] bidders,
        uint256 amount
    );

    /**
     * @notice Emitted when a currency is whitelisted.
     *
     * @param currency The newly whitelisted currency.
     */
    event CurrencyWhitelisted(address currency);

    /**
     * @notice Emitted when a currency is removed from the whitelist.
     *
     * @param currency The newly unwhitelisted currency.
     */
    event CurrencyUnwhitelisted(address currency);

    /**
     * @notice Emitted when user bids are manually marked as outbid. Used as a backup
     * when there are multiple bids of the same price.
     *
     * @param auctionId The auction identifier.
     * @param bidders The array of bidders outbid.
     */
    event UsersOutbid(uint256 indexed auctionId, address[] bidders);

    /**
     * @notice Constructor sets the immutable WETH address.
     *
     * @param weth The WETH address.
     */
    constructor(address weth) WETHBase(weth) {}

    /**
     * @notice Initializes the contract.
     *
     * @param admin The admin address to set.
     * @param overtimeWindow The overtime window to set.
     */
    function initialize(address admin, uint40 overtimeWindow) external initializer {
        require(admin != address(0) && overtimeWindow < 2 days, Errors.INVALID_INIT_PARAMS);
        _admin = admin;
        _overtimeWindow = overtimeWindow;
        _currencyWhitelisted[address(WETH)] = true;
        _paused = false;

        emit Initialized(address(WETH), overtimeWindow);
    }

    /**
     * @notice Creates a new auction, only available to the admin.
     *
     * @param maxWinners The total amount of winners expected, must be emitted.
     * @param minPrice The starting minimum price for the auction.
     * @param currency The currency to be used in the auction.
     * @param recipient The address to receive proceeds from the auction.
     * @param startTimestamp The starting timestamp for the auction.
     * @param endTimestamp The ending timestamp for the auction.
     */
    function createAuction(
        uint256 maxWinners,
        address currency,
        uint256 minPrice,
        address recipient,
        uint40 startTimestamp,
        uint40 endTimestamp
    ) external nonReentrant onlyAdmin whenNotPaused {
        require(recipient != address(0), Errors.ZERO_RECIPIENT);
        require(currency != address(0), Errors.ZERO_CURRENCY);
        require(_currencyWhitelisted[currency], Errors.CURRENCY_NOT_WHITELSITED);
        require(
            startTimestamp > block.timestamp && endTimestamp > startTimestamp,
            Errors.INVALID_AUCTION_TIMESTAMPS
        );
        DataTypes.RankedAuctionData storage auction = _auctionsById[_auctionCounter];
        auction.minPrice = minPrice;
        auction.recipient = recipient;
        auction.currency = currency;
        auction.startTimestamp = startTimestamp;
        auction.endTimestamp = endTimestamp;

        emit AuctionCreated(
            _auctionCounter++,
            currency,
            minPrice,
            maxWinners,
            recipient,
            startTimestamp,
            endTimestamp
        );
    }

    /**
     * @notice Bids on the auction.
     *
     * @param auctionId The auction identifier.
     * @param onBehalfOf The address to bid on behalf of.
     * @param amount The amount to bid.
     */
    function bid(
        uint256 auctionId,
        address onBehalfOf,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _bid(auctionId, msg.sender, onBehalfOf, amount);
    }

    /**
     * @notice Bids bypassing an 'approval' transaction by bundling the bid with a permit on the underlying asset.
     *
     * @param auctionId The auction identifier.
     * @param params The parameters containing the necessary data to execute the 'permit' and the 'bid.'
     */
    function bidWithPermit(uint256 auctionId, DataTypes.SimpleBidWithPermitParams calldata params)
        external
        nonReentrant
        whenNotPaused
    {
        IERC20Permit currency = IERC20Permit(_auctionsById[auctionId].currency);
        currency.permit(
            msg.sender,
            address(this),
            params.amount,
            params.deadline,
            params.v,
            params.r,
            params.s
        );
        _bid(auctionId, msg.sender, params.onBehalfOf, params.amount);
    }

    /**
     * @dev Sets the minimum price for new bids, allowing lower bids to withdraw.
     *
     * @param auctionId The auction identifier.
     * @param newMinimum New minimum bid price.
     */
    function updateMinimumPrice(uint256 auctionId, uint256 newMinimum)
        external
        nonReentrant
        onlyAdmin
    {
        _auctionsById[auctionId].minPrice = newMinimum;

        emit MinimumPriceUpdated(auctionId, newMinimum);
    }

    /**
     * @dev Sets user bids as manually outbid, in case bids are placed at the same price, causing the
     * minimum price to not allow users to withdraw their bids.
     *
     * @param auctionId The auction identifier.
     * @param toOutbid The array of addresses to mark as outbid.
     */
    function setOutbid(uint256 auctionId, address[] calldata toOutbid)
        external
        nonReentrant
        onlyAdmin
    {
        for (uint256 i = 0; i < toOutbid.length; i++) {
            require(_bids[toOutbid[i]][auctionId] > 0, Errors.INVALID_BID_AMOUNT);
            _outbid[toOutbid[i]][auctionId] = true;
        }

        emit UsersOutbid(auctionId, toOutbid);
    }

    /**
     * @notice Withdraws the caller's bid if it is outbid.
     *
     * @param auctionId The auction identifier.
     */
    function withdrawBid(uint256 auctionId) external nonReentrant whenNotPaused {
        DataTypes.RankedAuctionData storage auction = _auctionsById[auctionId];
        uint256 returnAmount = _bids[msg.sender][auctionId];
        require(
            (returnAmount > 0 && returnAmount < auction.minPrice) || _outbid[msg.sender][auctionId],
            Errors.RA_NOT_OUTBID
        );
        IERC20Permit currency = IERC20Permit(auction.currency);
        delete (_bids[msg.sender][auctionId]);
        delete (_outbid[msg.sender][auctionId]);

        if (address(currency) == address(WETH)) {
            WETH.withdraw(returnAmount);
            (bool success, ) = msg.sender.call{value: returnAmount}(new bytes(0));
            if (!success) {
                WETH.deposit{value: returnAmount}();
                IERC20Permit(address(WETH)).safeTransferFrom(
                    address(this),
                    msg.sender,
                    returnAmount
                );
            }
        } else {
            currency.safeTransfer(msg.sender, returnAmount);
        }

        emit BidWithdrew(auctionId, msg.sender, returnAmount);
    }

    /**
     * @notice Transfers the funds from winning bids to the recipient address.
     *
     * @param auctionId The auction identifier.
     * @param toReceive winning bid addresses to transfer bid amounts from.
     */
    function receiveFunds(uint256 auctionId, address[] calldata toReceive)
        external
        nonReentrant
        onlyAdmin
    {
        DataTypes.RankedAuctionData storage auction = _auctionsById[auctionId];
        uint256 endTimestamp = auction.endTimestamp;
        uint256 minPrice = auction.minPrice;
        uint256 amountToTransfer;
        address recipient = auction.recipient;
        IERC20Permit currency = IERC20Permit(auction.currency);
        require(block.timestamp > endTimestamp, Errors.INVALID_AUCTION_TIMESTAMPS);

        for (uint256 i = 0; i < toReceive.length; i++) {
            require(!_outbid[toReceive[i]][auctionId], Errors.RA_OUTBID);
            uint256 bidAmount = _bids[toReceive[i]][auctionId];
            require(bidAmount >= minPrice, Errors.RA_OUTBID);
            amountToTransfer = amountToTransfer.add(bidAmount);
            delete (_bids[toReceive[i]][auctionId]);
        }
        currency.safeTransfer(recipient, amountToTransfer);

        emit FundsReceived(auctionId, recipient, toReceive, amountToTransfer);
    }

    /**
     * @dev Admin function to whitelist a currency.
     *
     * @param toWhitelist The currency address to whitelist.
     */
    function whitelistCurrency(address toWhitelist) external onlyAdmin {
        _currencyWhitelisted[toWhitelist] = true;
        emit CurrencyWhitelisted(toWhitelist);
    }

    /**
     * @dev Admin function to remove a whitelisted currency.
     *
     * @param toRemove The currency address to remove from the whitelist.
     */
    function removeCurrencyFromWhitelist(address toRemove) external onlyAdmin {
        _currencyWhitelisted[toRemove] = false;
        emit CurrencyUnwhitelisted(toRemove);
    }

    /**
     * @dev transfer native Ether, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     *
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount) external onlyAdmin {
        _safeTransferETH(to, amount);
    }

    /**
     * @notice Returns the auction data for a given auction ID.
     *
     * @return The RankedAuctionData struct containing the auction's parameters.
     */
    function getAuctionData(uint256 auctionId)
        external
        view
        returns (DataTypes.RankedAuctionData memory)
    {
        return _auctionsById[auctionId];
    }

    /**
     * @notice Returns a specific bid data query.
     *
     * @param bidder The bidder to query the bid for.
     * @param auctionId The auction ID to query the bid for.
     */
    function getBid(address bidder, uint256 auctionId) external view returns (uint256) {
        return _bids[bidder][auctionId];
    }

    /**
     * @notice Returns the overtime window.
     *
     * @return The overtime window.
     */
    function getOvertimeWindow() external view returns (uint256) {
        return _overtimeWindow;
    }

    /**
     * @notice Returns whether a currency address is whitelisted and allowed to be used in the auction.
     *
     * @param query The address to query.
     */
    function isWhitelisted(address query) external view returns (bool) {
        return _currencyWhitelisted[query];
    }

    /**
     * @dev Internal function executes the underlying logic of a bid.
     *
     * @param auctionId The auction identifier.
     * @param spender The spender to transfer currency from.
     * @param onBehalfOf The address to bid on behalf of.
     * @param amount The amount to bid with.
     */
    function _bid(
        uint256 auctionId,
        address spender,
        address onBehalfOf,
        uint256 amount
    ) internal {
        DataTypes.RankedAuctionData storage auction = _auctionsById[auctionId];
        uint256 minPrice = auction.minPrice;
        IERC20Permit currency = IERC20Permit(auction.currency);
        uint40 startTimestamp = auction.startTimestamp;
        uint40 endTimestamp = auction.endTimestamp;
        require(onBehalfOf != address(0), Errors.INVALID_BIDDER);
        require(amount > minPrice, Errors.INVALID_BID_AMOUNT);
        require(
            block.timestamp > startTimestamp && block.timestamp < endTimestamp,
            Errors.INVALID_BID_TIMESTAMPS
        );
        if (_overtimeWindow > 0 && block.timestamp > endTimestamp - _overtimeWindow) {
            endTimestamp = endTimestamp + _overtimeWindow;
        }

        uint256 previousBid = _bids[onBehalfOf][auctionId];
        _bids[onBehalfOf][auctionId] = amount;
        if (amount > previousBid) {
            currency.safeTransferFrom(spender, address(this), amount - previousBid);
        } else {
            revert(Errors.INVALID_BID_AMOUNT);
        }

        emit BidSubmitted(auctionId, onBehalfOf, spender, amount);
    }

    function getRevision() internal pure override returns (uint256) {
        return RANKEDAUCTION_REVISION;
    }

    receive() external payable {
        require(msg.sender == address(WETH));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import {Errors} from '../libraries/Errors.sol';

/**
 * @title AdminPausableUpgradeSafe
 *
 * @author Aito
 * 
 * @dev Contract to be inherited from that adds simple administrator pausable functionality. This does not
 * implement any changes on its own as there is no constructor or initializer. Both _admin and _paused must
 * be initialized in the inheriting contract.
 */
contract AdminPausableUpgradeSafe {
    address internal _admin;
    bool internal _paused;
    
    /**
     * @notice Emitted when the contract is paused.
     * 
     * @param admin The current administrator address.
     */
    event Paused(address admin);

    /**
     * @notice Emitted when the contract is unpaused.
     *
     * @param admin The current administrator address.
     */
    event Unpaused(address admin);

    /**
     * @notice Emitted when the admin is set to a different address.
     * 
     * @param to The address of the new administrator. 
     */
    event AdminChanged(address to);

    constructor() {
        _paused = true;
    }

    /**
     * @dev Modifier to only allow functions to be called when not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, Errors.PAUSED);
        _;
    }

    /**
     * @dev Modifier to only allow the admin as the caller.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, Errors.NOT_ADMIN);
        _;
    }

    /**
     * @dev Admin function pauses the contract.
     */
    function pause() external onlyAdmin {
        _paused = true;
        emit Paused(_admin);
    }

    /**
     * @dev Admin function unpauses the contract.
     */
    function unpause() external onlyAdmin {
        _paused = false;
        emit Unpaused(_admin);
    }

    /**
     * @dev Admin function that changes the administrator.
     */
    function changeAdmin(address to) external onlyAdmin {
        _admin = to;
        emit AdminChanged(to);
    }

    /**
     * @dev View function that returns the current admin.
     */
    function getAdmin() external view returns (address) {
        return _admin;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import {IWETH} from '../interfaces/IWETH.sol';

contract WETHBase {

    IWETH public immutable WETH;

    /**
     * @notice Constructor sets the immutable WETH address.
     */
    constructor(address weth) {
        WETH = IWETH(weth);
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }    
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @dev Returns true if and only if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

/// Library containing data types needed for the NFT controller & vaults
library DataTypes {
    struct DistributionData {
        address recipient;
        uint256 bps;
    }

    struct StakingAuctionFullData {
        StakingAuctionData auction;
        DistributionData[] distribution;
        uint256 auctionId;
        address auctioner;
        address vault;
    }

    struct StakingAuctionData {
        uint256 currentBid;
        address currentBidder;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

    struct StakingAuctionConfiguration {
        address vaultLogic;
        address treasury;
        uint40 minimumAuctionDuration;
        uint40 overtimeWindow;
        uint16 treasuryFeeBps;
        uint16 burnPenaltyBps;
    }

    struct GenericAuctionFullData {
        GenericAuctionData auction;
        DistributionData[] distribution;
        uint256 auctionId;
        address auctioner;
    }

    struct GenericAuctionData {
        uint256 currentBid;
        address currency;
        address currentBidder;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

    struct GenericAuctionConfiguration {
        address treasury;
        uint40 minimumAuctionDuration;
        uint40 overtimeWindow;
        uint16 treasuryFeeBps;
    }

    struct RankedAuctionData {
        uint256 minPrice;
        address recipient;
        address currency;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

    struct ReserveAuctionFullData {
        ReserveAuctionData auction;
        DistributionData[] distribution;
        uint256 auctionId;
        address auctioner;
    }

    struct ReserveAuctionData {
        uint256 currentBid;
        uint256 buyNow;
        address currency;
        address currentBidder;
        uint40 duration;
        uint40 firstBidTimestamp;
        uint40 endTimestamp;
    }

    struct OpenEditionFullData {
        DistributionData[] distribution;
        OpenEditionSaleData saleData;
    }

    struct OpenEditionSaleData {
        uint256 price;
        address currency;
        address nft;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }

    struct OpenEditionConfiguration {
        address treasury;
        uint40 minimumAuctionDuration;
        uint16 treasuryFeeBps;
    }

    struct OpenEditionBuyWithPermitParams {
        uint256 id;
        uint256 amount;
        uint256 permitAmount;
        uint256 deadline;
        address onBehalfOf;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BidWithPermitParams {
        uint256 amount;
        uint256 deadline;
        uint256 nftId;
        address onBehalfOf;
        address nft;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct SimpleBidWithPermitParams {
        uint256 amount;
        uint256 deadline;
        address onBehalfOf;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum CallType {Call, DelegateCall}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

/// Contains error code strings
library Errors {
  string public constant INVALID_AUCTION_TIMESTAMPS = '1';
  string public constant INVALID_BID_TIMESTAMPS = '2';
  string public constant INVALID_BID_AMOUNT = '3';
  string public constant AUCTION_ONGOING = '4';
  string public constant VALID_BIDDER = '5';
  string public constant NONEXISTANT_VAULT = '6';
  string public constant INVALID_DISTRIBUTION_BPS = '7';
  string public constant AUCTION_EXISTS = '8';
  string public constant NOT_STAKING_AUCTION = '9';
  string public constant INVALID_CALL_TYPE = '10';
  string public constant INVALID_AUCTION_DURATION = '11';
  string public constant INVALID_BIDDER = '12';
  string public constant PAUSED = '13';
  string public constant NOT_ADMIN = '14';
  string public constant INVALID_INIT_PARAMS = '15';
  string public constant INVALID_DISTRIBUTION_COUNT = '16';
  string public constant ZERO_RECIPIENT = '17';
  string public constant ZERO_CURRENCY = '18';
  string public constant RA_NOT_OUTBID = '19';
  string public constant RA_OUTBID = '20';
  string public constant NO_DISTRIBUTIONS = '21';
  string public constant VAULT_ARRAY_MISMATCH = '22';
  string public constant CURRENCY_NOT_WHITELSITED = '23';
  string public constant NOT_NFT_OWNER = '24';
  string public constant ZERO_NFT = '25';
  string public constant NOT_COLLECTION_CREATOR = '26';
  string public constant INVALID_BUY_NOW = '27';
  string public constant INVALID_RESERVE_PRICE = '28';
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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IWETH {

  function balanceOf(address guy) external returns (uint256);

  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

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