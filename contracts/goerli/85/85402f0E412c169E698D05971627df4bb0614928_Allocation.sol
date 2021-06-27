// SPDX-License-Identifier: MIT AND AGPLv3
// File: @openzeppelin/contracts/math/SafeMath.sol


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/common/Constants.sol

pragma solidity >=0.6.0 <0.7.0;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint8 public constant DEFAULT_DECIMALS = 18; // GToken and Controller use this decimals
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR = uint256(10)**CURVE_RATIO_DECIMALS;
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/interfaces/IController.sol

pragma solidity >=0.6.0 <0.7.0;

interface IController {
    function stablecoins() external view returns (address[3] memory);

    function vaults() external view returns (address[3] memory);

    function underlyingVaults(uint256 i) external view returns (address vault);

    function curveVault() external view returns (address);

    function pnl() external view returns (address);

    function insurance() external view returns (address);

    function lifeGuard() external view returns (address);

    function buoy() external view returns (address);

    function reward() external view returns (address);

    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function emergencyHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);

    function emergencyState() external view returns (bool);

    function deadCoin() external view returns (uint256);

    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external;

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external;

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external;

    function getUserAssets(bool pwrd, address account) external view returns (uint256 deductUsd);

    function referrals(address account) external view returns (address);

    function addReferral(address account, address referral) external;

    function getStrategiesTargetRatio() external view returns (uint256[] memory);

    function withdrawalFee(bool pwrd) external view returns (uint256);

    function validGTokenDecrease(uint256 amount) external view returns (bool);
}

// File: contracts/interfaces/IPausable.sol

pragma solidity >=0.6.0 <0.7.0;

interface IPausable {
    function paused() external view returns (bool);
}

// File: contracts/common/Controllable.sol

pragma solidity >=0.6.0 <0.7.0;




contract Controllable is Ownable {
    address public controller;

    event ChangeController(address indexed oldController, address indexed newController);

    /// Modifier to make a function callable only when the contract is not paused.
    /// Requirements:
    /// - The contract must not be paused.
    modifier whenNotPaused() {
        require(!_pausable().paused(), "Pausable: paused");
        _;
    }

    /// Modifier to make a function callable only when the contract is paused
    /// Requirements:
    /// - The contract must be paused
    modifier whenPaused() {
        require(_pausable().paused(), "Pausable: not paused");
        _;
    }

    /// @notice Returns true if the contract is paused, and false otherwise
    function ctrlPaused() public view returns (bool) {
        return _pausable().paused();
    }

    function setController(address newController) external onlyOwner {
        require(newController != address(0), "setController: !0x");
        address oldController = controller;
        controller = newController;
        emit ChangeController(oldController, newController);
    }

    function _controller() internal view returns (IController) {
        require(controller != address(0), "Controller not set");
        return IController(controller);
    }

    function _pausable() internal view returns (IPausable) {
        require(controller != address(0), "Controller not set");
        return IPausable(controller);
    }
}

// File: contracts/interfaces/IERC20Detailed.sol

pragma solidity >=0.6.0 <0.7.0;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/common/StructDefinitions.sol

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

struct SystemState {
    uint256 totalCurrentAssetsUsd;
    uint256 curveCurrentAssetsUsd;
    uint256 lifeguardCurrentAssetsUsd;
    uint256[3] vaultCurrentAssets;
    uint256[3] vaultCurrentAssetsUsd;
    uint256 rebalanceThreshold;
    uint256 utilisationRatio;
    uint256 targetBuffer;
    uint256[3] stablePercents;
    uint256 curvePercent;
}

struct ExposureState {
    uint256[3] stablecoinExposure;
    uint256[] protocolExposure;
    uint256 curveExposure;
    bool stablecoinExposed;
    bool protocolExposed;
}

struct AllocationState {
    uint256[] strategyTargetRatio;
    bool needProtocolWithdrawal;
    uint256 protocolExposedIndex;
    uint256[3] protocolWithdrawalUsd;
    StablecoinAllocationState stableState;
}

struct StablecoinAllocationState {
    uint256 swapInTotalAmountUsd;
    uint256[3] swapInAmounts;
    uint256[3] swapInAmountsUsd;
    uint256[3] swapOutPercents;
    uint256[3] vaultsTargetUsd;
    uint256 curveTargetUsd;
    uint256 curveTargetDeltaUsd;
}

// File: contracts/interfaces/IAllocation.sol

pragma solidity >=0.6.0 <0.7.0;


