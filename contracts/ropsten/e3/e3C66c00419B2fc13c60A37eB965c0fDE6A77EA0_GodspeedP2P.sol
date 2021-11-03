// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Implementation of P2P Trading contract that allows creation
 * of trades by {seller} or {buyer}.
 *
 * Buyer or seller can start trades by making the seller deposit the trade
 * amount of tokens. Buyer marks the trade as paid and then seller
 * completes the trade by transferring trade amount less the escrow fee
 * to buyer. Escrow fee is sent to the contract owner.
 *
 * Trade can be disputed by either party when it is in the state of
 * {processing} or {paid}. Buyer can cancel trade when it is {pending}
 * or {paid} and seller can cancel trade when it is {pending}.
 *
 * Admin can complete or cancel the trade and {Godspeed} tokens are
 * sent to both parties amounting to roughly 90%+ of the gas spent
 * by the respective party.
 */

contract GodspeedP2P is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Variable

    address public owner;
    using Counters for Counters.Counter;
    Counters.Counter public tradeId;

    IERC20 public godSpeed;

    // price of 1 eth to Godspeed tokens
    // e.g. 1e18 of eth is equal to 100e18 of Godspeed tokens,
    // the price is (100e18 * 10**18)/1e18 = 100e18
    uint256 public ethToGodspeed;

    constructor(
        uint256 _ethToGodspeed,
        address _godSpeed
    ) {
        owner = msg.sender;
        godSpeed = IERC20(_godSpeed);
        setEthToGodSpeedPrice(_ethToGodspeed);
    }

    enum Status{
        pending,
        processing,
        paid,
        cancelled,
        completed,
        disputed,
        waiting
    }

    struct Trade {
        uint256 tradeId;
        address seller;
        address buyer;
        uint256 amount;
        address tokenContractAddress;
        Status status;
        string offerId;
        uint256 buyerSpentGas;
        uint256 sellerSpentGas;
    }

    uint256 public feeInPercent = 25;
    uint256 public percentFraction = 1000;

    mapping(uint256 => Trade) public trades;


    // Events
    event TradeCreated(
        uint256 tradeId,
        address seller,
        address buyer,
        uint256 amount,
        address tokenContractAddress,
        Status status
    );

    event TradeStarted(
        uint256 tradeId,
        address seller,
        address buyer,
        uint256 amount,
        address tokenContractAddress,
        Status status
    );

    event TradePaid(
        uint256 tradeId,
        address seller,
        address buyer,
        uint256 amount,
        address tokenContractAddress,
        Status status
    );

    event TradeCompleted(
        uint256 tradeId,
        address seller,
        address buyer,
        uint256 amount,
        address tokenContractAddress,
        Status status);

    event TradeCancelled(
        uint256 tradeId,
        address seller,
        address buyer,
        uint256 amount,
        address tokenContractAddress,
        Status status);

    event TradeDisputed(
        uint256 tradeId,
        address seller,
        address buyer,
        uint256 amount,
        address tokenContractAddress,
        Status status);


    // Public functions

    // Seller : Who sells token for money / other items
    // Buyer : Who Buys token

    // @ Method :Trade create
    // @ Description: Seller will create a trade for a Buyer
    // @ Params : Buyer Address, Amount (token amount * decimals) , token contract Address
    function createTrade(
        address _buyer,
        uint256 _amount,
        address _tokenAddress,
        string memory _offerId
    ) external {
        uint256 gasBefore = gasleft();

        require(
            _amount != 0,
            "Amount must be greater than zero"
        );
        require(
            _buyer != address(0),
            "Buyer must be an valid address"
        );
        require(
            _tokenAddress != address(0),
            "Token Address must be an valid address"
        );
        tradeId.increment();
        uint256 currentId =  tradeId.current();
        trades[currentId] = Trade(
            currentId,
            msg.sender,
            _buyer,
            _amount,
            _tokenAddress,
            Status.pending,
            _offerId,
            0,
            0
        );

        emit TradeCreated(
            currentId,
            msg.sender,
            _buyer,
            _amount,
            _tokenAddress,
            Status.pending
        );

        uint256 gasAfter = gasleft();

        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 22500 // gas cost for the message call.
            + 20000; // gas cost for performing storage write on the next line.

        trades[currentId].sellerSpentGas = gasConsumed * tx.gasprice;
    }



    // @ Method : Trade create by  buyer
    // @ Description: Buyer will create a trade for a Seller
    // @ Params : Seller Address, Amount (token amount * decimals) , token contract Address
    function createTradeByBuyer(
        address _seller,
        uint256 _amount,
        address _tokenAddress,
        string memory _offerId
    ) external {
        uint256 gasBefore = gasleft();

        require(
            _amount != 0,
            "Amount must be greater than zero"
        );
        require(
            _seller != address(0),
             "Seller must be an valid address"
        );
        require(
            _tokenAddress != address(0),
            "Token Address must be an valid address"
        );
        tradeId.increment();
        uint256 currentId =  tradeId.current();

        trades[currentId] = Trade(
            currentId,
            _seller,
            msg.sender,
            _amount,
            _tokenAddress,
            Status.waiting,
            _offerId,
            0,
            0
        );

        emit TradeCreated(
            currentId,
            _seller,
            msg.sender,
            _amount,
            _tokenAddress,
            Status.waiting
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 22500 // gas cost for the message call.
            + 20000; // gas cost for performing storage write on the next line.

        trades[currentId].buyerSpentGas = gasConsumed * tx.gasprice;
    }

    // @ Method : start trade By seller
    // @ Description : Seller will start the trade. Seller need to approve this contract first then this method to deposit.
    // @ Params : tradeId
    function startTradeBySeller(uint256 _tradeId)
        external
        nonReentrant
    {
        uint256 gasBefore = gasleft();

        require(
            trades[_tradeId].seller == msg.sender,
            "You are not seller"
        );
        require(
            trades[_tradeId].status == Status.waiting,
            "Trade already proceed"
        );
        trades[_tradeId].status = Status.processing;
        IERC20(trades[_tradeId].tokenContractAddress).safeTransferFrom(
            trades[_tradeId].seller,
            address(this),
            trades[_tradeId].amount
        );

        emit TradeStarted(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.processing
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 22500 // gas cost for the message call.
            + 20800; // gas cost for performing storage write on the next line.

        trades[_tradeId].sellerSpentGas += gasConsumed * tx.gasprice;
    }

    // @ Method : Start trade
    // @ Description : Buyer will start the trade. Seller need to approve this contract with the trade amount . Otherwise this action can't be done.
    // @ Params : tradeId
    function startTrade(uint256 _tradeId)
        external
        nonReentrant
    {
        uint256 gasBefore = gasleft();

        require(
            trades[_tradeId].buyer == msg.sender,
            "You are not buyer"
        );
        require(
            trades[_tradeId].status == Status.pending,
            "Trade already proceed or not deposited"
        );
        trades[_tradeId].status = Status.processing;
        IERC20(trades[_tradeId].tokenContractAddress).safeTransferFrom(
            trades[_tradeId].seller,
            address(this),
            trades[_tradeId].amount
        );

        emit TradeStarted(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.processing
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 22500 // gas cost for the message call.
            + 20800; // gas cost for performing storage write on the next line.

        trades[_tradeId].buyerSpentGas += gasConsumed * tx.gasprice;
    }

    // @ Method : Mark the trade as paid
    // @ Description : Buyer will mark the trade as paid when he gives the service / money to Token Seller
    // @ Params : tradeId
    function markedPaidTrade(uint256 _tradeId) external {
        uint256 gasBefore = gasleft();

        require(
            trades[_tradeId].buyer == msg.sender,
            "You are not buyer"
        );
        require(
            trades[_tradeId].status == Status.processing,
            "Trade is not processing"
        );
        trades[_tradeId].status = Status.paid;
        emit TradePaid(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.paid
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 22500 // gas cost for the message call.
            + 5800; // gas cost for performing storage write on the next line.

        trades[_tradeId].buyerSpentGas += gasConsumed * tx.gasprice;
    }

    // @Method : Complete the trades
    // @Description : Seller will complete the trade when seller paid him / her
    // @ Params : tradeId
    function completeTrade(uint256 _tradeId)
        external
        nonReentrant
    {
        uint256 gasBefore = gasleft();

        require(
            trades[_tradeId].seller == msg.sender,
            "You are not seller"
        );
        require(
            trades[_tradeId].status == Status.paid,
            "Buyer not paid yet"
        );
        uint256 fee = escrowFee(trades[_tradeId].amount);
        uint256 amount = trades[_tradeId].amount - fee;

        IERC20 token = IERC20(trades[_tradeId].tokenContractAddress);
        token.safeTransfer(trades[_tradeId].buyer, amount);
        token.safeTransfer(owner,fee);
        trades[_tradeId].status = Status.completed;

        emit TradeCompleted(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.completed
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 22500 // gas cost for the message call.
            + 5800 // gas cost for performing storage write on the next line.
            + 17289; // gas consumed in reimbursement

        trades[_tradeId].sellerSpentGas += gasConsumed * tx.gasprice;

        reimburseGas(_tradeId); // 17289
    }

    // @Method: Dispute the trades
    // @Description :  Buyer or seller can dispute the trade (processing and paid stage)
    // @ Params : tradeId

    function disputeTrade(uint256 _tradeId) external {
        uint256 gasBefore = gasleft();

        require(
            trades[_tradeId].seller == msg.sender ||
            trades[_tradeId].buyer == msg.sender,
            "You are not buyer or seller"
        );
        require(
            trades[_tradeId].status == Status.processing ||
            trades[_tradeId].status == Status.paid,
            "Trade is not processing nor marked as paid"
        );

        trades[_tradeId].status = Status.disputed;

        emit TradeDisputed(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.disputed
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 22500 // gas cost for the message call.
            + 7900; // gas cost for performing storage write on the next line.

        if (trades[_tradeId].seller == msg.sender) {
            trades[_tradeId].sellerSpentGas += gasConsumed * tx.gasprice;
        } else {
            trades[_tradeId].buyerSpentGas += gasConsumed * tx.gasprice;
        }
    }

    // @Method: Cancel the trades by seller
    // @Description :  Seller can cancel the trade only before start the trade
    // @ Params : tradeId

    function cancelTradeBySeller(uint256 _tradeId) external {
        uint256 gasBefore = gasleft();

        require(
            trades[_tradeId].seller == msg.sender,
            "You are not seller"
        );
        require(
            trades[_tradeId].status == Status.pending,
            "Trade already started"
        );
        trades[_tradeId].status = Status.cancelled;

        emit TradeCancelled(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.cancelled
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 21000 // gas cost for the message call.
            + 5000 // gas cost for performing storage write on the next line.
            + 17289; // gas for reimbursement

        trades[_tradeId].sellerSpentGas += gasConsumed * tx.gasprice;
        reimburseGas(_tradeId);
    }

    // @Method:  Cancel the trades by buyer
    // @Description : Buyer can cancel the trade if the trade on pending or paid stage. Token will reverted to Seller.
    // @ Params : tradeId
    function cancelTradeByBuyer(uint256 _tradeId)
        external
        nonReentrant
    {
        uint256 gasBefore = gasleft();

        require(
            trades[_tradeId].buyer == msg.sender,
            "You are not buyer"
        );
        require(
            trades[_tradeId].status == Status.processing
            || trades[_tradeId].status == Status.paid,
            "Trade not strated or already finished"
        );
        trades[_tradeId].status = Status.cancelled;
        IERC20(trades[_tradeId].tokenContractAddress).safeTransfer(
            trades[_tradeId].seller,
            trades[_tradeId].amount
        );

        emit TradeCancelled(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.cancelled
        );

        uint256 gasAfter = gasleft();
        uint256 gasConsumed =
            gasBefore
            - gasAfter
            + 21000 // gas cost for the message call.
            + 5000 // gas cost for performing storage write on the next line.
            + 17289;

        trades[_tradeId].buyerSpentGas += gasConsumed * tx.gasprice;
        reimburseGas(_tradeId); // 17289
    }

    // @ Method:  Cancel the trades by Admin
    // @ Description : Admin can cancel the trade. only for disputed trade. Token will reverted to Seller.
    // @ Params : tradeId
    function cancelTradeByAdmin(uint256 _tradeId)
        external
        onlyOwner
    {
        require(
            trades[_tradeId].status == Status.disputed,
            "Trade not disputed"
        );
        trades[_tradeId].status = Status.cancelled;
        IERC20(trades[_tradeId].tokenContractAddress).safeTransfer(
            trades[_tradeId].seller,
            trades[_tradeId].amount
        );

        reimburseGas(_tradeId);

        emit TradeCancelled(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.cancelled
        );
    }

    // @ Method: Complete the trades by Admin
    // @ Description : admin can complete the trades
    // @ Params : tradeId
    function completeTradeByAdmin(uint256 _tradeId)
        external
        onlyOwner
    {
        require(
            trades[_tradeId].status == Status.disputed,
            "Trade not disputed"
        );
        trades[_tradeId].status = Status.completed;
        IERC20(trades[_tradeId].tokenContractAddress).safeTransfer(
            trades[_tradeId].buyer,
            trades[_tradeId].amount
        );

        reimburseGas(_tradeId);

        emit TradeCompleted(
            _tradeId,
            trades[_tradeId].seller,
            trades[_tradeId].buyer,
            trades[_tradeId].amount,
            trades[_tradeId].tokenContractAddress,
            Status.completed
        );
    }

    // The gas reimbursed in godspeed tokens is roughly 90% or above
    // of the original gas consumed by the network.
    function reimburseGas(uint256 _tradeId) private {
        uint256 toSeller =
            trades[_tradeId].sellerSpentGas
            * ethToGodspeed
            / 10 ** 9; // gas spent is in gwei so we only divide by 1e9 instead of 1e18

        uint256 toBuyer =
            trades[_tradeId].buyerSpentGas
            * ethToGodspeed
            / 10 ** 9; // gas spent is in gwei so we only divide by 1e9 instead of 1e18

        IERC20(godSpeed).safeTransfer(
            trades[_tradeId].seller,
            toSeller
        );

        IERC20(godSpeed).safeTransfer(
            trades[_tradeId].buyer,
            toBuyer
        );
    }

    // Private Function
    function escrowFee(uint256 amount)
        private
        view
        returns(uint256 adminFee)
    {
        uint256 x = amount.mul(feeInPercent);
        adminFee = x.div(percentFraction);
    }


    // Admin function
    function changeFee(uint256 fee, uint256 fraction)
        external
        onlyOwner
    {
        feeInPercent = fee;
        percentFraction = fraction;
    }

    function setEthToGodSpeedPrice(uint256 _price)
        public
        onlyOwner
    {
        require(
            _price != 0,
            "price cannot be zero"
        );
        ethToGodspeed = _price;
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "You are not owner"
        );
        _;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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