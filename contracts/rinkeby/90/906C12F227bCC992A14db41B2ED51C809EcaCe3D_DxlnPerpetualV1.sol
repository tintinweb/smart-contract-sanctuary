// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./DxlnStorage.sol";
import "./DxlnFinalSettlement.sol";
import "../intf/I_DxlnOracle.sol";
import "../intf/I_DxlnFunder.sol";
import "../lib/DxlnTypes.sol";
import "../utils/BaseMath.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Adminable.sol";

/**
 * @notice Contract allowing the Admin address to set certain parameters.
 */
contract DxlnAdmin is DxlnStorage, DxlnFinalSettlement {
    // ============ Events ============

    event LogSetGlobalOperator(address operator, bool approved);

    event LogSetOracle(address oracle);

    event LogSetFunder(address funder);

    event LogSetMinCollateral(uint256 minCollateral);

    event LogFinalSettlementEnabled(uint256 settlementPrice);

    // ============ Functions ============

    /**
     * @notice Add or remove a Global Operator address.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetGlobalOperator event.
     *
     * @param  operator  The address for which to enable or disable global operator privileges.
     * @param  approved  True if approved, false if disapproved.
     */
    function setGlobalOperator(address operator, bool approved)
        external
        onlyAdmin
        nonReentrant
    {
        _GLOBAL_OPERATORS_[operator] = approved;
        emit LogSetGlobalOperator(operator, approved);
    }

    /**
     * @notice Sets a new price oracle contract.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetOracle event.
     *
     * @param  oracle  The address of the new price oracle contract.
     */
    function setOracle(address oracle) external onlyAdmin nonReentrant {
        require(
            I_DxlnOracle(oracle).getPrice() != 0,
            "New oracle cannot return a zero price"
        );
        _ORACLE_ = oracle;
        emit LogSetOracle(oracle);
    }

    /**
     * @notice Sets a new funder contract.
     * @dev Must be called by the DexilonV1 admin. Emits the LogSetFunder event.
     *
     * @param  funder  The address of the new funder contract.
     */
    function setFunder(address funder) external onlyAdmin nonReentrant {
        // call getFunding to ensure that no reverts occur
        I_DxlnFunder(funder).getFunding(0);

        _FUNDER_ = funder;
        emit LogSetFunder(funder);
    }

    /**
     * @notice Sets a new value for the minimum collateralization percentage.
     * @dev Must be called by the PerpetualV1 admin. Emits the LogSetMinCollateral event.
     *
     * @param  minCollateral  The new value of the minimum initial collateralization percentage,
     *                        as a fixed-point number with 18 decimals.
     */
    function setMinCollateral(uint256 minCollateral)
        external
        onlyAdmin
        nonReentrant
    {
        require(
            minCollateral >= BaseMath.base(),
            "The collateral requirement cannot be under 100%"
        );
        _MIN_COLLATERAL_ = minCollateral;
        emit LogSetMinCollateral(minCollateral);
    }

    /**
     * @notice Enables final settlement if the oracle price is between the provided bounds.
     * @dev Must be called by the PerpetualV1 admin. The current result of the price oracle
     *  must be between the two bounds supplied. Emits the LogFinalSettlementEnabled event.
     *
     * @param  priceLowerBound  The lower-bound (inclusive) of the acceptable price range.
     * @param  priceUpperBound  The upper-bound (inclusive) of the acceptable price range.
     */
    function enableFinalSettlement(
        uint256 priceLowerBound,
        uint256 priceUpperBound
    ) external onlyAdmin noFinalSettlement nonReentrant {
        // Update the Global Index and grab the Price.
        DxlnTypes.Context memory context = _loadContext();

        // Check price bounds.
        require(
            context.price >= priceLowerBound,
            "Oracle price is less than the provided lower bound"
        );
        require(
            context.price <= priceUpperBound,
            "Oracle price is greater than the provided upper bound"
        );

        // Save storage variables.
        _FINAL_SETTLEMENT_PRICE_ = context.price;
        _FINAL_SETTLEMENT_ENABLED_ = true;

        emit LogFinalSettlementEnabled(_FINAL_SETTLEMENT_PRICE_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/Math.sol";
import "../utils/SafeMath.sol";
import "../utils/IERC20.sol";
import "../utils/SafeERC20.sol";
import "../utils/BaseMath.sol";
import "../lib/DxlnBalanceMath.sol";
import "../lib/DxlnTypes.sol";
import "./DxlnSettlement.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/SafeCast.sol";

/**
 * @notice Functions regulating the smart contract's behavior during final settlement.
 */

contract DxlnFinalSettlement is DxlnSettlement {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using DxlnBalanceMath for DxlnTypes.Balance;

    // ============ Events ============

    event LogWithdrawFinalSettlement(
        address indexed account,
        uint256 amount,
        bytes32 balance
    );

    // ============ Modifiers ============

    /**
     * @dev Modifier to ensure the function is not run after final settlement has been enabled.
     */

    modifier noFinalSettlement() {
        require(
            !_FINAL_SETTLEMENT_ENABLED_,
            "Not permitted during final settlement"
        );
        _;
    }

    /**
     * @dev Modifier to ensure the function is only run after final settlement has been enabled.
     */
    modifier onlyFinalSettlement() {
        require(
            _FINAL_SETTLEMENT_ENABLED_,
            "Only permitted during final settlement"
        );
        _;
    }

    // ============ Functions ============

    /**
     * @notice Withdraw the number of margin tokens equal to the value of the account at the time
     *  that final settlement occurred.
     * @dev Emits the LogAccountSettled and LogWithdrawFinalSettlement events.
     */
    function withdrawFinalSettlement()
        external
        onlyFinalSettlement
        nonReentrant
    {
        // Load the context using the final settlement price.
        DxlnTypes.Context memory context = DxlnTypes.Context({
            price: _FINAL_SETTLEMENT_PRICE_,
            minCollateral: _MIN_COLLATERAL_,
            index: _GLOBAL_INDEX_
        });

        // Apply funding changes.
        DxlnTypes.Balance memory balance = _settleAccount(context, msg.sender);

        // Determine the account net value.
        // `positive` and `negative` are base values with extra precision.
        (uint256 positive, uint256 negative) = DxlnBalanceMath
            .getPositiveAndNegativeValue(balance, context.price);

        // No amount is withdrawable.
        if (positive < negative) {
            return;
        }

        // Get the account value, which is rounded down to the nearest token amount.
        uint256 accountValue = positive.sub(negative).div(BaseMath.base());

        // Get the number of tokens in the Perpetual Contract.
        uint256 contractBalance = IERC20(_TOKEN_).balanceOf(address(this));

        // Determine the maximum withdrawable amount.
        uint256 amountToWithdraw = Math.min(contractBalance, accountValue);

        // Update the user's balance.
        uint120 remainingMargin = accountValue
            .sub(amountToWithdraw)
            .toUint120();
        balance = DxlnTypes.Balance({
            marginIsPositive: remainingMargin != 0,
            positionIsPositive: false,
            margin: remainingMargin,
            position: 0
        });
        _BALANCES_[msg.sender] = balance;

        // Send the tokens.
        SafeERC20.safeTransfer(IERC20(_TOKEN_), msg.sender, amountToWithdraw);

        // Emit the log.
        emit LogWithdrawFinalSettlement(
            msg.sender,
            amountToWithdraw,
            balance.toBytes32()
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./DxlnStorage.sol";
import "../intf/I_DxlnOracle.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice Contract for read-only getters.
 */
contract DxlnGetters is DxlnStorage {
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
        returns (DxlnTypes.Balance memory)
    {
        return _BALANCES_[account];
    }

    /**
     * @notice Gets the most recently cached index of an account.
     *
     * @param  account  The address of the account to query the index of.
     * @return          The index of the account.
     */
    function getAccountIndex(address account)
        external
        view
        returns (DxlnTypes.Index memory)
    {
        return _LOCAL_INDEXES_[account];
    }

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
        returns (bool)
    {
        return _LOCAL_OPERATORS_[account][operator];
    }

    // ============ Global Getters ============

    /**
     * @notice Gets the global operator status of an address.
     *
     * @param  operator  The address of the operator to query the status of.
     * @return           True if the address is a global operator, false otherwise.
     */
    function getIsGlobalOperator(address operator)
        external
        view
        returns (bool)
    {
        return _GLOBAL_OPERATORS_[operator];
    }

    /**
     * @notice Gets the address of the ERC20 margin contract used for margin deposits.
     *
     * @return The address of the ERC20 token.
     */
    function getTokenContract() external view returns (address) {
        return _TOKEN_;
    }

    /**
     * @notice Gets the current address of the price oracle contract.
     *
     * @return The address of the price oracle contract.
     */
    function getOracleContract() external view returns (address) {
        return _ORACLE_;
    }

    /**
     * @notice Gets the current address of the funder contract.
     *
     * @return The address of the funder contract.
     */
    function getFunderContract() external view returns (address) {
        return _FUNDER_;
    }

    /**
     * @notice Gets the most recently cached global index.
     *
     * @return The most recently cached global index.
     */
    function getGlobalIndex() external view returns (DxlnTypes.Index memory) {
        return _GLOBAL_INDEX_;
    }

    /**
     * @notice Gets minimum collateralization ratio of the protocol.
     *
     * @return The minimum-acceptable collateralization ratio, returned as a fixed-point number with
     *  18 decimals of precision.
     */
    function getMinCollateral() external view returns (uint256) {
        return _MIN_COLLATERAL_;
    }

    /**
     * @notice Gets the status of whether final-settlement was initiated by the Admin.
     *
     * @return True if final-settlement was enabled, false otherwise.
     */
    function getFinalSettlementEnabled() external view returns (bool) {
        return _FINAL_SETTLEMENT_ENABLED_;
    }

    // ============ Authorized External Getters ============

    /**
     * @notice Gets the price returned by the oracle.
     * @dev Only able to be called by global operators.
     *
     * @return The price returned by the current price oracle.
     */
    function getOraclePrice() external view returns (uint256) {
        require(
            _GLOBAL_OPERATORS_[msg.sender],
            "Oracle price requester not global operator"
        );
        return I_DxlnOracle(_ORACLE_).getPrice();
    }

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
        public
        view
        returns (bool)
    {
        return
            account == operator ||
            _GLOBAL_OPERATORS_[operator] ||
            _LOCAL_OPERATORS_[account][operator];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/IERC20.sol";
import "../utils/SafeERC20.sol";
import "../lib/DxlnBalanceMath.sol";
import "../lib/DxlnTypes.sol";
import "./DxlnFinalSettlement.sol";
import "./DxlnGetters.sol";
import "../utils/ReentrancyGuard.sol";

/**
 * @notice Contract for withdrawing and depositing.
 */
contract DxlnMargin is DxlnFinalSettlement, DxlnGetters {
    using DxlnBalanceMath for DxlnTypes.Balance;

    // ============ Events ============

    event LogDeposit(address indexed account, uint256 amount, bytes32 balance);

    event LogWithdraw(
        address indexed account,
        address destination,
        uint256 amount,
        bytes32 balance
    );

    // ============ Functions ============

    /**
     * @notice Deposit some amount of margin tokens from the msg.sender into an account.
     * @dev Emits LogIndex, LogAccountSettled, and LogDeposit events.
     *
     * @param  account  The account for which to credit the deposit.
     * @param  amount   the amount of tokens to deposit.
     */
    function deposit(address account, uint256 amount)
        external
        noFinalSettlement
        nonReentrant
    {
        DxlnTypes.Context memory context = _loadContext();
        DxlnTypes.Balance memory balance = _settleAccount(context, account);

        SafeERC20.safeTransferFrom(
            IERC20(_TOKEN_),
            msg.sender,
            address(this),
            amount
        );

        balance.addToMargin(amount);
        _BALANCES_[account] = balance;

        emit LogDeposit(account, amount, balance.toBytes32());
    }

    /**
     * @notice Withdraw some amount of margin tokens from an account to a destination address.
     * @dev Emits LogIndex, LogAccountSettled, and LogWithdraw events.
     *
     * @param  account      The account for which to debit the withdrawal.
     * @param  destination  The address to which the tokens are transferred.
     * @param  amount       The amount of tokens to withdraw.
     */
    function withdraw(
        address account,
        address destination,
        uint256 amount
    ) external noFinalSettlement nonReentrant {
        require(
            hasAccountPermissions(account, msg.sender),
            "sender does not have permission to withdraw"
        );

        DxlnTypes.Context memory context = _loadContext();
        DxlnTypes.Balance memory balance = _settleAccount(context, account);

        SafeERC20.safeTransfer(IERC20(_TOKEN_), destination, amount);

        balance.subFromMargin(amount);
        _BALANCES_[account] = balance;

        require(
            _isCollateralized(context, balance),
            "account not collateralized"
        );

        emit LogWithdraw(account, destination, amount, balance.toBytes32());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./DxlnStorage.sol";

/**
 * @notice Contract for setting local operators for an account.
 */
contract DxlnOperator is DxlnStorage {
    // ============ Events ============

    event LogSetLocalOperator(
        address indexed sender,
        address operator,
        bool approved
    );

    // ============ Functions ============

    /**
     * @notice Grants or revokes permission for another account to perform certain actions on behalf
     *  of the sender.
     * @dev Emits the LogSetLocalOperator event.
     *
     * @param  operator  The account that is approved or disapproved.
     * @param  approved  True for approval, false for disapproval.
     */
    function setLocalOperator(address operator, bool approved) external {
        _LOCAL_OPERATORS_[msg.sender][operator] = approved;
        emit LogSetLocalOperator(msg.sender, operator, approved);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/Storage.sol";
import "./DxlnAdmin.sol";
import "./DxlnFinalSettlement.sol";
import "./DxlnGetters.sol";
import "./DxlnMargin.sol";
import "./DxlnOperator.sol";
import "./DxlnTrade.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice A market for a perpetual contract, a financial derivative which may be traded on margin
 *  and which aims to closely track the spot price of an underlying asset. The underlying asset is
 *  specified via the price oracle which reports its spot price. Tethering of the perpetual market
 *  price is supported by a funding oracle which governs funding payments between longs and shorts.
 * @dev Main perpetual market implementation contract that inherits from other contracts.
 */
contract DxlnPerpetualV1 is
    DxlnFinalSettlement,
    DxlnAdmin,
    DxlnGetters,
    DxlnMargin,
    DxlnOperator,
    DxlnTrade
{
    // Non-colliding storage slot.
    bytes32 internal constant DXLN_PERPETUAL_V1_INITIALIZE_SLOT =
        bytes32(uint256(keccak256("Dxln.PerpetualV1.initialize")) - 1);

    /**
     * @dev Once-only initializer function that replaces the constructor since this contract is
     *  proxied. Uses a non-colliding storage slot to store if this version has been initialized.
     * @dev Can only be called once and can only be called by the admin of this contract.
     *
     * @param  token          The address of the token to use for margin-deposits.
     * @param  oracle         The address of the price oracle contract.
     * @param  funder         The address of the funder contract.
     * @param  minCollateral  The minimum allowed initial collateralization percentage.
     */
    function initializeV1(
        address token,
        address oracle,
        address funder,
        uint256 minCollateral
    ) external onlyAdmin nonReentrant {
        // only allow initialization once
        require(
            Storage.load(DXLN_PERPETUAL_V1_INITIALIZE_SLOT) == 0x0,
            "DxlnPerpetualV1 already initialized"
        );
        Storage.store(DXLN_PERPETUAL_V1_INITIALIZE_SLOT, bytes32(uint256(1)));

        _TOKEN_ = token;
        _ORACLE_ = oracle;
        _FUNDER_ = funder;
        _MIN_COLLATERAL_ = minCollateral;

        _GLOBAL_INDEX_ = DxlnTypes.Index({
            timestamp: uint32(block.timestamp),
            isPositive: false,
            value: 0
        });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./DxlnStorage.sol";
import "../utils/BaseMath.sol";
import "../utils/SafeCast.sol";
import "../lib/DxlnTypes.sol";
import "../lib/DxlnBalanceMath.sol";
import "../lib/DxlnIndexMath.sol";
import "../utils/SignedMath.sol";
import "../intf/I_DxlnOracle.sol";
import "../intf/I_DxlnFunder.sol";

/**
 * @notice Contract containing logic for settling funding payments between accounts.
 */

contract DxlnSettlement is DxlnStorage {
    using BaseMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using DxlnBalanceMath for DxlnTypes.Balance;
    using DxlnIndexMath for DxlnTypes.Index;
    using SignedMath for SignedMath.Int;

    // ============ Events ============

    event LogIndex(bytes32 index);

    event LogAccountSettled(
        address indexed account,
        bool isPositive,
        uint256 amount,
        bytes32 balance
    );

    // ============ Functions ============

    /**
     * @dev Calculates the funding change since the last update and stores it in the Global Index.
     *
     * @return Context struct that containing:
     *         - The current oracle price;
     *         - The global index;
     *         - The minimum required collateralization.
     */
    function _loadContext() internal returns (DxlnTypes.Context memory) {
        // SLOAD old index
        DxlnTypes.Index memory index = _GLOBAL_INDEX_;

        // get Price (P)
        uint256 price = I_DxlnOracle(_ORACLE_).getPrice();

        // get Funding (F)
        uint256 timeDelta = block.timestamp.sub(index.timestamp);
        if (timeDelta > 0) {
            // turn the current index into a signed integer
            SignedMath.Int memory signedIndex = SignedMath.Int({
                value: index.value,
                isPositive: index.isPositive
            });

            // Get the funding rate, applied over the time delta.
            (bool fundingPositive, uint256 fundingValue) = I_DxlnFunder(
                _FUNDER_
            ).getFunding(timeDelta);
            fundingValue = fundingValue.baseMul(price);

            // Update the index according to the funding rate, applied over the time delta.
            if (fundingPositive) {
                signedIndex = signedIndex.add(fundingValue);
            } else {
                signedIndex = signedIndex.sub(fundingValue);
            }

            // store new index
            index = DxlnTypes.Index({
                timestamp: block.timestamp.toUint32(),
                isPositive: signedIndex.isPositive,
                value: signedIndex.value.toUint128()
            });
            _GLOBAL_INDEX_ = index;
        }

        emit LogIndex(index.toBytes32());

        return
            DxlnTypes.Context({
                price: price,
                minCollateral: _MIN_COLLATERAL_,
                index: index
            });
    }

    /**
     * @dev Settle the funding payments for a list of accounts and return their resulting balances.
     */
    function _settleAccounts(
        DxlnTypes.Context memory context,
        address[] memory accounts
    ) internal returns (DxlnTypes.Balance[] memory) {
        uint256 numAccounts = accounts.length;
        DxlnTypes.Balance[] memory result = new DxlnTypes.Balance[](
            numAccounts
        );

        for (uint256 i = 0; i < numAccounts; i++) {
            result[i] = _settleAccount(context, accounts[i]);
        }

        return result;
    }

    /**
     * @dev Settle the funding payment for a single account and return its resulting balance.
     */
    function _settleAccount(DxlnTypes.Context memory context, address account)
        internal
        returns (DxlnTypes.Balance memory)
    {
        DxlnTypes.Index memory newIndex = context.index;
        DxlnTypes.Index memory oldIndex = _LOCAL_INDEXES_[account];
        DxlnTypes.Balance memory balance = _BALANCES_[account];

        // Don't update the index if no time has passed.
        if (oldIndex.timestamp == newIndex.timestamp) {
            return balance;
        }

        // Store a cached copy of the index for this account.
        _LOCAL_INDEXES_[account] = newIndex;

        // No need for settlement if balance is zero.
        if (balance.position == 0) {
            return balance;
        }

        // Get the difference between the newIndex and oldIndex.
        SignedMath.Int memory signedIndexDiff = SignedMath.Int({
            isPositive: newIndex.isPositive,
            value: newIndex.value
        });
        if (oldIndex.isPositive) {
            signedIndexDiff = signedIndexDiff.sub(oldIndex.value);
        } else {
            signedIndexDiff = signedIndexDiff.add(oldIndex.value);
        }

        // By convention, positive funding (index increases) means longs pay shorts
        // and negative funding (index decreases) means shorts pay longs.
        bool settlementIsPositive = signedIndexDiff.isPositive !=
            balance.positionIsPositive;

        // Settle the account balance by applying the index delta as a credit or debit.
        // The interest amount scales with the position size.
        //
        // We round interest debits up and credits down to ensure that the contract won't become
        // insolvent due to rounding errors.
        uint256 settlementAmount;
        if (settlementIsPositive) {
            settlementAmount = signedIndexDiff.value.baseMul(balance.position);
            balance.addToMargin(settlementAmount);
        } else {
            settlementAmount = signedIndexDiff.value.baseMulRoundUp(
                balance.position
            );
            balance.subFromMargin(settlementAmount);
        }
        _BALANCES_[account] = balance;

        // Log the change to the account balance, which is the negative of the change in the index.
        emit LogAccountSettled(
            account,
            settlementIsPositive,
            settlementAmount,
            balance.toBytes32()
        );

        return balance;
    }

    /**
     * @dev Returns true if the balance is collateralized according to the price and minimum
     * collateralization passed-in through the context.
     */
    function _isCollateralized(
        DxlnTypes.Context memory context,
        DxlnTypes.Balance memory balance
    ) internal pure returns (bool) {
        (uint256 positive, uint256 negative) = balance
            .getPositiveAndNegativeValue(context.price);

        // Overflow risk assessment:
        // 2^256 / 10^36 is significantly greater than 2^120 and this calculation is therefore not
        // expected to be a limiting factor on the size of accounts that this contract can handle.
        return
            positive.mul(BaseMath.base()) >=
            negative.mul(context.minCollateral);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/Adminable.sol";
import "../lib/DxlnTypes.sol";
import "../utils/ReentrancyGuard.sol";
import "../lib/DxlnTypes.sol";

/**
 * @notice Storage contract. Contains or inherits from all contracts that have ordered storage.
 */
contract DxlnStorage is Adminable, ReentrancyGuard {
    mapping(address => DxlnTypes.Balance) internal _BALANCES_;
    mapping(address => DxlnTypes.Index) internal _LOCAL_INDEXES_;

    mapping(address => bool) internal _GLOBAL_OPERATORS_;
    mapping(address => mapping(address => bool)) internal _LOCAL_OPERATORS_;

    address internal _TOKEN_;
    address internal _ORACLE_;
    address internal _FUNDER_;

    DxlnTypes.Index internal _GLOBAL_INDEX_;
    uint256 internal _MIN_COLLATERAL_;

    bool internal _FINAL_SETTLEMENT_ENABLED_;
    uint256 internal _FINAL_SETTLEMENT_PRICE_;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/SafeMath.sol";
import "../impl/DxlnFinalSettlement.sol";
import "../utils/BaseMath.sol";
import "../utils/Require.sol";
import "../intf/I_DxlnTrader.sol";
import "../lib/DxlnBalanceMath.sol";
import "../lib/DxlnTypes.sol";
import "../utils/ReentrancyGuard.sol";

/**
 * @notice Contract for settling trades between two accounts. A "trade" in this context may refer
 *  to any approved transfer of balances, as determined by the smart contracts implementing the
 *  I_DxlnTrader interface and approved as global operators on the PerpetualV1 contract.
 */

contract DxlnTrade is DxlnFinalSettlement {
    using SafeMath for uint120;
    using SafeMath for uint256;
    using BaseMath for uint256;
    using DxlnBalanceMath for DxlnTypes.Balance;

    // ============ Structs ============

    struct TradeArg {
        uint256 takerIndex;
        uint256 makerIndex;
        address trader;
        bytes data;
    }

    // ============ Events ============

    event LogTrade(
        address indexed maker,
        address indexed taker,
        address trader,
        uint256 marginAmount,
        uint256 positionAmount,
        bool isBuy, // from taker's perspective
        bytes32 makerBalance,
        bytes32 takerBalance
    );

    // ============ Functions ============

    /**
     * @notice Submits one or more trades between any number of accounts.
     * @dev Emits the LogIndex event, one LogAccountSettled event for each account in `accounts`,
     *  and the LogTrade event for each trade in `trades`.
     *
     * @param  accounts  The sorted list of accounts that are involved in trades.
     * @param  trades    The list of trades to execute in-order.
     */
    function trade(address[] memory accounts, TradeArg[] memory trades)
        public
        noFinalSettlement
        nonReentrant
    {
        _verifyAccounts(accounts);
        DxlnTypes.Context memory context = _loadContext();
        DxlnTypes.Balance[] memory initialBalances = _settleAccounts(
            context,
            accounts
        );
        DxlnTypes.Balance[] memory currentBalances = new DxlnTypes.Balance[](
            initialBalances.length
        );

        uint256 i;
        for (i = 0; i < initialBalances.length; i++) {
            currentBalances[i] = initialBalances[i].copy();
        }

        bytes32 traderFlags = 0;
        for (i = 0; i < trades.length; i++) {
            TradeArg memory tradeArg = trades[i];

            require(
                _GLOBAL_OPERATORS_[tradeArg.trader],
                "trader is not global operator"
            );

            address maker = accounts[tradeArg.makerIndex];
            address taker = accounts[tradeArg.takerIndex];

            DxlnTypes.TradeResult memory tradeResult = I_DxlnTrader(
                tradeArg.trader
            ).trade(
                    msg.sender,
                    maker,
                    taker,
                    context.price,
                    tradeArg.data,
                    traderFlags
                );

            traderFlags |= tradeResult.traderFlags;

            // If the accounts are equal, no need to update balances.
            if (maker == taker) {
                continue;
            }

            // Modify currentBalances in-place. Note that `isBuy` is from the taker's perspective.
            DxlnTypes.Balance memory makerBalance = currentBalances[
                tradeArg.makerIndex
            ];
            DxlnTypes.Balance memory takerBalance = currentBalances[
                tradeArg.takerIndex
            ];
            if (tradeResult.isBuy) {
                makerBalance.addToMargin(tradeResult.marginAmount);
                makerBalance.subFromPosition(tradeResult.positionAmount);
                takerBalance.subFromMargin(tradeResult.marginAmount);
                takerBalance.addToPosition(tradeResult.positionAmount);
            } else {
                makerBalance.subFromMargin(tradeResult.marginAmount);
                makerBalance.addToPosition(tradeResult.positionAmount);
                takerBalance.addToMargin(tradeResult.marginAmount);
                takerBalance.subFromPosition(tradeResult.positionAmount);
            }

            // Store the new balances in storage.
            _BALANCES_[maker] = makerBalance;
            _BALANCES_[taker] = takerBalance;

            emit LogTrade(
                maker,
                taker,
                tradeArg.trader,
                tradeResult.marginAmount,
                tradeResult.positionAmount,
                tradeResult.isBuy,
                makerBalance.toBytes32(),
                takerBalance.toBytes32()
            );
        }

        _verifyAccountsFinalBalances(
            context,
            accounts,
            initialBalances,
            currentBalances
        );
    }

    /**
     * @dev Verify that `accounts` contains at least one address and that the contents are unique.
     *  We verify uniqueness by requiring that the array is sorted.
     */
    function _verifyAccounts(address[] memory accounts) private pure {
        require(accounts.length > 0, "Accounts must have non-zero length");

        // Check that accounts are unique
        address prevAccount = accounts[0];
        for (uint256 i = 1; i < accounts.length; i++) {
            address account = accounts[i];
            require(
                account > prevAccount,
                "Accounts must be sorted and unique"
            );
            prevAccount = account;
        }
    }

    /**
     * Verify that account balances at the end of the tx are allowable given the initial balances.
     *
     * We require that for every account, either:
     * 1. The account meets the collateralization requirement; OR
     * 2. All of the following are true:
     *   a) The absolute value of the account position has not increased;
     *   b) The sign of the account position has not flipped positive to negative or vice-versa.
     *   c) The account's collateralization ratio has not worsened;
     */
    function _verifyAccountsFinalBalances(
        DxlnTypes.Context memory context,
        address[] memory accounts,
        DxlnTypes.Balance[] memory initialBalances,
        DxlnTypes.Balance[] memory currentBalances
    ) private pure {
        for (uint256 i = 0; i < accounts.length; i++) {
            DxlnTypes.Balance memory currentBalance = currentBalances[i];
            (uint256 currentPos, uint256 currentNeg) = currentBalance
                .getPositiveAndNegativeValue(context.price);

            // See DxlnSettlement._isCollateralized().
            bool isCollateralized = currentPos.mul(BaseMath.base()) >=
                currentNeg.mul(context.minCollateral);

            if (isCollateralized) {
                continue;
            }

            address account = accounts[i];
            DxlnTypes.Balance memory initialBalance = initialBalances[i];
            (uint256 initialPos, uint256 initialNeg) = initialBalance
                .getPositiveAndNegativeValue(context.price);

            Require.that(
                currentPos != 0,
                "account is undercollateralized and has no positive value",
                account
            );
            Require.that(
                currentBalance.position <= initialBalance.position,
                "account is undercollateralized and absolute position size increased",
                account
            );

            // Note that currentBalance.position can't be zero at this point since that would imply
            // either currentPos is zero or the account is well-collateralized.

            Require.that(
                currentBalance.positionIsPositive ==
                    initialBalance.positionIsPositive,
                "account is undercollateralized and position changed signs",
                account
            );
            Require.that(
                initialNeg != 0,
                "account is undercollateralized and was not previously",
                account
            );

            // Note that at this point:
            //   Absolute position size must have decreased and not changed signs.
            //   Initial margin/position must be one of -/-, -/+, or +/-.
            //   Current margin/position must now be either -/+ or +/-.
            //
            // Which implies one of the following [intial] -> [current] configurations:
            //   [-/-] -> [+/-]
            //   [-/+] -> [-/+]
            //   [+/-] -> [+/-]

            // Check that collateralization increased.
            // In the case of [-/-] initial, initialPos == 0 so the following will pass. Otherwise:
            // at this point, either initialNeg and currentNeg represent the margin values, or
            // initialPos and currentPos do. Since the margin is multiplied by the base value in
            // getPositiveAndNegativeValue(), it is safe to use baseDivMul() to divide the margin
            // without any rounding. This is important to avoid the possibility of overflow.
            Require.that(
                currentBalance.positionIsPositive
                    ? currentNeg.baseDivMul(initialPos) <=
                        initialNeg.baseDivMul(currentPos)
                    : initialPos.baseDivMul(currentNeg) <=
                        currentPos.baseDivMul(initialNeg),
                "account is undercollateralized and collateralization decreased",
                account
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @notice Interface for an oracle providing the funding rate for a perpetual market.
 */
interface I_DxlnFunder {
    /**
     * @notice Calculates the signed funding amount that has accumulated over a period of time.
     *
     * @param  timeDelta  Number of seconds over which to calculate the accumulated funding amount.
     * @return            True if the funding rate is positive, and false otherwise.
     * @return            The funding amount as a unitless rate, represented as a fixed-point number
     *                    with 18 decimals.
     */
    function getFunding(uint256 timeDelta)
        external
        view
        returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @notice Interface that DxlnPerpetualV1 Price Oracles must implement.
 */
interface I_DxlnOracle {
    /**
     * @notice Returns the price of the underlying asset relative to the margin token.
     *
     * @return The price as a fixed-point number with 18 decimals.
     */
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/DxlnTypes.sol";

/**
 * @notice Interface that PerpetualV1 Traders must implement.
 */
interface I_DxlnTrader {
    /**
     * @notice Returns the result of the trade between the maker and the taker. Expected to be
     *  called by PerpetualV1. Reverts if the trade is disallowed.
     *
     * @param  sender       The address that called the `trade()` function of PerpetualV1.
     * @param  maker        The address of the passive maker account.
     * @param  taker        The address of the active taker account.
     * @param  price        The current oracle price of the underlying asset.
     * @param  data         Arbitrary data passed in to the `trade()` function of PerpetualV1.
     * @param  traderFlags  Any flags that have been set by other I_P1Trader contracts during the
     *                      same call to the `trade()` function of PerpetualV1.
     * @return              The result of the trade from the perspective of the taker.
     */
    function trade(
        address sender,
        address maker,
        address taker,
        uint256 price,
        bytes calldata data,
        bytes32 traderFlags
    ) external returns (DxlnTypes.TradeResult memory);
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

import "./DxlnTypes.sol";

/**
 * @dev Library for manipulating DxlnTypes.Index structs.
 */

library DxlnIndexMath {
    // ============ Constants ============

    uint256 private constant FLAG_IS_POSITIVE = 1 << (8 * 16);

    // ============ Functions ============

    /**
     * @dev Returns a compressed bytes32 representation of the index for logging.
     */

    function toBytes32(DxlnTypes.Index memory index)
        internal
        pure
        returns (bytes32)
    {
        uint256 result = index.value |
            (index.isPositive ? FLAG_IS_POSITIVE : 0) |
            (uint256(index.timestamp) << 136);
        return bytes32(result);
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
import "./Storage.sol";

/**
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier to check whether the `msg.sender` is the admin.
     *  If it is, it will run the function. Otherwise, it will revert.
     */
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "Adminable: caller is not admin");
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin() public view returns (address) {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
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
pragma abicoder v2;

import "./SafeMath.sol";

/**
 * @dev Library for non-standard Math functions.
 */

library Math {
    using SafeMath for uint256;

    // ============ Library Functions ============

    /**
     * @dev Return target * (numerator / denominator), rounded down.
     */
    function getFraction(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    /**
     * @dev Return target * (numerator / denominator), rounded up.
     */
    function getFractionRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    /**
     * @dev Returns the minimum between a and b.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the maximum between a and b.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Stringifies parameters to pretty-print revert messages.
 */
library Require {
    // ============ Constants ============

    uint256 constant ASCII_ZERO = 0x30; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 0x57; // 'a' - 10
    uint256 constant FOUR_BIT_MASK = 0xf;
    bytes23 constant ZERO_ADDRESS =
        0x3a20307830303030303030302e2e2e3030303030303030; // ": 0x00000000...00000000"

    // ============ Library Functions ============

    /**
     * @dev If the must condition is not true, reverts using a string combination of the reason and
     *  the address.
     */
    function that(
        bool must,
        string memory reason,
        address addr
    ) internal pure {
        if (!must) {
            revert(string(abi.encodePacked(reason, stringify(addr))));
        }
    }

    // ============ Helper Functions ============

    /**
     * @dev Returns a bytes array that is an ASCII string representation of the input address.
     *  Returns " 0x", the first 4 bytes of the address in lowercase hex, "...", then the last 4
     *  bytes of the address in lowercase hex.
     */
    function stringify(address input) private pure returns (bytes memory) {
        // begin with ": 0x00000000...00000000"
        bytes memory result = abi.encodePacked(ZERO_ADDRESS);

        // initialize values
        uint256 z = uint256(uint160(input));
        uint256 shift1 = 8 * 20 - 4;
        uint256 shift2 = 8 * 4 - 4;

        // populate both sections in parallel
        for (uint256 i = 4; i < 12; i++) {
            result[i] = char(z >> shift1); // set char in first section
            result[i + 11] = char(z >> shift2); // set char in second section
            shift1 -= 4;
            shift2 -= 4;
        }

        return result;
    }

    /**
     * @dev Returns the ASCII hex character representing the last four bits of the input (0-9a-f).
     */
    function char(uint256 input) private pure returns (bytes1) {
        uint256 b = input & FOUR_BIT_MASK;
        return bytes1(uint8(b + ((b < 10) ? ASCII_ZERO : ASCII_RELATIVE_ZERO)));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @dev Storage library for reading/writing storage at a low level.
 */

library Storage {
    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(bytes32 slot) internal view returns (bytes32) {
        bytes32 result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(bytes32 slot, bytes32 value) internal {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