interface IAllocation {
    function calcSystemTargetDelta(SystemState calldata sysState, ExposureState calldata expState)
        external
        view
        returns (AllocationState memory allState);

    function calcVaultTargetDelta(SystemState calldata sysState, bool onlySwapOut)
        external
        view
        returns (StablecoinAllocationState memory stableState);

    function calcStrategyPercent(uint256 utilisationRatio) external pure returns (uint256[] memory);
}

// File: contracts/interfaces/ILifeGuard.sol

pragma solidity >=0.6.0 <0.7.0;

// LP -> Liquidity pool token
interface ILifeGuard {
    function assets(uint256 i) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function getAssets() external view returns (uint256[3] memory);

    function totalAssetsUsd() external view returns (uint256);

    function availableUsd() external view returns (uint256 dollar);

    function availableLP() external view returns (uint256);

    function depositStable(bool rebalance) external returns (uint256);

    function investToCurveVault() external;

    function distributeCurveVault(uint256 amount, uint256[3] memory delta) external returns (uint256[3] memory);

    function deposit() external returns (uint256 usdAmount);

    function withdrawSingleByLiquidity(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external returns (uint256 usdAmount, uint256 amount);

    function withdrawSingleByExchange(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external returns (uint256 usdAmount, uint256 amount);

    function invest(uint256 whaleDepositAmount, uint256[3] calldata delta) external returns (uint256 dollarAmount);

    function getBuoy() external view returns (address);

    function investSingle(
        uint256[3] calldata inAmounts,
        uint256 i,
        uint256 j
    ) external returns (uint256 dollarAmount);

    function investToCurveVaultTrigger() external view returns (bool _invest);
}

// File: contracts/interfaces/IVault.sol

pragma solidity >=0.6.0 <0.7.0;

interface IVault {
    function withdraw(uint256 amount) external;

    function withdraw(uint256 amount, address recipient) external;

    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external;

    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external;

    function deposit(uint256 amount) external;

    function updateStrategyRatio(uint256[] calldata strategyRetios) external;

    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);

    function vault() external view returns (address);

    function investTrigger() external view returns (bool);

    function invest() external;
}

// File: contracts/interfaces/IBuoy.sol

pragma solidity >=0.6.0 <0.7.0;

interface IBuoy {
    function safetyCheck() external view returns (bool);

    function updateRatios() external returns (bool);

    function updateRatiosWithTolerance(uint256 tolerance) external returns (bool);

    function lpToUsd(uint256 inAmount) external view returns (uint256);

    function usdToLp(uint256 inAmount) external view returns (uint256);

    function stableToUsd(uint256[3] calldata inAmount, bool deposit) external view returns (uint256);

    function stableToLp(uint256[3] calldata inAmount, bool deposit) external view returns (uint256);

    function singleStableFromLp(uint256 inAmount, int128 i) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function singleStableFromUsd(uint256 inAmount, int128 i) external view returns (uint256);

