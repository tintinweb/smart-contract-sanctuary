// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./AloePredictions.sol";
import "./IncentiveVault.sol";

contract Factory is IncentiveVault {
    /// @dev The ALOE token used for staking
    address public immutable ALOE;

    /// @dev The Uniswap factory
    IUniswapV3Factory public immutable UNI_FACTORY;

    /// @dev A mapping from [token A][token B][fee tier] to Aloe predictions market. Note
    /// that order of token A/B doesn't matter
    mapping(address => mapping(address => mapping(uint24 => address))) public getMarket;

    /// @dev A mapping that indicates which addresses are Aloe predictions markets
    mapping(address => bool) public doesMarketExist;

    constructor(
        address _ALOE,
        IUniswapV3Factory _UNI_FACTORY,
        address _multisig
    ) IncentiveVault(_multisig) {
        ALOE = _ALOE;
        UNI_FACTORY = _UNI_FACTORY;
    }

    function createMarket(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address market) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        market = deploy(token0, token1, fee);

        doesMarketExist[market] = true;
        // Populate mapping such that token order doesn't matter
        getMarket[token0][token1][fee] = market;
        getMarket[token1][token0][fee] = market;
    }

    function deploy(
        address token0,
        address token1,
        uint24 fee
    ) private returns (address market) {
        IUniswapV3Pool pool = IUniswapV3Pool(UNI_FACTORY.getPool(token0, token1, fee));
        require(address(pool) != address(0), "Uni pool missing");

        market = address(
            new AloePredictions{salt: keccak256(abi.encode(token0, token1, fee))}(
                IERC20(ALOE),
                pool,
                IncentiveVault(address(this))
            )
        );
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./libraries/Equations.sol";
import "./libraries/FullMath.sol";
import "./libraries/Math.sol";
import "./libraries/TickMath.sol";
import "./libraries/UINT512.sol";

import "./interfaces/IAloePredictions.sol";

import "./AloePredictionsState.sol";
import "./IncentiveVault.sol";

/*
                                                                                                                        
                                                   #                                                                    
                                                  ###                                                                   
                                                  #####                                                                 
                               #                 #######                                *###*                           
                                ###             #########                         ########                              
                                #####         ###########                   ###########                                 
                                ########    ############               ############                                     
                                 ########    ###########         *##############                                        
                                ###########   ########      #################                                           
                                ############   ###      #################                                               
                                ############       ##################                                                   
                               #############    #################*         *#############*                              
                              ##############    #############      #####################################                
                             ###############   ####******      #######################*                                 
                           ################                                                                             
                         #################   *############################*                                             
                           ##############    ######################################                                     
                               ########    ################*                     **######*                              
                                   ###    ###                                                                           
                                                                                                                        
         ___       ___       ___       ___            ___       ___       ___       ___       ___       ___       ___   
        /\  \     /\__\     /\  \     /\  \          /\  \     /\  \     /\  \     /\  \     /\  \     /\  \     /\__\  
       /::\  \   /:/  /    /::\  \   /::\  \        /::\  \   /::\  \   /::\  \   _\:\  \    \:\  \   /::\  \   /:/  /  
      /::\:\__\ /:/__/    /:/\:\__\ /::\:\__\      /:/\:\__\ /::\:\__\ /::\:\__\ /\/::\__\   /::\__\ /::\:\__\ /:/__/   
      \/\::/  / \:\  \    \:\/:/  / \:\:\/  /      \:\ \/__/ \/\::/  / \/\::/  / \::/\/__/  /:/\/__/ \/\::/  / \:\  \   
        /:/  /   \:\__\    \::/  /   \:\/  /        \:\__\     /:/  /     \/__/   \:\__\    \/__/      /:/  /   \:\__\  
        \/__/     \/__/     \/__/     \/__/          \/__/     \/__/               \/__/               \/__/     \/__/  
*/

uint256 constant TWO_144 = 2**144;
uint256 constant TWO_80 = 2**80;
uint256 constant SQRT_6 = 2449;

/// @title Aloe predictions market
/// @author Aloe Capital LLC
contract AloePredictions is AloePredictionsState, IAloePredictions {
    using SafeERC20 for IERC20;
    using UINT512Math for UINT512;

    /// @dev The number of standard deviations to +/- from the mean when computing ground truth bounds
    uint256 public constant GROUND_TRUTH_STDDEV_SCALE = 2;

    /// @dev The minimum length of an epoch, in seconds. Epochs may be longer if no one calls `advance`
    uint32 public constant EPOCH_LENGTH_SECONDS = 3600;

    /// @dev The ALOE token used for staking
    IERC20 public immutable ALOE;

    /// @dev The Uniswap pair for which predictions should be made
    IUniswapV3Pool public immutable UNI_POOL;

    /// @dev The incentive vault to use for staking extras and `advance()` reward
    IncentiveVault public immutable INCENTIVE_VAULT;

    /// @dev For reentrancy check
    bool private locked;

    modifier lock() {
        require(!locked, "Aloe: Locked");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        IERC20 _ALOE,
        IUniswapV3Pool _UNI_POOL,
        IncentiveVault _INCENTIVE_VAULT
    ) AloePredictionsState() {
        ALOE = _ALOE;
        UNI_POOL = _UNI_POOL;
        INCENTIVE_VAULT = _INCENTIVE_VAULT;

        // Ensure we have an hour of data, assuming Uniswap interaction every 10 seconds
        _UNI_POOL.increaseObservationCardinalityNext(360);
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function current()
        external
        view
        override
        returns (
            bool,
            uint176,
            uint128,
            uint128
        )
    {
        require(epoch != 0, "Aloe: No data yet");

        uint176 mean = computeMean();
        (uint256 lower, uint256 upper) = computeSemivariancesAbout(mean);
        return (
            didInvertPrices,
            mean,
            // Each proposal is a uniform distribution aiming to be `GROUND_TRUTH_STDDEV_SCALE` sigma wide.
            // So we have to apply a scaling factor (sqrt(6)) to make results more gaussian.
            uint128((Math.sqrt(lower) * SQRT_6) / (1000 * GROUND_TRUTH_STDDEV_SCALE)),
            uint128((Math.sqrt(upper) * SQRT_6) / (1000 * GROUND_TRUTH_STDDEV_SCALE))
        );
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function epochExpectedEndTime() public view override returns (uint32) {
        unchecked {return epochStartTime + EPOCH_LENGTH_SECONDS;}
    }

    /// @inheritdoc IAloePredictionsActions
    function advance() external override lock {
        require(uint32(block.timestamp) > epochExpectedEndTime(), "Aloe: Too early");
        epochStartTime = uint32(block.timestamp);

        if (epoch != 0) {
            (Bounds memory groundTruth, bool shouldInvertPricesNext) = fetchGroundTruth();
            emit FetchedGroundTruth(groundTruth.lower, groundTruth.upper, didInvertPrices);

            summaries[epoch - 1].groundTruth = groundTruth;
            didInvertPrices = shouldInvertPrices;
            shouldInvertPrices = shouldInvertPricesNext;

            _consolidateAccumulators(epoch - 1);
        }

        epoch++;
        INCENTIVE_VAULT.claimAdvanceIncentive(address(ALOE), msg.sender);
        emit Advanced(epoch, uint32(block.timestamp));
    }

    /// @inheritdoc IAloePredictionsActions
    function submitProposal(
        uint176 lower,
        uint176 upper,
        uint80 stake
    ) external override lock returns (uint40 key) {
        require(ALOE.transferFrom(msg.sender, address(this), stake), "Aloe: Provide ALOE");

        key = _submitProposal(stake, lower, upper);
        _organizeProposals(key, stake);

        emit ProposalSubmitted(msg.sender, epoch, key, lower, upper, stake);
    }

    /// @inheritdoc IAloePredictionsActions
    function updateProposal(
        uint40 key,
        uint176 lower,
        uint176 upper
    ) external override {
        _updateProposal(key, lower, upper);
        emit ProposalUpdated(msg.sender, epoch, key, lower, upper);
    }

    /// @inheritdoc IAloePredictionsActions
    function claimReward(uint40 key, address[] calldata extras) external override lock {
        Proposal storage proposal = proposals[key];
        require(proposal.upper != 0, "Aloe: Nothing to claim");

        EpochSummary storage summary = summaries[proposal.epoch];
        require(summary.groundTruth.upper != 0, "Aloe: Need ground truth");

        uint256 lowerError =
            proposal.lower > summary.groundTruth.lower
                ? proposal.lower - summary.groundTruth.lower
                : summary.groundTruth.lower - proposal.lower;
        uint256 upperError =
            proposal.upper > summary.groundTruth.upper
                ? proposal.upper - summary.groundTruth.upper
                : summary.groundTruth.upper - proposal.upper;
        uint256 stakeTotal = summary.accumulators.stakeTotal;

        UINT512 memory temp;

        // Compute reward numerator
        // --> Start with sum of all squared errors
        UINT512 memory numer = summary.accumulators.sumOfSquaredBounds;
        // --> Subtract current proposal's squared error
        (temp.LS, temp.MS) = FullMath.square512(lowerError);
        (numer.LS, numer.MS) = numer.sub(temp.LS, temp.MS);
        (temp.LS, temp.MS) = FullMath.square512(upperError);
        (numer.LS, numer.MS) = numer.sub(temp.LS, temp.MS);
        // --> Weight entire numerator by proposal's stake
        (numer.LS, numer.MS) = numer.muls(proposal.stake);

        UINT512 memory denom = summary.accumulators.sumOfSquaredBoundsWeighted;

        // Now our 4 key numbers are available: numerLS, numerMS, denomLS, denomMS
        uint256 reward;
        if (denom.MS == 0 && denom.LS == 0) {
            // In this case, only 1 proposal was submitted
            reward = proposal.stake;
        } else if (denom.MS == 0) {
            // If denominator MS is 0, then numerator MS is 0 as well.
            // This keeps things simple:
            reward = FullMath.mulDiv(stakeTotal, numer.LS, denom.LS);
        } else {
            if (numer.LS != 0) {
                reward = 257 + FullMath.log2floor(denom.MS) - FullMath.log2floor(numer.LS);
                reward = reward < 80 ? stakeTotal / (2**reward) : 0;
            }
            if (numer.MS != 0) {
                reward += FullMath.mulDiv(
                    stakeTotal,
                    TWO_80 * numer.MS,
                    TWO_80 * denom.MS + FullMath.mulDiv(TWO_80, denom.LS, type(uint256).max)
                );
            }
        }

        require(ALOE.transfer(proposal.source, reward), "Aloe: failed to reward");
        if (extras.length != 0)
            INCENTIVE_VAULT.claimStakingIncentives(key, extras, proposal.source, uint80(reward), uint80(stakeTotal));
        emit ClaimedReward(proposal.source, proposal.epoch, key, uint80(reward));
        delete proposals[key];
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function computeMean() public view override returns (uint176 mean) {
        Accumulators memory accumulators = summaries[epoch - 1].accumulators;
        require(accumulators.stakeTotal != 0, "Aloe: No proposals with stake");

        uint256 denominator = accumulators.stake0thMomentRaw;
        // It's more gas efficient to read from memory copy
        uint40[NUM_PROPOSALS_TO_AGGREGATE] memory keysToAggregate = highestStakeKeys[(epoch - 1) % 2];

        unchecked {
            for (uint40 i = 0; i < NUM_PROPOSALS_TO_AGGREGATE && i < accumulators.proposalCount; i++) {
                Proposal storage proposal = proposals[keysToAggregate[i]];

                // These fit in uint176, using uint256 to avoid phantom overflow later on
                uint256 proposalCenter = (uint256(proposal.lower) + uint256(proposal.upper)) >> 1;
                uint256 proposalSpread = proposal.upper - proposal.lower;

                mean += uint176(FullMath.mulDiv(uint256(proposal.stake) * proposalSpread, proposalCenter, denominator));
            }
        }
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function computeSemivariancesAbout(uint176 center) public view override returns (uint256 lower, uint256 upper) {
        Accumulators memory accumulators = summaries[epoch - 1].accumulators;
        require(accumulators.stakeTotal != 0, "Aloe: No proposals with stake");

        uint256 denominator = 3 * accumulators.stake0thMomentRaw;
        uint256 x;
        uint256 y;
        // It's more gas efficient to read from memory copy
        uint40[NUM_PROPOSALS_TO_AGGREGATE] memory keysToAggregate = highestStakeKeys[(epoch - 1) % 2];

        unchecked {
            for (uint40 i = 0; i < NUM_PROPOSALS_TO_AGGREGATE && i < accumulators.proposalCount; i++) {
                Proposal storage proposal = proposals[keysToAggregate[i]];

                if (proposal.upper < center) {
                    // Proposal is entirely below the center
                    x = center - proposal.upper;
                    y = center - proposal.lower;
                    if (x > type(uint128).max) x = type(uint128).max;
                    if (y > type(uint128).max) y = type(uint128).max;

                    lower += uint176(
                        FullMath.mulDiv(
                            uint256(proposal.stake) * uint256(proposal.upper - proposal.lower),
                            x**2 + x * y + y**2,
                            denominator
                        )
                    );
                } else if (proposal.lower < center) {
                    // Proposal includes the center
                    x = proposal.upper - center;
                    y = center - proposal.lower;
                    if (x > type(uint128).max) x = type(uint128).max;
                    if (y > type(uint128).max) y = type(uint128).max;

                    lower += uint176(FullMath.mulDiv(uint256(proposal.stake) * y, y**2, denominator));
                    upper += uint176(FullMath.mulDiv(uint256(proposal.stake) * x, x**2, denominator));
                } else {
                    // Proposal is entirely above the center
                    x = proposal.upper - center;
                    y = proposal.lower - center;
                    if (x > type(uint128).max) x = type(uint128).max;
                    if (y > type(uint128).max) y = type(uint128).max;

                    upper += uint176(
                        FullMath.mulDiv(
                            uint256(proposal.stake) * uint256(proposal.upper - proposal.lower),
                            x**2 + x * y + y**2,
                            denominator
                        )
                    );
                }
            }
        }
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function fetchGroundTruth() public view override returns (Bounds memory bounds, bool shouldInvertPricesNext) {
        (int56[] memory tickCumulatives, ) = UNI_POOL.observe(selectedOracleTimetable());
        uint176 mean = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[9] - tickCumulatives[0]) / 3240));
        shouldInvertPricesNext = mean < TWO_80;

        // After accounting for possible inversion, compute mean price over the entire 54 minute period
        if (didInvertPrices) mean = type(uint160).max / mean;
        mean = uint176(FullMath.mulDiv(mean, mean, TWO_144));

        // stat will take on a few different statistical values
        // Here it's MAD (Mean Absolute Deviation), except not yet divided by number of samples
        uint184 stat;
        uint176 sample;

        for (uint8 i = 0; i < 9; i++) {
            sample = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[i + 1] - tickCumulatives[i]) / 360));

            // After accounting for possible inversion, compute mean price over a 6 minute period
            if (didInvertPrices) sample = type(uint160).max / sample;
            sample = uint176(FullMath.mulDiv(sample, sample, TWO_144));

            // Accumulate
            stat += sample > mean ? sample - mean : mean - sample;
        }

        // MAD = stat / n, here n = 10
        // STDDEV = MAD * sqrt(2/pi) for a normal distribution
        // We want bounds to be +/- G*stddev, so we have an additional factor of G here
        stat = uint176((uint256(stat) * GROUND_TRUTH_STDDEV_SCALE * 79788) / 1000000);
        // Compute mean +/- stat, but be careful not to overflow
        bounds.lower = mean > stat ? uint176(mean - stat) : 0;
        bounds.upper = uint184(mean) + stat > type(uint176).max ? type(uint176).max : uint176(mean + stat);
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function selectedOracleTimetable() public pure override returns (uint32[] memory secondsAgos) {
        secondsAgos = new uint32[](10);
        secondsAgos[0] = 3420;
        secondsAgos[1] = 3060;
        secondsAgos[2] = 2700;
        secondsAgos[3] = 2340;
        secondsAgos[4] = 1980;
        secondsAgos[5] = 1620;
        secondsAgos[6] = 1260;
        secondsAgos[7] = 900;
        secondsAgos[8] = 540;
        secondsAgos[9] = 180;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract IncentiveVault {
    using SafeERC20 for IERC20;

    /// @dev A mapping from predictions address to token address to incentive per epoch (amount)
    mapping(address => mapping(address => uint256)) public stakingIncentivesPerEpoch;

    /// @dev A mapping from predictions address to token address to incentive per advance (amount)
    mapping(address => mapping(address => uint256)) public advanceIncentives;

    /// @dev A mapping from unique hashes to claim status
    mapping(bytes32 => bool) public claimed;

    address immutable multisig;

    constructor(address _multisig) {
        multisig = _multisig;
    }

    function getClaimHash(
        address market,
        uint40 key,
        address token
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(market, key, token));
    }

    function didClaim(
        address market,
        uint40 key,
        address token
    ) public view returns (bool) {
        return claimed[getClaimHash(market, key, token)];
    }

    function setClaimed(
        address market,
        uint40 key,
        address token
    ) private {
        claimed[getClaimHash(market, key, token)] = true;
    }

    function transfer(address to, address token) external {
        require(msg.sender == multisig, "Not authorized");
        IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @notice Allows owner to set staking incentive amounts on a per-token per-market basis
     * @param market The predictions market to incentivize
     * @param token The token in which incentives should be denominated
     * @param incentivePerEpoch The maximum number of tokens to give out each epoch
     */
    function setStakingIncentive(
        address market,
        address token,
        uint256 incentivePerEpoch
    ) external {
        require(msg.sender == multisig, "Not authorized");
        stakingIncentivesPerEpoch[market][token] = incentivePerEpoch;
    }

    /**
     * @notice Allows a predictions contract to claim staking incentives on behalf of a user
     * @dev Should only be called once per proposal. And fails if vault has insufficient
     * funds to make good on incentives
     * @param key The key of the proposal for which incentives are being claimed
     * @param tokens An array of tokens for which incentives should be claimed
     * @param to The user to whom incentives should be sent
     * @param reward The preALOE reward earned by the user
     * @param stakeTotal The total amount of preALOE staked in the pertinent epoch
     */
    function claimStakingIncentives(
        uint40 key,
        address[] calldata tokens,
        address to,
        uint80 reward,
        uint80 stakeTotal
    ) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 incentivePerEpoch = stakingIncentivesPerEpoch[msg.sender][tokens[i]];
            if (incentivePerEpoch == 0) continue;

            if (didClaim(msg.sender, key, tokens[i])) continue;
            setClaimed(msg.sender, key, tokens[i]);

            IERC20(tokens[i]).safeTransfer(to, (incentivePerEpoch * uint256(reward)) / uint256(stakeTotal));
        }
    }

    /**
     * @notice Allows owner to set advance incentive amounts on a per-market basis
     * @param market The predictions market to incentivize
     * @param token The token in which incentives should be denominated
     * @param amount The number of tokens to give out on each `advance()`
     */
    function setAdvanceIncentive(
        address market,
        address token,
        uint80 amount
    ) external {
        require(msg.sender == multisig, "Not authorized");
        advanceIncentives[market][token] = amount;
    }

    /**
     * @notice Allows a predictions contract to claim advance incentives on behalf of a user
     * @param token The token for which incentive should be claimed
     * @param to The user to whom incentive should be sent
     */
    function claimAdvanceIncentive(address token, address to) external {
        uint256 amount = advanceIncentives[msg.sender][token];
        if (amount == 0) return;

        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./UINT512.sol";

library Equations {
    using UINT512Math for UINT512;

    /// @dev Computes both raw (LS0, MS0) and weighted (LS1, MS1) squared bounds for a proposal
    function eqn0(
        uint80 stake,
        uint176 lower,
        uint176 upper
    )
        internal
        pure
        returns (
            uint256 LS0,
            uint256 MS0,
            uint256 LS1,
            uint256 MS1
        )
    {
        unchecked {
            // square each bound
            (LS0, MS0) = FullMath.square512(lower);
            (LS1, MS1) = FullMath.square512(upper);
            // add squared bounds together
            LS0 = (LS0 >> 1) + (LS1 >> 1);
            (LS0, LS1) = FullMath.mul512(LS0, 2); // LS1 is now a carry bit
            MS0 += MS1 + LS1;
            // multiply by stake
            (LS1, MS1) = FullMath.mul512(LS0, stake);
            MS1 += MS0 * stake;
        }
    }

    /**
     * @notice A complicated equation used when computing rewards.
     * @param a One of `sumOfSquaredBounds` | `sumOfSquaredBoundsWeighted`
     * @param b One of `sumOfLowerBounds`   | `sumOfLowerBoundsWeighted`
     * @param c: One of `sumOfUpperBounds`  | `sumOfUpperBoundsWeighted`
     * @param d: One of `proposalCount`     | `stakeTotal`
     * @param lowerTrue: `groundTruth.lower`
     * @param upperTrue: `groundTruth.upper`
     * @return Output of Equation 1 from the whitepaper
     */
    function eqn1(
        UINT512 memory a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 lowerTrue,
        uint256 upperTrue
    ) internal pure returns (UINT512 memory) {
        UINT512 memory temp;

        (temp.LS, temp.MS) = FullMath.mul512(d * lowerTrue, lowerTrue);
        (a.LS, a.MS) = a.add(temp.LS, temp.MS);

        (temp.LS, temp.MS) = FullMath.mul512(d * upperTrue, upperTrue);
        (a.LS, a.MS) = a.add(temp.LS, temp.MS);

        (temp.LS, temp.MS) = FullMath.mul512(b, lowerTrue << 1);
        (a.LS, a.MS) = a.sub(temp.LS, temp.MS);

        (temp.LS, temp.MS) = FullMath.mul512(c, upperTrue << 1);
        (a.LS, a.MS) = a.sub(temp.LS, temp.MS);

        return a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // https://ethereum.stackexchange.com/a/96646
            uint256 twos = denominator & (~denominator + 1);
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// @dev https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// @dev Like `mul512`, but multiply a number by itself
    function square512(uint256 a) internal pure returns (uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, a, not(0))
            r0 := mul(a, a)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// @dev https://github.com/hifi-finance/prb-math/blob/main/contracts/PRBMathCommon.sol
    function log2floor(uint256 x) internal pure returns (uint256 msb) {
        unchecked {
            if (x >= 2**128) {
                x >>= 128;
                msb += 128;
            }
            if (x >= 2**64) {
                x >>= 64;
                msb += 64;
            }
            if (x >= 2**32) {
                x >>= 32;
                msb += 32;
            }
            if (x >= 2**16) {
                x >>= 16;
                msb += 16;
            }
            if (x >= 2**8) {
                x >>= 8;
                msb += 8;
            }
            if (x >= 2**4) {
                x >>= 4;
                msb += 4;
            }
            if (x >= 2**2) {
                x >>= 2;
                msb += 2;
            }
            if (x >= 2**1) {
                // No need to shift x any more.
                msb += 1;
            }
        }
    }

    /// @dev https://graphics.stanford.edu/~seander/bithacks.html#IntegerLogDeBruijn
    function log2ceil(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m, 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m, 0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m, 0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m, 0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m, 0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m, 0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m, 0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m, 0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        unchecked {
            if (y > 3) {
                z = y;
                uint256 x = y / 2 + 1;
                while (x < z) {
                    z = x;
                    x = (y / x + x) / 2;
                }
            } else if (y != 0) {
                z = 1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./FullMath.sol";

struct UINT512 {
    // Least significant bits
    uint256 LS;
    // Most significant bits
    uint256 MS;
}

library UINT512Math {
    /// @dev Adds an (LS, MS) pair in place. Assumes result fits in uint512
    function iadd(
        UINT512 storage self,
        uint256 LS,
        uint256 MS
    ) internal {
        unchecked {
            if (self.LS > type(uint256).max - LS) {
                self.LS = addmod(self.LS, LS, type(uint256).max);
                self.MS += 1 + MS;
            } else {
                self.LS += LS;
                self.MS += MS;
            }
        }
    }

    /// @dev Adds an (LS, MS) pair to self. Assumes result fits in uint512
    function add(
        UINT512 memory self,
        uint256 LS,
        uint256 MS
    ) internal pure returns (uint256, uint256) {
        unchecked {
            return
                (self.LS > type(uint256).max - LS)
                    ? (addmod(self.LS, LS, type(uint256).max), self.MS + MS + 1)
                    : (self.LS + LS, self.MS + MS);
        }
    }

    /// @dev Subtracts an (LS, MS) pair in place. Assumes result > 0
    function isub(
        UINT512 storage self,
        uint256 LS,
        uint256 MS
    ) internal {
        unchecked {
            if (self.LS < LS) {
                self.LS = type(uint256).max + self.LS - LS;
                self.MS -= 1 + MS;
            } else {
                self.LS -= LS;
                self.MS -= MS;
            }
        }
    }

    /// @dev Subtracts an (LS, MS) pair from self. Assumes result > 0
    function sub(
        UINT512 memory self,
        uint256 LS,
        uint256 MS
    ) internal pure returns (uint256, uint256) {
        unchecked {
            return (self.LS < LS) ? (type(uint256).max + self.LS - LS, self.MS - MS - 1) : (self.LS - LS, self.MS - MS);
        }
    }

    /// @dev Multiplies self by single uint256, s. Assumes result fits in uint512
    function muls(UINT512 memory self, uint256 s) internal pure returns (uint256, uint256) {
        unchecked {
            self.MS *= s;
            (self.LS, s) = FullMath.mul512(self.LS, s);
            return (self.LS, self.MS + s);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAloePredictionsActions.sol";
import "./IAloePredictionsDerivedState.sol";
import "./IAloePredictionsEvents.sol";
import "./IAloePredictionsState.sol";

/// @title Aloe predictions market interface
/// @dev The interface is broken up into many smaller pieces
interface IAloePredictions is
    IAloePredictionsActions,
    IAloePredictionsDerivedState,
    IAloePredictionsEvents,
    IAloePredictionsState
{

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./libraries/Equations.sol";
import "./libraries/UINT512.sol";

import "./structs/Accumulators.sol";
import "./structs/EpochSummary.sol";
import "./structs/Proposal.sol";

import "./interfaces/IAloePredictionsState.sol";

contract AloePredictionsState is IAloePredictionsState {
    using UINT512Math for UINT512;

    /// @dev The maximum number of proposals that should be aggregated
    uint8 public constant NUM_PROPOSALS_TO_AGGREGATE = 100;

    /// @dev A mapping containing a summary of every epoch
    mapping(uint24 => EpochSummary) public summaries;

    /// @inheritdoc IAloePredictionsState
    mapping(uint40 => Proposal) public override proposals;

    /// @dev An array containing keys of the highest-stake proposals. Outer index 0 corresponds to
    /// most recent even-numbered epoch; outer index 1 corresponds to most recent odd-numbered epoch
    uint40[NUM_PROPOSALS_TO_AGGREGATE][2] public highestStakeKeys;

    /// @inheritdoc IAloePredictionsState
    uint40 public override nextProposalKey = 0;

    /// @inheritdoc IAloePredictionsState
    uint24 public override epoch;

    /// @inheritdoc IAloePredictionsState
    uint32 public override epochStartTime;

    /// @inheritdoc IAloePredictionsState
    bool public override shouldInvertPrices;

    /// @inheritdoc IAloePredictionsState
    bool public override didInvertPrices;

    /// @dev Should run after `_submitProposal`, otherwise `accumulators.proposalCount` will be off by 1
    function _organizeProposals(uint40 newestProposalKey, uint80 newestProposalStake) internal {
        uint40 insertionIdx = summaries[epoch].accumulators.proposalCount - 1;
        uint24 parity = epoch % 2;

        if (insertionIdx < NUM_PROPOSALS_TO_AGGREGATE) {
            highestStakeKeys[parity][insertionIdx] = newestProposalKey;
            return;
        }

        // Start off by assuming the first key in the array corresponds to min stake
        insertionIdx = 0;
        uint80 stakeMin = proposals[highestStakeKeys[parity][0]].stake;
        uint80 stake;
        // Now iterate through rest of keys and update [insertionIdx, stakeMin] as needed
        for (uint8 i = 1; i < NUM_PROPOSALS_TO_AGGREGATE; i++) {
            stake = proposals[highestStakeKeys[parity][i]].stake;
            if (stake < stakeMin) {
                insertionIdx = i;
                stakeMin = stake;
            }
        }

        // `>=` (instead of `>`) prefers newer proposals to old ones. This is what we want,
        // since newer proposals will have more market data on which to base bounds.
        if (newestProposalStake >= stakeMin) highestStakeKeys[parity][insertionIdx] = newestProposalKey;
    }

    function _submitProposal(
        uint80 stake,
        uint176 lower,
        uint176 upper
    ) internal returns (uint40 key) {
        require(stake != 0, "Aloe: Need stake");
        require(lower < upper, "Aloe: Impossible bounds");

        summaries[epoch].accumulators.proposalCount++;
        accumulate(stake, lower, upper);

        key = nextProposalKey;
        proposals[key] = Proposal(msg.sender, epoch, lower, upper, stake);
        nextProposalKey++;
    }

    function _updateProposal(
        uint40 key,
        uint176 lower,
        uint176 upper
    ) internal {
        require(lower < upper, "Aloe: Impossible bounds");

        Proposal storage proposal = proposals[key];
        require(proposal.source == msg.sender, "Aloe: Not yours");
        require(proposal.epoch == epoch, "Aloe: Not fluid");

        unaccumulate(proposal.stake, proposal.lower, proposal.upper);
        accumulate(proposal.stake, lower, upper);

        proposal.lower = lower;
        proposal.upper = upper;
    }

    function accumulate(
        uint80 stake,
        uint176 lower,
        uint176 upper
    ) private {
        unchecked {
            Accumulators storage accumulators = summaries[epoch].accumulators;

            accumulators.stakeTotal += stake;
            accumulators.stake0thMomentRaw += uint256(stake) * uint256(upper - lower);
            accumulators.sumOfLowerBounds += lower;
            accumulators.sumOfUpperBounds += upper;
            accumulators.sumOfLowerBoundsWeighted += uint256(stake) * uint256(lower);
            accumulators.sumOfUpperBoundsWeighted += uint256(stake) * uint256(upper);

            (uint256 LS0, uint256 MS0, uint256 LS1, uint256 MS1) = Equations.eqn0(stake, lower, upper);

            // update each storage slot only once
            accumulators.sumOfSquaredBounds.iadd(LS0, MS0);
            accumulators.sumOfSquaredBoundsWeighted.iadd(LS1, MS1);
        }
    }

    function unaccumulate(
        uint80 stake,
        uint176 lower,
        uint176 upper
    ) private {
        unchecked {
            Accumulators storage accumulators = summaries[epoch].accumulators;

            accumulators.stakeTotal -= stake;
            accumulators.stake0thMomentRaw -= uint256(stake) * uint256(upper - lower);
            accumulators.sumOfLowerBounds -= lower;
            accumulators.sumOfUpperBounds -= upper;
            accumulators.sumOfLowerBoundsWeighted -= uint256(stake) * uint256(lower);
            accumulators.sumOfUpperBoundsWeighted -= uint256(stake) * uint256(upper);

            (uint256 LS0, uint256 MS0, uint256 LS1, uint256 MS1) = Equations.eqn0(stake, lower, upper);

            // update each storage slot only once
            accumulators.sumOfSquaredBounds.isub(LS0, MS0);
            accumulators.sumOfSquaredBoundsWeighted.isub(LS1, MS1);
        }
    }

    /// @dev Consolidate accumulators into variables better-suited for reward math
    function _consolidateAccumulators(uint24 inEpoch) internal {
        EpochSummary storage summary = summaries[inEpoch];
        require(summary.groundTruth.upper != 0, "Aloe: Need ground truth");

        uint256 stakeTotal = summary.accumulators.stakeTotal;

        // Reassign sumOfSquaredBounds to sumOfSquaredErrors
        summary.accumulators.sumOfSquaredBounds = Equations.eqn1(
            summary.accumulators.sumOfSquaredBounds,
            summary.accumulators.sumOfLowerBounds,
            summary.accumulators.sumOfUpperBounds,
            summary.accumulators.proposalCount,
            summary.groundTruth.lower,
            summary.groundTruth.upper
        );

        // Compute reward denominator
        UINT512 memory denom = summary.accumulators.sumOfSquaredBounds;
        // --> Scale this initial term by total stake
        (denom.LS, denom.MS) = denom.muls(stakeTotal);
        // --> Subtract sum of all weighted squared errors
        UINT512 memory temp =
            Equations.eqn1(
                summary.accumulators.sumOfSquaredBoundsWeighted,
                summary.accumulators.sumOfLowerBoundsWeighted,
                summary.accumulators.sumOfUpperBoundsWeighted,
                stakeTotal,
                summary.groundTruth.lower,
                summary.groundTruth.upper
            );
        (denom.LS, denom.MS) = denom.sub(temp.LS, temp.MS);

        // Reassign sumOfSquaredBoundsWeighted to denom
        summary.accumulators.sumOfSquaredBoundsWeighted = denom;

        delete summary.accumulators.stake0thMomentRaw;
        delete summary.accumulators.sumOfLowerBounds;
        delete summary.accumulators.sumOfLowerBoundsWeighted;
        delete summary.accumulators.sumOfUpperBounds;
        delete summary.accumulators.sumOfUpperBoundsWeighted;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAloePredictionsActions {
    /// @notice Advances the epoch no more than once per hour
    function advance() external;

    /**
     * @notice Allows users to submit proposals in `epoch`. These proposals specify aggregate position
     * in `epoch + 1` and adjusted stakes become claimable in `epoch + 2`
     * @param lower The Q128.48 price at the lower bound, unless `shouldInvertPrices`, in which case
     * this should be `1 / (priceAtUpperBound * 2 ** 16)`
     * @param upper The Q128.48 price at the upper bound, unless `shouldInvertPrices`, in which case
     * this should be `1 / (priceAtLowerBound * 2 ** 16)`
     * @param stake The amount of ALOE to stake on this proposal. Once submitted, you can't unsubmit!
     * @return key The unique ID of this proposal, used to update bounds and claim reward
     */
    function submitProposal(
        uint176 lower,
        uint176 upper,
        uint80 stake
    ) external returns (uint40 key);

    /**
     * @notice Allows users to update bounds of a proposal they submitted previously. This only
     * works if the epoch hasn't increased since submission
     * @param key The key of the proposal that should be updated
     * @param lower The Q128.48 price at the lower bound, unless `shouldInvertPrices`, in which case
     * this should be `1 / (priceAtUpperBound * 2 ** 16)`
     * @param upper The Q128.48 price at the upper bound, unless `shouldInvertPrices`, in which case
     * this should be `1 / (priceAtLowerBound * 2 ** 16)`
     */
    function updateProposal(
        uint40 key,
        uint176 lower,
        uint176 upper
    ) external;

    /**
     * @notice Allows users to reclaim ALOE that they staked in previous epochs, as long as
     * the epoch has ground truth information
     * @dev ALOE is sent to `proposal.source` not `msg.sender`, so anyone can trigger a claim
     * for anyone else
     * @param key The key of the proposal that should be judged and rewarded
     * @param extras An array of tokens for which extra incentives should be claimed
     */
    function claimReward(uint40 key, address[] calldata extras) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Bounds.sol";

interface IAloePredictionsDerivedState {
    /**
     * @notice Statistics for the most recent crowdsourced probability density function, evaluated about current price
     * @return areInverted Whether the reported values are for inverted prices
     * @return mean Result of `computeMean()`
     * @return sigmaL The sqrt of the lower semivariance
     * @return sigmaU The sqrt of the upper semivariance
     */
    function current()
        external
        view
        returns (
            bool areInverted,
            uint176 mean,
            uint128 sigmaL,
            uint128 sigmaU
        );

    /// @notice The earliest time at which the epoch can end
    function epochExpectedEndTime() external view returns (uint32);

    /**
     * @notice Aggregates proposals in the previous `epoch`. Only the top `NUM_PROPOSALS_TO_AGGREGATE`, ordered by
     * stake, will be considered.
     * @return mean The mean of the crowdsourced probability density function (1st Raw Moment)
     */
    function computeMean() external view returns (uint176 mean);

    /**
     * @notice Aggregates proposals in the previous `epoch`. Only the top `NUM_PROPOSALS_TO_AGGREGATE`, ordered by
     * stake, will be considered.
     * @return lower The lower semivariance of the crowdsourced probability density function (2nd Central Moment, Lower)
     * @return upper The upper semivariance of the crowdsourced probability density function (2nd Central Moment, Upper)
     */
    function computeSemivariancesAbout(uint176 center) external view returns (uint256 lower, uint256 upper);

    /**
     * @notice Fetches Uniswap prices over 10 discrete intervals in the past hour. Computes mean and standard
     * deviation of these samples, and returns "ground truth" bounds that should enclose ~95% of trading activity
     * @return bounds The "ground truth" price range that will be used when computing rewards
     * @return shouldInvertPricesNext Whether proposals in the next epoch should be submitted with inverted bounds
     */
    function fetchGroundTruth() external view returns (Bounds memory bounds, bool shouldInvertPricesNext);

    /**
     * @notice Builds a memory array that can be passed to Uniswap V3's `observe` function to specify
     * intervals over which mean prices should be fetched
     * @return secondsAgos From how long ago each cumulative tick and liquidity value should be returned
     */
    function selectedOracleTimetable() external pure returns (uint32[] memory secondsAgos);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAloePredictionsEvents {
    event ProposalSubmitted(
        address indexed source,
        uint24 indexed epoch,
        uint40 key,
        uint176 lower,
        uint176 upper,
        uint80 stake
    );

    event ProposalUpdated(address indexed source, uint24 indexed epoch, uint40 key, uint176 lower, uint176 upper);

    event FetchedGroundTruth(uint176 lower, uint176 upper, bool didInvertPrices);

    event Advanced(uint24 epoch, uint32 epochStartTime);

    event ClaimedReward(address indexed recipient, uint24 indexed epoch, uint40 key, uint80 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/EpochSummary.sol";
import "../structs/Proposal.sol";

interface IAloePredictionsState {
    /// @dev A mapping containing every proposal. These get deleted when claimed
    function proposals(uint40 key)
        external
        view
        returns (
            address source,
            uint24 submissionEpoch,
            uint176 lower,
            uint176 upper,
            uint80 stake
        );

    /// @dev The unique ID that will be assigned to the next submitted proposal
    function nextProposalKey() external view returns (uint40);

    /// @dev The current epoch. May increase up to once per hour. Never decreases
    function epoch() external view returns (uint24);

    /// @dev The time at which the current epoch started
    function epochStartTime() external view returns (uint32);

    /// @dev Whether new proposals should be submitted with inverted prices
    function shouldInvertPrices() external view returns (bool);

    /// @dev Whether proposals in `epoch - 1` were submitted with inverted prices
    function didInvertPrices() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Bounds {
    // Q128.48 price at tickLower of a Uniswap position
    uint176 lower;
    // Q128.48 price at tickUpper of a Uniswap position
    uint176 upper;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Accumulators.sol";
import "./Bounds.sol";

struct EpochSummary {
    Bounds groundTruth;
    Accumulators accumulators;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Proposal {
    // The address that submitted the proposal
    address source;
    // The epoch in which the proposal was submitted
    uint24 epoch;
    // Q128.48 price at tickLower of proposed Uniswap position
    uint176 lower;
    // Q128.48 price at tickUpper of proposed Uniswap position
    uint176 upper;
    // The amount of ALOE held; fits in uint80 because max supply is 1000000 with 18 decimals
    uint80 stake;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/UINT512.sol";

struct Accumulators {
    // The number of (proposals added - proposals removed) during the epoch
    uint40 proposalCount;
    // The total amount of ALOE staked; fits in uint80 because max supply is 1000000 with 18 decimals
    uint80 stakeTotal;
    // For the remaining properties, read comments as if `stake`, `lower`, and `upper` are NumPy arrays.
    // Each index represents a proposal, e.g. proposal 0 would be `(stake[0], lower[0], upper[0])`

    // `(stake * (upper - lower)).sum()`
    uint256 stake0thMomentRaw;
    // `lower.sum()`
    uint256 sumOfLowerBounds;
    // `(stake * lower).sum()`
    uint256 sumOfLowerBoundsWeighted;
    // `upper.sum()`
    uint256 sumOfUpperBounds;
    // `(stake * upper).sum()`
    uint256 sumOfUpperBoundsWeighted;
    // `(np.square(lower) + np.square(upper)).sum()`
    UINT512 sumOfSquaredBounds;
    // `(stake * (np.square(lower) + np.square(upper))).sum()`
    UINT512 sumOfSquaredBoundsWeighted;
}

