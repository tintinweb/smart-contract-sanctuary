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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IncentiveDistribution.sol";
import "./RoleAware.sol";
import "./Fund.sol";
import "./CrossMarginTrading.sol";

/// @dev Here we support staking for MFI incentives as well as
/// staking to perform the maintenance role.
contract Admin is RoleAware, Ownable {
    address MFI;
    mapping(address => uint256) public stakes;
    uint256 public totalStakes;
    mapping(address => uint256) public claimIds;

    uint256 feesPer10k;
    mapping(address => uint256) public collectedFees;

    uint256 public maintenanceStakePerBlock = 10 ether;
    mapping(address => address) public nextMaintenanceStaker;
    mapping(address => mapping(address => bool)) public maintenanceDelegateTo;
    address public currentMaintenanceStaker;
    address public prevMaintenanceStaker;
    uint256 public currentMaintenanceStakerStartBlock;
    address public lockedMFI;

    constructor(
        uint256 _feesPer10k,
        address _MFI,
        address _lockedMFI,
        address lockedMFIDelegate,
        address _roles
    ) RoleAware(_roles) Ownable() {
        MFI = _MFI;
        feesPer10k = _feesPer10k;
        maintenanceStakePerBlock = 1 ether;
        lockedMFI = _lockedMFI;

        // for initialization purposes and to ensure availability of service
        // the team's locked MFI participate in maintenance staking only
        // (not in the incentive staking part)
        // this implies some trust of the team to execute, which we deem reasonable
        // since the locked stake is temporary and diminishing as well as the fact
        // that the team is heavily invested in the protocol and incentivized
        // by fees like any other maintainer
        // furthermore others could step in to liquidate via the attacker route
        // and take away the team fees if they were delinquent
        nextMaintenanceStaker[lockedMFI] = lockedMFI;
        currentMaintenanceStaker = lockedMFI;
        prevMaintenanceStaker = lockedMFI;
        maintenanceDelegateTo[lockedMFI][lockedMFIDelegate];
        currentMaintenanceStakerStartBlock = block.number;
    }

    function setMaintenanceStakePerBlock(uint256 amount) external onlyOwner {
        maintenanceStakePerBlock = amount;
    }

    function _stake(address holder, uint256 amount) internal {
        require(
            Fund(fund()).depositFor(holder, MFI, amount),
            "Could not deposit stake funds (perhaps make allowance to fund contract?"
        );
        stakes[holder] += amount;
        totalStakes += amount;

        if (claimIds[holder] > 0) {
            IncentiveDistribution(incentiveDistributor()).addToClaimAmount(
                0,
                claimIds[holder],
                amount
            );
        } else {
            uint256 claimId =
                IncentiveDistribution(incentiveDistributor()).startClaim(
                    0,
                    holder,
                    amount
                );
            claimIds[holder] = claimId;
            require(claimId > 0, "Distribution is over or paused");
        }
    }

    function depositStake(uint256 amount) external {
        _stake(msg.sender, amount);
    }

    function _withdrawStake(
        address holder,
        uint256 amount,
        address recipient
    ) internal {
        uint256 stakeAmount = stakes[holder];
        // overflow failure desirable
        stakes[holder] = amount;
        totalStakes -= amount;
        require(
            Fund(fund()).withdraw(MFI, recipient, amount),
            "Insufficient funds -- something went really wrong."
        );
        if (stakeAmount == amount) {
            IncentiveDistribution(incentiveDistributor()).endClaim(
                0,
                claimIds[holder]
            );
            claimIds[holder] = 0;
        } else {
            IncentiveDistribution(incentiveDistributor())
                .subtractFromClaimAmount(0, claimIds[holder], amount);
        }
    }

    function withdrawStake(uint256 amount) external {
        require(
            !isAuthorizedStaker(msg.sender),
            "You can't withdraw while you're authorized staker"
        );
        _withdrawStake(msg.sender, amount, msg.sender);
    }

    function addTradingFees(address token, uint256 amount)
        external
        returns (uint256 fees)
    {
        require(isFeeSource(msg.sender), "Not authorized to source fees");
        fees = (feesPer10k * amount) / 10_000;
        collectedFees[token] += fees;
    }

    function subtractTradingFees(address token, uint256 amount)
        external
        returns (uint256 fees)
    {
        require(isFeeSource(msg.sender), "Not authorized to source fees");
        fees = (feesPer10k * amount) / (10_000 + feesPer10k);
        collectedFees[token] += fees;
    }

    function depositMaintenanceStake(uint256 amount) external {
        require(
            amount + stakes[msg.sender] >= maintenanceStakePerBlock,
            "Insufficient stake to call even one block"
        );
        _stake(msg.sender, amount);
        if (nextMaintenanceStaker[msg.sender] == address(0)) {
            nextMaintenanceStaker[msg.sender] = getUpdatedCurrentStaker();
            nextMaintenanceStaker[prevMaintenanceStaker] = msg.sender;
        }
    }

    function getMaintenanceStakerStake(address staker)
        public
        view
        returns (uint256)
    {
        if (staker == lockedMFI) {
            return IERC20(MFI).balanceOf(lockedMFI) / 2;
        } else {
            return stakes[staker];
        }
    }

    function getUpdatedCurrentStaker() public returns (address) {
        uint256 currentStake =
            getMaintenanceStakerStake(currentMaintenanceStaker);
        while (
            (block.number - currentMaintenanceStakerStartBlock) *
                maintenanceStakePerBlock >=
            currentStake
        ) {
            if (maintenanceStakePerBlock > currentStake) {
                // delete current from daisy chain
                address nextOne =
                    nextMaintenanceStaker[currentMaintenanceStaker];
                nextMaintenanceStaker[prevMaintenanceStaker] = nextOne;
                nextMaintenanceStaker[currentMaintenanceStaker] = address(0);

                currentMaintenanceStaker = nextOne;
            } else {
                currentMaintenanceStakerStartBlock +=
                    stakes[currentMaintenanceStaker] /
                    maintenanceStakePerBlock;

                prevMaintenanceStaker = currentMaintenanceStaker;
                currentMaintenanceStaker = nextMaintenanceStaker[
                    currentMaintenanceStaker
                ];
            }
            currentStake = getMaintenanceStakerStake(currentMaintenanceStaker);
        }
        return currentMaintenanceStaker;
    }

    function viewCurrentMaintenanceStaker()
        public
        view
        returns (address staker, uint256 startBlock)
    {
        staker = currentMaintenanceStaker;
        uint256 currentStake = getMaintenanceStakerStake(staker);
        startBlock = currentMaintenanceStakerStartBlock;
        while (
            (block.number - startBlock) * maintenanceStakePerBlock >=
            currentStake
        ) {
            if (maintenanceStakePerBlock > currentStake) {
                // skip
                staker = nextMaintenanceStaker[staker];
                currentStake = getMaintenanceStakerStake(staker);
            } else {
                startBlock +=
                    stakes[currentMaintenanceStaker] /
                    maintenanceStakePerBlock;
                staker = nextMaintenanceStaker[staker];
                currentStake = getMaintenanceStakerStake(staker);
            }
        }
    }

    function addDelegate(address forStaker, address delegate) external {
        require(
            msg.sender == forStaker ||
                maintenanceDelegateTo[forStaker][msg.sender],
            "msg.sender not authorized to delegate for staker"
        );
        maintenanceDelegateTo[forStaker][delegate] = true;
    }

    function removeDelegate(address forStaker, address delegate) external {
        require(
            msg.sender == forStaker ||
                maintenanceDelegateTo[forStaker][msg.sender],
            "msg.sender not authorized to delegate for staker"
        );
        maintenanceDelegateTo[forStaker][delegate] = false;
    }

    function isAuthorizedStaker(address caller)
        public
        returns (bool isAuthorized)
    {
        address currentStaker = getUpdatedCurrentStaker();
        isAuthorized =
            currentStaker == caller ||
            maintenanceDelegateTo[currentStaker][caller];
    }

    function penalizeMaintenanceStake(
        address maintainer,
        uint256 penalty,
        address recipient
    ) external returns (uint256 stakeTaken) {
        require(
            isStakePenalizer(msg.sender),
            "msg.sender not authorized to penalize stakers"
        );
        if (penalty > stakes[maintainer]) {
            stakeTaken = stakes[maintainer];
        } else {
            stakeTaken = penalty;
        }
        _withdrawStake(maintainer, stakeTaken, recipient);
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
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Fund.sol";
import "./Lending.sol";
import "./RoleAware.sol";
import "./MarginRouter.sol";
import "./PriceAware.sol";

// Goal: all external functions only accessible to margintrader role
// except for view functions of course

struct CrossMarginAccount {
    uint256 lastDepositBlock;
    address[] borrowTokens;
    // borrowed token address => amount
    mapping(address => uint256) borrowed;
    // borrowed token => yield quotient
    mapping(address => uint256) borrowedYieldQuotientsFP;
    address[] holdingTokens;
    // token held in portfolio => amount
    mapping(address => uint256) holdings;
    // boolean value of whether an account holds a token
    mapping(address => bool) holdsToken;
}

abstract contract CrossMarginAccounts is RoleAware, PriceAware {
    /// @dev gets used in calculating how much accounts can borrow
    uint256 public leverage;

    /// @dev percentage of assets held per assets borrowed at which to liquidate
    uint256 public liquidationThresholdPercent;

    /// @dev record of all cross margin accounts
    mapping(address => CrossMarginAccount) marginAccounts;
    /// @dev total token caps
    mapping(address => uint256) public tokenCaps;
    /// @dev tracks total of short positions per token
    mapping(address => uint256) public totalShort;
    /// @dev tracks total of long positions per token
    mapping(address => uint256) public totalLong;
    uint256 public coolingOffPeriod;

    /// @dev view function to display account held assets state
    function getHoldingAmounts(address trader)
        external
        view
        returns (
            address[] memory holdingTokens,
            uint256[] memory holdingAmounts
        )
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        holdingTokens = account.holdingTokens;

        holdingAmounts = new uint256[](account.holdingTokens.length);
        for (uint256 idx = 0; holdingTokens.length > idx; idx++) {
            address tokenAddress = holdingTokens[idx];
            holdingAmounts[idx] = account.holdings[tokenAddress];
        }

        (holdingTokens, holdingAmounts);
    }

    /// @dev view function to display account borrowing state
    function getBorrowAmounts(address trader)
        external
        view
        returns (address[] memory borrowTokens, uint256[] memory borrowAmounts)
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        borrowTokens = account.borrowTokens;

        borrowAmounts = new uint256[](account.borrowTokens.length);
        for (uint256 idx = 0; borrowTokens.length > idx; idx++) {
            address tokenAddress = borrowTokens[idx];
            borrowAmounts[idx] = Lending(lending()).viewBorrowInterest(
                account.borrowed[tokenAddress],
                tokenAddress,
                account.borrowedYieldQuotientsFP[tokenAddress]
            );
        }

        (borrowTokens, borrowAmounts);
    }

    /// @dev last time this account deposited
    /// relevant for withdrawal window
    function getLastDepositBlock(address trader)
        external
        view
        returns (uint256)
    {
        return marginAccounts[trader].lastDepositBlock;
    }

    /// @dev add an asset to be held by account
    function addHolding(
        CrossMarginAccount storage account,
        address token,
        uint256 depositAmount
    ) internal {
        if (!hasHoldingToken(account, token)) {
            account.holdingTokens.push(token);
        }

        account.holdings[token] += depositAmount;
    }

    /// @dev adjust account to reflect borrowing of token amount
    function borrow(
        CrossMarginAccount storage account,
        address borrowToken,
        uint256 borrowAmount
    ) internal {
        if (!hasBorrowedToken(account, borrowToken)) {
            account.borrowTokens.push(borrowToken);
        } else {
            account.borrowed[borrowToken] = Lending(lending())
                .applyBorrowInterest(
                account.borrowed[borrowToken],
                borrowToken,
                account.borrowedYieldQuotientsFP[borrowToken]
            );
        }
        account.borrowedYieldQuotientsFP[borrowToken] = Lending(lending())
            .viewBorrowingYieldFP(borrowToken);

        account.borrowed[borrowToken] += borrowAmount;
        addHolding(account, borrowToken, borrowAmount);

        require(positiveBalance(account), "Can't borrow: insufficient balance");
    }

    /// @dev checks whether account is in the black, deposit + earnings relative to borrowed
    function positiveBalance(CrossMarginAccount storage account)
        internal
        returns (bool)
    {
        uint256 loan = loanInPeg(account, false);
        uint256 holdings = holdingsInPeg(account, false);
        // The following condition should hold:
        // holdings / loan >= leverage / (leverage - 1)
        // =>
        return holdings * (leverage - 1) >= loan * leverage;
    }

    /// @dev internal function adjusting holding and borrow balances when debt extinguished
    function extinguishDebt(
        CrossMarginAccount storage account,
        address debtToken,
        uint256 extinguishAmount
    ) internal {
        // will throw if insufficient funds
        account.borrowed[debtToken] = Lending(lending()).applyBorrowInterest(
            account.borrowed[debtToken],
            debtToken,
            account.borrowedYieldQuotientsFP[debtToken]
        );

        account.borrowed[debtToken] =
            account.borrowed[debtToken] -
            extinguishAmount;
        account.holdings[debtToken] =
            account.holdings[debtToken] -
            extinguishAmount;

        if (account.borrowed[debtToken] > 0) {
            account.borrowedYieldQuotientsFP[debtToken] = Lending(lending())
                .viewBorrowingYieldFP(debtToken);
        }
    }

    /// @dev checks whether an account holds a token
    function hasHoldingToken(CrossMarginAccount storage account, address token)
        internal
        view
        returns (bool)
    {
        return account.holdsToken[token];
    }

    /// @dev checks whether an account has borrowed a token
    function hasBorrowedToken(CrossMarginAccount storage account, address token)
        internal
        view
        returns (bool)
    {
        return account.borrowedYieldQuotientsFP[token] > 0;
    }

    /// @dev calculate total loan in reference currency, including compound interest
    function loanInPeg(CrossMarginAccount storage account, bool forceCurBlock)
        internal
        returns (uint256)
    {
        return
            sumTokensInPegWithYield(
                account.borrowTokens,
                account.borrowed,
                account.borrowedYieldQuotientsFP,
                forceCurBlock
            );
    }

    /// @dev total of assets of account, expressed in reference currency
    function holdingsInPeg(
        CrossMarginAccount storage account,
        bool forceCurBlock
    ) internal returns (uint256) {
        return
            sumTokensInPeg(
                account.holdingTokens,
                account.holdings,
                forceCurBlock
            );
    }

    /// @dev check whether an account can/should be liquidated
    function belowMaintenanceThreshold(CrossMarginAccount storage account)
        internal
        returns (bool)
    {
        uint256 loan = loanInPeg(account, true);
        uint256 holdings = holdingsInPeg(account, true);
        // The following should hold:
        // holdings / loan >= 1.1
        // => holdings >= loan * 1.1
        return 100 * holdings >= liquidationThresholdPercent * loan;
    }

    /// @dev go through list of tokens and their amounts, summing up
    function sumTokensInPeg(
        address[] storage tokens,
        mapping(address => uint256) storage amounts,
        bool forceCurBlock
    ) internal returns (uint256 totalPeg) {
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            address token = tokens[tokenId];
            totalPeg += PriceAware.getCurrentPriceInPeg(
                token,
                amounts[token],
                forceCurBlock
            );
        }
    }

    /// @dev go through list of tokens and ammounts, summing up with interest
    function sumTokensInPegWithYield(
        address[] storage tokens,
        mapping(address => uint256) storage amounts,
        mapping(address => uint256) storage yieldQuotientsFP,
        bool forceCurBlock
    ) internal returns (uint256 totalPeg) {
        for (uint256 tokenId = 0; tokenId < tokens.length; tokenId++) {
            address token = tokens[tokenId];
            totalPeg += yieldTokenInPeg(
                token,
                amounts[token],
                yieldQuotientsFP,
                forceCurBlock
            );
        }
    }

    /// @dev calculate yield for token amount and convert to reference currency
    function yieldTokenInPeg(
        address token,
        uint256 amount,
        mapping(address => uint256) storage yieldQuotientsFP,
        bool forceCurBlock
    ) internal returns (uint256) {
        uint256 yieldFP = Lending(lending()).viewBorrowingYieldFP(token);
        // 1 * FP / FP = 1
        uint256 amountInToken = (amount * yieldFP) / yieldQuotientsFP[token];
        return
            PriceAware.getCurrentPriceInPeg(
                token,
                amountInToken,
                forceCurBlock
            );
    }

    /// @dev move tokens from one holding to another
    function adjustAmounts(
        CrossMarginAccount storage account,
        address fromToken,
        address toToken,
        uint256 soldAmount,
        uint256 boughtAmount
    ) internal {
        account.holdings[fromToken] = account.holdings[fromToken] - soldAmount;
        addHolding(account, toToken, boughtAmount);
    }

    /// sets borrow and holding to zero
    function deleteAccount(CrossMarginAccount storage account) internal {
        for (
            uint256 borrowIdx = 0;
            account.borrowTokens.length > borrowIdx;
            borrowIdx++
        ) {
            address borrowToken = account.borrowTokens[borrowIdx];
            totalShort[borrowToken] -= account.borrowed[borrowToken];
            account.borrowed[borrowToken] = 0;
            account.borrowedYieldQuotientsFP[borrowToken] = 0;
        }
        for (
            uint256 holdingIdx = 0;
            account.holdingTokens.length > holdingIdx;
            holdingIdx++
        ) {
            address holdingToken = account.holdingTokens[holdingIdx];
            totalLong[holdingToken] -= account.holdings[holdingToken];
            account.holdings[holdingToken] = 0;
            account.holdsToken[holdingToken] = false;
        }
        delete account.borrowTokens;
        delete account.holdingTokens;
    }

    /// @dev minimum
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./CrossMarginAccounts.sol";

