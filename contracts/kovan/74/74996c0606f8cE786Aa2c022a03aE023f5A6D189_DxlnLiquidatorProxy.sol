// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/DxlnTypes.sol";

/**
 * @notice Interface for PerpetualV1.
 */

interface I_DxlnPerpetualV1 {
    // ============ Structs ============

    struct TradeArg {
        uint256 takerIndex;
        uint256 makerIndex;
        address trader;
        bytes data;
    }

    // ============ State-Changing Functions ============

    /**
     * @notice Submits one or more trades between any number of accounts.
     *
     * @param  accounts  The sorted list of accounts that are involved in trades.
     * @param  trades    The list of trades to execute in-order.
     */
    function trade(address[] calldata accounts, TradeArg[] calldata trades)
        external;

    /**
     * @notice Withdraw the number of margin tokens equal to the value of the account at the time
     *  that final settlement occurred.
     */
    function withdrawFinalSettlement() external;

    /**
     * @notice Deposit some amount of margin tokens from the msg.sender into an account.
     *
     * @param  account  The account for which to credit the deposit.
     * @param  amount   the amount of tokens to deposit.
     */
    function deposit(address account, uint256 amount) external;

    /**
     * @notice Withdraw some amount of margin tokens from an account to a destination address.
     *
     * @param  account      The account for which to debit the withdrawal.
     * @param  destination  The address to which the tokens are transferred.
     * @param  amount       The amount of tokens to withdraw.
     */
    function withdraw(
        address account,
        address destination,
        uint256 amount
    ) external;

    /**
     * @notice Grants or revokes permission for another account to perform certain actions on behalf
     *  of the sender.
     *
     * @param  operator  The account that is approved or disapproved.
     * @param  approved  True for approval, false for disapproval.
     */
    function setLocalOperator(address operator, bool approved) external;

    // ============ Account Getters ============

    /**
     * @notice Get the balance of an account, without accounting for changes in the index.
     *
     * @param  account  The address of the account to query the balances of.
     * @return          The balances of the account.
     */
    function getAccountBalance(address account)
        external
        view
        returns (DxlnTypes.Balance memory);

    /**
     * @notice Gets the most recently cached index of an account.
     *
     * @param  account  The address of the account to query the index of.
     * @return          The index of the account.
     */
    function getAccountIndex(address account)
        external
        view
        returns (DxlnTypes.Index memory);

    /**
     * @notice Gets the local operator status of an operator for a particular account.
     *
     * @param  account   The account to query the operator for.
     * @param  operator  The address of the operator to query the status of.
     * @return           True if the operator is a local operator of the account, false otherwise.
     */
    function getIsLocalOperator(address account, address operator)
        external
        view
        returns (bool);

    // ============ Global Getters ============

    /**
     * @notice Gets the global operator status of an address.
     *
     * @param  operator  The address of the operator to query the status of.
     * @return           True if the address is a global operator, false otherwise.
     */
    function getIsGlobalOperator(address operator) external view returns (bool);

    /**
     * @notice Gets the address of the ERC20 margin contract used for margin deposits.
     *
     * @return The address of the ERC20 token.
     */
    function getTokenContract() external view returns (address);

    /**
     * @notice Gets the current address of the price oracle contract.
     *
     * @return The address of the price oracle contract.
     */
    function getOracleContract() external view returns (address);

    /**
     * @notice Gets the current address of the funder contract.
     *
     * @return The address of the funder contract.
     */
    function getFunderContract() external view returns (address);

    /**
     * @notice Gets the most recently cached global index.
     *
     * @return The most recently cached global index.
     */
    function getGlobalIndex() external view returns (DxlnTypes.Index memory);

    /**
     * @notice Gets minimum collateralization ratio of the protocol.
     *
     * @return The minimum-acceptable collateralization ratio, returned as a fixed-point number with
     *  18 decimals of precision.
     */
    function getMinCollateral() external view returns (uint256);

    /**
     * @notice Gets the status of whether final-settlement was initiated by the Admin.
     *
     * @return True if final-settlement was enabled, false otherwise.
     */
    function getFinalSettlementEnabled() external view returns (bool);