    function singleStableToUsd(uint256 inAmount, uint256 i) external view returns (uint256);
}

// File: contracts/insurance/Allocation.sol

pragma solidity >=0.6.0 <0.7.0;









/// @notice Contract for setting allocation targets for current protocol setup.
///     This contract will need to be upgraded if strategies in the protocol change.
///     --------------------------------------------------------
///     Current protocol setup:
///     --------------------------------------------------------
///     Stablecoins: DAI, USDC, USDT
///     LP tokens: 3Crv
///     Vaults: DAIVault, USDCVault, USDTVault, 3Crv vault
///     Strategy (exposures):
///         - Compound
///         - Idle finance
///         - Yearn Generic Lender:
///             - Cream
///         - CurveXpool:
///             - Curve3Pool
///             - CurveMetaPool
///             - Yearn
contract Allocation is Constants, Controllable, IAllocation {
    using SafeMath for uint256;

    // Threshold used to make sure that small change in token value don't trigger rebalances
    uint256 public swapThreshold;
    // Threshold for determining if assets should be moved from the Curve vault
    uint256 public curvePercentThreshold;

    event LogNewSwapThreshold(uint256 threshold);
    event LogNewCurveThreshold(uint256 threshold);

    function setSwapThreshold(uint256 _swapThreshold) external onlyOwner {
        swapThreshold = _swapThreshold;
        emit LogNewSwapThreshold(_swapThreshold);
    }

    function setCurvePercentThreshold(uint256 _curvePercentThreshold) external onlyOwner {
        curvePercentThreshold = _curvePercentThreshold;
        emit LogNewCurveThreshold(_curvePercentThreshold);
    }

    /// @notice Calculate the difference between the protocol target allocations and
    ///     the actual protocol exposures (refered to as delta). This is used to determine
    ///     how the system needs to be rebalanced in the case that its getting close to being
    ///     overexposed.
    /// @param sysState Struct holding system state info
    /// @param expState Struct holding exposure state info
    function calcSystemTargetDelta(SystemState memory sysState, ExposureState memory expState)
        public
        view
        override
        returns (AllocationState memory allState)
    {
        // Strategy targets in stablecoin vaults are determined by the pwrd/gvt utilisationRatio
        allState.strategyTargetRatio = calcStrategyPercent(sysState.utilisationRatio);
        // Curve target is determined by governance (insurance - curveVaultPercent)
        allState.stableState = _calcVaultTargetDelta(sysState, false, true);
        // Calculate exposure delta - difference between targets and current assets
        (uint256 protocolExposedDeltaUsd, uint256 protocolExposedIndex) = calcProtocolExposureDelta(
            expState.protocolExposure,
            sysState
        );
        allState.protocolExposedIndex = protocolExposedIndex;
        if (protocolExposedDeltaUsd > allState.stableState.swapInTotalAmountUsd) {
            // If the rebalance cannot be achieved by simply moving assets from one vault, the
            // system needs to establish how to withdraw assets from all vaults and their
            // underlying strategies. Calculate protocol withdrawals based on all vaults,
            // each strategy above target withdraws: delta of current assets - target assets
            allState.needProtocolWithdrawal = true;
            allState.protocolWithdrawalUsd = calcProtocolWithdraw(allState, protocolExposedIndex);
        }
    }

    /// @notice Calculate the difference between target allocations for vault, and
    ///     actual exposures
    /// @param sysState Struct holding system state info
    /// @param onlySwapOut Calculation only for moving assets out of vault
    function calcVaultTargetDelta(SystemState memory sysState, bool onlySwapOut)
        public
        view
        override
        returns (StablecoinAllocationState memory)
    {
        return _calcVaultTargetDelta(sysState, onlySwapOut, false);
    }

    /// @notice Calculate how much assets should be moved out of strategies
    /// @param allState Struct holding system allocation info
    /// @param protocolExposedIndex Index of protocol for which exposures is being calculated
    /// @dev Protocol exposures are considered on their highest level - This means
    ///     that we can consider each strategy to have one exposure, even though they
    ///     might have several lower level exposures. For this to be true, the following
    ///     assumptions need to be true:
    ///     - Exposure overlap cannot occure among strategies:
    ///         - Strategies can't share protocol exposures. If two strategies are exposed
    ///             to Compound, the system level exposure to Compound may be higher than
    ///             the sum exposure of any individual strategy, e.g.:
    ///             Consider the following 2 strategies:
    ///                 - Strat A: Invest to protocol X
    ///                 - Strat B: Invest to protocol X and Y, through protocol Z
    ///             There is now a possibility that the total exposure to protocol X is higher
    ///             than the tolerated exposure level, and thus there would have to be
    ///             seperate logic to split out the exposure calculations in strat B
    ///             If on the other hand we have the following scenario:
    ///                 - Strat A: Invest to protocol X
    ///                 - Strat B: Invets to protocol Y, through protocol Z
    ///             We no longer need to consider the underlying exposures, but can rather look
    ///             at the total investment into the strategies as our current exposure
    ///     - Strategies in different vaults need to be ordered based on their exposure:
    ///         - To simplify the calculations, the order of strategies in vaults is important,
    ///             as the protocol exposures are addative for each strategy
    function calcProtocolWithdraw(AllocationState memory allState, uint256 protocolExposedIndex)
        private
        view
        returns (uint256[N_COINS] memory protocolWithdrawalUsd)
    {
        address[N_COINS] memory vaults = _controller().vaults();
        // How much to withdraw from each protocol
        uint256 strategyCurrentUsd;
        uint256 strategyTargetUsd;
        ILifeGuard lg = ILifeGuard(_controller().lifeGuard());
        IBuoy buoy = IBuoy(lg.getBuoy());
        // Loop over each vault
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 strategyAssets = IVault(vaults[i]).getStrategyAssets(protocolExposedIndex);
            // If the strategy has assets, determine the USD value of the asset
            if (strategyAssets > 0) {
                strategyCurrentUsd = buoy.singleStableToUsd(strategyAssets, i);
            }
            // Determine the USD value of the strategy asset target
            strategyTargetUsd = allState
            .stableState
            .vaultsTargetUsd[i]
            .mul(allState.strategyTargetRatio[protocolExposedIndex])
            .div(PERCENTAGE_DECIMAL_FACTOR);
            // If the strategy is over exposed, assets can be removed
            if (strategyCurrentUsd > strategyTargetUsd) {
                protocolWithdrawalUsd[i] = strategyCurrentUsd.sub(strategyTargetUsd);
            }
            // If the strategy is empty or under exposed, assets can be added
            if (protocolWithdrawalUsd[i] > 0 && protocolWithdrawalUsd[i] < allState.stableState.swapInAmountsUsd[i]) {
                protocolWithdrawalUsd[i] = allState.stableState.swapInAmountsUsd[i];
            }
        }
    }

