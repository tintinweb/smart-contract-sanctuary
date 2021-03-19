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

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;
import "./RoleAware.sol";

abstract contract BaseLending is RoleAware, Ownable {
    uint256 constant FP32 = 2**32;
    uint256 constant ACCUMULATOR_INIT = 10**18;

    mapping(address => uint256) public totalLending;
    mapping(address => uint256) public totalBorrowed;
    mapping(address => uint256) public lendingBuffer;
    mapping(address => uint256) public lendingCap;

    uint256 public maxHourlyYieldFP;
    uint256 public yieldChangePerSecondFP;

    /// @dev simple formula for calculating interest relative to accumulator
    function applyInterest(
        uint256 balance,
        uint256 accumulatorFP,
        uint256 yieldQuotientFP
    ) internal pure returns (uint256) {
        // 1 * FP / FP = 1
        return (balance * accumulatorFP) / yieldQuotientFP;
    }

    /// update the yield for an asset based on recent supply and demand
    function updatedYieldFP(
        // previous yield
        uint256 _yieldFP,
        // timestamp
        uint256 lastUpdated,
        uint256 totalLendingInBucket,
        uint256 bucketTarget,
        uint256 buyingSpeed,
        uint256 withdrawingSpeed,
        uint256 bucketMaxYield
    ) internal view returns (uint256 yieldFP) {
        yieldFP = _yieldFP;
        uint256 timeDiff = block.timestamp - lastUpdated;
        uint256 yieldDiff = timeDiff * yieldChangePerSecondFP;

        if (
            totalLendingInBucket >= bucketTarget ||
            buyingSpeed >= withdrawingSpeed
        ) {
            yieldFP -= min(yieldFP, yieldDiff);
        } else if (
            bucketTarget > totalLendingInBucket &&
            withdrawingSpeed > buyingSpeed
        ) {
            yieldFP += yieldDiff;
            if (yieldFP > bucketMaxYield) {
                yieldFP = bucketMaxYield;
            }
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

    function _makeFallbackBond(
        address token,
        address holder,
        uint256 amount
    ) internal virtual;

    function lendingTarget(address token) public view returns (uint256) {
        return
            min(lendingCap[token], totalBorrowed[token] + lendingBuffer[token]);
    }

    function setLendingCap(address token, uint256 cap) external {
        require(
            isTokenActivator(msg.sender),
            "not authorized to set lending cap"
        );
        lendingCap[token] = cap;
    }

    function setLendingBuffer(address token, uint256 buffer) external {
        require(
            isTokenActivator(msg.sender),
            "not autorized to set lending buffer"
        );
        lendingBuffer[token] = buffer;
    }

    function setMaxHourlyYieldFP(uint256 maxYieldFP) external onlyOwner {
        maxHourlyYieldFP = maxYieldFP;
    }

    function setYieldChangePerSecondFP(uint256 changePerSecondFP)
        external
        onlyOwner
    {
        yieldChangePerSecondFP = changePerSecondFP;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;
import "./BaseLending.sol";
import "./Fund.sol";

struct Bond {
    address holder;
    address token;
    uint256 originalPrice;
    uint256 returnAmount;
    uint256 maturityTimestamp;
    uint256 runtime;
    uint256 yieldFP;
}

/// @dev Lending for fixed runtime, fixed interest
/// Lenders can pick their own bond maturity date --
/// In order to manage interest rates for the different
/// maturities and create a yield curve we bucket
/// bond runtimes into weighted baskets and adjust
/// rates individually per bucket, based on supply and demand.
abstract contract BondLending is BaseLending {
    uint256 public minRuntime = 30 days;
    uint256 public maxRuntime = 365 days;
    uint256 public diffMaxMinRuntime;
    // this is the numerator under runtimeWeights.
    // any excess left over is the weight of hourly bonds
    uint256 public constant WEIGHT_TOTAL_10k = 10_000;
    uint256 public borrowingMarkupFP;

    mapping(address => uint256[]) public runtimeWeights;
    mapping(address => uint256[]) public buyingSpeed;
    mapping(address => uint256[]) public lastBought;
    mapping(address => uint256[]) public withdrawingSpeed;
    mapping(address => uint256[]) public lastWithdrawn;
    mapping(address => uint256[]) public yieldLastUpdated;

    mapping(uint256 => Bond) public bonds;

    mapping(address => uint256[]) public totalLendingPerRuntime;
    mapping(address => uint256[]) runtimeYieldsFP;
    uint256 public nextBondIndex = 1;

    event LiquidityWarning(
        address indexed token,
        address indexed holder,
        uint256 value
    );

    function _makeBond(
        address holder,
        address token,
        uint256 runtime,
        uint256 amount,
        uint256 minReturn
    ) internal returns (uint256 bondIndex) {
        uint256 bucketIndex = getBucketIndex(token, runtime);
        uint256 yieldFP =
            calcBondYieldFP(
                token,
                amount + totalLendingPerRuntime[token][bucketIndex],
                bucketIndex
            );
        uint256 bondReturn = (yieldFP * amount) / FP32;
        if (bondReturn >= minReturn) {
            if (Fund(fund()).depositFor(holder, token, amount)) {
                uint256 interpolatedAmount = (amount + bondReturn) / 2;
                totalLending[token] += interpolatedAmount;

                totalLendingPerRuntime[token][
                    bucketIndex
                ] += interpolatedAmount;

                bondIndex = nextBondIndex;
                nextBondIndex++;

                bonds[bondIndex] = Bond({
                    holder: holder,
                    token: token,
                    originalPrice: amount,
                    returnAmount: bondReturn,
                    maturityTimestamp: block.timestamp + runtime,
                    runtime: runtime,
                    yieldFP: yieldFP
                });

                updateSpeed(
                    buyingSpeed[token],
                    lastBought[token],
                    bucketIndex,
                    amount
                );
            }
        }
    }

    function _withdrawBond(Bond storage bond) internal {
        address token = bond.token;
        uint256 bucketIndex = getBucketIndex(token, bond.runtime);
        uint256 interpolatedAmount =
            (bond.originalPrice + bond.returnAmount) / 2;
        totalLending[token] -= interpolatedAmount;
        totalLendingPerRuntime[token][bucketIndex] -= interpolatedAmount;

        updateSpeed(
            withdrawingSpeed[token],
            lastWithdrawn[token],
            bucketIndex,
            bond.originalPrice
        );

        if (
            totalBorrowed[token] > totalLending[token] ||
            !Fund(fund()).withdraw(token, bond.holder, bond.returnAmount)
        ) {
            // apparently there is a liquidity issue
            emit LiquidityWarning(token, bond.holder, bond.returnAmount);
            _makeFallbackBond(token, bond.holder, bond.returnAmount);
        }
    }

    function getUpdatedBondYieldFP(
        address token,
        uint256 runtime,
        uint256 amount
    ) internal returns (uint256 yieldFP, uint256 bucketIndex) {
        bucketIndex = getBucketIndex(token, runtime);
        yieldFP = calcBondYieldFP(
            token,
            amount + totalLendingPerRuntime[token][bucketIndex],
            bucketIndex
        );
        runtimeYieldsFP[token][bucketIndex] = yieldFP;
        yieldLastUpdated[token][bucketIndex] = block.timestamp;
    }

    function calcBondYieldFP(
        address token,
        uint256 totalLendingInBucket,
        uint256 bucketIndex
    ) internal view returns (uint256 yieldFP) {
        yieldFP = runtimeYieldsFP[token][bucketIndex];
        uint256 lastUpdated = yieldLastUpdated[token][bucketIndex];

        uint256 bucketTarget =
            (lendingTarget(token) * runtimeWeights[token][bucketIndex]) /
                WEIGHT_TOTAL_10k;

        uint256 buying = buyingSpeed[token][bucketIndex];
        uint256 withdrawing = withdrawingSpeed[token][bucketIndex];

        uint256 runtime = minRuntime + bucketIndex * diffMaxMinRuntime;
        uint256 bucketMaxYield = maxHourlyYieldFP * (runtime / (1 hours));

        yieldFP = updatedYieldFP(
            yieldFP,
            lastUpdated,
            totalLendingInBucket,
            bucketTarget,
            buying,
            withdrawing,
            bucketMaxYield
        );
    }

    function viewBondReturn(
        address token,
        uint256 runtime,
        uint256 amount
    ) external view returns (uint256) {
        uint256 bucketIndex = getBucketIndex(token, runtime);
        uint256 yieldFP =
            calcBondYieldFP(
                token,
                amount + totalLendingPerRuntime[token][bucketIndex],
                bucketIndex
            );
        return (yieldFP * amount) / FP32;
    }

    function getBucketIndex(address token, uint256 runtime)
        internal
        view
        returns (uint256 bucketIndex)
    {
        uint256[] storage yieldsFP = runtimeYieldsFP[token];
        uint256 bucketSize = diffMaxMinRuntime / yieldsFP.length;
        bucketIndex = (runtime - minRuntime) / bucketSize;
    }

    function updateSpeed(
        uint256[] storage speedRegister,
        uint256[] storage lastAction,
        uint256 bucketIndex,
        uint256 amount
    ) internal {
        uint256 bucketSize = diffMaxMinRuntime / speedRegister.length;
        uint256 runtime = minRuntime + bucketSize * bucketIndex;
        uint256 timeDiff = block.timestamp - lastAction[bucketIndex];
        uint256 currentSpeed = (amount * runtime) / (timeDiff + 1);

        uint256 runtimeScale = runtime / (10 minutes);
        // scale adjustment relative togit  runtime
        speedRegister[bucketIndex] =
            (speedRegister[bucketIndex] *
                runtimeScale +
                currentSpeed *
                timeDiff) /
            (runtimeScale + timeDiff);
        lastAction[bucketIndex] = block.timestamp;
    }

    function setRuntimeYieldsFP(address token, uint256[] memory yieldsFP)
        external
        onlyOwner
    {
        runtimeYieldsFP[token] = yieldsFP;
    }

    function setRuntimeWeights(address token, uint256[] memory weights)
        external
    {
        //require(
        //    isTokenActivator(msg.sender),
        //    "not autorized to set runtime weights"
        //);
        require(
            runtimeWeights[token].length == 0 ||
                runtimeWeights[token].length == weights.length,
            "Cannot change size of weight array"
        );
        if (runtimeWeights[token].length == 0) {
            // we are initializing

            runtimeYieldsFP[token] = new uint256[](weights.length);
            lastBought[token] = new uint256[](weights.length);
            lastWithdrawn[token] = new uint256[](weights.length);
            yieldLastUpdated[token] = new uint256[](weights.length);
            buyingSpeed[token] = new uint256[](weights.length);
            withdrawingSpeed[token] = new uint256[](weights.length);

            uint256 hourlyYieldFP = (110 * FP32) / 100 / (24 * 365);
            uint256 bucketSize = diffMaxMinRuntime / weights.length;

            for (uint24 i = 0; weights.length > i; i++) {
                uint256 runtime = minRuntime + bucketSize * i;
                // Do a best guess of initializing
                runtimeYieldsFP[token][i] =
                    hourlyYieldFP *
                    (runtime / (1 hours));

                lastBought[token][i] = block.timestamp;
                lastWithdrawn[token][i] = block.timestamp;
                yieldLastUpdated[token][i] = block.timestamp;
            }
        }

        runtimeWeights[token] = weights;
    }

    function setMinRuntime(uint256 runtime) external onlyOwner {
        require(runtime > 1 hours, "Min runtime needs to be at least 1 hour");
        minRuntime = runtime;
    }

    function setMaxRuntime(uint256 runtime) external onlyOwner {
        require(
            runtime > minRuntime,
            "Max runtime must be greater than min runtime"
        );
        maxRuntime = runtime;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "./RoleAware.sol";

contract Fund is RoleAware, Ownable {
    address public WETH;
    mapping(address => bool) public activeTokens;

    constructor(address _WETH, address _roles) Ownable() RoleAware(_roles) {
        WETH = _WETH;
    }

    function activateToken(address token) external {
        require(
            isTokenActivator(msg.sender),
            "Address not authorized to activate tokens"
        );
        activeTokens[token] = true;
    }

    function deactivateToken(address token) external {
        require(
            isTokenActivator(msg.sender),
            "Address not authorized to activate tokens"
        );
        activeTokens[token] = false;
    }

    function deposit(address depositToken, uint256 depositAmount)
        external
        returns (bool)
    {
        require(activeTokens[depositToken], "Deposit token is not active");
        return
            IERC20(depositToken).transferFrom(
                msg.sender,
                address(this),
                depositAmount
            );
    }

    function depositFor(
        address sender,
        address depositToken,
        uint256 depositAmount
    ) external returns (bool) {
        require(activeTokens[depositToken], "Deposit token is not active");
        require(isWithdrawer(msg.sender), "Contract not authorized to deposit");
        return
            IERC20(depositToken).transferFrom(
                sender,
                address(this),
                depositAmount
            );
    }

    function depositToWETH() external payable {
        IWETH(WETH).deposit{value: msg.value}();
    }

    // withdrawers role
    function withdraw(
        address withdrawalToken,
        address recipient,
        uint256 withdrawalAmount
    ) external returns (bool) {
        require(
            isWithdrawer(msg.sender),
            "Contract not authorized to withdraw"
        );
        return IERC20(withdrawalToken).transfer(recipient, withdrawalAmount);
    }

    // withdrawers role
    function withdrawETH(address recipient, uint256 withdrawalAmount) external {
        require(isWithdrawer(msg.sender), "Not authorized to withdraw");
        IWETH(WETH).withdraw(withdrawalAmount);
        payable(recipient).transfer(withdrawalAmount);
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./BaseLending.sol";
import "./Fund.sol";

struct YieldAccumulator {
    uint256 accumulatorFP;
    uint256 lastUpdated;
    uint256 hourlyYieldFP;
}

struct HourlyBond {
    uint256 amount;
    uint256 yieldQuotientFP;
    uint256 moduloHour;
}

/// @dev Here we offer subscriptions to auto-renewing hourly bonds
/// Funds are locked in for an 50 minutes per hour, while interest rates float
abstract contract HourlyBondSubscriptionLending is BaseLending {
    uint256 withdrawalWindow = 10 minutes;
    // token => holder => bond record
    mapping(address => mapping(address => HourlyBond))
        public hourlyBondAccounts;

    mapping(address => YieldAccumulator) public hourlyBondYieldAccumulators;
    /// @dev accumulate interest per token (like compound indices)
    mapping(address => YieldAccumulator) public borrowYieldAccumulators;

    uint256 public borrowingFactorPercent = 200;

    mapping(address => uint256) public hourlyBondBuyingSpeed;
    mapping(address => uint256) public hourlyBondWithdrawingSpeed;

    function setHourlyYieldAPR(address token, uint256 aprPercent) external {
        require(
            isTokenActivator(msg.sender),
            "not autorized to set hourly yield"
        );
        if (hourlyBondYieldAccumulators[token].accumulatorFP == 0) {
            hourlyBondYieldAccumulators[token] = YieldAccumulator({
                accumulatorFP: FP32,
                lastUpdated: block.timestamp,
                hourlyYieldFP: (FP32 * (100 + aprPercent)) / 100 / (24 * 365)
            });
        } else {
            hourlyBondYieldAccumulators[token].hourlyYieldFP =
                (FP32 * (100 + aprPercent)) /
                100 /
                (24 * 365);
        }
    }

    function setWithdrawalWindow(uint256 window) external onlyOwner {
        withdrawalWindow = window;
    }

    function _makeHourlyBond(
        address token,
        address holder,
        uint256 amount
    ) internal {
        HourlyBond storage bond = hourlyBondAccounts[token][holder];
        updateHourlyBondAmount(token, bond);
        bond.yieldQuotientFP = hourlyBondYieldAccumulators[token].accumulatorFP;
        bond.moduloHour = block.timestamp % (1 hours);
        bond.amount += amount;
        totalLending[token] += amount;
    }

    function updateHourlyBondAmount(address token, HourlyBond storage bond)
        internal
    {
        uint256 yieldQuotientFP = bond.yieldQuotientFP;
        if (yieldQuotientFP > 0) {
            YieldAccumulator storage yA = getUpdatedHourlyYield(token);

            uint256 oldAmount = bond.amount;
            bond.amount = applyInterest(
                bond.amount,
                yA.accumulatorFP,
                yieldQuotientFP
            );

            uint256 deltaAmount = bond.amount - oldAmount;
            totalLending[token] += deltaAmount;
        }
    }

    function _withdrawHourlyBond(
        address token,
        HourlyBond storage bond,
        address recipient,
        uint256 amount
    ) internal {
        // how far the current hour has advanced (relative to acccount hourly clock)
        uint256 currentOffset = (block.timestamp - bond.moduloHour) % (1 hours);

        require(
            withdrawalWindow >= currentOffset,
            "Tried withdrawing outside subscription cancellation time window"
        );

        require(
            Fund(fund()).withdraw(token, recipient, amount),
            "Insufficient liquidity"
        );

        bond.amount -= amount;
        totalLending[token] -= amount;
    }

    function closeHourlyBondAccount(address token) external {
        HourlyBond storage bond = hourlyBondAccounts[token][msg.sender];
        // apply all interest
        updateHourlyBondAmount(token, bond);
        _withdrawHourlyBond(token, bond, msg.sender, bond.amount);
        bond.amount = 0;
        bond.yieldQuotientFP = 0;
        bond.moduloHour = 0;
    }

    function calcCumulativeYieldFP(
        YieldAccumulator storage yieldAccumulator,
        uint256 timeDelta
    ) internal view returns (uint256 accumulatorFP) {
        uint256 secondsDelta = timeDelta % (1 hours);
        // linearly interpolate interest for seconds
        // accumulator * hourly_yield == seconds_per_hour * accumulator * hourly_yield / seconds_per_hour
        // FP * FP * 1 / (FP * 1) = FP
        accumulatorFP =
            (yieldAccumulator.accumulatorFP *
                yieldAccumulator.hourlyYieldFP *
                secondsDelta) /
            (FP32 * 1 hours);

        uint256 hoursDelta = timeDelta / (1 hours);
        if (hoursDelta > 0) {
            // This loop should hardly ever 1 or more unless something bad happened
            // In which case it costs gas but there isn't overflow
            for (uint256 i = 0; hoursDelta > i; i++) {
                // FP32 * FP32 / FP32 = FP32
                accumulatorFP =
                    (accumulatorFP * yieldAccumulator.hourlyYieldFP) /
                    FP32;
            }
        }
    }

    /// @dev updates yield accumulators for both borrowing and lending
    function getUpdatedHourlyYield(address token)
        internal
        returns (YieldAccumulator storage accumulator)
    {
        accumulator = hourlyBondYieldAccumulators[token];
        uint256 timeDelta = (block.timestamp - accumulator.lastUpdated);

        accumulator.accumulatorFP = calcCumulativeYieldFP(
            accumulator,
            timeDelta
        );

        accumulator.hourlyYieldFP = updatedYieldFP(
            accumulator.hourlyYieldFP,
            accumulator.lastUpdated,
            totalLending[token],
            lendingTarget(token),
            hourlyBondBuyingSpeed[token],
            hourlyBondWithdrawingSpeed[token],
            maxHourlyYieldFP
        );

        YieldAccumulator storage borrowAccumulator =
            borrowYieldAccumulators[token];
        timeDelta = block.timestamp - borrowAccumulator.lastUpdated;
        borrowAccumulator.accumulatorFP = calcCumulativeYieldFP(
            borrowAccumulator,
            timeDelta
        );

        borrowYieldAccumulators[token].hourlyYieldFP =
            (borrowingFactorPercent * accumulator.hourlyYieldFP) /
            100;

        accumulator.lastUpdated = block.timestamp;
        borrowAccumulator.lastUpdated = block.timestamp;
    }

    function viewCumulativeYieldFP(
        address token,
        mapping(address => YieldAccumulator) storage yieldAccumulators,
        uint256 timestamp
    ) internal view returns (uint256) {
        uint256 timeDelta = (timestamp - yieldAccumulators[token].lastUpdated);
        return calcCumulativeYieldFP(yieldAccumulators[token], timeDelta);
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RoleAware.sol";
import "./Fund.sol";

struct Claim {
    uint256 startingRewardRateFP;
    address recipient;
    uint256 amount;
}

contract IncentiveDistribution is RoleAware, Ownable {
    // fixed point number factor
    uint256 constant FP32 = 2**32;
    // the amount of contraction per thousand, per day
    // of the overal daily incentive distribution
    uint256 constant contractionPerMil = 999;
    // the period for which claims are batch updated
    uint256 constant period = 4 hours;
    uint256 constant periodsPerDay = 24 hours / period;
    address MFI;

    constructor(
        address _MFI,
        uint256 startingDailyDistributionWithoutDecimals,
        address _roles
    ) RoleAware(_roles) Ownable() {
        MFI = _MFI;
        currentDailyDistribution =
            startingDailyDistributionWithoutDecimals *
            (1 ether);
        lastDailyDistributionUpdate = block.timestamp / (1 days);
    }

    // how much is going to be distributed, contracts every day
    uint256 public currentDailyDistribution;
    // last day on which we updated currentDailyDistribution
    uint256 lastDailyDistributionUpdate;
    // portion of daily distribution per each tranche
    mapping(uint8 => uint256) public trancheShare;
    uint256 public trancheShareTotal;

    // tranche => claim totals for the period we're currently aggregating
    mapping(uint8 => uint256) public currentPeriodTotals;
    // tranche => timestamp / period of last update
    mapping(uint8 => uint256) public lastUpdatedPeriods;

    // how each claim unit would get if they had staked from the dawn of time
    // expressed as fixed point number
    // claim amounts are expressed relative to this ongoing aggregate
    mapping(uint8 => uint256) public aggregatePeriodicRewardRateFP;
    // claim records
    mapping(uint256 => Claim) public claims;
    uint256 public nextClaimId = 1;

    function setTrancheShare(uint8 tranche, uint256 share) external onlyOwner {
        require(
            lastUpdatedPeriods[tranche] > 0,
            "Tranche is not initialized, please initialize first"
        );
        _setTrancheShare(tranche, share);
    }

    function _setTrancheShare(uint8 tranche, uint256 share) internal {
        if (share > trancheShare[tranche]) {
            trancheShareTotal += share - trancheShare[tranche];
        } else {
            trancheShareTotal -= trancheShare[tranche] - share;
        }
        trancheShare[tranche] = share;
    }

    function initTranche(uint8 tranche, uint256 share) external onlyOwner {
        _setTrancheShare(tranche, share);

        lastUpdatedPeriods[tranche] = block.timestamp / period;
        // simply initialize to 1.0
        aggregatePeriodicRewardRateFP[tranche] = FP32;
    }

    function updatePeriodTotals(uint8 tranche) internal {
        uint256 currentPeriod = block.timestamp / period;

        // update the amount that gets distributed per day, if there has been
        // a day transition
        updateCurrentDailyDistribution();
        // Do a bunch of updating of periodic variables when the period changes
        uint256 lU = lastUpdatedPeriods[tranche];
        uint256 periodDiff = currentPeriod - lU;

        if (periodDiff > 0) {
            aggregatePeriodicRewardRateFP[tranche] +=
                currentPeriodicRewardRateFP(tranche) *
                periodDiff;
        }

        lastUpdatedPeriods[tranche] = currentPeriod;
    }

    function forcePeriodTotalUpdate(uint8 tranche) external {
        updatePeriodTotals(tranche);
    }

    function updateCurrentDailyDistribution() internal {
        uint256 nowDay = block.timestamp / (1 days);
        uint256 dayDiff = nowDay - lastDailyDistributionUpdate;

        // shrink the daily distribution for every day that has passed
        for (uint256 i = 0; i < dayDiff; i++) {
            currentDailyDistribution =
                (currentDailyDistribution * contractionPerMil) /
                1000;
        }
        // now update this memo
        lastDailyDistributionUpdate = nowDay;
    }

    function currentPeriodicRewardRateFP(uint8 tranche)
        internal
        view
        returns (uint256)
    {
        // scale daily distribution down to tranche share
        uint256 tranchePeriodDistributionFP =
            (FP32 * currentDailyDistribution * trancheShare[tranche]) /
                trancheShareTotal /
                periodsPerDay;

        // rate = (total_reward / total_claims) per period
        return tranchePeriodDistributionFP / currentPeriodTotals[tranche];
    }

    function startClaim(
        uint8 tranche,
        address recipient,
        uint256 claimAmount
    ) external returns (uint256) {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        if (currentDailyDistribution > 0) {
            updatePeriodTotals(tranche);

            currentPeriodTotals[tranche] += claimAmount;

            claims[nextClaimId] = Claim({
                startingRewardRateFP: aggregatePeriodicRewardRateFP[tranche],
                recipient: recipient,
                amount: claimAmount
            });
            nextClaimId += 1;
            return nextClaimId - 1;
        } else {
            return 0;
        }
    }

    function addToClaimAmount(
        uint8 tranche,
        uint256 claimId,
        uint256 additionalAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        if (currentDailyDistribution > 0) {
            updatePeriodTotals(tranche);

            currentPeriodTotals[tranche] += additionalAmount;

            Claim storage claim = claims[claimId];
            require(
                claim.startingRewardRateFP > 0,
                "Trying to add to non-existant claim"
            );
            _withdrawReward(tranche, claim);
            claim.amount += additionalAmount;
        }
    }

    function subtractFromClaimAmount(
        uint8 tranche,
        uint256 claimId,
        uint256 subtractAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);

        currentPeriodTotals[tranche] -= subtractAmount;

        Claim storage claim = claims[claimId];
        _withdrawReward((tranche), claim);
        claim.amount -= subtractAmount;
    }

    function endClaim(uint8 tranche, uint256 claimId) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);
        Claim storage claim = claims[claimId];

        if (claim.startingRewardRateFP > 0) {
            _withdrawReward(tranche, claim);
            delete claim.recipient;
            delete claim.startingRewardRateFP;
            delete claim.amount;
        }
    }

    function calcRewardAmount(uint8 tranche, Claim storage claim)
        internal
        view
        returns (uint256)
    {
        return
            (claim.amount *
                (aggregatePeriodicRewardRateFP[tranche] -
                    claim.startingRewardRateFP)) / FP32;
    }

    function viewRewardAmount(uint8 tranche, uint256 claimId)
        external
        view
        returns (uint256)
    {
        return calcRewardAmount(tranche, claims[claimId]);
    }

    function withdrawReward(uint8 tranche, uint256 claimId)
        external
        returns (uint256)
    {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        updatePeriodTotals(tranche);
        Claim storage claim = claims[claimId];
        return _withdrawReward(tranche, claim);
    }

    function _withdrawReward(uint8 tranche, Claim storage claim)
        internal
        returns (uint256 rewardAmount)
    {
        rewardAmount = calcRewardAmount(tranche, claim);

        require(
            Fund(fund()).withdraw(MFI, claim.recipient, rewardAmount),
            "There seems to be a lack of MFI in the incentive fund!"
        );

        claim.startingRewardRateFP = aggregatePeriodicRewardRateFP[tranche];
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./IncentiveDistribution.sol";
import "./RoleAware.sol";

/// @dev helper class to facilitate staking and unstaking
/// within the incentive system
abstract contract IncentivizedHolder is RoleAware {
    // here we cache incentive tranches to save on a bit of gas
    mapping(address => uint8) public incentiveTranches;
    // claimant => token => claimId
    mapping(address => mapping(address => uint256)) public claimIds;

    function setIncentiveTranche(address token, uint8 tranche) external {
        require(
            isTokenActivator(msg.sender),
            "Caller not authorized to set incentive tranche"
        );
        incentiveTranches[token] = tranche;
    }

    function stakeClaim(
        address claimant,
        address token,
        uint256 amount
    ) internal {
        IncentiveDistribution iD =
            IncentiveDistribution(incentiveDistributor());
        uint256 claimId = claimIds[claimant][token];
        uint8 tranche = incentiveTranches[token];
        if (claimId > 0) {
            iD.addToClaimAmount(tranche, claimId, amount);
        } else {
            claimId = iD.startClaim(tranche, claimant, amount);
            claimIds[claimant][token] = claimId;
        }
    }

    function withdrawClaim(
        address claimant,
        address token,
        uint256 amount
    ) internal {
        uint256 claimId = claimIds[claimant][token];
        uint8 tranche = incentiveTranches[token];
        IncentiveDistribution(incentiveDistributor()).subtractFromClaimAmount(
            tranche,
            claimId,
            amount
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./Fund.sol";
import "./HourlyBondSubscriptionLending.sol";
import "./BondLending.sol";
import "./IncentivizedHolder.sol";

contract Lending is
    BaseLending,
    HourlyBondSubscriptionLending,
    BondLending,
    IncentivizedHolder
{
    /// @dev IDs for all bonds held by an address
    mapping(address => uint256[]) public bondIds;

    constructor(address _roles) RoleAware(_roles) Ownable() {
        uint256 APR = 899;
        maxHourlyYieldFP = (FP32 * APR) / 100 / (24 * 365);

        uint256 aprChangePerMil = 3;
        yieldChangePerSecondFP = (FP32 * aprChangePerMil) / 1000;
    }

    /// @dev how much interest has accrued to a borrowed balance over time
    function applyBorrowInterest(
        uint256 balance,
        address token,
        uint256 yieldQuotientFP
    ) external returns (uint256 balanceWithInterest) {
        YieldAccumulator storage yA = borrowYieldAccumulators[token];
        balanceWithInterest = applyInterest(
            balance,
            yA.accumulatorFP,
            yieldQuotientFP
        );

        uint256 deltaAmount = balanceWithInterest - balance;
        totalBorrowed[token] += deltaAmount;
    }

    /// @dev view function to get current borrowing interest
    function viewBorrowInterest(
        uint256 balance,
        address token,
        uint256 yieldQuotientFP
    ) external view returns (uint256) {
        uint256 accumulatorFP =
            viewCumulativeYieldFP(
                token,
                borrowYieldAccumulators,
                block.timestamp
            );
        return applyInterest(balance, accumulatorFP, yieldQuotientFP);
    }

    /// @dev gets called by router to register if a trader borrows tokens
    function registerBorrow(address token, uint256 amount) external {
        require(isBorrower(msg.sender), "Not an approved borrower");
        require(Fund(fund()).activeTokens(token), "Not an approved token");
        totalBorrowed[token] += amount;
        require(
            totalLending[token] >= totalBorrowed[token],
            "Insufficient capital to lend, try again later!"
        );
    }

    /// @dev gets called by router if loan is extinguished
    function payOff(address token, uint256 amount) external {
        require(isBorrower(msg.sender), "Not an approved borrower");
        totalBorrowed[token] -= amount;
    }

    /// @dev get the borrow yield
    function viewBorrowingYieldFP(address token)
        external
        view
        returns (uint256)
    {
        return
            viewCumulativeYieldFP(
                token,
                borrowYieldAccumulators,
                block.timestamp
            );
    }

    /// @dev In a liquidity crunch make a fallback bond until liquidity is good again
    function _makeFallbackBond(
        address token,
        address holder,
        uint256 amount
    ) internal override {
        _makeHourlyBond(token, holder, amount);
    }

    /// @dev withdraw an hour bond
    function withdrawHourlyBond(address token, uint256 amount) external {
        HourlyBond storage bond = hourlyBondAccounts[token][msg.sender];
        // apply all interest
        updateHourlyBondAmount(token, bond);
        super._withdrawHourlyBond(token, bond, msg.sender, amount);

        withdrawClaim(msg.sender, token, amount);
    }

    /// @dev buy hourly bond subscription
    function buyHourlyBondSubscription(address token, uint256 amount) external {
        if (lendingTarget(token) >= totalLending[token] + amount) {
            require(
                Fund(fund()).depositFor(msg.sender, token, amount),
                "Could not transfer bond deposit token to fund"
            );
            super._makeHourlyBond(token, msg.sender, amount);

            stakeClaim(msg.sender, token, amount);
        }
    }

    /// @dev buy fixed term bond that does not renew
    function buyBond(
        address token,
        uint256 runtime,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256 bondIndex) {
        if (
            lendingTarget(token) >= totalLending[token] + amount &&
            maxRuntime >= runtime &&
            runtime >= minRuntime
        ) {
            bondIndex = super._makeBond(
                msg.sender,
                token,
                runtime,
                amount,
                minReturn
            );
            bondIds[msg.sender].push(bondIndex);

            stakeClaim(msg.sender, token, amount);
        }
    }

    /// @dev send back funds of bond after maturity
    function withdrawBond(uint256 bondId) external {
        Bond storage bond = bonds[bondId];
        require(msg.sender == bond.holder, "Not holder of bond");
        require(
            block.timestamp > bond.maturityTimestamp,
            "bond is still immature"
        );

        super._withdrawBond(bond);
        delete bonds[bondId];
        // in case of a shortfall, governance can step in to provide
        // additonal compensation beyond the usual incentive which
        // gets withdrawn here
        withdrawClaim(msg.sender, bond.token, bond.originalPrice);
    }

    function initBorrowYieldAccumulator(address token) external {
        require(
            isTokenActivator(msg.sender),
            "not autorized to init yield accumulator"
        );
        borrowYieldAccumulators[token].accumulatorFP = FP32;
    }

    function setBorrowingFactorPercent(uint256 borrowingFactor)
        external
        onlyOwner
    {
        borrowingFactorPercent = borrowingFactor;
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./Roles.sol";

/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware {
    uint16 public constant WITHDRAWER = 1;
    uint16 public constant MARGIN_CALLER = 2;
    uint16 public constant BORROWER = 3;
    uint16 public constant MARGIN_TRADER = 4;
    uint16 public constant FEE_SOURCE = 5;
    uint16 public constant LIQUIDATOR = 6;
    uint16 public constant AUTHORIZED_FUND_TRADER = 7;
    uint16 public constant INCENTIVE_REPORTER = 8;
    uint16 public constant TOKEN_ACTIVATOR = 9;
    uint16 public constant STAKE_PENALIZER = 10;

    uint16 public constant FUND = 101;
    uint16 public constant LENDING = 102;
    uint16 public constant ROUTER = 103;
    uint16 public constant MARGIN_TRADING = 104;
    uint16 public constant FEE_CONTROLLER = 105;
    uint16 public constant PRICE_CONTROLLER = 106;
    uint16 public constant ADMIN = 107;
    uint16 public constant INCENTIVE_DISTRIBUTION = 108;

    Roles public roles;
    mapping(uint16 => address) public mainCharacterCache;
    mapping(address => mapping(uint16 => bool)) public roleCache;

    constructor(address _roles) {
        roles = Roles(_roles);
    }

    modifier noIntermediary() {
        require(
            msg.sender == tx.origin,
            "Currently no intermediaries allowed for this function call"
        );
        _;
    }

    function updateRoleCache(uint16 role, address contr) public virtual {
        roleCache[contr][role] = roles.getRole(role, contr);
    }

    function updateMainCharacterCache(uint16 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    function fund() internal view returns (address) {
        return mainCharacterCache[FUND];
    }

    function lending() internal view returns (address) {
        return mainCharacterCache[LENDING];
    }

    function router() internal view returns (address) {
        return mainCharacterCache[ROUTER];
    }

    function marginTrading() internal view returns (address) {
        return mainCharacterCache[MARGIN_TRADING];
    }

    function feeController() internal view returns (address) {
        return mainCharacterCache[FEE_CONTROLLER];
    }

    function price() internal view returns (address) {
        return mainCharacterCache[PRICE_CONTROLLER];
    }

    function admin() internal view returns (address) {
        return mainCharacterCache[ADMIN];
    }

    function incentiveDistributor() internal view returns (address) {
        return mainCharacterCache[INCENTIVE_DISTRIBUTION];
    }

    function isBorrower(address contr) internal view returns (bool) {
        return roleCache[contr][BORROWER];
    }

    function isWithdrawer(address contr) internal view returns (bool) {
        return roleCache[contr][WITHDRAWER];
    }

    function isMarginTrader(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_TRADER];
    }

    function isFeeSource(address contr) internal view returns (bool) {
        return roleCache[contr][FEE_SOURCE];
    }

    function isMarginCaller(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_CALLER];
    }

    function isLiquidator(address contr) internal view returns (bool) {
        return roleCache[contr][LIQUIDATOR];
    }

    function isAuthorizedFundTrader(address contr)
        internal
        view
        returns (bool)
    {
        return roleCache[contr][AUTHORIZED_FUND_TRADER];
    }

    function isIncentiveReporter(address contr) internal view returns (bool) {
        return roleCache[contr][INCENTIVE_REPORTER];
    }

    function isTokenActivator(address contr) internal view returns (bool) {
        return roleCache[contr][TOKEN_ACTIVATOR];
    }

    function isStakePenalizer(address contr) internal view returns (bool) {
        return roles.getRole(STAKE_PENALIZER, contr);
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Roles is Ownable {
    mapping(address => mapping(uint16 => bool)) public roles;
    mapping(uint16 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][9] = true;
    }

    function giveRole(uint16 role, address actor) external onlyOwner {
        roles[actor][role] = true;
    }

    function removeRole(uint16 role, address actor) external onlyOwner {
        roles[actor][role] = false;
    }

    function setMainCharacter(uint16 role, address actor) external onlyOwner {
        mainCharacters[role] = actor;
    }

    function getRole(uint16 role, address contr) external view returns (bool) {
        return roles[contr][role];
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}