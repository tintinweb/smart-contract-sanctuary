// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Asset.sol";
import "./BondSubHour.sol";
import "../libraries/IncentiveReporter.sol";

// TODO activate bonds for lending

/// @title Manage lending for a variety of bond issuers
contract Lend is RoleAware, BondSubHour {
    /// mapping issuers to tokens
    /// (in crossmargin, the issuers are tokens  themselves)
    mapping(address => address) public issuerTokens;

    /// In case of shortfall, adjust debt
    mapping(address => uint256) public haircuts;

    /// map of available issuers
    mapping(address => bool) public activeIssuers;

    // used in regBorrow API, to check Insufficient lending amount
    uint256 constant borrowRateDelay = 60 minutes;

    address public immutable MFI;

    constructor(address _MFI, address _roles) RoleAware(_roles) {
        MFI = _MFI;
    }

    /// Make a issuer available for protocol
    function activateIssuer(address issuer) external {
        activateIssuer(issuer, issuer);
    }

    /// Make issuer != token available for protocol (isol. margin)
    function activateIssuer(address issuer, address token)
        public
        onlyOwnerExecActivator
    {
        activeIssuers[issuer] = true;
        issuerTokens[issuer] = token;
    }

    /// Remove a issuer from trading availability
    function deactivateIssuer(address issuer) external onlyOwnerExecActivator {
        activeIssuers[issuer] = false;
    }

    /// Set lending cap
    function setLendingCap(address issuer, uint256 cap)
        external
        onlyOwnerExecActivator
    {
        lendingMeta[issuer].lendingCap = cap;
    }

    /// Set withdrawal delay
    function setWithdrawDelay(uint256 delay) external onlyOwnerExec {
        withdrawDelay = delay;
    }

    function setNormalRate(uint256 rate) external onlyOwnerExec {
        normalRate = rate;
    }

    function setHighRate(uint256 rate) external onlyOwnerExec {
        highRate = rate;
    }

    /// Set hourly yield APR for issuer
    function setHourlyYieldAPR(address issuer, uint256 aprPercent)
        external
        onlyOwnerExecActivator
    {
        YieldAccumulator storage yieldAccumulator =
            hourlyBondYieldAccumulators[issuer];

        if (yieldAccumulator.accumulatorFP == 0) {
            uint256 yieldFP = slot + (slot * aprPercent) / 100 / (24 * 365);
            hourlyBondYieldAccumulators[issuer] = YieldAccumulator({
                accumulatorFP: slot,
                lastUpdated: block.timestamp,
                hourlyYieldFP: yieldFP
            });
        } else {
            YieldAccumulator storage yA = getUpdatedHAPY(issuer, yieldAccumulator, callRateUpdate);
            yA.hourlyYieldFP = (slot * (100 + aprPercent)) / 100 / (24 * 365);
        }
    }

    /// @dev how much interest has accrued to a borrowed balance over time
    function applyBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external returns (uint256 balanceWithInterest, uint256 accumulatorFP) {
        require(isBorrower(msg.sender), "Not approved call");

        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowAPR(yA);
        accumulatorFP = yA.accumulatorFP;

        balanceWithInterest = applyInterest(
            balance,
            accumulatorFP,
            yieldQuotientFP
        );

        uint256 deltaAmount = balanceWithInterest - balance;
        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += deltaAmount;
    }

    /// @dev view function to get balance with borrowing interest applied
    function viewWithBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external view returns (uint256) {
        uint256 accumulatorFP =
            getTotalYield(
                borrowYieldAccumulators[issuer],
                block.timestamp
            );
        return applyInterest(balance, accumulatorFP, yieldQuotientFP);
    }

    /// @dev gets called by router to register if a trader borrows issuers
    function registerBorrow(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += amount;

        getUpdatedHAPY(issuer, hourlyBondYieldAccumulators[issuer], borrowRateDelay);
        require(meta.totalLending >= meta.totalBorrowed, "Insufficient lending");
    }

    /// @dev gets called when external sources provide lending
    function registerLend(address issuer, uint256 amount) external {
        require(isLender(msg.sender), "Not an approved lender");
        require(activeIssuers[issuer], "Not approved issuer");
        LendingMetadata storage meta = lendingMeta[issuer];
        addToTotalLend(meta, amount);

        getUpdatedHAPY(issuer, hourlyBondYieldAccumulators[issuer], callRateUpdate);
    }

    /// @dev gets called when external sources pay withdraw their bobnd
    function registerWithdrawal(address issuer, uint256 amount) external {
        require(isLender(msg.sender), "Not an approved lender");
        require(activeIssuers[issuer], "Not approved issuer");
        LendingMetadata storage meta = lendingMeta[issuer];
        subtractFromTotalLend(meta, amount);

        getUpdatedHAPY(issuer, hourlyBondYieldAccumulators[issuer], callRateUpdate);
    }

    /// @dev gets called by router if loan is extinguished
    function payOff(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        lendingMeta[issuer].totalBorrowed -= amount;
    }

    /// @dev get the borrow yield for a specific issuer/token
    function viewAccumulatedBorrowingYieldFP(address issuer)
        external
        view
        returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        return getTotalYield(yA, block.timestamp);
    }

    function viewAPRPer10k(YieldAccumulator storage yA)
        internal
        view
        returns (uint256)
    {
        uint256 hourlyYieldFP = yA.hourlyYieldFP;

        uint256 aprFP =
            ((hourlyYieldFP * 10_000 - slot * 10_000) * 365 days) / (1 hours);

        return aprFP / slot;
    }

    /// @dev get current borrowing interest per 10k for a token / issuer
    function viewBorrowAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(borrowYieldAccumulators[issuer]);
    }

    /// @dev get current lending APR per 10k for a token / issuer
    function viewHourlyBondAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(hourlyBondYieldAccumulators[issuer]);
    }

    /// @dev In a liquidity crunch make a fallback bond until liquidity is good again
    function makeFallbackBond(
        address issuer,
        address holder,
        uint256 amount
    ) external {
        require(isLender(msg.sender), "Not an approved lender");
        hBond(issuer, holder, amount);
    }

    /// @dev withdraw an hour bond
    function withdrawHourlyBond(address issuer, uint256 amount) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];
        super.removeHBond(issuer, bond, amount, msg.sender);

        if (bond.amount == 0) {
            delete hourlyBondAccounts[issuer][msg.sender];
        }

        disburse(issuer, msg.sender, amount);

        IncentiveReporter.subtractFromClaimAmount(issuer, msg.sender, amount);
    }

    /// Shut down hourly bond account for `issuer`
    function closeHourlyBondAccount(address issuer) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];

        uint256 amount = bond.amount;
        super.removeHBond(issuer, bond, amount, msg.sender);

        disburse(issuer, msg.sender, amount);

        delete hourlyBondAccounts[issuer][msg.sender];

        IncentiveReporter.subtractFromClaimAmount(issuer, msg.sender, amount);
    }

    /// @dev buy hourly bond subscription
    function buyHourlyBondSubscription(address issuer, uint256 amount)
        external
    {
        require(activeIssuers[issuer], "Not approved issuer");

        collectToken(issuer, msg.sender, amount);

        super.hBond(issuer, msg.sender, amount);

        IncentiveReporter.addToClaimAmount(issuer, msg.sender, amount);
    }

    function initBorrowYieldAccumulator(address issuer)
        external
        onlyOwnerExecActivator
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        require(yA.accumulatorFP == 0, "don't re-initialize");

        yA.accumulatorFP = slot;
        yA.lastUpdated = block.timestamp;
        yA.hourlyYieldFP = slot + (slot * borrowMinRate) / 1000 / (365 * 24);
    }

    function setBorrowingFactor(uint256 _borrowingFactor)
        external
        onlyOwnerExec
    {
        borrowingFactor = _borrowingFactor;
    }

    function issuanceBalance(address issuer)
        internal
        view
        override
        returns (uint256)
    {
        address token = issuerTokens[issuer];
        if (token == issuer) {
            // cross margin
            return IERC20(token).balanceOf(asset());
        } else {
            return lendingMeta[issuer].totalLending - haircuts[issuer];
        }
    }

    function disburse(
        address issuer,
        address recipient,
        uint256 amount
    ) internal {
        uint256 haircutAmount = haircuts[issuer];
        if (haircutAmount > 0 && amount > 0) {
            uint256 totalLending = lendingMeta[issuer].totalLending;
            uint256 adjustment =
                (amount * min(totalLending, haircutAmount)) / totalLending;
            amount = amount - adjustment;
            haircuts[issuer] -= adjustment;
        }

        address token = issuerTokens[issuer];
        Asset(asset()).withdraw(token, recipient, amount);
    }

    function collectToken(
        address issuer,
        address source,
        uint256 amount
    ) internal {
        Asset(asset()).depositFor(source, issuerTokens[issuer], amount);
    }

    function haircut(uint256 amount) external {
        haircuts[msg.sender] += amount;
    }

    function addIncentive(
        address token,
        uint256 amount,
        uint256 endTimestamp
    ) external onlyOwnerExecActivator {
        LendingMetadata storage meta = lendingMeta[token];
        meta.incentiveEnd = endTimestamp;
        meta.incentiveTarget = amount;
        meta.incentiveLastUpdated = block.timestamp;
    }

    function payRewards(
        HourlyBond storage bond,
        LendingMetadata storage meta,
        address holder
    ) internal override {
        uint256 allocationDelta =
            meta.cumulIncentiveAllocationFP - bond.incentiveAllocationStart;
        if (allocationDelta > 0) {
            uint256 disburseAmount = (allocationDelta * bond.amount) / slot;
            Asset(asset()).withdraw(MFI, holder, disburseAmount);
            bond.incentiveAllocationStart += allocationDelta;
        }
    }

    function withdrawIncentive(address token) external {
        LendingMetadata storage meta = lendingMeta[token];
        updateRewardsAlloc(meta);
        payRewards(
            hourlyBondAccounts[token][msg.sender],
            meta,
            msg.sender
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWETH.sol";
import "./RoleAware.sol";

/// @title Manage funding
contract Asset is RoleAware {
    using SafeERC20 for IERC20;
    /// wrapped ether
    address public immutable WETH;

    constructor(address _WETH, address _roles) RoleAware(_roles) {
        WETH = _WETH;
    }

    /// Deposit an active token
    function deposit(address depositToken, uint256 depositAmount) external {
        IERC20(depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
    }

    /// Deposit token on behalf of `sender`
    function depositFor(
        address sender,
        address depositToken,
        uint256 depositAmount
    ) external {
        require(isAssetTransferer(msg.sender), "Unauthorized deposit");
        IERC20(depositToken).safeTransferFrom(
            sender,
            address(this),
            depositAmount
        );
    }

    /// Deposit to wrapped ether
    function depositToWETH() external payable {
        IWETH(WETH).deposit{value: msg.value}();
    }

    // withdrawers role
    function withdraw(
        address withdrawalToken,
        address recipient,
        uint256 withdrawalAmount
    ) external {
        require(isAssetTransferer(msg.sender), "Unauthorized withdraw");
        IERC20(withdrawalToken).safeTransfer(recipient, withdrawalAmount);
    }

    // withdrawers role
    function withdrawETH(address recipient, uint256 withdrawalAmount) external {
        require(isAssetTransferer(msg.sender), "Unauthorized withdraw");
        IWETH(WETH).withdraw(withdrawalAmount);
        Address.sendValue(payable(recipient), withdrawalAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./LendMath.sol";

struct HourlyBond {
    uint256 amount;
    uint256 yieldQuotientFP;
    uint256 moduloHour;
    uint256 incentiveAllocationStart;
}

/// @title Here we offer subscriptions to auto-renewing hourly bonds
/// Funds are locked in for an 50 minutes per hour, while interest rates float
abstract contract BondSubHour is LendMath {
    mapping(address => YieldAccumulator) hourlyBondYieldAccumulators;

    // recall yield update for borrowing and lending
    uint256 constant callRateUpdate = 10 minutes;
    // delay for withdrawBondFrame
    uint256 public withdrawDelay = 20 minutes;
    // math - recall yield update for borrowing and lending
    uint256 constant maxUpdatePerHour = 4;
    // issuer => holder => bond record
    mapping(address => mapping(address => HourlyBond)) public hourlyBondAccounts;
    // math - recall yield update for borrowing and lending
    uint256 public borrowingFactor = 200;
    // math - borrowMinYieldH calculations
    uint256 constant borrowMinRate = 25;
    // // math - floating calc in getUpdatedHAPY()
    uint256 constant borrowMinYieldH = slot + (borrowMinRate * slot) / 1000 / hoursPY;

    function hBond(address issuer, address holder, uint256 amount) internal 
    {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        LendingMetadata storage meta = lendingMeta[issuer];
        addToTotalLend(meta, amount);
        updateHBond(issuer, bond, holder);

        if (bond.amount == 0) {
            bond.moduloHour = block.timestamp % (1 hours);
        }
        bond.amount += amount;
    }

    function updateHBond(address issuer, HourlyBond storage bond, address holder) internal 
    {
        uint256 yieldQuotientFP = bond.yieldQuotientFP;

        YieldAccumulator storage yA = getUpdatedHAPY(issuer, hourlyBondYieldAccumulators[issuer], callRateUpdate);
        LendingMetadata storage meta = lendingMeta[issuer];

        if (yieldQuotientFP > 0) {
            payRewards(bond, meta, holder);
            uint256 oldAmount = bond.amount;

            bond.amount = applyInterest(bond.amount, yA.accumulatorFP, yieldQuotientFP);
            uint256 deltaAmount = bond.amount - oldAmount;
            addToTotalLend(meta, deltaAmount);
        } 
        else {
            bond.incentiveAllocationStart = meta.cumulIncentiveAllocationFP;
        }
        bond.yieldQuotientFP = yA.accumulatorFP;
    }

    // Retrieves bond balance for issuer and holder
    function viewHBond(address issuer, address holder)public view returns (uint256)
    {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        uint256 yieldQuotientFP = bond.yieldQuotientFP;
        uint256 cumulativeYield = getTotalYield(hourlyBondYieldAccumulators[issuer], block.timestamp);

        if (yieldQuotientFP > 0) {
            return applyInterest(bond.amount, cumulativeYield, yieldQuotientFP);
        } else {
            return bond.amount;
        }
    }

    function removeHBond(address issuer, HourlyBond storage bond, uint256 amount, address holder) internal 
    {
        subtractFromTotalLend(lendingMeta[issuer], amount);
        updateHBond(issuer, bond, holder);

        // how far the current hour has advanced (relative to acccount hourly clock)
        uint256 currentOffset = (block.timestamp - bond.moduloHour) % (1 hours);

        require(withdrawDelay >= currentOffset, "Tried withdrawing outside subscription cancellation time window");
        bond.amount -= amount;
    }

    function calcAPYBond(YieldAccumulator storage yieldAccumulator, uint256 timeDelta) internal view returns (uint256 accumulatorFP) 
    {
        uint256 secondsDelta = timeDelta % (1 hours);
        // linearly interpolate interest for seconds
        // FP * FP * 1 / (FP * 1) = FP
        accumulatorFP =
            yieldAccumulator.accumulatorFP +
            (yieldAccumulator.accumulatorFP * (yieldAccumulator.hourlyYieldFP - slot) * secondsDelta) /
            (slot * 1 hours);

        uint256 hoursDelta = timeDelta / (1 hours);
        if (hoursDelta > 0) {
            uint256 accumulatorBeforeFP = accumulatorFP;
            for (uint256 i = 0; hoursDelta > i && maxUpdatePerHour > i; i++) {
                // slot * slot / slot = slot
                accumulatorFP = (accumulatorFP * yieldAccumulator.hourlyYieldFP) / slot;
            }

            // a lot of time has passed
            if (hoursDelta > maxUpdatePerHour) {
                // apply interest in non-compounding way
                accumulatorFP += ((accumulatorFP - accumulatorBeforeFP) * (hoursDelta - maxUpdatePerHour)) / maxUpdatePerHour;
            }
        }
    }

    /// @dev updates yield accumulators for both borrowing and lending
    /// issuer address represents a token
    function updateHAPY(address issuer) public returns (uint256 hourlyYield)
    {
        return getUpdatedHAPY(issuer, hourlyBondYieldAccumulators[issuer], callRateUpdate).hourlyYieldFP;
    }

    /// @dev updates yield accumulators for both borrowing and lending
    function getUpdatedHAPY(address issuer, YieldAccumulator storage accumulator, uint256 window) internal returns (YieldAccumulator storage) 
    {
        uint256 lastUpdated = accumulator.lastUpdated;
        uint256 timeDelta = (block.timestamp - lastUpdated);

        if (timeDelta > window) 
        {
            YieldAccumulator storage borrowAccumulator = borrowYieldAccumulators[issuer];
            accumulator.accumulatorFP = calcAPYBond(accumulator, timeDelta);

            LendingMetadata storage meta = lendingMeta[issuer];

            accumulator.hourlyYieldFP = LendingRate(meta.totalLending, meta.totalBorrowed);
            accumulator.lastUpdated = block.timestamp;

            updateBorrowAPR(borrowAccumulator);
            borrowAccumulator.hourlyYieldFP = max(borrowMinYieldH, slot + (borrowingFactor * (accumulator.hourlyYieldFP - slot)) / 100);
        }

        return accumulator;
    }

    function updateBorrowAPR(YieldAccumulator storage borrowAccumulator) internal
    {
        uint256 timeDelta = block.timestamp - borrowAccumulator.lastUpdated;

        if (timeDelta > callRateUpdate) {
            borrowAccumulator.accumulatorFP = calcAPYBond(borrowAccumulator, timeDelta);
            borrowAccumulator.lastUpdated = block.timestamp;
        }
    }

    function getUpdatedBorrowAPR(address issuer)external returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowAPR(yA);
        return yA.accumulatorFP;
    }

    function getTotalYield(YieldAccumulator storage yA, uint256 timestamp) internal view returns (uint256) 
    {
        uint256 timeDelta = (timestamp - yA.lastUpdated);
        if (timeDelta > callRateUpdate) {
            return calcAPYBond(yA, timeDelta);
        } else {
            return yA.accumulatorFP;
        }
    }

    function getYearlyRewards10k(address token) external view returns (uint256)
    {
        LendingMetadata storage meta = lendingMeta[token];
        if (meta.incentiveEnd < block.timestamp || meta.incentiveLastUpdated > meta.incentiveEnd) {
            return 0;
        } else {
            uint256 timeDelta = meta.incentiveEnd - meta.incentiveLastUpdated;
            // scale to 1 year
            return (10_000 * (365 days) * meta.incentiveTarget) / (1 + meta.totalLending * timeDelta);
        }
    }

    function updateRewardsAlloc(LendingMetadata storage meta) internal 
    {
        uint256 endTime = min(meta.incentiveEnd, block.timestamp);
        if (meta.incentiveTarget > 0 && endTime > meta.incentiveLastUpdated) {
            uint256 timeDelta = endTime - meta.incentiveLastUpdated;
            uint256 targetDelta = min(meta.incentiveTarget, (timeDelta * meta.incentiveTarget) / (meta.incentiveEnd - meta.incentiveLastUpdated));
            meta.incentiveTarget -= targetDelta;
            meta.cumulIncentiveAllocationFP += (targetDelta * slot) / (1 + meta.totalLending); meta.incentiveLastUpdated = block.timestamp;
        }
    }

    function addToTotalLend(LendingMetadata storage meta, uint256 amount) internal
    {
        updateRewardsAlloc(meta);
        meta.totalLending += amount;
    }

    function subtractFromTotalLend(LendingMetadata storage meta, uint256 amount) internal 
    {
        updateRewardsAlloc(meta);
        meta.totalLending -= amount;
    }

    function payRewards(HourlyBond storage bond, LendingMetadata storage meta,address holder) internal virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library IncentiveReporter {
    event AddToClaim(address topic, address indexed claimant, uint256 amount);
    event SubtractFromClaim(
        address topic,
        address indexed claimant,
        uint256 amount
    );

    /// Start / increase amount of claim
    function addToClaimAmount(
        address topic,
        address recipient,
        uint256 claimAmount
    ) internal {
        emit AddToClaim(topic, recipient, claimAmount);
    }

    /// Decrease amount of claim
    function subtractFromClaimAmount(
        address topic,
        address recipient,
        uint256 subtractAmount
    ) internal {
        emit SubtractFromClaim(topic, recipient, subtractAmount);
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Users.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware {
    Users public immutable roles;
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Users(_roles);
    }

    modifier noIntermediary() {
        require(
            msg.sender == tx.origin,
            "Currently no intermediaries allowed for this function call"
        );
        _;
    }

    // @dev Throws if called by any account other than the owner or performer
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || performer() == msg.sender,
            "Users: caller is not the owner"
        );
        _;
    }

    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                performer() == msg.sender ||
                immobilizer() == msg.sender,
            "Caller is not the owner, performer or authorized immobilizer"
        );
        _;
    }

    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                performer() == msg.sender ||
                isAssetInitiator(msg.sender),
            "Caller is not the owner, performer or authorized activator"
        );
        _;
    }

    function updRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.getRole(role, contr);
    }

    function updMainIdCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    function owner() internal view returns (address) {
        return roles.owner();
    }

    function performer() internal returns (address) {
        return roles.performer();
    }

    function immobilizer() internal view returns (address) {
        return mainCharacterCache[IMMOBILIZER];
    }

    function asset() internal view returns (address) {
        return mainCharacterCache[ASSET];
    }

    function lending() internal view returns (address) {
        return mainCharacterCache[LENDING];
    }

    function leverageRouter() internal view returns (address) {
        return mainCharacterCache[LEVERAGE_ROUTER];
    }

    function leverageTrading() internal view returns (address) {
        return mainCharacterCache[LEVERAGE_TRADING];
    }

    function feeManager() internal view returns (address) {
        return mainCharacterCache[FEE_MANAGER];
    }

    function price() internal view returns (address) {
        return mainCharacterCache[PRICE_MANAGER];
    }

    function manager() internal view returns (address) {
        return mainCharacterCache[TOP_MANAGER];
    }

    function incentiveIssuer() internal view returns (address) {
        return mainCharacterCache[INCENTIVE_ISSUER];
    }

    function assetManager() internal view returns (address) {
        return mainCharacterCache[ASSET_MANAGER];
    }

    function isBorrower(address contr) internal view returns (bool) {
        return roleCache[contr][BORROWER];
    }

    function isAssetTransferer(address contr) internal view returns (bool) {
        return roleCache[contr][ASSET_TRANSFERER];
    }

    function isLeverageTrader(address contr) internal view returns (bool) {
        return roleCache[contr][LEVERAGE_TRADER];
    }

    function isFeeRoot(address contr) internal view returns (bool) {
        return roleCache[contr][FEE_ROOT];
    }

    function isMargincallTaker(address contr) internal view returns (bool) {
        return roleCache[contr][MARGINCALL_TAKER];
    }

    function isLiquidatorBot(address contr) internal view returns (bool) {
        return roleCache[contr][LIQUIDATOR_BOT];
    }

    function isAuthorizedAssetTrader(address contr)
        internal
        view
        returns (bool)
    {
        return roleCache[contr][AUTHORIZED_ASSET_TRADER];
    }

    function isIncentiveCaller(address contr) internal view returns (bool) {
        return roleCache[contr][INCENTIVE_CALLER];
    }

    function isAssetInitiator(address contr) internal view returns (bool) {
        return roleCache[contr][ASSET_INITIATOR];
    }

    function isStakeFiner(address contr) internal view returns (bool) {
        return roleCache[contr][STAKE_FINER];
    }

    function isLender(address contr) internal view returns (bool) {
        return roleCache[contr][LENDER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDependencyManager.sol";

// we chose not to go with an enum
// to make this list easy to extend

uint256 constant IMMOBILIZER = 101;
uint256 constant DEPENDENCY_MANAGER = 102;

uint256 constant ASSET = 201;
uint256 constant LENDING = 202;
uint256 constant LEVERAGE_ROUTER = 203;
uint256 constant LEVERAGE_TRADING = 204;
uint256 constant FEE_MANAGER = 205;
uint256 constant PRICE_MANAGER = 206;
uint256 constant TOP_MANAGER = 207;
uint256 constant INCENTIVE_ISSUER = 208;
uint256 constant ASSET_MANAGER = 209;

uint256 constant ASSET_TRANSFERER = 301;
uint256 constant MARGINCALL_TAKER = 302;
uint256 constant BORROWER = 303;
uint256 constant LEVERAGE_TRADER = 304;
uint256 constant FEE_ROOT = 305;
uint256 constant LIQUIDATOR_BOT = 306;
uint256 constant AUTHORIZED_ASSET_TRADER = 307;
uint256 constant INCENTIVE_CALLER = 308;
uint256 constant ASSET_INITIATOR = 309;
uint256 constant STAKE_FINER = 310;
uint256 constant LENDER = 311;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet (0xEED9D1c6B4cdEcB3af070D85bfd394E7aF179CBd) during
/// beta and will then be transfered to governance
/// https://github.com/marginswap/governance
contract Users is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][ASSET_INITIATOR] = true;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                performer() == msg.sender ||
                mainCharacters[DEPENDENCY_MANAGER] == msg.sender,
            "Users: caller is not the owner"
        );
        _;
    }

    function setRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = true;
    }

    function deleteRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = false;
    }

    function setMainId(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        mainCharacters[role] = actor;
    }

    function getRole(uint256 role, address contr) external view returns (bool) {
        return roles[contr][role];
    }

    /// @dev current performer
    function performer() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_MANAGER];
        if (depController != address(0)) {
            exec = IDependencyManager(depController).currentPerformer();
        }
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDependencyManager {
    function currentPerformer() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";

/// @title Lend math behavior
abstract contract LendMath {
    // Math for LendingRate
    uint256 constant slot = 2**48;
    // Hours per 1 year
    uint256 constant hoursPY = 365 days / (1 hours);
    // Math for LendingRate
    uint256 constant change_slot = 82;
    // Math for LendingRate
    uint256 public normalRate = (slot * 12) / hoursPY / change_slot / 100;
    // Math for LendingRate
    uint256 public highRate = (slot * (135 - 12)) / hoursPY / (100 - change_slot) / 100;

    struct YieldAccumulator {
        uint256 accumulatorFP;
        uint256 lastUpdated;
        uint256 hourlyYieldFP;
    }

    struct LendingMetadata {
        uint256 totalLending;
        uint256 totalBorrowed;
        uint256 lendingCap;
        uint256 cumulIncentiveAllocationFP;
        uint256 incentiveLastUpdated;
        uint256 incentiveEnd;
        uint256 incentiveTarget;
    }
    mapping(address => LendingMetadata) public lendingMeta;

    /// @dev accumulate interest per issuer (like compound indices)
    mapping(address => YieldAccumulator) public borrowYieldAccumulators;

    /// @dev simple formula for calculating interest relative to accumulator
    function applyInterest(
        uint256 balance,
        uint256 accumulatorFP,
        uint256 yieldQuotientFP
    ) internal pure returns (uint256) {
        // 1 * FP / FP = 1
        return (balance * accumulatorFP) / yieldQuotientFP;
    }

    function LendingRate(uint256 totalLending, uint256 totalBorrowing)
        internal
        view
        returns (uint256 rate)
    {
        rate = slot;
        uint256 utilizationPercent = totalLending > 0 ? (100 * totalBorrowing) / totalLending : 0;
        if (utilizationPercent < change_slot) {
            rate += utilizationPercent * normalRate;
        } else {
            rate += change_slot * normalRate + (utilizationPercent - change_slot) * highRate;
        }
    }

    /// @dev minimum
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    /// @dev maximum
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    /// Available tokens to this issuance
    function issuanceBalance(address issuance)
        internal
        view
        virtual
        returns (uint256);
}