    /// @notice Calculate how much assets should be moved in or out of vaults
    /// @param sysState Struct holding info about current system state
    /// @param onlySwapOut Do assets only need to be added to the vaults
    /// @param includeCurveVault Does the Curve vault need to considered in the rebalance
    function _calcVaultTargetDelta(
        SystemState memory sysState,
        bool onlySwapOut,
        bool includeCurveVault
    ) private view returns (StablecoinAllocationState memory stableState) {
        ILifeGuard lg = ILifeGuard(_controller().lifeGuard());
        IBuoy buoy = IBuoy(lg.getBuoy());

        uint256 amountToRebalance;
        // The rebalance may only be possible by moving assets out of the Curve vault,
        //  as Curve adds exposure to all stablecoins
        if (includeCurveVault && needCurveVault(sysState)) {
            stableState.curveTargetUsd = sysState.totalCurrentAssetsUsd.mul(sysState.curvePercent).div(
                PERCENTAGE_DECIMAL_FACTOR
            );
            // Estimate how much needs to be moved out of the Curve vault
            amountToRebalance = sysState.totalCurrentAssetsUsd.sub(stableState.curveTargetUsd);
            // When establishing current Curve exposures, we include uninvested assets in the lifeguard
            // as part of the Curve vault, otherwise I rebalance could temporarily fix an overexposure,
            // just to have to deal with the same overexposure when the lifeguard assets get invested
            // into the Curve vault.
            uint256 curveCurrentAssetsUsd = sysState.lifeguardCurrentAssetsUsd.add(sysState.curveCurrentAssetsUsd);
            stableState.curveTargetDeltaUsd = curveCurrentAssetsUsd > stableState.curveTargetUsd
                ? curveCurrentAssetsUsd.sub(stableState.curveTargetUsd)
                : 0;
        } else {
            // If we dont have to consider the Curve vault, Remove Curve assets and the part in lifeguard for Curve
            // from the rebalance calculations
            amountToRebalance = sysState
            .totalCurrentAssetsUsd
            .sub(sysState.curveCurrentAssetsUsd)
            .sub(sysState.lifeguardCurrentAssetsUsd)
            .add(lg.availableUsd());
        }

        // Calculate the strategy amount by vaultAssets * percentOfStrategy
        uint256 swapOutTotalUsd = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            // Compare allocation targets with actual assets in vault -
            //   if onlySwapOut = True, we don't consider the the current assets in the vault,
            //   but rather how much we need to remove from the vault based on target allocations.
            //   This means that the removal amount gets split throughout the vaults based on
            //   the allocation targets, rather than the difference between the allocation target
            //   and the actual amount of assets in the vault.
            uint256 vaultTargetUsd = amountToRebalance.mul(sysState.stablePercents[i]).div(PERCENTAGE_DECIMAL_FACTOR);
            uint256 vaultTargetAssets;
            if (!onlySwapOut) {
                vaultTargetAssets = vaultTargetUsd == 0 ? 0 : buoy.singleStableFromUsd(vaultTargetUsd, int128(i));
                stableState.vaultsTargetUsd[i] = vaultTargetUsd;
            }

            // More than target
            if (sysState.vaultCurrentAssetsUsd[i] > vaultTargetUsd) {
                if (!onlySwapOut) {
                    stableState.swapInAmounts[i] = sysState.vaultCurrentAssets[i].sub(vaultTargetAssets);
                    stableState.swapInAmountsUsd[i] = sysState.vaultCurrentAssetsUsd[i].sub(vaultTargetUsd);
                    // Make sure that that the change in vault asset is large enough to
                    // justify rebalancing the vault
                    if (invalidDelta(swapThreshold, stableState.swapInAmountsUsd[i])) {
                        stableState.swapInAmounts[i] = 0;
                        stableState.swapInAmountsUsd[i] = 0;
                    } else {
                        stableState.swapInTotalAmountUsd = stableState.swapInTotalAmountUsd.add(
                            stableState.swapInAmountsUsd[i]
                        );
                    }
                }
                // Less than target
            } else {
                stableState.swapOutPercents[i] = vaultTargetUsd.sub(sysState.vaultCurrentAssetsUsd[i]);
                // Make sure that that the change in vault asset is large enough to
                // justify rebalancing the vault
                if (invalidDelta(swapThreshold, stableState.swapOutPercents[i])) {
                    stableState.swapOutPercents[i] = 0;
                } else {
                    swapOutTotalUsd = swapOutTotalUsd.add(stableState.swapOutPercents[i]);
                }
            }
        }

