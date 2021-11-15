// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./GPv2VaultRelayer.sol";
import "./interfaces/GPv2Authentication.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IVault.sol";
import "./libraries/GPv2Interaction.sol";
import "./libraries/GPv2Order.sol";
import "./libraries/GPv2Trade.sol";
import "./libraries/GPv2Transfer.sol";
import "./libraries/SafeCast.sol";
import "./libraries/SafeMath.sol";
import "./mixins/GPv2Signing.sol";
import "./mixins/ReentrancyGuard.sol";
import "./mixins/StorageAccessible.sol";

/// @title Gnosis Protocol v2 Settlement Contract
/// @author Gnosis Developers
contract GPv2Settlement is GPv2Signing, ReentrancyGuard, StorageAccessible {
    using GPv2Order for bytes;
    using GPv2Transfer for IVault;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;

    /// @dev The authenticator is used to determine who can call the settle function.
    /// That is, only authorised solvers have the ability to invoke settlements.
    /// Any valid authenticator implements an isSolver method called by the onlySolver
    /// modifier below.
    GPv2Authentication public immutable authenticator;

    /// @dev The Balancer Vault the protocol uses for managing user funds.
    IVault public immutable vault;

    /// @dev The Balancer Vault relayer which can interact on behalf of users.
    /// This contract is created during deployment
    GPv2VaultRelayer public immutable vaultRelayer;

    /// @dev Map each user order by UID to the amount that has been filled so
    /// far. If this amount is larger than or equal to the amount traded in the
    /// order (amount sold for sell orders, amount bought for buy orders) then
    /// the order cannot be traded anymore. If the order is fill or kill, then
    /// this value is only used to determine whether the order has already been
    /// executed.
    mapping(bytes => uint256) public filledAmount;

    /// @dev Event emitted for each executed trade.
    event Trade(
        address indexed owner,
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 feeAmount,
        bytes orderUid
    );

    /// @dev Event emitted for each executed interaction.
    ///
    /// For gas effeciency, only the interaction calldata selector (first 4
    /// bytes) is included in the event. For interactions without calldata or
    /// whose calldata is shorter than 4 bytes, the selector will be `0`.
    event Interaction(address indexed target, uint256 value, bytes4 selector);

    /// @dev Event emitted when a settlement complets
    event Settlement(address indexed solver);

    /// @dev Event emitted when an order is invalidated.
    event OrderInvalidated(address indexed owner, bytes orderUid);

    constructor(GPv2Authentication authenticator_, IVault vault_) {
        authenticator = authenticator_;
        vault = vault_;
        vaultRelayer = new GPv2VaultRelayer(vault_);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // NOTE: Include an empty receive function so that the settlement
        // contract can receive Ether from contract interactions.
    }

    /// @dev This modifier is called by settle function to block any non-listed
    /// senders from settling batches.
    modifier onlySolver {
        require(authenticator.isSolver(msg.sender), "GPv2: not a solver");
        _;
    }

    /// @dev Modifier to ensure that an external function is only callable as a
    /// settlement interaction.
    modifier onlyInteraction {
        require(address(this) == msg.sender, "GPv2: not an interaction");
        _;
    }

    /// @dev Settle the specified orders at a clearing price. Note that it is
    /// the responsibility of the caller to ensure that all GPv2 invariants are
    /// upheld for the input settlement, otherwise this call will revert.
    /// Namely:
    /// - All orders are valid and signed
    /// - Accounts have sufficient balance and approval.
    /// - Settlement contract has sufficient balance to execute trades. Note
    ///   this implies that the accumulated fees held in the contract can also
    ///   be used for settlement. This is OK since:
    ///   - Solvers need to be authorized
    ///   - Misbehaving solvers will be slashed for abusing accumulated fees for
    ///     settlement
    ///   - Critically, user orders are entirely protected
    ///
    /// @param tokens An array of ERC20 tokens to be traded in the settlement.
    /// Trades encode tokens as indices into this array.
    /// @param clearingPrices An array of clearing prices where the `i`-th price
    /// is for the `i`-th token in the [`tokens`] array.
    /// @param trades Trades for signed orders.
    /// @param interactions Smart contract interactions split into three
    /// separate lists to be run before the settlement, during the settlement
    /// and after the settlement respectively.
    function settle(
        IERC20[] calldata tokens,
        uint256[] calldata clearingPrices,
        GPv2Trade.Data[] calldata trades,
        GPv2Interaction.Data[][3] calldata interactions
    ) external nonReentrant onlySolver {
        executeInteractions(interactions[0]);

        (
            GPv2Transfer.Data[] memory inTransfers,
            GPv2Transfer.Data[] memory outTransfers
        ) = computeTradeExecutions(tokens, clearingPrices, trades);

        vaultRelayer.transferFromAccounts(inTransfers);

        executeInteractions(interactions[1]);

        vault.transferToAccounts(outTransfers);

        executeInteractions(interactions[2]);

        emit Settlement(msg.sender);
    }

    /// @dev Settle an order directly against Balancer V2 pools.
    ///
    /// @param swaps The Balancer V2 swap steps to use for trading.
    /// @param tokens An array of ERC20 tokens to be traded in the settlement.
    /// Swaps and the trade encode tokens as indices into this array.
    /// @param trade The trade to match directly against Balancer liquidity. The
    /// order will always be fully executed, so the trade's `executedAmount`
    /// field is used to represent a swap limit amount.
    function swap(
        IVault.BatchSwapStep[] calldata swaps,
        IERC20[] calldata tokens,
        GPv2Trade.Data calldata trade
    ) external nonReentrant onlySolver {
        RecoveredOrder memory recoveredOrder = allocateRecoveredOrder();
        GPv2Order.Data memory order = recoveredOrder.data;
        recoverOrderFromTrade(recoveredOrder, tokens, trade);

        IVault.SwapKind kind =
            order.kind == GPv2Order.KIND_SELL
                ? IVault.SwapKind.GIVEN_IN
                : IVault.SwapKind.GIVEN_OUT;

        IVault.FundManagement memory funds;
        funds.sender = recoveredOrder.owner;
        funds.fromInternalBalance =
            order.sellTokenBalance == GPv2Order.BALANCE_INTERNAL;
        funds.recipient = payable(recoveredOrder.receiver);
        funds.toInternalBalance =
            order.buyTokenBalance == GPv2Order.BALANCE_INTERNAL;

        int256[] memory limits = new int256[](tokens.length);
        uint256 limitAmount = trade.executedAmount;
        // NOTE: Array allocation initializes elements to 0, so we only need to
        // set the limits we care about. This ensures that the swap will respect
        // the order's limit price.
        if (order.kind == GPv2Order.KIND_SELL) {
            require(limitAmount >= order.buyAmount, "GPv2: limit too low");
            limits[trade.sellTokenIndex] = order.sellAmount.toInt256();
            limits[trade.buyTokenIndex] = -limitAmount.toInt256();
        } else {
            require(limitAmount <= order.sellAmount, "GPv2: limit too high");
            limits[trade.sellTokenIndex] = limitAmount.toInt256();
            limits[trade.buyTokenIndex] = -order.buyAmount.toInt256();
        }

        GPv2Transfer.Data memory feeTransfer;
        feeTransfer.account = recoveredOrder.owner;
        feeTransfer.token = order.sellToken;
        feeTransfer.amount = order.feeAmount;
        feeTransfer.balance = order.sellTokenBalance;

        int256[] memory tokenDeltas =
            vaultRelayer.batchSwapWithFee(
                kind,
                swaps,
                tokens,
                funds,
                limits,
                // NOTE: Specify a deadline to ensure that an expire order
                // cannot be used to trade.
                order.validTo,
                feeTransfer
            );

        bytes memory orderUid = recoveredOrder.uid;
        uint256 executedSellAmount =
            tokenDeltas[trade.sellTokenIndex].toUint256();
        uint256 executedBuyAmount =
            (-tokenDeltas[trade.buyTokenIndex]).toUint256();

        // NOTE: Check that the orders were completely filled and update their
        // filled amounts to avoid replaying them. The limit price and order
        // validity have already been verified when executing the swap through
        // the `limit` and `deadline` parameters.
        require(filledAmount[orderUid] == 0, "GPv2: order filled");
        if (order.kind == GPv2Order.KIND_SELL) {
            require(
                executedSellAmount == order.sellAmount,
                "GPv2: sell amount not respected"
            );
            filledAmount[orderUid] = order.sellAmount;
        } else {
            require(
                executedBuyAmount == order.buyAmount,
                "GPv2: buy amount not respected"
            );
            filledAmount[orderUid] = order.buyAmount;
        }

        emit Trade(
            recoveredOrder.owner,
            order.sellToken,
            order.buyToken,
            executedSellAmount,
            executedBuyAmount,
            order.feeAmount,
            orderUid
        );
        emit Settlement(msg.sender);
    }

    /// @dev Invalidate onchain an order that has been signed offline.
    ///
    /// @param orderUid The unique identifier of the order that is to be made
    /// invalid after calling this function. The user that created the order
    /// must be the the sender of this message. See [`extractOrderUidParams`]
    /// for details on orderUid.
    function invalidateOrder(bytes calldata orderUid) external {
        (, address owner, ) = orderUid.extractOrderUidParams();
        require(owner == msg.sender, "GPv2: caller does not own order");
        filledAmount[orderUid] = uint256(-1);
        emit OrderInvalidated(owner, orderUid);
    }

    /// @dev Free storage from the filled amounts of **expired** orders to claim
    /// a gas refund. This method can only be called as an interaction.
    ///
    /// @param orderUids The unique identifiers of the expired order to free
    /// storage for.
    function freeFilledAmountStorage(bytes[] calldata orderUids)
        external
        onlyInteraction
    {
        freeOrderStorage(filledAmount, orderUids);
    }

    /// @dev Free storage from the pre signatures of **expired** orders to claim
    /// a gas refund. This method can only be called as an interaction.
    ///
    /// @param orderUids The unique identifiers of the expired order to free
    /// storage for.
    function freePreSignatureStorage(bytes[] calldata orderUids)
        external
        onlyInteraction
    {
        freeOrderStorage(preSignature, orderUids);
    }

    /// @dev Process all trades one at a time returning the computed net in and
    /// out transfers for the trades.
    ///
    /// This method reverts if processing of any single trade fails. See
    /// [`computeTradeExecution`] for more details.
    ///
    /// @param tokens An array of ERC20 tokens to be traded in the settlement.
    /// @param clearingPrices An array of token clearing prices.
    /// @param trades Trades for signed orders.
    /// @return inTransfers Array of in transfers of executed sell amounts.
    /// @return outTransfers Array of out transfers of executed buy amounts.
    function computeTradeExecutions(
        IERC20[] calldata tokens,
        uint256[] calldata clearingPrices,
        GPv2Trade.Data[] calldata trades
    )
        internal
        returns (
            GPv2Transfer.Data[] memory inTransfers,
            GPv2Transfer.Data[] memory outTransfers
        )
    {
        RecoveredOrder memory recoveredOrder = allocateRecoveredOrder();

        inTransfers = new GPv2Transfer.Data[](trades.length);
        outTransfers = new GPv2Transfer.Data[](trades.length);

        for (uint256 i = 0; i < trades.length; i++) {
            GPv2Trade.Data calldata trade = trades[i];

            recoverOrderFromTrade(recoveredOrder, tokens, trade);
            computeTradeExecution(
                recoveredOrder,
                clearingPrices[trade.sellTokenIndex],
                clearingPrices[trade.buyTokenIndex],
                trade.executedAmount,
                inTransfers[i],
                outTransfers[i]
            );
        }
    }

    /// @dev Compute the in and out transfer amounts for a single trade.
    /// This function reverts if:
    /// - The order has expired
    /// - The order's limit price is not respected
    /// - The order gets over-filled
    /// - The fee discount is larger than the executed fee
    ///
    /// @param recoveredOrder The recovered order to process.
    /// @param sellPrice The price of the order's sell token.
    /// @param buyPrice The price of the order's buy token.
    /// @param executedAmount The portion of the order to execute. This will be
    /// ignored for fill-or-kill orders.
    /// @param inTransfer Memory location for computed executed sell amount
    /// transfer.
    /// @param outTransfer Memory location for computed executed buy amount
    /// transfer.
    function computeTradeExecution(
        RecoveredOrder memory recoveredOrder,
        uint256 sellPrice,
        uint256 buyPrice,
        uint256 executedAmount,
        GPv2Transfer.Data memory inTransfer,
        GPv2Transfer.Data memory outTransfer
    ) internal {
        GPv2Order.Data memory order = recoveredOrder.data;
        bytes memory orderUid = recoveredOrder.uid;

        // solhint-disable-next-line not-rely-on-time
        require(order.validTo >= block.timestamp, "GPv2: order expired");

        // NOTE: The following computation is derived from the equation:
        // ```
        // amount_x * price_x = amount_y * price_y
        // ```
        // Intuitively, if a chocolate bar is 0,50€ and a beer is 4€, 1 beer
        // is roughly worth 8 chocolate bars (`1 * 4 = 8 * 0.5`). From this
        // equation, we can derive:
        // - The limit price for selling `x` and buying `y` is respected iff
        // ```
        // limit_x * price_x >= limit_y * price_y
        // ```
        // - The executed amount of token `y` given some amount of `x` and
        //   clearing prices is:
        // ```
        // amount_y = amount_x * price_x / price_y
        // ```

        require(
            order.sellAmount.mul(sellPrice) >= order.buyAmount.mul(buyPrice),
            "GPv2: limit price not respected"
        );

        uint256 executedSellAmount;
        uint256 executedBuyAmount;
        uint256 executedFeeAmount;
        uint256 currentFilledAmount;

        if (order.kind == GPv2Order.KIND_SELL) {
            if (order.partiallyFillable) {
                executedSellAmount = executedAmount;
                executedFeeAmount = order.feeAmount.mul(executedSellAmount).div(
                    order.sellAmount
                );
            } else {
                executedSellAmount = order.sellAmount;
                executedFeeAmount = order.feeAmount;
            }

            executedBuyAmount = executedSellAmount.mul(sellPrice).ceilDiv(
                buyPrice
            );

            currentFilledAmount = filledAmount[orderUid].add(
                executedSellAmount
            );
            require(
                currentFilledAmount <= order.sellAmount,
                "GPv2: order filled"
            );
        } else {
            if (order.partiallyFillable) {
                executedBuyAmount = executedAmount;
                executedFeeAmount = order.feeAmount.mul(executedBuyAmount).div(
                    order.buyAmount
                );
            } else {
                executedBuyAmount = order.buyAmount;
                executedFeeAmount = order.feeAmount;
            }

            executedSellAmount = executedBuyAmount.mul(buyPrice).div(sellPrice);

            currentFilledAmount = filledAmount[orderUid].add(executedBuyAmount);
            require(
                currentFilledAmount <= order.buyAmount,
                "GPv2: order filled"
            );
        }

        executedSellAmount = executedSellAmount.add(executedFeeAmount);
        filledAmount[orderUid] = currentFilledAmount;

        emit Trade(
            recoveredOrder.owner,
            order.sellToken,
            order.buyToken,
            executedSellAmount,
            executedBuyAmount,
            executedFeeAmount,
            orderUid
        );

        inTransfer.account = recoveredOrder.owner;
        inTransfer.token = order.sellToken;
        inTransfer.amount = executedSellAmount;
        inTransfer.balance = order.sellTokenBalance;

        outTransfer.account = recoveredOrder.receiver;
        outTransfer.token = order.buyToken;
        outTransfer.amount = executedBuyAmount;
        outTransfer.balance = order.buyTokenBalance;
    }

    /// @dev Execute a list of arbitrary contract calls from this contract.
    /// @param interactions The list of interactions to execute.
    function executeInteractions(GPv2Interaction.Data[] calldata interactions)
        internal
    {
        for (uint256 i; i < interactions.length; i++) {
            GPv2Interaction.Data calldata interaction = interactions[i];

            // To prevent possible attack on user funds, we explicitly disable
            // any interactions with the vault relayer contract.
            require(
                interaction.target != address(vaultRelayer),
                "GPv2: forbidden interaction"
            );
            GPv2Interaction.execute(interaction);

            emit Interaction(
                interaction.target,
                interaction.value,
                GPv2Interaction.selector(interaction)
            );
        }
    }

    /// @dev Claims refund for the specified storage and order UIDs.
    ///
    /// This method reverts if any of the orders are still valid.
    ///
    /// @param orderUids Order refund data for freeing storage.
    /// @param orderStorage Order storage mapped on a UID.
    function freeOrderStorage(
        mapping(bytes => uint256) storage orderStorage,
        bytes[] calldata orderUids
    ) internal {
        for (uint256 i = 0; i < orderUids.length; i++) {
            bytes calldata orderUid = orderUids[i];

            (, , uint32 validTo) = orderUid.extractOrderUidParams();
            // solhint-disable-next-line not-rely-on-time
            require(validTo < block.timestamp, "GPv2: order still valid");

            orderStorage[orderUid] = 0;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IERC20.sol";
import "./interfaces/IVault.sol";
import "./libraries/GPv2Transfer.sol";

/// @title Gnosis Protocol v2 Vault Relayer Contract
/// @author Gnosis Developers
contract GPv2VaultRelayer {
    using GPv2Transfer for IVault;

    /// @dev The creator of the contract which has special permissions. This
    /// value is set at creation time and cannot change.
    address private immutable creator;

    /// @dev The vault this relayer is for.
    IVault private immutable vault;

    constructor(IVault vault_) {
        creator = msg.sender;
        vault = vault_;
    }

    /// @dev Modifier that ensures that a function can only be called by the
    /// creator of this contract.
    modifier onlyCreator {
        require(msg.sender == creator, "GPv2: not creator");
        _;
    }

    /// @dev Transfers all sell amounts for the executed trades from their
    /// owners to the caller.
    ///
    /// This function reverts if:
    /// - The caller is not the creator of the vault relayer
    /// - Any ERC20 transfer fails
    ///
    /// @param transfers The transfers to execute.
    function transferFromAccounts(GPv2Transfer.Data[] calldata transfers)
        external
        onlyCreator
    {
        vault.transferFromAccounts(transfers, msg.sender);
    }

    /// @dev Performs a Balancer batched swap on behalf of a user and sends a
    /// fee to the caller.
    ///
    /// This function reverts if:
    /// - The caller is not the creator of the vault relayer
    /// - The swap fails
    /// - The fee transfer fails
    ///
    /// @param kind The Balancer swap kind, this can either be `GIVEN_IN` for
    /// sell orders or `GIVEN_OUT` for buy orders.
    /// @param swaps The swaps to perform.
    /// @param tokens The tokens for the swaps. Swaps encode to and from tokens
    /// as indices into this array.
    /// @param funds The fund management settings, specifying the user the swap
    /// is being performed for as well as the recipient of the proceeds.
    /// @param limits Swap limits for encoding limit prices.
    /// @param deadline The deadline for the swap.
    /// @param feeTransfer The transfer data for the caller fee.
    /// @return tokenDeltas The executed swap amounts.
    function batchSwapWithFee(
        IVault.SwapKind kind,
        IVault.BatchSwapStep[] calldata swaps,
        IERC20[] memory tokens,
        IVault.FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline,
        GPv2Transfer.Data calldata feeTransfer
    ) external onlyCreator returns (int256[] memory tokenDeltas) {
        tokenDeltas = vault.batchSwap(
            kind,
            swaps,
            tokens,
            funds,
            limits,
            deadline
        );
        vault.fastTransferFromAccount(feeTransfer, msg.sender);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;

/// @title Gnosis Protocol v2 Authentication Interface
/// @author Gnosis Developers
interface GPv2Authentication {
    /// @dev determines whether the provided address is an authenticated solver.
    /// @param prospectiveSolver the address of prospective solver.
    /// @return true when prospectiveSolver is an authenticated solver, otherwise false.
    function isSolver(address prospectiveSolver) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;

library GPv2EIP1271 {
    /// @dev Value returned by a call to `isValidSignature` if the signature
    /// was verified successfully. The value is defined in EIP-1271 as:
    /// bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
}

/// @title EIP1271 Interface
/// @dev Standardized interface for an implementation of smart contract
/// signatures as described in EIP-1271. The code that follows is identical to
/// the code in the standard with the exception of formatting and syntax
/// changes to adapt the code to our Solidity version.
interface EIP1271Verifier {
    /// @dev Should return whether the signature provided is valid for the
    /// provided data
    /// @param _hash      Hash of the data to be signed
    /// @param _signature Signature byte array associated with _data
    ///
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for
    /// solc > 0.5)
    /// MUST allow external calls
    ///
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// - Added `name`, `symbol` and `decimals` function declarations
// <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/IERC20.sol>

pragma solidity ^0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals the token uses.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IERC20.sol";

/**
 * @dev Minimal interface for the Vault core contract only containing methods
 * used by Gnosis Protocol V2. Original source:
 * <https://github.com/balancer-labs/balancer-core-v2/blob/v1.0.0/contracts/vault/interfaces/IVault.sol>
 */
interface IVault {
    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IERC20 asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IERC20 assetIn;
        IERC20 assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IERC20[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;

/// @title Gnosis Protocol v2 Interaction Library
/// @author Gnosis Developers
library GPv2Interaction {
    /// @dev Interaction data for performing arbitrary contract interactions.
    /// Submitted to [`GPv2Settlement.settle`] for code execution.
    struct Data {
        address target;
        uint256 value;
        bytes callData;
    }

    /// @dev Execute an arbitrary contract interaction.
    ///
    /// @param interaction Interaction data.
    function execute(Data calldata interaction) internal {
        address target = interaction.target;
        uint256 value = interaction.value;
        bytes calldata callData = interaction.callData;

        // NOTE: Use assembly to call the interaction instead of a low level
        // call for two reasons:
        // - We don't want to copy the return data, since we discard it for
        // interactions.
        // - Solidity will under certain conditions generate code to copy input
        // calldata twice to memory (the second being a "memcopy loop").
        // <https://github.com/gnosis/gp-v2-contracts/pull/417#issuecomment-775091258>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            calldatacopy(freeMemoryPointer, callData.offset, callData.length)
            if iszero(
                call(
                    gas(),
                    target,
                    value,
                    freeMemoryPointer,
                    callData.length,
                    0,
                    0
                )
            ) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /// @dev Extracts the Solidity ABI selector for the specified interaction.
    ///
    /// @param interaction Interaction data.
    /// @return result The 4 byte function selector of the call encoded in
    /// this interaction.
    function selector(Data calldata interaction)
        internal
        pure
        returns (bytes4 result)
    {
        bytes calldata callData = interaction.callData;
        if (callData.length >= 4) {
            // NOTE: Read the first word of the interaction's calldata. The
            // value does not need to be shifted since `bytesN` values are left
            // aligned, and the value does not need to be masked since masking
            // occurs when the value is accessed and not stored:
            // <https://docs.soliditylang.org/en/v0.7.6/abi-spec.html#encoding-of-indexed-event-parameters>
            // <https://docs.soliditylang.org/en/v0.7.6/assembly.html#access-to-external-variables-functions-and-libraries>
            // solhint-disable-next-line no-inline-assembly
            assembly {
                result := calldataload(callData.offset)
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;

import "../interfaces/IERC20.sol";

/// @title Gnosis Protocol v2 Order Library
/// @author Gnosis Developers
library GPv2Order {
    /// @dev The complete data for a Gnosis Protocol order. This struct contains
    /// all order parameters that are signed for submitting to GP.
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        uint32 validTo;
        bytes32 appData;
        uint256 feeAmount;
        bytes32 kind;
        bool partiallyFillable;
        bytes32 sellTokenBalance;
        bytes32 buyTokenBalance;
    }

    /// @dev The order EIP-712 type hash for the [`GPv2Order.Data`] struct.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256(
    ///     "Order(" +
    ///         "address sellToken," +
    ///         "address buyToken," +
    ///         "address receiver," +
    ///         "uint256 sellAmount," +
    ///         "uint256 buyAmount," +
    ///         "uint32 validTo," +
    ///         "bytes32 appData," +
    ///         "uint256 feeAmount," +
    ///         "string kind," +
    ///         "bool partiallyFillable" +
    ///         "string sellTokenBalance" +
    ///         "string buyTokenBalance" +
    ///     ")"
    /// )
    /// ```
    bytes32 internal constant TYPE_HASH =
        hex"d5a25ba2e97094ad7d83dc28a6572da797d6b3e7fc6663bd93efb789fc17e489";

    /// @dev The marker value for a sell order for computing the order struct
    /// hash. This allows the EIP-712 compatible wallets to display a
    /// descriptive string for the order kind (instead of 0 or 1).
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("sell")
    /// ```
    bytes32 internal constant KIND_SELL =
        hex"f3b277728b3fee749481eb3e0b3b48980dbbab78658fc419025cb16eee346775";

    /// @dev The OrderKind marker value for a buy order for computing the order
    /// struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("buy")
    /// ```
    bytes32 internal constant KIND_BUY =
        hex"6ed88e868af0a1983e3886d5f3e95a2fafbd6c3450bc229e27342283dc429ccc";

    /// @dev The TokenBalance marker value for using direct ERC20 balances for
    /// computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("erc20")
    /// ```
    bytes32 internal constant BALANCE_ERC20 =
        hex"5a28e9363bb942b639270062aa6bb295f434bcdfc42c97267bf003f272060dc9";

    /// @dev The TokenBalance marker value for using Balancer Vault external
    /// balances (in order to re-use Vault ERC20 approvals) for computing the
    /// order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("external")
    /// ```
    bytes32 internal constant BALANCE_EXTERNAL =
        hex"abee3b73373acd583a130924aad6dc38cfdc44ba0555ba94ce2ff63980ea0632";

    /// @dev The TokenBalance marker value for using Balancer Vault internal
    /// balances for computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("internal")
    /// ```
    bytes32 internal constant BALANCE_INTERNAL =
        hex"4ac99ace14ee0a5ef932dc609df0943ab7ac16b7583634612f8dc35a4289a6ce";

    /// @dev Marker address used to indicate that the receiver of the trade
    /// proceeds should the owner of the order.
    ///
    /// This is chosen to be `address(0)` for gas efficiency as it is expected
    /// to be the most common case.
    address internal constant RECEIVER_SAME_AS_OWNER = address(0);

    /// @dev The byte length of an order unique identifier.
    uint256 internal constant UID_LENGTH = 56;

    /// @dev Returns the actual receiver for an order. This function checks
    /// whether or not the [`receiver`] field uses the marker value to indicate
    /// it is the same as the order owner.
    ///
    /// @return receiver The actual receiver of trade proceeds.
    function actualReceiver(Data memory order, address owner)
        internal
        pure
        returns (address receiver)
    {
        if (order.receiver == RECEIVER_SAME_AS_OWNER) {
            receiver = owner;
        } else {
            receiver = order.receiver;
        }
    }

    /// @dev Return the EIP-712 signing hash for the specified order.
    ///
    /// @param order The order to compute the EIP-712 signing hash for.
    /// @param domainSeparator The EIP-712 domain separator to use.
    /// @return orderDigest The 32 byte EIP-712 struct hash.
    function hash(Data memory order, bytes32 domainSeparator)
        internal
        pure
        returns (bytes32 orderDigest)
    {
        bytes32 structHash;

        // NOTE: Compute the EIP-712 order struct hash in place. As suggested
        // in the EIP proposal, noting that the order struct has 10 fields, and
        // including the type hash `(12 + 1) * 32 = 416` bytes to hash.
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-encodedata>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, TYPE_HASH)
            structHash := keccak256(dataStart, 416)
            mstore(dataStart, temp)
        }

        // NOTE: Now that we have the struct hash, compute the EIP-712 signing
        // hash using scratch memory past the free memory pointer. The signing
        // hash is computed from `"\x19\x01" || domainSeparator || structHash`.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory>
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }
    }

    /// @dev Packs order UID parameters into the specified memory location. The
    /// result is equivalent to `abi.encodePacked(...)` with the difference that
    /// it allows re-using the memory for packing the order UID.
    ///
    /// This function reverts if the order UID buffer is not the correct size.
    ///
    /// @param orderUid The buffer pack the order UID parameters into.
    /// @param orderDigest The EIP-712 struct digest derived from the order
    /// parameters.
    /// @param owner The address of the user who owns this order.
    /// @param validTo The epoch time at which the order will stop being valid.
    function packOrderUidParams(
        bytes memory orderUid,
        bytes32 orderDigest,
        address owner,
        uint32 validTo
    ) internal pure {
        require(orderUid.length == UID_LENGTH, "GPv2: uid buffer overflow");

        // NOTE: Write the order UID to the allocated memory buffer. The order
        // parameters are written to memory in **reverse order** as memory
        // operations write 32-bytes at a time and we want to use a packed
        // encoding. This means, for example, that after writing the value of
        // `owner` to bytes `20:52`, writing the `orderDigest` to bytes `0:32`
        // will **overwrite** bytes `20:32`. This is desirable as addresses are
        // only 20 bytes and `20:32` should be `0`s:
        //
        //        |           1111111111222222222233333333334444444444555555
        //   byte | 01234567890123456789012345678901234567890123456789012345
        // -------+---------------------------------------------------------
        //  field | [.........orderDigest..........][......owner.......][vT]
        // -------+---------------------------------------------------------
        // mstore |                         [000000000000000000000000000.vT]
        //        |                     [00000000000.......owner.......]
        //        | [.........orderDigest..........]
        //
        // Additionally, since Solidity `bytes memory` are length prefixed,
        // 32 needs to be added to all the offsets.
        //
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(orderUid, 56), validTo)
            mstore(add(orderUid, 52), owner)
            mstore(add(orderUid, 32), orderDigest)
        }
    }

    /// @dev Extracts specific order information from the standardized unique
    /// order id of the protocol.
    ///
    /// @param orderUid The unique identifier used to represent an order in
    /// the protocol. This uid is the packed concatenation of the order digest,
    /// the validTo order parameter and the address of the user who created the
    /// order. It is used by the user to interface with the contract directly,
    /// and not by calls that are triggered by the solvers.
    /// @return orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the user who owns this order.
    /// @return validTo The epoch time at which the order will stop being valid.
    function extractOrderUidParams(bytes calldata orderUid)
        internal
        pure
        returns (
            bytes32 orderDigest,
            address owner,
            uint32 validTo
        )
    {
        require(orderUid.length == UID_LENGTH, "GPv2: invalid uid");

        // Use assembly to efficiently decode packed calldata.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            orderDigest := calldataload(orderUid.offset)
            owner := shr(96, calldataload(add(orderUid.offset, 32)))
            validTo := shr(224, calldataload(add(orderUid.offset, 52)))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;

import "../interfaces/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract that notably
/// does not revert when calling a non-contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTansferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTansferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTansferResult(IERC20 token)
        private
        view
        returns (bool success)
    {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
                // Non-standard ERC20 transfer without return.
                case 0 {
                    // NOTE: When the return data size is 0, verify that there
                    // is code at the address. This is done in order to maintain
                    // compatibility with Solidity calling conventions.
                    // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                    if iszero(extcodesize(token)) {
                        revertWithMessage(20, "GPv2: not a contract")
                    }

                    success := 1
                }
                // Standard ERC20 transfer returning boolean success value.
                case 32 {
                    returndatacopy(0, 0, returndatasize())

                    // NOTE: For ABI encoding v1, any non-zero value is accepted
                    // as `true` for a boolean. In order to stay compatible with
                    // OpenZeppelin's `SafeERC20` library which is known to work
                    // with the existing ERC20 implementation we care about,
                    // make sure we return success for any non-zero return value
                    // from the `transfer*` call.
                    success := iszero(iszero(mload(0)))
                }
                default {
                    revertWithMessage(31, "GPv2: malformed transfer result")
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;

import "../interfaces/IERC20.sol";
import "../mixins/GPv2Signing.sol";
import "./GPv2Order.sol";

/// @title Gnosis Protocol v2 Trade Library.
/// @author Gnosis Developers
library GPv2Trade {
    using GPv2Order for GPv2Order.Data;
    using GPv2Order for bytes;

    /// @dev A struct representing a trade to be executed as part a batch
    /// settlement.
    struct Data {
        uint256 sellTokenIndex;
        uint256 buyTokenIndex;
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        uint32 validTo;
        bytes32 appData;
        uint256 feeAmount;
        uint256 flags;
        uint256 executedAmount;
        bytes signature;
    }

    /// @dev Extracts the order data and signing scheme for the specified trade.
    ///
    /// @param trade The trade.
    /// @param tokens The list of tokens included in the settlement. The token
    /// indices in the trade parameters map to tokens in this array.
    /// @param order The memory location to extract the order data to.
    function extractOrder(
        Data calldata trade,
        IERC20[] calldata tokens,
        GPv2Order.Data memory order
    ) internal pure returns (GPv2Signing.Scheme signingScheme) {
        order.sellToken = tokens[trade.sellTokenIndex];
        order.buyToken = tokens[trade.buyTokenIndex];
        order.receiver = trade.receiver;
        order.sellAmount = trade.sellAmount;
        order.buyAmount = trade.buyAmount;
        order.validTo = trade.validTo;
        order.appData = trade.appData;
        order.feeAmount = trade.feeAmount;
        (
            order.kind,
            order.partiallyFillable,
            order.sellTokenBalance,
            order.buyTokenBalance,
            signingScheme
        ) = extractFlags(trade.flags);
    }

    /// @dev Decodes trade flags.
    ///
    /// Trade flags are used to tightly encode information on how to decode
    /// an order. Examples that directly affect the structure of an order are
    /// the kind of order (either a sell or a buy order) as well as whether the
    /// order is partially fillable or if it is a "fill-or-kill" order. It also
    /// encodes the signature scheme used to validate the order. As the most
    /// likely values are fill-or-kill sell orders by an externally owned
    /// account, the flags are chosen such that `0x00` represents this kind of
    /// order. The flags byte uses the following format:
    ///
    /// ```
    /// bit | 31 ...   | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
    /// ----+----------+---+---+-------+---+---+
    ///     | reserved | *   * | * | *   * | * | * |
    ///                  |   |   |   |   |   |   |
    ///                  |   |   |   |   |   |   +---- order kind bit, 0 for a sell order
    ///                  |   |   |   |   |   |         and 1 for a buy order
    ///                  |   |   |   |   |   |
    ///                  |   |   |   |   |   +-------- order fill bit, 0 for fill-or-kill
    ///                  |   |   |   |   |             and 1 for a partially fillable order
    ///                  |   |   |   |   |
    ///                  |   |   |   +---+------------ use internal sell token balance bit:
    ///                  |   |   |                     0x: ERC20 token balance
    ///                  |   |   |                     10: external Balancer Vault balance
    ///                  |   |   |                     11: internal Balancer Vault balance
    ///                  |   |   |
    ///                  |   |   +-------------------- use buy token balance bit
    ///                  |   |                         0: ERC20 token balance
    ///                  |   |                         1: internal Balancer Vault balance
    ///                  |   |
    ///                  +---+------------------------ signature scheme bits:
    ///                                                00: EIP-712
    ///                                                01: eth_sign
    ///                                                10: EIP-1271
    ///                                                11: pre_sign
    /// ```
    function extractFlags(uint256 flags)
        internal
        pure
        returns (
            bytes32 kind,
            bool partiallyFillable,
            bytes32 sellTokenBalance,
            bytes32 buyTokenBalance,
            GPv2Signing.Scheme signingScheme
        )
    {
        if (flags & 0x01 == 0) {
            kind = GPv2Order.KIND_SELL;
        } else {
            kind = GPv2Order.KIND_BUY;
        }
        partiallyFillable = flags & 0x02 != 0;
        if (flags & 0x08 == 0) {
            sellTokenBalance = GPv2Order.BALANCE_ERC20;
        } else if (flags & 0x04 == 0) {
            sellTokenBalance = GPv2Order.BALANCE_EXTERNAL;
        } else {
            sellTokenBalance = GPv2Order.BALANCE_INTERNAL;
        }
        if (flags & 0x10 == 0) {
            buyTokenBalance = GPv2Order.BALANCE_ERC20;
        } else {
            buyTokenBalance = GPv2Order.BALANCE_INTERNAL;
        }

        // NOTE: Take advantage of the fact that Solidity will revert if the
        // following expression does not produce a valid enum value. This means
        // we check here that the leading reserved bits must be 0.
        signingScheme = GPv2Signing.Scheme(flags >> 5);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/IERC20.sol";
import "../interfaces/IVault.sol";
import "./GPv2Order.sol";
import "./GPv2SafeERC20.sol";

/// @title Gnosis Protocol v2 Transfers
/// @author Gnosis Developers
library GPv2Transfer {
    using GPv2SafeERC20 for IERC20;

    /// @dev Transfer data.
    struct Data {
        address account;
        IERC20 token;
        uint256 amount;
        bytes32 balance;
    }

    /// @dev Ether marker address used to indicate an Ether transfer.
    address internal constant BUY_ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Execute the specified transfer from the specified account to a
    /// recipient. The recipient will either receive internal Vault balances or
    /// ERC20 token balances depending on whether the account is using internal
    /// balances or not.
    ///
    /// This method is used for transferring fees to the settlement contract
    /// when settling a single order directly with Balancer.
    ///
    /// Note that this method is subtly different from `transferFromAccounts`
    /// with a single transfer with respect to how it deals with internal
    /// balances. Specifically, this method will perform an **internal balance
    /// transfer to the settlement contract instead of a withdrawal to the
    /// external balance of the settlement contract** for trades that specify
    /// trading with internal balances. This is done as a gas optimization in
    /// the single order "fast-path".
    ///
    /// @param vault The Balancer vault to use.
    /// @param transfer The transfer to perform specifying the sender account.
    /// @param recipient The recipient for the transfer.
    function fastTransferFromAccount(
        IVault vault,
        Data calldata transfer,
        address recipient
    ) internal {
        require(
            address(transfer.token) != BUY_ETH_ADDRESS,
            "GPv2: cannot transfer native ETH"
        );

        if (transfer.balance == GPv2Order.BALANCE_ERC20) {
            transfer.token.safeTransferFrom(
                transfer.account,
                recipient,
                transfer.amount
            );
        } else {
            IVault.UserBalanceOp[] memory balanceOps =
                new IVault.UserBalanceOp[](1);

            IVault.UserBalanceOp memory balanceOp = balanceOps[0];
            balanceOp.kind = transfer.balance == GPv2Order.BALANCE_EXTERNAL
                ? IVault.UserBalanceOpKind.TRANSFER_EXTERNAL
                : IVault.UserBalanceOpKind.TRANSFER_INTERNAL;
            balanceOp.asset = transfer.token;
            balanceOp.amount = transfer.amount;
            balanceOp.sender = transfer.account;
            balanceOp.recipient = payable(recipient);

            vault.manageUserBalance(balanceOps);
        }
    }

    /// @dev Execute the specified transfers from the specified accounts to a
    /// single recipient. The recipient will receive all transfers as ERC20
    /// token balances, regardless of whether or not the accounts are using
    /// internal Vault balances.
    ///
    /// This method is used for accumulating user balances into the settlement
    /// contract.
    ///
    /// @param vault The Balancer vault to use.
    /// @param transfers The batched transfers to perform specifying the
    /// sender accounts.
    /// @param recipient The single recipient for all the transfers.
    function transferFromAccounts(
        IVault vault,
        Data[] calldata transfers,
        address recipient
    ) internal {
        // NOTE: Allocate buffer of Vault balance operations large enough to
        // hold all GP transfers. This is done to avoid re-allocations (which
        // are gas inefficient) while still allowing all transfers to be batched
        // into a single Vault call.
        IVault.UserBalanceOp[] memory balanceOps =
            new IVault.UserBalanceOp[](transfers.length);
        uint256 balanceOpCount = 0;

        for (uint256 i = 0; i < transfers.length; i++) {
            Data calldata transfer = transfers[i];
            require(
                address(transfer.token) != BUY_ETH_ADDRESS,
                "GPv2: cannot transfer native ETH"
            );

            if (transfer.balance == GPv2Order.BALANCE_ERC20) {
                transfer.token.safeTransferFrom(
                    transfer.account,
                    recipient,
                    transfer.amount
                );
            } else {
                IVault.UserBalanceOp memory balanceOp =
                    balanceOps[balanceOpCount++];
                balanceOp.kind = transfer.balance == GPv2Order.BALANCE_EXTERNAL
                    ? IVault.UserBalanceOpKind.TRANSFER_EXTERNAL
                    : IVault.UserBalanceOpKind.WITHDRAW_INTERNAL;
                balanceOp.asset = transfer.token;
                balanceOp.amount = transfer.amount;
                balanceOp.sender = transfer.account;
                balanceOp.recipient = payable(recipient);
            }
        }

        if (balanceOpCount > 0) {
            truncateBalanceOpsArray(balanceOps, balanceOpCount);
            vault.manageUserBalance(balanceOps);
        }
    }

    /// @dev Execute the specified transfers to their respective accounts.
    ///
    /// This method is used for paying out trade proceeds from the settlement
    /// contract.
    ///
    /// @param vault The Balancer vault to use.
    /// @param transfers The batched transfers to perform.
    function transferToAccounts(IVault vault, Data[] memory transfers)
        internal
    {
        IVault.UserBalanceOp[] memory balanceOps =
            new IVault.UserBalanceOp[](transfers.length);
        uint256 balanceOpCount = 0;

        for (uint256 i = 0; i < transfers.length; i++) {
            Data memory transfer = transfers[i];

            if (address(transfer.token) == BUY_ETH_ADDRESS) {
                require(
                    transfer.balance != GPv2Order.BALANCE_INTERNAL,
                    "GPv2: unsupported internal ETH"
                );
                payable(transfer.account).transfer(transfer.amount);
            } else if (transfer.balance == GPv2Order.BALANCE_ERC20) {
                transfer.token.safeTransfer(transfer.account, transfer.amount);
            } else {
                IVault.UserBalanceOp memory balanceOp =
                    balanceOps[balanceOpCount++];
                balanceOp.kind = IVault.UserBalanceOpKind.DEPOSIT_INTERNAL;
                balanceOp.asset = transfer.token;
                balanceOp.amount = transfer.amount;
                balanceOp.sender = address(this);
                balanceOp.recipient = payable(transfer.account);
            }
        }

        if (balanceOpCount > 0) {
            truncateBalanceOpsArray(balanceOps, balanceOpCount);
            vault.manageUserBalance(balanceOps);
        }
    }

    /// @dev Truncate a Vault balance operation array to its actual size.
    ///
    /// This method **does not** check whether or not the new length is valid,
    /// and specifying a size that is larger than the array's actual length is
    /// undefined behaviour.
    ///
    /// @param balanceOps The memory array of balance operations to truncate.
    /// @param newLength The new length to set.
    function truncateBalanceOpsArray(
        IVault.UserBalanceOp[] memory balanceOps,
        uint256 newLength
    ) private pure {
        // NOTE: Truncate the vault transfers array to the specified length.
        // This is done by setting the array's length which occupies the first
        // word in memory pointed to by the `balanceOps` memory variable.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(balanceOps, newLength)
        }
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// - Shortened revert messages
// - Removed unused methods
// - Convert to `type(*).*` notation
// <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/SafeCast.sol>

pragma solidity ^0.7.6;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: not positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            "SafeCast: int256 overflow"
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// - Shortened some revert messages
// - Removed unused methods
// - Added `ceilDiv` method
// <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/math/SafeMath.sol>

pragma solidity ^0.7.6;

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
        require(c / a == b, "SafeMath: mul overflow");
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
        require(b > 0, "SafeMath: division by 0");
        return a / b;
    }

    /**
     * @dev Returns the ceiling integer division of two unsigned integers,
     * reverting on division by zero. The result is rounded towards up the
     * nearest integer, instead of truncating the fractional part.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     * - The sum of the dividend and divisor cannot overflow.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: ceiling division by 0");
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;

import "../interfaces/GPv2EIP1271.sol";
import "../libraries/GPv2Order.sol";
import "../libraries/GPv2Trade.sol";

/// @title Gnosis Protocol v2 Signing Library.
/// @author Gnosis Developers
abstract contract GPv2Signing {
    using GPv2Order for GPv2Order.Data;
    using GPv2Order for bytes;

    /// @dev Recovered trade data containing the extracted order and the
    /// recovered owner address.
    struct RecoveredOrder {
        GPv2Order.Data data;
        bytes uid;
        address owner;
        address receiver;
    }

    /// @dev Signing scheme used for recovery.
    enum Scheme {Eip712, EthSign, Eip1271, PreSign}

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 private constant DOMAIN_NAME = keccak256("Gnosis Protocol");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 private constant DOMAIN_VERSION = keccak256("v2");

    /// @dev Marker value indicating an order is pre-signed.
    uint256 private constant PRE_SIGNED =
        uint256(keccak256("GPv2Signing.Scheme.PreSign"));

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// GPv2 contracts.
    bytes32 public immutable domainSeparator;

    /// @dev Storage indicating whether or not an order has been signed by a
    /// particular address.
    mapping(bytes => uint256) public preSignature;

    /// @dev Event that is emitted when an account either pre-signs an order or
    /// revokes an existing pre-signature.
    event PreSignature(address indexed owner, bytes orderUid, bool signed);

    constructor() {
        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );
    }

    /// @dev Sets a presignature for the specified order UID.
    ///
    /// @param orderUid The unique identifier of the order to pre-sign.
    function setPreSignature(bytes calldata orderUid, bool signed) external {
        (, address owner, ) = orderUid.extractOrderUidParams();
        require(owner == msg.sender, "GPv2: cannot presign order");
        if (signed) {
            preSignature[orderUid] = PRE_SIGNED;
        } else {
            preSignature[orderUid] = 0;
        }
        emit PreSignature(owner, orderUid, signed);
    }

    /// @dev Returns an empty recovered order with a pre-allocated buffer for
    /// packing the unique identifier.
    ///
    /// @return recoveredOrder The empty recovered order data.
    function allocateRecoveredOrder()
        internal
        pure
        returns (RecoveredOrder memory recoveredOrder)
    {
        recoveredOrder.uid = new bytes(GPv2Order.UID_LENGTH);
    }

    /// @dev Extracts order data and recovers the signer from the specified
    /// trade.
    ///
    /// @param recoveredOrder Memory location used for writing the recovered order data.
    /// @param tokens The list of tokens included in the settlement. The token
    /// indices in the trade parameters map to tokens in this array.
    /// @param trade The trade data to recover the order data from.
    function recoverOrderFromTrade(
        RecoveredOrder memory recoveredOrder,
        IERC20[] calldata tokens,
        GPv2Trade.Data calldata trade
    ) internal view {
        GPv2Order.Data memory order = recoveredOrder.data;

        Scheme signingScheme = GPv2Trade.extractOrder(trade, tokens, order);
        (bytes32 orderDigest, address owner) =
            recoverOrderSigner(order, signingScheme, trade.signature);

        recoveredOrder.uid.packOrderUidParams(
            orderDigest,
            owner,
            order.validTo
        );
        recoveredOrder.owner = owner;
        recoveredOrder.receiver = order.actualReceiver(owner);
    }

    /// @dev The length of any signature from an externally owned account.
    uint256 private constant ECDSA_SIGNATURE_LENGTH = 65;

    /// @dev Recovers an order's signer from the specified order and signature.
    ///
    /// @param order The order to recover a signature for.
    /// @param signingScheme The signing scheme.
    /// @param signature The signature bytes.
    /// @return orderDigest The computed order hash.
    /// @return owner The recovered address from the specified signature.
    function recoverOrderSigner(
        GPv2Order.Data memory order,
        Scheme signingScheme,
        bytes calldata signature
    ) internal view returns (bytes32 orderDigest, address owner) {
        orderDigest = order.hash(domainSeparator);
        if (signingScheme == Scheme.Eip712) {
            owner = recoverEip712Signer(orderDigest, signature);
        } else if (signingScheme == Scheme.EthSign) {
            owner = recoverEthsignSigner(orderDigest, signature);
        } else if (signingScheme == Scheme.Eip1271) {
            owner = recoverEip1271Signer(orderDigest, signature);
        } else {
            // signingScheme == Scheme.PreSign
            owner = recoverPreSigner(orderDigest, signature, order.validTo);
        }
    }

    /// @dev Perform an ECDSA recover for the specified message and calldata
    /// signature.
    ///
    /// The signature is encoded by tighyly packing the following struct:
    /// ```
    /// struct EncodedSignature {
    ///     bytes32 r;
    ///     bytes32 s;
    ///     uint8 v;
    /// }
    /// ```
    ///
    /// @param message The signed message.
    /// @param encodedSignature The encoded signature.
    function ecdsaRecover(bytes32 message, bytes calldata encodedSignature)
        internal
        pure
        returns (address signer)
    {
        require(
            encodedSignature.length == ECDSA_SIGNATURE_LENGTH,
            "GPv2: malformed ecdsa signature"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        // NOTE: Use assembly to efficiently decode signature data.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // r = uint256(encodedSignature[0:32])
            r := calldataload(encodedSignature.offset)
            // s = uint256(encodedSignature[32:64])
            s := calldataload(add(encodedSignature.offset, 32))
            // v = uint8(encodedSignature[64])
            v := shr(248, calldataload(add(encodedSignature.offset, 64)))
        }

        signer = ecrecover(message, v, r, s);
        require(signer != address(0), "GPv2: invalid ecdsa signature");
    }

    /// @dev Decodes signature bytes originating from an EIP-712-encoded
    /// signature.
    ///
    /// EIP-712 signs typed data. The specifications are described in the
    /// related EIP (<https://eips.ethereum.org/EIPS/eip-712>).
    ///
    /// EIP-712 signatures are encoded as standard ECDSA signatures as described
    /// in the corresponding decoding function [`ecdsaRecover`].
    ///
    /// @param orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @param encodedSignature Calldata pointing to tightly packed signature
    /// bytes.
    /// @return owner The address of the signer.
    function recoverEip712Signer(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal pure returns (address owner) {
        owner = ecdsaRecover(orderDigest, encodedSignature);
    }

    /// @dev Decodes signature bytes originating from the output of the eth_sign
    /// RPC call.
    ///
    /// The specifications are described in the Ethereum documentation
    /// (<https://eth.wiki/json-rpc/API#eth_sign>).
    ///
    /// eth_sign signatures are encoded as standard ECDSA signatures as
    /// described in the corresponding decoding function
    /// [`ecdsaRecover`].
    ///
    /// @param orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @param encodedSignature Calldata pointing to tightly packed signature
    /// bytes.
    /// @return owner The address of the signer.
    function recoverEthsignSigner(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal pure returns (address owner) {
        // The signed message is encoded as:
        // `"\x19Ethereum Signed Message:\n" || length || data`, where
        // the length is a constant (32 bytes) and the data is defined as:
        // `orderDigest`.
        bytes32 ethsignDigest =
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    orderDigest
                )
            );

        owner = ecdsaRecover(ethsignDigest, encodedSignature);
    }

    /// @dev Verifies the input calldata as an EIP-1271 contract signature and
    /// returns the address of the signer.
    ///
    /// The encoded signature tightly packs the following struct:
    ///
    /// ```
    /// struct EncodedEip1271Signature {
    ///     address owner;
    ///     bytes signature;
    /// }
    /// ```
    ///
    /// This function enforces that the encoded data stores enough bytes to
    /// cover the full length of the decoded signature.
    ///
    /// @param encodedSignature The encoded EIP-1271 signature.
    /// @param orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the signer.
    function recoverEip1271Signer(
        bytes32 orderDigest,
        bytes calldata encodedSignature
    ) internal view returns (address owner) {
        // NOTE: Use assembly to read the verifier address from the encoded
        // signature bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // owner = address(encodedSignature[0:20])
            owner := shr(96, calldataload(encodedSignature.offset))
        }

        // NOTE: Configure prettier to ignore the following line as it causes
        // a panic in the Solidity plugin.
        // prettier-ignore
        bytes calldata signature = encodedSignature[20:];

        require(
            EIP1271Verifier(owner).isValidSignature(orderDigest, signature) ==
                GPv2EIP1271.MAGICVALUE,
            "GPv2: invalid eip1271 signature"
        );
    }

    /// @dev Verifies the order has been pre-signed. The signature is the
    /// address of the signer of the order.
    ///
    /// @param orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @param encodedSignature The pre-sign signature reprenting the order UID.
    /// @param validTo The order expiry timestamp.
    /// @return owner The address of the signer.
    function recoverPreSigner(
        bytes32 orderDigest,
        bytes calldata encodedSignature,
        uint32 validTo
    ) internal view returns (address owner) {
        require(encodedSignature.length == 20, "GPv2: malformed presignature");
        // NOTE: Use assembly to read the owner address from the encoded
        // signature bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // owner = address(encodedSignature[0:20])
            owner := shr(96, calldataload(encodedSignature.offset))
        }

        bytes memory orderUid = new bytes(GPv2Order.UID_LENGTH);
        orderUid.packOrderUidParams(orderDigest, owner, validTo);

        require(
            preSignature[orderUid] == PRE_SIGNED,
            "GPv2: order not presigned"
        );
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol>

pragma solidity ^0.7.6;

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

// SPDX-License-Identifier: LGPL-3.0-only

// Vendored from Gnosis utility contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// - Added linter directives to ignore low level call and assembly warnings
// <https://github.com/gnosis/util-contracts/blob/v3.1.0-solc-7/contracts/StorageAccessible.sol>

pragma solidity ^0.7.6;

/// @title ViewStorageAccessible - Interface on top of StorageAccessible base class to allow simulations from view functions
interface ViewStorageAccessible {
    /**
     * @dev Same as `simulateDelegatecall` on StorageAccessible. Marked as view so that it can be called from external contracts
     * that want to run simulations from within view functions. Will revert if the invoked simulation attempts to change state.
     */
    function simulateDelegatecall(
        address targetContract,
        bytes memory calldataPayload
    ) external view returns (bytes memory);

    /**
     * @dev Same as `getStorageAt` on StorageAccessible. This method allows reading aribtrary ranges of storage.
     */
    function getStorageAt(uint256 offset, uint256 length)
        external
        view
        returns (bytes memory);
}

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length)
        external
        view
        returns (bytes memory)
    {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static). Catches revert and returns encoded result as bytes.
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateDelegatecall(
        address targetContract,
        bytes memory calldataPayload
    ) public returns (bytes memory response) {
        bytes memory innerCall =
            abi.encodeWithSelector(
                this.simulateDelegatecallInternal.selector,
                targetContract,
                calldataPayload
            );
        // solhint-disable-next-line avoid-low-level-calls
        (, response) = address(this).call(innerCall);
        bool innerSuccess = response[response.length - 1] == 0x01;
        setLength(response, response.length - 1);
        if (innerSuccess) {
            return response;
        } else {
            revertWith(response);
        }
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static). Returns encoded result as revert message
     * concatenated with the success flag of the inner call as a last byte.
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateDelegatecallInternal(
        address targetContract,
        bytes memory calldataPayload
    ) external returns (bytes memory response) {
        bool success;
        // solhint-disable-next-line avoid-low-level-calls
        (success, response) = targetContract.delegatecall(calldataPayload);
        revertWith(abi.encodePacked(response, success));
    }

    function revertWith(bytes memory response) internal pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            revert(add(response, 0x20), mload(response))
        }
    }

    function setLength(bytes memory buffer, uint256 length) internal pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(buffer, length)
        }
    }
}