/// @dev Handles liquidation of accounts below maintenance threshold
/// Liquidation can be called by the authorized staker, as determined
/// in the Admin contract.
/// If the authorized staker is delinquent, other participants can jump
/// in and attack, taking their fees and potentially even their stake,
/// depending how delinquent the responsible authorized staker is.
abstract contract CrossMarginLiquidation is CrossMarginAccounts {
    event LiquidationShortfall(uint256 amount);
    event AccountLiquidated(address account);

    struct Liquidation {
        uint256 buy;
        uint256 sell;
        uint256 blockNum;
    }

    /// record kept around until a stake attacker can claim their reward
    struct AccountLiqRecord {
        uint256 blockNum;
        address loser;
        uint256 amount;
        address stakeAttacker;
    }

    mapping(address => Liquidation) liquidationAmounts;
    address[] sellTokens;
    address[] buyTokens;
    address[] tradersToLiquidate;

    mapping(address => uint256) public maintenanceFailures;
    mapping(address => AccountLiqRecord) public stakeAttackRecords;
    uint256 public avgLiquidationPerBlock = 10;

    uint256 public liqStakeAttackWindow = 5;
    uint256 public MAINTAINER_CUT_PERCENT = 5;

    uint256 public failureThreshold = 10;

    function setFailureThreshold(uint256 threshFactor) external onlyOwner {
        failureThreshold = threshFactor;
    }

    function setLiqStakeAttackWindow(uint256 window) external onlyOwner {
        liqStakeAttackWindow = window;
    }

    function setMaintainerCutPercent(uint256 cut) external onlyOwner {
        MAINTAINER_CUT_PERCENT = cut;
    }

    /// @dev calcLiquidationamounts does a number of tasks in this contract
    /// and some of them are not straightforward.
    /// First of all it aggregates liquidation amounts in storage (not in memory)
    /// owing to the fact that arrays can't be pushed to and hash maps don't
    /// exist in memory.
    /// Then it also returns any stake attack funds if the stake was unsuccessful
    /// (i.e. current caller is authorized). Also see context below.
    function calcLiquidationAmounts(
        address[] memory liquidationCandidates,
        bool isAuthorized
    ) internal returns (uint256 attackReturns) {
        sellTokens = new address[](0);
        buyTokens = new address[](0);
        tradersToLiquidate = new address[](0);

        for (
            uint256 traderIndex = 0;
            liquidationCandidates.length > traderIndex;
            traderIndex++
        ) {
            address traderAddress = liquidationCandidates[traderIndex];
            CrossMarginAccount storage account = marginAccounts[traderAddress];
            if (belowMaintenanceThreshold(account)) {
                tradersToLiquidate.push(traderAddress);
                for (
                    uint256 sellIdx = 0;
                    account.holdingTokens.length > sellIdx;
                    sellIdx++
                ) {
                    address token = account.holdingTokens[sellIdx];
                    Liquidation storage liquidation = liquidationAmounts[token];

                    if (liquidation.blockNum != block.number) {
                        liquidation.sell = account.holdings[token];
                        liquidation.buy = 0;
                        liquidation.blockNum = block.number;
                        sellTokens.push(token);
                    } else {
                        liquidation.sell += account.holdings[token];
                    }
                }
                for (
                    uint256 buyIdx = 0;
                    account.borrowTokens.length > buyIdx;
                    buyIdx++
                ) {
                    address token = account.borrowTokens[buyIdx];
                    Liquidation storage liquidation = liquidationAmounts[token];

                    uint256 loanAmount =
                        Lending(lending()).applyBorrowInterest(
                            account.borrowed[token],
                            token,
                            account.borrowedYieldQuotientsFP[token]
                        );

                    Lending(lending()).payOff(token, loanAmount);

                    if (liquidation.blockNum != block.number) {
                        liquidation.sell = 0;
                        liquidation.buy = loanAmount;
                        liquidation.blockNum = block.number;
                        buyTokens.push(token);
                    } else {
                        liquidation.buy += loanAmount;
                    }
                }
            }

            AccountLiqRecord storage liqAttackRecord =
                stakeAttackRecords[traderAddress];
            if (isAuthorized) {
                attackReturns += _disburseLiqAttack(liqAttackRecord);
            }
        }
    }

    function _disburseLiqAttack(AccountLiqRecord storage liqAttackRecord)
        internal
        returns (uint256 returnAmount)
    {
        if (liqAttackRecord.amount > 0) {
            // validate attack records, if any
            uint256 blockDiff =
                min(
                    block.number - liqAttackRecord.blockNum,
                    liqStakeAttackWindow
                );

            uint256 attackerCut =
                (liqAttackRecord.amount * blockDiff) / liqStakeAttackWindow;

            Fund(fund()).withdraw(
                PriceAware.peg,
                liqAttackRecord.stakeAttacker,
                attackerCut
            );

            Admin a = Admin(admin());
            uint256 penalty =
                (a.maintenanceStakePerBlock() * attackerCut) /
                    avgLiquidationPerBlock;
            a.penalizeMaintenanceStake(
                liqAttackRecord.loser,
                penalty,
                liqAttackRecord.stakeAttacker
            );

            liqAttackRecord.amount = 0;
            liqAttackRecord.stakeAttacker = address(0);
            liqAttackRecord.blockNum = 0;
            liqAttackRecord.loser = address(0);

            returnAmount -= attackerCut;
        }
    }

    function disburseLiqStakeAttacks(address[] memory liquidatedAccounts)
        external
    {
        for (uint256 i = 0; liquidatedAccounts.length > i; i++) {
            AccountLiqRecord storage liqAttackRecord =
                stakeAttackRecords[liquidatedAccounts[i]];
            if (
                block.number > liqAttackRecord.blockNum + liqStakeAttackWindow
            ) {
                _disburseLiqAttack(liqAttackRecord);
            }
        }
    }

    function liquidateFromPeg() internal returns (uint256 pegAmount) {
        for (uint256 tokenIdx = 0; buyTokens.length > tokenIdx; tokenIdx++) {
            address buyToken = buyTokens[tokenIdx];
            Liquidation storage liq = liquidationAmounts[buyToken];
            if (liq.buy > liq.sell) {
                pegAmount += PriceAware.liquidateToPeg(
                    buyToken,
                    liq.buy - liq.sell
                );
                delete liquidationAmounts[buyToken];
            }
        }
        delete buyTokens;
    }

    function liquidateToPeg() internal returns (uint256 pegAmount) {
        for (
            uint256 tokenIndex = 0;
            sellTokens.length > tokenIndex;
            tokenIndex++
        ) {
            address token = sellTokens[tokenIndex];
            Liquidation storage liq = liquidationAmounts[token];
            if (liq.sell > liq.buy) {
                uint256 sellAmount = liq.sell - liq.buy;
                pegAmount += PriceAware.liquidateToPeg(token, sellAmount);
                delete liquidationAmounts[token];
            }
        }
        delete sellTokens;
    }

    function maintainerIsFailing() internal view returns (bool) {
        (address currentMaintainer, ) =
            Admin(admin()).viewCurrentMaintenanceStaker();
        return
            maintenanceFailures[currentMaintainer] >
            failureThreshold * avgLiquidationPerBlock;
    }

    /// called by maintenance stakers to liquidate accounts below liquidation threshold
    function liquidate(address[] memory liquidationCandidates)
        external
        returns (uint256 maintainerCut)
    {
        bool isAuthorized = Admin(admin()).isAuthorizedStaker(msg.sender);
        bool canTakeNow = isAuthorized || maintainerIsFailing();

        // calcLiquidationAmounts does a lot of the work here
        // * aggregates both sell and buy side targets to be liquidated
        // * returns attacker cuts to them
        // * aggregates any returned fees from unauthorized (attacking) attempts
        uint256 attackReturns2Authorized =
            calcLiquidationAmounts(liquidationCandidates, isAuthorized);
        maintainerCut = attackReturns2Authorized;

        uint256 sale2pegAmount = liquidateToPeg();
        uint256 peg2targetCost = liquidateFromPeg();

        // this may be a bit imprecise, since individual shortfalls may be obscured
        // by overall returns and the maintainer cut is taken out of the net total,
        // but it gives us the general picture
        if (
            (peg2targetCost * (100 + MAINTAINER_CUT_PERCENT)) / 100 >
            sale2pegAmount
        ) {
            emit LiquidationShortfall(peg2targetCost - sale2pegAmount);
        }

        address loser = address(0);
        if (!canTakeNow) {
            // whoever is the current responsible maintenance staker
            // and liable to lose their stake
            loser = Admin(admin()).getUpdatedCurrentStaker();
        }

        // iterate over traders and send back their money
        // as well as giving attackers their due, in case caller isn't authorized
        for (
            uint256 traderIdx = 0;
            tradersToLiquidate.length > traderIdx;
            traderIdx++
        ) {
            address traderAddress = tradersToLiquidate[traderIdx];
            CrossMarginAccount storage account = marginAccounts[traderAddress];

            uint256 holdingsValue = holdingsInPeg(account, true);
            uint256 borrowValue = loanInPeg(account, true);
            // 5% of value borrowed
            uint256 maintainerCut4Account =
                (borrowValue * MAINTAINER_CUT_PERCENT) / 100;
            maintainerCut += maintainerCut4Account;

            if (!canTakeNow) {
                // This could theoretically lead to a previous attackers
                // record being overwritten, but only if the trader restarts
                // their account and goes back into the red within the short time window
                // which would be a costly attack requiring collusion without upside
                AccountLiqRecord storage liqAttackRecord =
                    stakeAttackRecords[traderAddress];
                liqAttackRecord.amount = maintainerCut4Account;
                liqAttackRecord.stakeAttacker = msg.sender;
                liqAttackRecord.blockNum = block.number;
                liqAttackRecord.loser = loser;
            }

            // send back trader money
            if (holdingsValue >= maintainerCut4Account + borrowValue) {
                // send remaining funds back to trader
                Fund(fund()).withdraw(
                    PriceAware.peg,
                    traderAddress,
                    holdingsValue - borrowValue - maintainerCut4Account
                );
            }

            emit AccountLiquidated(traderAddress);
            deleteAccount(account);
        }

        avgLiquidationPerBlock =
            (avgLiquidationPerBlock * 99 + maintainerCut) /
            100;

        address currentMaintainer = Admin(admin()).getUpdatedCurrentStaker();
        if (isAuthorized) {
            if (maintenanceFailures[currentMaintainer] > maintainerCut) {
                maintenanceFailures[currentMaintainer] -= maintainerCut;
            } else {
                maintenanceFailures[currentMaintainer] = 0;
            }
        } else {
            maintenanceFailures[currentMaintainer] += maintainerCut;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Fund.sol";
import "./Lending.sol";
import "./RoleAware.sol";
import "./MarginRouter.sol";
import "./CrossMarginLiquidation.sol";

// Goal: all external functions only accessible to margintrader role
// except for view functions of course

contract CrossMarginTrading is CrossMarginLiquidation, IMarginTrading {
    constructor(address _peg, address _roles)
        RoleAware(_roles)
        PriceAware(_peg)
    {
        liquidationThresholdPercent = 110;
        coolingOffPeriod = 20;
    }

    /// @dev admin function to set the token cap
    function setTokenCap(address token, uint256 cap) external {
        require(
            isTokenActivator(msg.sender),
            "Caller not authorized to set token cap"
        );
        tokenCaps[token] = cap;
    }

    /// @dev setter for cooling off period for withdrawing funds after deposit
    function setCoolingOffPeriod(uint256 blocks) external onlyOwner {
        coolingOffPeriod = blocks;
    }

    /// @dev admin function to set leverage
    function setLeverage(uint256 _leverage) external onlyOwner {
        leverage = _leverage;
    }

    /// @dev admin function to set liquidation threshold
    function setLiquidationThresholdPercent(uint256 threshold)
        external
        onlyOwner
    {
        liquidationThresholdPercent = threshold;
    }

    /// @dev gets called by router to affirm a deposit to an account
    function registerDeposit(
        address trader,
        address token,
        uint256 depositAmount
    ) external override returns (uint256 extinguishableDebt) {
        require(
            isMarginTrader(msg.sender),
            "Calling contract not authorized to deposit"
        );

        CrossMarginAccount storage account = marginAccounts[trader];
        if (account.borrowed[token] > 0) {
            extinguishableDebt = min(depositAmount, account.borrowed[token]);
            extinguishDebt(account, token, extinguishableDebt);
            totalShort[token] -= extinguishableDebt;
        }
        // no overflow because depositAmount >= extinguishableDebt
        uint256 addedHolding = depositAmount - extinguishableDebt;
        addHolding(account, token, addedHolding);

        totalLong[token] += addedHolding;
        require(
            tokenCaps[token] >= totalLong[token],
            "Exceeding global exposure cap to token -- try again later"
        );

        account.lastDepositBlock = block.number;
    }

    /// @dev gets called by router to affirm isolated borrowing event
    function registerBorrow(
        address trader,
        address borrowToken,
        uint256 borrowAmount
    ) external override {
        require(
            isMarginTrader(msg.sender),
            "Calling contract not authorized to deposit"
        );
        totalShort[borrowToken] += borrowAmount;
        totalLong[borrowToken] += borrowAmount;
        require(
            tokenCaps[borrowToken] >= totalShort[borrowToken] &&
                tokenCaps[borrowToken] >= totalLong[borrowToken],
            "Exceeding global exposure cap to token -- try again later"
        );

        CrossMarginAccount storage account = marginAccounts[trader];
        borrow(account, borrowToken, borrowAmount);
    }

    /// @dev gets called by router to affirm withdrawal of tokens from account
    function registerWithdrawal(
        address trader,
        address withdrawToken,
        uint256 withdrawAmount
    ) external override {
        require(
            isMarginTrader(msg.sender),
            "Calling contract not authorized to deposit"
        );
        CrossMarginAccount storage account = marginAccounts[trader];
        require(
            block.number > account.lastDepositBlock + coolingOffPeriod,
            "To prevent attacks you must wait until your cooling off period is over to withdraw"
        );

        totalLong[withdrawToken] -= withdrawAmount;
        // throws on underflow
        account.holdings[withdrawToken] =
            account.holdings[withdrawToken] -
            withdrawAmount;
        require(
            positiveBalance(account),
            "Account balance is too low to withdraw"
        );
    }

    /// @dev gets callled by router to register a trade and borrow and extinguis as necessary
    function registerTradeAndBorrow(
        address trader,
        address tokenFrom,
        address tokenTo,
        uint256 inAmount,
        uint256 outAmount
    )
        external
        override
        returns (uint256 extinguishableDebt, uint256 borrowAmount)
    {
        require(
            isMarginTrader(msg.sender),
            "Calling contract is not an authorized margin trader agent"
        );

        CrossMarginAccount storage account = marginAccounts[trader];

        if (account.borrowed[tokenTo] > 0) {
            extinguishableDebt = min(outAmount, account.borrowed[tokenTo]);
            extinguishDebt(account, tokenTo, extinguishableDebt);
            totalShort[tokenTo] -= extinguishableDebt;
        }
        totalLong[tokenFrom] -= inAmount;
        totalLong[tokenTo] += outAmount - extinguishableDebt;
        require(
            tokenCaps[tokenTo] >= totalLong[tokenTo],
            "Exceeding global exposure cap to token -- try again later"
        );

        uint256 sellAmount = inAmount;
        if (inAmount > account.holdings[tokenFrom]) {
            sellAmount = account.holdings[tokenFrom];
            /// won't overflow
            borrowAmount = inAmount - sellAmount;

            totalShort[tokenFrom] += borrowAmount;
            require(
                tokenCaps[tokenFrom] >= totalShort[tokenFrom],
                "Exceeding global exposure cap to token -- try again later"
            );

            borrow(account, tokenFrom, borrowAmount);
        }
        adjustAmounts(account, tokenFrom, tokenTo, sellAmount, outAmount);
    }

    /// @dev can get called by router to register the dissolution of an account
    function registerLiquidation(address trader) external override {
        require(
            isMarginTrader(msg.sender),
            "Calling contract is not an authorized margin trader agent"
        );

        CrossMarginAccount storage account = marginAccounts[trader];
        for (uint24 i = 0; account.borrowTokens.length > i; i++) {
            address token = account.borrowTokens[i];
            Lending(lending()).payOff(token, account.borrowed[token]);
        }

        deleteAccount(account);
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

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";

import "./RoleAware.sol";
import "./Fund.sol";
import "../interfaces/IMarginTrading.sol";
import "./Lending.sol";
import "./Admin.sol";
import "./IncentivizedHolder.sol";

contract MarginRouter is RoleAware, IncentivizedHolder, Ownable {
    /// different uniswap compatible factories to talk to
    mapping(address => bool) public factories;
    /// wrapped ETH ERC20 contract
    address public WETH;
    address public constant UNI = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant SUSHI = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    /// emitted when a trader depoits on cross margin
    event CrossDeposit(
        address trader,
        address depositToken,
        uint256 depositAmount
    );
    /// emitted whenever a trade happens
    event CrossTrade(
        address trader,
        address inToken,
        uint256 inTokenAmount,
        uint256 inTokenBorrow,
        address outToken,
        uint256 outTokenAmount,
        uint256 outTokenExtinguish
    );
    /// emitted when a trader withdraws funds
    event CrossWithdraw(
        address trader,
        address withdrawToken,
        uint256 withdrawAmount
    );
    /// emitted upon sucessfully borrowing
    event CrossBorrow(
        address trader,
        address borrowToken,
        uint256 borrowAmount
    );

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Trade has expired");
        _;
    }

    constructor(address _WETH, address _roles) RoleAware(_roles) {
        factories[UNI] = true;
        factories[SUSHI] = true;

        WETH = _WETH;
    }

    function authorizeAMM(address ammFactory) external onlyOwner {
        factories[ammFactory] = true;
    }

    /// @dev traders call this to deposit funds on cross margin
    function crossDeposit(address depositToken, uint256 depositAmount)
        external
    {
        require(
            Fund(fund()).depositFor(msg.sender, depositToken, depositAmount),
            "Cannot transfer deposit to margin account"
        );
        uint256 extinguishAmount =
            IMarginTrading(marginTrading()).registerDeposit(
                msg.sender,
                depositToken,
                depositAmount
            );
        if (extinguishAmount > 0) {
            Lending(lending()).payOff(depositToken, extinguishAmount);
            withdrawClaim(msg.sender, depositToken, extinguishAmount);
        }
        emit CrossDeposit(msg.sender, depositToken, depositAmount);
    }

    /// @dev deposit wrapped ehtereum into cross margin account
    function crossDepositETH() external payable {
        Fund(fund()).depositToWETH{value: msg.value}();
        uint256 extinguishAmount =
            IMarginTrading(marginTrading()).registerDeposit(
                msg.sender,
                WETH,
                msg.value
            );
        if (extinguishAmount > 0) {
            Lending(lending()).payOff(WETH, extinguishAmount);
            withdrawClaim(msg.sender, WETH, extinguishAmount);
        }
        emit CrossDeposit(msg.sender, WETH, msg.value);
    }

    /// @dev withdraw deposits/earnings from cross margin account
    function crossWithdraw(address withdrawToken, uint256 withdrawAmount)
        external
    {
        IMarginTrading(marginTrading()).registerWithdrawal(
            msg.sender,
            withdrawToken,
            withdrawAmount
        );
        require(
            Fund(fund()).withdraw(withdrawToken, msg.sender, withdrawAmount),
            "Could not withdraw from fund"
        );
        emit CrossWithdraw(msg.sender, withdrawToken, withdrawAmount);
    }

    /// @dev withdraw ethereum from cross margin account
    function crossWithdrawETH(uint256 withdrawAmount) external {
        IMarginTrading(marginTrading()).registerWithdrawal(
            msg.sender,
            WETH,
            withdrawAmount
        );
        Fund(fund()).withdrawETH(msg.sender, withdrawAmount);
    }

    /// @dev borrow into cross margin trading account
    function crossBorrow(address borrowToken, uint256 borrowAmount) external {
        Lending(lending()).registerBorrow(borrowToken, borrowAmount);
        IMarginTrading(marginTrading()).registerBorrow(
            msg.sender,
            borrowToken,
            borrowAmount
        );

        stakeClaim(msg.sender, borrowToken, borrowAmount);
        emit CrossBorrow(msg.sender, borrowToken, borrowAmount);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        address factory,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0
                    ? (uint256(0), amountOut)
                    : (amountOut, uint256(0));
            address to =
                i < path.length - 2
                    ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                    : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @dev internal helper swapping exact token for token on AMM
    function _swapExactT4T(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) internal returns (uint256[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "MarginRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        require(
            Fund(fund()).withdraw(
                path[0],
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            ),
            "MarginRouter: Insufficient lending funds"
        );
        _swap(factory, amounts, path, fund());
    }

    /// @dev external function to make swaps on AMM using protocol funds, only for authorized contracts
    function authorizedSwapExactT4T(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external returns (uint256[] memory) {
        require(
            isAuthorizedFundTrader(msg.sender),
            "Calling contract is not authorized to trade with protocl funds"
        );
        return _swapExactT4T(factory, amountIn, amountOutMin, path);
    }

    // @dev internal helper swapping exact token for token on on AMM
    function _swapT4ExactT(
        address factory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    ) internal returns (uint256[] memory amounts) {
        // TODO minimum trade?
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "MarginRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        require(
            Fund(fund()).withdraw(
                path[0],
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            ),
            "MarginRouter: Insufficient lending funds"
        );
        _swap(factory, amounts, path, fund());
    }

    //// @dev external function for swapping protocol funds on AMM, only for authorized
    function authorizedSwapT4ExactT(
        address factory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    ) external returns (uint256[] memory) {
        require(
            isAuthorizedFundTrader(msg.sender),
            "Calling contract is not authorized to trade with protocl funds"
        );
        return _swapT4ExactT(factory, amountOut, amountInMax, path);
    }

    /// @dev entry point for swapping tokens held in cross margin account
    function crossSwapExactTokensForTokens(
        address ammFactory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        // calc fees
        uint256 fees =
            Admin(feeController()).subtractTradingFees(path[0], amountIn);

        requireAuthorizedAMM(ammFactory);
        // swap
        amounts = _swapExactT4T(
            ammFactory,
            amountIn - fees,
            amountOutMin,
            path
        );

        registerTrade(
            msg.sender,
            path[0],
            path[path.length - 1],
            amountIn,
            amounts[amounts.length - 1]
        );
    }

    /// @dev entry point for swapping tokens held in cross margin account
    function crossSwapTokensForExactTokens(
        address ammFactory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        // calc fees
        uint256 fees =
            Admin(feeController()).addTradingFees(
                path[path.length - 1],
                amountOut
            );

        requireAuthorizedAMM(ammFactory);
        // swap
        amounts = _swapT4ExactT(
            ammFactory,
            amountOut + fees,
            amountInMax,
            path
        );

        registerTrade(
            msg.sender,
            path[0],
            path[path.length - 1],
            amounts[0],
            amountOut
        );
    }

    /// @dev helper function does all the work of telling other contracts
    /// about a trade
    function registerTrade(
        address trader,
        address inToken,
        address outToken,
        uint256 inAmount,
        uint256 outAmount
    ) internal {
        (uint256 extinguishAmount, uint256 borrowAmount) =
            IMarginTrading(marginTrading()).registerTradeAndBorrow(
                trader,
                inToken,
                outToken,
                inAmount,
                outAmount
            );
        if (extinguishAmount > 0) {
            Lending(lending()).payOff(outToken, extinguishAmount);
            withdrawClaim(trader, outToken, extinguishAmount);
        }
        if (borrowAmount > 0) {
            Lending(lending()).registerBorrow(inToken, borrowAmount);
            stakeClaim(trader, inToken, borrowAmount);
        }

        emit CrossTrade(
            trader,
            inToken,
            inAmount,
            borrowAmount,
            outToken,
            outAmount,
            extinguishAmount
        );
    }

    function getAmountsOut(
        address factory,
        uint256 inAmount,
        address[] calldata path
    ) external view returns (uint256[] memory) {
        return UniswapV2Library.getAmountsOut(factory, inAmount, path);
    }

    function getAmountsIn(
        address factory,
        uint256 outAmount,
        address[] calldata path
    ) external view returns (uint256[] memory) {
        return UniswapV2Library.getAmountsIn(factory, outAmount, path);
    }

    function requireAuthorizedAMM(address ammFactory) internal view {
        require(
            ammFactory == UNI || ammFactory == SUSHI || factories[ammFactory],
            "Not using an authorized AMM"
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./MarginRouter.sol";

/// Stores how many of token you could get for 1k of peg
struct TokenPrice {
    uint256 blockLastUpdated;
    uint256 tokenPer1k;
    address[] liquidationPath;
    address[] inverseLiquidationPath;
}

abstract contract PriceAware is Ownable, RoleAware {
    address public constant UNI = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public peg;
    mapping(address => TokenPrice) public tokenPrices;
    /// update window in blocks
    uint16 public priceUpdateWindow = 8;
    uint256 public TEPID_UPDATE_RATE_PERMIL = 20;
    uint256 public CONFIDENT_UPDATE_RATE_PERMIL = 650;
    uint256 UPDATE_MAX_PEG_AMOUNT = 50_000;
    uint256 UPDATE_MIN_PEG_AMOUNT = 1_000;

    constructor(address _peg) Ownable() {
        peg = _peg;
    }

    function setPriceUpdateWindow(uint16 window) external onlyOwner {
        priceUpdateWindow = window;
    }

    function setTepidUpdateRate(uint256 rate) external onlyOwner {
        TEPID_UPDATE_RATE_PERMIL = rate;
    }

    function setConfidentUpdateRate(uint256 rate) external onlyOwner {
        CONFIDENT_UPDATE_RATE_PERMIL = rate;
    }

    function forcePriceUpdate(address token, uint256 inAmount)
        public
        returns (uint256)
    {
        return getUpdatedPriceInPeg(token, inAmount);
    }

    function setUpdateMaxPegAmount(uint256 amount) external onlyOwner {
        UPDATE_MAX_PEG_AMOUNT = amount;
    }

    function setUpdateMinPegAmount(uint256 amount) external onlyOwner {
        UPDATE_MIN_PEG_AMOUNT = amount;
    }

    function getCurrentPriceInPeg(
        address token,
        uint256 inAmount,
        bool forceCurBlock
    ) internal returns (uint256) {
        TokenPrice storage tokenPrice = tokenPrices[token];
        if (
            block.number - tokenPrice.blockLastUpdated > priceUpdateWindow ||
            (forceCurBlock && block.number != tokenPrice.blockLastUpdated) ||
            tokenPrice.tokenPer1k == 0
        ) {
            return getUpdatedPriceInPeg(token, inAmount);
        } else {
            return (inAmount * 1000 ether) / tokenPrice.tokenPer1k;
        }
    }

    function getUpdatedPriceInPeg(address token, uint256 inAmount)
        internal
        virtual
        returns (uint256)
    {
        if (token == peg) {
            return inAmount;
        } else {
            TokenPrice storage tokenPrice = tokenPrices[token];
            uint256[] memory pathAmounts =
                MarginRouter(router()).getAmountsOut(
                    UNI,
                    inAmount,
                    tokenPrice.liquidationPath
                );
            uint256 outAmount = pathAmounts[pathAmounts.length - 1];

            if (
                outAmount > UPDATE_MIN_PEG_AMOUNT &&
                outAmount < UPDATE_MAX_PEG_AMOUNT
            ) {
                confidentUpdatePriceInPeg(tokenPrice, inAmount, outAmount);
            }

            return outAmount;
        }
    }

    // /// Do a tepid update of price coming from a potentially unreliable source
    // function tepidUpdatePriceInPeg(
    //     address token,
    //     uint256 inAmount,
    //     uint256 outAmount
    // ) internal {
    //     _updatePriceInPeg(
    //         tokenPrices[token],
    //         inAmount,
    //         outAmount,
    //         TEPID_UPDATE_RATE_PERMIL
    //     );
    // }

    function confidentUpdatePriceInPeg(
        TokenPrice storage tokenPrice,
        uint256 inAmount,
        uint256 outAmount
    ) internal {
        _updatePriceInPeg(
            tokenPrice,
            inAmount,
            outAmount,
            CONFIDENT_UPDATE_RATE_PERMIL
        );
        tokenPrice.blockLastUpdated = block.number;
    }

    function _updatePriceInPeg(
        TokenPrice storage tokenPrice,
        uint256 inAmount,
        uint256 outAmount,
        uint256 weightPerMil
    ) internal {
        uint256 updatePer1k = (1000 ether * inAmount) / (outAmount + 1);
        tokenPrice.tokenPer1k =
            (tokenPrice.tokenPer1k *
                (1000 - weightPerMil) +
                updatePer1k *
                weightPerMil) /
            1000;
    }

    // add path from token to current liquidation peg
    function setLiquidationPath(address[] memory path) external {
        require(
            isTokenActivator(msg.sender),
            "not authorized to set lending cap"
        );
        address token = path[0];
        tokenPrices[token].liquidationPath = new address[](path.length);
        tokenPrices[token].inverseLiquidationPath = new address[](path.length);

        for (uint16 i = 0; path.length > i; i++) {
            tokenPrices[token].liquidationPath[i] = path[i];
            tokenPrices[token].inverseLiquidationPath[i] = path[
                path.length - i - 1
            ];
        }
        uint256[] memory pathAmounts =
            MarginRouter(router()).getAmountsIn(UNI, 1000 ether, path);
        uint256 inAmount = pathAmounts[0];
        _updatePriceInPeg(tokenPrices[token], inAmount, 1000 ether, 1000);
    }

    function liquidateToPeg(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (token == peg) {
            return amount;
        } else {
            TokenPrice storage tP = tokenPrices[token];
            uint256[] memory amounts =
                MarginRouter(router()).authorizedSwapExactT4T(
                    UNI,
                    amount,
                    0,
                    tP.liquidationPath
                );

            uint256 outAmount = amounts[amounts.length - 1];
            confidentUpdatePriceInPeg(tP, amount, outAmount);

            return outAmount;
        }
    }

    function liquidateFromPeg(address token, uint256 targetAmount)
        internal
        returns (uint256)
    {
        if (token == peg) {
            return targetAmount;
        } else {
            TokenPrice storage tP = tokenPrices[token];
            uint256[] memory amounts =
                MarginRouter(router()).authorizedSwapT4ExactT(
                    UNI,
                    targetAmount,
                    type(uint256).max,
                    tP.inverseLiquidationPath
                );

            confidentUpdatePriceInPeg(tP, targetAmount, amounts[0]);

            return amounts[0];
        }
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

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./IncentiveDistribution.sol";
import "./Fund.sol";
import "./CrossMarginTrading.sol";
import "./MarginRouter.sol";
import "../interfaces/IDelegateOwner.sol";

/// @dev A helper contract to manage the initialization of new tokens
/// across different parts of the protocol, as well as changing some
/// parameters throughout the lifetime of a token
contract TokenAdmin is RoleAware, Ownable, IDelegateOwner {
    uint256 public totalLendingTargetPortion;
    uint256 public totalBorrowingTargetPortion;
    address[] public incentiveTokens;
    mapping(address => uint256) public tokenWeights;
    uint256 public totalTokenWeights;
    mapping(address => uint8) public tokenLendingTranches;
    mapping(address => uint8) public tokenBorrowingTranches;
    uint8 public nextTrancheIndex = 20;

    uint256 public initHourlyYieldAPRPercent = 10;

    // TODO give this contract ownership of incentive distribution
    // during deploy after everything else is incentivized
    constructor(
        uint256 lendingTargetPortion,
        uint256 borrowingTargetPortion,
        address _roles
    ) RoleAware(_roles) Ownable() {
        totalLendingTargetPortion = lendingTargetPortion;
        totalBorrowingTargetPortion = borrowingTargetPortion;
    }

    function activateToken(
        address token,
        uint256 exposureCap,
        uint256 lendingBuffer,
        uint256 incentiveWeight,
        address[] memory liquidationPath
    ) external onlyOwner {
        require(!Fund(fund()).activeTokens(token), "Token already is active");

        Fund(fund()).activateToken(token);
        CrossMarginTrading(marginTrading()).setTokenCap(token, exposureCap);
        Lending(lending()).setLendingCap(token, exposureCap);
        Lending(lending()).setLendingBuffer(token, lendingBuffer);
        Lending(lending()).setHourlyYieldAPR(token, initHourlyYieldAPRPercent);
        Lending(lending()).initBorrowYieldAccumulator(token);

        if (incentiveWeight > 0) {
            totalTokenWeights += incentiveWeight;
            tokenWeights[token] = incentiveWeight;
            IncentiveDistribution iD =
                IncentiveDistribution(incentiveDistributor());

            // init lending
            uint256 lendingShare =
                calcTrancheShare(incentiveWeight, totalLendingTargetPortion);
            iD.initTranche(nextTrancheIndex, lendingShare);
            tokenLendingTranches[token] = nextTrancheIndex;
            Lending(lending()).setIncentiveTranche(token, nextTrancheIndex);
            nextTrancheIndex++;

            // init borrowing
            uint256 borrowingShare =
                calcTrancheShare(incentiveWeight, totalBorrowingTargetPortion);
            iD.initTranche(nextTrancheIndex, borrowingShare);
            tokenBorrowingTranches[token] = nextTrancheIndex;
            MarginRouter(router()).setIncentiveTranche(token, nextTrancheIndex);
            nextTrancheIndex++;

            updateIncentiveShares(iD);
            incentiveTokens.push(token);

            require(
                liquidationPath[0] == token &&
                    liquidationPath[liquidationPath.length - 1] ==
                    CrossMarginTrading(marginTrading()).peg(),
                "Invalid liquidationPath -- should go from token to peg"
            );
            CrossMarginTrading(marginTrading()).setLiquidationPath(
                liquidationPath
            );
        }
    }

    function changeTokenCap(address token, uint256 exposureCap)
        external
        onlyOwner
    {
        Lending(lending()).setLendingCap(token, exposureCap);
        CrossMarginTrading(marginTrading()).setTokenCap(token, exposureCap);
    }

    function changeTokenIncentiveWeight(address token, uint256 tokenWeight)
        external
        onlyOwner
    {
        totalTokenWeights =
            totalTokenWeights +
            tokenWeight -
            tokenWeights[token];
        tokenWeights[token] = tokenWeight;

        updateIncentiveShares(IncentiveDistribution(incentiveDistributor()));
    }

    function changeLendingBuffer(address token, uint256 lendingBuffer)
        external
        onlyOwner
    {
        Lending(lending()).setLendingBuffer(token, lendingBuffer);
    }

    //function changeBondLendingWeights(address token, uint256[] memory weights) external onlyOwner {
    //    Lending(lending()).setRuntimeWeights(token, weights);
    //}

    function updateIncentiveShares(IncentiveDistribution iD) internal {
        for (uint8 i = 0; incentiveTokens.length > i; i++) {
            address incentiveToken = incentiveTokens[i];
            uint256 tokenWeight = tokenWeights[incentiveToken];
            uint256 lendingShare =
                calcTrancheShare(tokenWeight, totalLendingTargetPortion);
            iD.setTrancheShare(
                tokenLendingTranches[incentiveToken],
                lendingShare
            );

            uint256 borrowingShare =
                calcTrancheShare(tokenWeight, totalBorrowingTargetPortion);
            iD.setTrancheShare(
                tokenBorrowingTranches[incentiveToken],
                borrowingShare
            );
        }
    }

    function calcTrancheShare(uint256 incentiveWeight, uint256 targetPortion)
        internal
        view
        returns (uint256)
    {
        return (incentiveWeight * targetPortion) / totalTokenWeights;
    }

    function setLendingTargetPortion(uint256 portion) external onlyOwner {
        totalLendingTargetPortion = portion;
    }

    function setBorrowingTargetPortion(uint256 portion) external onlyOwner {
        totalBorrowingTargetPortion = portion;
    }

    function changeHourlyYieldAPR(address token, uint256 aprPercent)
        external
        onlyOwner
    {
        Lending(lending()).setHourlyYieldAPR(token, aprPercent);
    }

    function setInitHourlyYieldAPR(uint256 value) external onlyOwner {
        initHourlyYieldAPRPercent = value;
    }

    function relinquishOwnership(address property, address newOwner)
        external
        override
        onlyOwner
    {
        Ownable(property).transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

interface IDelegateOwner {
    function relinquishOwnership(address property, address newOwner) external;
}

// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

interface IMarginTrading {
    function registerDeposit(
        address trader,
        address token,
        uint256 amount
    ) external returns (uint256 extinguishAmount);

    function registerWithdrawal(
        address trader,
        address token,
        uint256 amount
    ) external;

    function registerBorrow(
        address trader,
        address token,
        uint256 amount
    ) external;

    function registerTradeAndBorrow(
        address trader,
        address inToken,
        address outToken,
        uint256 inAmount,
        uint256 outAmount
    ) external returns (uint256 extinguishAmount, uint256 borrowAmount);

    function registerLiquidation(address trader) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) - 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}