        // Establish percentage (BP) amount for change in each vault
        uint256 percent = PERCENTAGE_DECIMAL_FACTOR;
        for (uint256 i = 0; i < N_COINS - 1; i++) {
            if (stableState.swapOutPercents[i] > 0) {
                stableState.swapOutPercents[i] = stableState.swapOutPercents[i].mul(PERCENTAGE_DECIMAL_FACTOR).div(
                    swapOutTotalUsd
                );
                percent = percent.sub(stableState.swapOutPercents[i]);
            }
        }
        stableState.swapOutPercents[N_COINS - 1] = percent;
    }

    /// @notice Calculate assets distribution to strategies
    /// @param utilisationRatio Ratio of gvt to pwrd
    /// @dev The distribution of assets between the primary and secondary
    ///     strategies are based on the pwrd/gvt utilisation ratio
    function calcStrategyPercent(uint256 utilisationRatio)
        public
        pure
        override
        returns (uint256[] memory targetPercent)
    {
        targetPercent = new uint256[](2);
        uint256 primaryTarget = PERCENTAGE_DECIMAL_FACTOR.mul(PERCENTAGE_DECIMAL_FACTOR).div(
            PERCENTAGE_DECIMAL_FACTOR.add(utilisationRatio)
        );

        targetPercent[0] = primaryTarget; // Primary
        targetPercent[1] = PERCENTAGE_DECIMAL_FACTOR // Secondary
        .sub(targetPercent[0]);
    }

    /// @notice Loops over the protocol exposures and calculate the delta between the exposure
    ///     and target threshold if the protocol is over exposed. For the Curve protocol, the delta is the
    ///     difference between the current exposure and target allocation.
    /// @param protocolExposure Exposure percent of protocols
    /// @param sysState Struct holding info of the systems current state
    /// @return protocolExposedDeltaUsd Difference between the overExposure and the target protocol exposure.
    ///     By defenition, only one protocol can exceed exposure in the current setup.
    /// @return protocolExposedIndex The index of the corresponding protocol of protocolDelta
    function calcProtocolExposureDelta(uint256[] memory protocolExposure, SystemState memory sysState)
        private
        pure
        returns (uint256 protocolExposedDeltaUsd, uint256 protocolExposedIndex)
    {
        for (uint256 i = 0; i < protocolExposure.length; i++) {
            // If the exposure is greater than the rebalance threshold...
            if (protocolExposedDeltaUsd == 0 && protocolExposure[i] > sysState.rebalanceThreshold) {
                // ...Calculate the delta between exposure and target
                uint256 target = sysState.rebalanceThreshold.sub(sysState.targetBuffer);
                protocolExposedDeltaUsd = protocolExposure[i].sub(target).mul(sysState.totalCurrentAssetsUsd).div(
                    PERCENTAGE_DECIMAL_FACTOR
                );
                protocolExposedIndex = i;
            }
        }
    }

    /// @notice Check if the change in a vault is above a certain threshold.
    ///     This stops a rebalance occurring from stablecoins going slightly off peg
    /// @param threshold Threshold for difference to be considered valid
    /// @param delta Difference between current exposure and target
    function invalidDelta(uint256 threshold, uint256 delta) private pure returns (bool) {
        return delta > 0 && threshold > 0 && delta < threshold.mul(DEFAULT_DECIMALS_FACTOR);
    }

    /// @notice Check if Curve vault needs to be considered in rebalance action
    /// @param sysState Struct holding info about system current state
    function needCurveVault(SystemState memory sysState) private view returns (bool) {
        uint256 currentPercent = sysState
        .curveCurrentAssetsUsd
        .add(sysState.lifeguardCurrentAssetsUsd)
        .mul(PERCENTAGE_DECIMAL_FACTOR)
        .div(sysState.totalCurrentAssetsUsd);
        return currentPercent > curvePercentThreshold;
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
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
  }
}