    // ============ Public Getters ============

    /**
     * @notice Gets whether an address has permissions to operate an account.
     *
     * @param  account   The account to query.
     * @param  operator  The address to query.
     * @return           True if the operator has permission to operate the account,
     *                   and false otherwise.
     */
    function hasAccountPermissions(address account, address operator)
        external
        view
        returns (bool);

    // ============ Authorized Getters ============

    /**
     * @notice Gets the price returned by the oracle.
     * @dev Only able to be called by global operators.
     *
     * @return The price returned by the current price oracle.
     */
    function getOraclePrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/BaseMath.sol";
import "../utils/SafeMath.sol";
import "../utils/SignedMath.sol";
import "./DxlnTypes.sol";
import "../utils/SafeCast.sol";

/**
 * @dev Library for manipulating DxlnTypes.Balance structs.
 */

library DxlnBalanceMath {
    using BaseMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedMath for SignedMath.Int;
    using DxlnBalanceMath for DxlnTypes.Balance;

    // ============ Constants ============

    uint256 private constant FLAG_MARGIN_IS_POSITIVE = 1 << (8 * 31);
    uint256 private constant FLAG_POSITION_IS_POSITIVE = 1 << (8 * 15);

    // ============ Functions ============

    /**
     * @dev Create a copy of the balance struct.
     */
    function copy(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (DxlnTypes.Balance memory)
    {
        return
            DxlnTypes.Balance({
                marginIsPositive: balance.marginIsPositive,
                positionIsPositive: balance.positionIsPositive,
                margin: balance.margin,
                position: balance.position
            });
    }

    /**
     * @dev In-place add amount to balance.margin.
     */
    function addToMargin(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedMargin = balance.getMargin();
        signedMargin = signedMargin.add(amount);
        balance.setMargin(signedMargin);
    }

    /**
     * @dev In-place subtract amount from balance.margin.
     */
    function subFromMargin(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedMargin = balance.getMargin();
        signedMargin = signedMargin.sub(amount);
        balance.setMargin(signedMargin);
    }

    /**
     * @dev In-place add amount to balance.position.
     */
    function addToPosition(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedPosition = balance.getPosition();
        signedPosition = signedPosition.add(amount);
        balance.setPosition(signedPosition);
    }

    /**
     * @dev In-place subtract amount from balance.position.
     */
    function subFromPosition(DxlnTypes.Balance memory balance, uint256 amount)
        internal
        pure
    {
        SignedMath.Int memory signedPosition = balance.getPosition();
        signedPosition = signedPosition.sub(amount);
        balance.setPosition(signedPosition);
    }

    /**
     * @dev Returns the positive and negative values of the margin and position together, given a
     *  price, which is used as a conversion rate between the two currencies.
     *
     *  No rounding occurs here--the returned values are "base values" with extra precision.
     */
    function getPositiveAndNegativeValue(
        DxlnTypes.Balance memory balance,
        uint256 price
    ) internal pure returns (uint256, uint256) {
        uint256 positiveValue = 0;
        uint256 negativeValue = 0;

        // add value of margin
        if (balance.marginIsPositive) {
            positiveValue = uint256(balance.margin).mul(BaseMath.base());
        } else {
            negativeValue = uint256(balance.margin).mul(BaseMath.base());
        }

        // add value of position
        uint256 positionValue = uint256(balance.position).mul(price);
        if (balance.positionIsPositive) {
            positiveValue = positiveValue.add(positionValue);
        } else {
            negativeValue = negativeValue.add(positionValue);
        }

        return (positiveValue, negativeValue);
    }

    /**
     * @dev Returns a compressed bytes32 representation of the balance for logging.
     */
    function toBytes32(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (bytes32)
    {
        uint256 result = uint256(balance.position) |
            (uint256(balance.margin) << 128) |
            (balance.marginIsPositive ? FLAG_MARGIN_IS_POSITIVE : 0) |
            (balance.positionIsPositive ? FLAG_POSITION_IS_POSITIVE : 0);
        return bytes32(result);
    }

    // ============ Helper Functions ============

    /**
     * @dev Returns a SignedMath.Int version of the margin in balance.
     */
    function getMargin(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (SignedMath.Int memory)
    {
        return
            SignedMath.Int({
                value: balance.margin,
                isPositive: balance.marginIsPositive
            });
    }

    /**
     * @dev Returns a SignedMath.Int version of the position in balance.
     */
    function getPosition(DxlnTypes.Balance memory balance)
        internal
        pure
        returns (SignedMath.Int memory)
    {
        return
            SignedMath.Int({
                value: balance.position,
                isPositive: balance.positionIsPositive
            });
    }

    /**
     * @dev In-place modify the signed margin value of a balance.
     */
    function setMargin(
        DxlnTypes.Balance memory balance,
        SignedMath.Int memory newMargin
    ) internal pure {
        balance.margin = newMargin.value.toUint120();
        balance.marginIsPositive = newMargin.isPositive;
    }

    /**
     * @dev In-place modify the signed position value of a balance.
     */
    function setPosition(
        DxlnTypes.Balance memory balance,
        SignedMath.Int memory newPosition
    ) internal pure {
        balance.position = newPosition.value.toUint120();
        balance.positionIsPositive = newPosition.isPositive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Library for common types used in PerpetualV1 contracts.
 */

library DxlnTypes {
    // ============ Structs ============

    /**
     * @dev Used to represent the global index and each account's cached index.
     *  Used to settle funding payments on a per-account basis.
     */
    struct Index {
        uint32 timestamp;
        bool isPositive;
        uint128 value;
    }

    /**
     * @dev Used to track the signed margin balance and position balance values for each account.
     */
    struct Balance {
        bool marginIsPositive;
        bool positionIsPositive;
        uint120 margin;
        uint120 position;
    }

    /**
     * @dev Used to cache commonly-used variables that are relatively gas-intensive to obtain.
     */
    struct Context {
        uint256 price;
        uint256 minCollateral;
        Index index;
    }

    /**
     * @dev Used by contracts implementing the I_DxlnTrader interface to return the result of a trade.
     */
    struct TradeResult {
        uint256 marginAmount;
        uint256 positionAmount;
        bool isBuy; // From taker's perspective.
        bytes32 traderFlags;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/SafeMath.sol";
import "../utils/Ownable.sol";
import "../utils/IERC20.sol";
import "../utils/SafeERC20.sol";
import "../utils/BaseMath.sol";
import "../utils/SignedMath.sol";
import "../intf/I_DxlnPerpetualV1.sol";
import "../lib/DxlnBalanceMath.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice Proxy contract for liquidating accounts. A fixed percentage of each liquidation is
 * directed to the insurance fund.
 */
contract DxlnLiquidatorProxy is Ownable {
    using BaseMath for uint256;
    using SafeMath for uint256;
    using SignedMath for SignedMath.Int;
    using DxlnBalanceMath for DxlnTypes.Balance;
    using SafeERC20 for IERC20;

    // ============ Events ============

    event LogLiquidatorProxyUsed(
        address indexed liquidatee,
        address indexed liquidator,
        bool isBuy,
        uint256 liquidationAmount,
        uint256 feeAmount
    );

    event LogInsuranceFundSet(address insuranceFund);

    event LogInsuranceFeeSet(uint256 insuranceFee);

    // ============ Immutable Storage ============

    // Address of the perpetual contract.
    address public _PERPETUAL_V1_;

    // Address of the P1Liquidation contract.
    address public _LIQUIDATION_;

    // ============ Mutable Storage ============

    // Address of the insurance fund.
    address public _INSURANCE_FUND_;

    // Proportion of liquidation profits that is directed to the insurance fund.
    // This number is represented as a fixed-point number with 18 decimals.
    uint256 public _INSURANCE_FEE_;

    // ============ Constructor ============

    constructor(
        address perpetualV1,
        address liquidator,
        address insuranceFund,
        uint256 insuranceFee
    ) {
        _PERPETUAL_V1_ = perpetualV1;
        _LIQUIDATION_ = liquidator;
        _INSURANCE_FUND_ = insuranceFund;
        _INSURANCE_FEE_ = insuranceFee;

        emit LogInsuranceFundSet(insuranceFund);
        emit LogInsuranceFeeSet(insuranceFee);
    }

    // ============ External Functions ============

    /**
     * @notice Sets the maximum allowance on the perpetual contract. Must be called at least once.
     * @dev Cannot be run in the constructor due to technical restrictions in Solidity.
     */
    function approveMaximumOnPerpetual() external {
        address perpetual = _PERPETUAL_V1_;
        IERC20 tokenContract = IERC20(
            I_DxlnPerpetualV1(perpetual).getTokenContract()
        );

        // safeApprove requires unsetting the allowance first.
        tokenContract.safeApprove(perpetual, 0);

        // Set the allowance to the highest possible value.
        tokenContract.safeApprove(perpetual, type(uint256).max);
    }

    /**
     * @notice Allows an account below the minimum collateralization to be liquidated by another
     *  account. This allows the account to be partially or fully subsumed by the liquidator.
     *  A proportion of all liquidation profits is directed to the insurance fund.
     * @dev Emits the LogLiquidatorProxyUsed event.
     *
     * @param  liquidatee   The account to liquidate.
     * @param  liquidator   The account that performs the liquidation.
     * @param  isBuy        True if the liquidatee has a long position, false otherwise.
     * @param  maxPosition  Maximum position size that the liquidator will take post-liquidation.
     * @return              The change in position.
     */
    function liquidate(
        address liquidatee,
        address liquidator,
        bool isBuy,
        SignedMath.Int calldata maxPosition
    ) external returns (uint256) {
        I_DxlnPerpetualV1 perpetual = I_DxlnPerpetualV1(_PERPETUAL_V1_);

        // Verify that this account can liquidate for the liquidator.
        require(
            liquidator == msg.sender ||
                perpetual.hasAccountPermissions(liquidator, msg.sender),
            "msg.sender cannot operate the liquidator account"
        );

        // Settle the liquidator's account and get balances.
        perpetual.deposit(liquidator, 0);
        DxlnTypes.Balance memory initialBalance = perpetual.getAccountBalance(
            liquidator
        );

        // Get the maximum liquidatable amount.
        SignedMath.Int memory maxPositionDelta = _getMaxPositionDelta(
            initialBalance,
            isBuy,
            maxPosition
        );

        // Do the liquidation.
        _doLiquidation(perpetual, liquidatee, liquidator, maxPositionDelta);

        // Get the balances of the liquidator.
        DxlnTypes.Balance memory currentBalance = perpetual.getAccountBalance(
            liquidator
        );

        // Get the liquidated amount and fee amount.
        (uint256 liqAmount, uint256 feeAmount) = _getLiquidatedAndFeeAmount(
            perpetual,
            initialBalance,
            currentBalance
        );

        // Transfer fee from liquidator to insurance fund.
        if (feeAmount > 0) {
            perpetual.withdraw(liquidator, address(this), feeAmount);
            perpetual.deposit(_INSURANCE_FUND_, feeAmount);
        }

        // Log the result.
        emit LogLiquidatorProxyUsed(
            liquidatee,
            liquidator,
            isBuy,
            liqAmount,
            feeAmount
        );

        return liqAmount;
    }

    // ============ Admin Functions ============

    /**
     * @dev Allows the owner to set the insurance fund address. Emits the LogInsuranceFundSet event.
     *
     * @param  insuranceFund  The address to set as the insurance fund.
     */
    function setInsuranceFund(address insuranceFund) external onlyOwner {
        _INSURANCE_FUND_ = insuranceFund;
        emit LogInsuranceFundSet(insuranceFund);
    }

    /**
     * @dev Allows the owner to set the insurance fee. Emits the LogInsuranceFeeSet event.
     *
     * @param  insuranceFee  The new fee as a fixed-point number with 18 decimal places. Max of 50%.
     */
    function setInsuranceFee(uint256 insuranceFee) external onlyOwner {
        require(
            insuranceFee <= BaseMath.base().div(2),
            "insuranceFee cannot be greater than 50%"
        );
        _INSURANCE_FEE_ = insuranceFee;
        emit LogInsuranceFeeSet(insuranceFee);
    }

    // ============ Helper Functions ============

    /**
     * @dev Calculate (and verify) the maximum amount to liquidate based on the maxPosition input.
     */
    function _getMaxPositionDelta(
        DxlnTypes.Balance memory initialBalance,
        bool isBuy,
        SignedMath.Int memory maxPosition
    ) private pure returns (SignedMath.Int memory) {
        SignedMath.Int memory result = maxPosition.signedSub(
            initialBalance.getPosition()
        );

        require(
            result.isPositive == isBuy && result.value > 0,
            "Cannot liquidate if it would put liquidator past the specified maxPosition"
        );

        return result;
    }

    /**
     * @dev Perform the liquidation by constructing the correct arguments and sending it to the
     * perpetual.
     */
    function _doLiquidation(
        I_DxlnPerpetualV1 perpetual,
        address liquidatee,
        address liquidator,
        SignedMath.Int memory maxPositionDelta
    ) private {
        // Create accounts. Base protocol requires accounts to be sorted.
        bool takerFirst = liquidator < liquidatee;
        address[] memory accounts = new address[](2);
        uint256 takerIndex = takerFirst ? 0 : 1;
        uint256 makerIndex = takerFirst ? 1 : 0;
        accounts[takerIndex] = liquidator;
        accounts[makerIndex] = liquidatee;

        // Create trade args.
        I_DxlnPerpetualV1.TradeArg[] memory trades = new I_DxlnPerpetualV1.TradeArg[](
            1
        );
        trades[0] = I_DxlnPerpetualV1.TradeArg({
            takerIndex: takerIndex,
            makerIndex: makerIndex,
            trader: _LIQUIDATION_,
            data: abi.encode(
                maxPositionDelta.value,
                maxPositionDelta.isPositive,
                false // allOrNothing
            )
        });

        // Do the liquidation.
        perpetual.trade(accounts, trades);
    }

    /**
     * @dev Calculate the liquidated amount and also the fee amount based on a percentage of the
     * value of the repaid debt.
     * @return  The position amount bought or sold.
     * @return  The fee amount in margin token.
     */
    function _getLiquidatedAndFeeAmount(
        I_DxlnPerpetualV1 perpetual,
        DxlnTypes.Balance memory initialBalance,
        DxlnTypes.Balance memory currentBalance
    ) private view returns (uint256, uint256) {
        // Get the change in the position and margin of the liquidator.
        SignedMath.Int memory deltaPosition = currentBalance
            .getPosition()
            .signedSub(initialBalance.getPosition());
        SignedMath.Int memory deltaMargin = currentBalance
            .getMargin()
            .signedSub(initialBalance.getMargin());

        // Get the change in the balances of the liquidator.
        DxlnTypes.Balance memory deltaBalance;
        deltaBalance.setPosition(deltaPosition);
        deltaBalance.setMargin(deltaMargin);

        // Get the positive and negative value taken by the liquidator.
        uint256 price = perpetual.getOraclePrice();
        (uint256 posValue, uint256 negValue) = deltaBalance
            .getPositiveAndNegativeValue(price);

        // Calculate the fee amount based on the liquidation profit.
        uint256 feeAmount = posValue > negValue
            ? posValue.sub(negValue).baseMul(_INSURANCE_FEE_).div(
                BaseMath.base()
            )
            : 0;

        return (deltaPosition.value, feeAmount);
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
pragma abicoder v2;
import "./SafeMath.sol";

/**
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision.
 */
library BaseMath {
    using SafeMath for uint256;

    // The number One in the BaseMath system.
    uint256 internal constant BASE = 10**18;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function base() internal pure returns (uint256) {
        return BASE;
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded down).
     */
    function baseMul(uint256 value, uint256 baseValue)
        internal
        pure
        returns (uint256)
    {
        return value.mul(baseValue).div(BASE);
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded down).
     *  Intended as an alternaltive to baseMul to prevent overflow, when `value` is known
     *  to be divisible by `BASE`.
     */
    function baseDivMul(uint256 value, uint256 baseValue)
        internal
        pure
        returns (uint256)
    {
        return value.div(BASE).mul(baseValue);
    }

    /**
     * @dev Multiplies a value by a base value (result is rounded up).
     */
    function baseMulRoundUp(uint256 value, uint256 baseValue)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || baseValue == 0) {
            return 0;
        }
        return value.mul(baseValue).sub(1).div(BASE).add(1);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Library for casting uint256 to other types of uint.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint128).
     *
     *  Counterpart to Solidity's `uint128` operator.
     *
     *  Requirements:
     *  - `value` must fit into 128 bits.
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint120).
     *
     *  Counterpart to Solidity's `uint120` operator.
     *
     *  Requirements:
     *  - `value` must fit into 120 bits.
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value < 2**120, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     *  overflow (i.e. when the input is greater than largest uint32).
     *
     *  Counterpart to Solidity's `uint32` operator.
     *
     *  Requirements:
     *  - `value` must fit into 32 bits.
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
pragma abicoder v2;

import "./SafeMath.sol";

/**
 * @dev SignedMath library for doing math with signed integers.
 */
 
library SignedMath {
    using SafeMath for uint256;

    // ============ Structs ============

    struct Int {
        uint256 value;
        bool isPositive;
    }

    // ============ Functions ============

    /**
     * @dev Returns a new signed integer equal to a signed integer plus an unsigned integer.
     */
    function add(Int memory sint, uint256 value)
        internal
        pure
        returns (Int memory)
    {
        if (sint.isPositive) {
            return Int({value: value.add(sint.value), isPositive: true});
        }
        if (sint.value < value) {
            return Int({value: value.sub(sint.value), isPositive: true});
        }
        return Int({value: sint.value.sub(value), isPositive: false});
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer minus an unsigned integer.
     */
    function sub(Int memory sint, uint256 value)
        internal
        pure
        returns (Int memory)
    {
        if (!sint.isPositive) {
            return Int({value: value.add(sint.value), isPositive: false});
        }
        if (sint.value > value) {
            return Int({value: sint.value.sub(value), isPositive: true});
        }
        return Int({value: value.sub(sint.value), isPositive: false});
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer plus another signed integer.
     */
    function signedAdd(Int memory augend, Int memory addend)
        internal
        pure
        returns (Int memory)
    {
        return
            addend.isPositive
                ? add(augend, addend.value)
                : sub(augend, addend.value);
    }

    /**
     * @dev Returns a new signed integer equal to a signed integer minus another signed integer.
     */
    function signedSub(Int memory minuend, Int memory subtrahend)
        internal
        pure
        returns (Int memory)
    {
        return
            subtrahend.isPositive
                ? sub(minuend, subtrahend.value)
                : add(minuend, subtrahend.value);
    }

    /**
     * @dev Returns true if signed integer `a` is greater than signed integer `b`, false otherwise.
     */
    function gt(Int memory a, Int memory b) internal pure returns (bool) {
        if (a.isPositive) {
            if (b.isPositive) {
                return a.value > b.value;
            } else {
                // True, unless both values are zero.
                return a.value != 0 || b.value != 0;
            }
        } else {
            if (b.isPositive) {
                return false;
            } else {
                return a.value < b.value;
            }
        }
    }

    /**
     * @dev Returns the minimum of signed integers `a` and `b`.
     */
    function min(Int memory a, Int memory b)
        internal
        pure
        returns (Int memory)
    {
        return gt(b, a) ? a : b;
    }

    /**
     * @dev Returns the maximum of signed integers `a` and `b`.
     */
    function max(Int memory a, Int memory b)
        internal
        pure
        returns (Int memory)
    {
        return gt(a, b) ? a : b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}