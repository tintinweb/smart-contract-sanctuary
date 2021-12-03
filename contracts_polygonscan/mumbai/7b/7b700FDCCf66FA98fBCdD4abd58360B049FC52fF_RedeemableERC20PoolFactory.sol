// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import { Factory } from "../factory/Factory.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20Pool, RedeemableERC20PoolConfig } from "./RedeemableERC20Pool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { RedeemableERC20 } from "../redeemableERC20/RedeemableERC20.sol";

/// Everything required to construct a `RedeemableERC20PoolFactory`.
struct RedeemableERC20PoolFactoryConfig {
    // The `CRPFactory` on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address crpFactory;
    // The `BFactory` on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address balancerFactory;
}

/// Everything else required to construct new `RedeemableERC20Pool` child
/// contracts.
struct RedeemableERC20PoolFactoryRedeemableERC20PoolConfig {
    // The reserve erc20 token.
    // The reserve token anchors our newly minted redeemable tokens to an
    // existant value system.
    // The weights and balances of the reserve token and the minted token
    // define a dynamic spot price in the AMM.
    IERC20 reserve;
    // The newly minted redeemable token contract.
    // 100% of the total supply of the token MUST be transferred to the
    // `RedeemableERC20Pool` for it to function.
    // This implies a 1:1 relationship between redeemable pools and tokens.
    // IMPORTANT: It is up to the caller to define a reserve that will remain
    // functional and outlive the RedeemableERC20.
    // For example, USDC could freeze the tokens owned by the RedeemableERC20
    // contract or close their business.
    RedeemableERC20 token;
    // Amount of reserve token to initialize the pool.
    // The starting/final weights are calculated against this.
    uint256 reserveInit;
    // Initial marketcap of the token according to the balancer pool
    // denominated in reserve token.
    // Th spot price of the token is ( market cap / token supply ) where market
    // cap is defined in terms of the reserve.
    // The spot price of a balancer pool token is a function of both the
    // amounts of each token and their weights.
    // This bonding curve is described in the balancer whitepaper.
    // We define a valuation of newly minted tokens in terms of the deposited
    // reserve. The reserve weight is set to the minimum allowable value to
    // achieve maximum capital efficiency for the fund raising.
    uint256 initialValuation;
    // Final valuation is treated the same as initial valuation.
    // The final valuation will ONLY be achieved if NO TRADING OCCURS.
    // Any trading activity that net deposits reserve funds into the pool will
    // increase the spot price permanently.
    uint256 finalValuation;
    // Minimum duration IN BLOCKS of the trading on Balancer.
    // The trading does not stop until the `anonEndDistribution` function is
    // called.
    uint256 minimumTradingDuration;
}

/// @title RedeemableERC20PoolFactory
/// @notice Factory for creating and registering new `RedeemableERC20Pool`
/// contracts.
contract RedeemableERC20PoolFactory is Factory {
    /// ConfigurableRightsPool factory.
    address public immutable crpFactory;
    /// Balancer factory.
    address public immutable balancerFactory;

    /// @param config_ All configuration for the `RedeemableERC20PoolFactory`.
    constructor(RedeemableERC20PoolFactoryConfig memory config_) {
        crpFactory = config_.crpFactory;
        balancerFactory = config_.balancerFactory;
    }

    /// @inheritdoc Factory
    function _createChild(
        bytes calldata data_
    ) internal virtual override returns(address) {
        (
            RedeemableERC20PoolFactoryRedeemableERC20PoolConfig
            memory
            config_
        ) = abi.decode(
            data_,
            (RedeemableERC20PoolFactoryRedeemableERC20PoolConfig)
        );
        RedeemableERC20Pool pool_ = new RedeemableERC20Pool(
            RedeemableERC20PoolConfig(
                crpFactory,
                balancerFactory,
                config_.reserve,
                config_.token,
                config_.reserveInit,
                config_.initialValuation,
                config_.finalValuation,
                config_.minimumTradingDuration
            )
        );
        /// Transfer Balancer pool ownership to sender (e.g. `Trust`).
        pool_.transferOwnership(msg.sender);
        return address(pool_);
    }

    /// Allows calling `createChild` with
    /// `RedeemableERC20PoolFactoryRedeemableERC20PoolConfig` struct.
    /// Can use original Factory `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `RedeemableERC20Pool` constructor configuration.
    /// @return New `RedeemableERC20Pool` child contract address.
    function createChild(
        RedeemableERC20PoolFactoryRedeemableERC20PoolConfig
        calldata
        config_
    )
        external
        returns(address)
    {
        return this.createChild(abi.encode(config_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import { IFactory } from "./IFactory.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Factory
/// @notice Base contract for deploying and registering child contracts.
abstract contract Factory is IFactory, ReentrancyGuard {
    /// @dev state to track each deployed contract address. A `Factory` will
    /// never lie about deploying a child, unless `isChild` is overridden to do
    /// so.
    mapping(address => bool) private contracts;

    /// Implements `IFactory`.
    ///
    /// `_createChild` hook must be overridden to actually create child
    /// contract.
    ///
    /// Implementers may want to overload this function with a typed equivalent
    /// to expose domain specific structs etc. to the compiled ABI consumed by
    /// tooling and other scripts. To minimise gas costs for deployment it is
    /// expected that the tooling will consume the typed ABI, then encode the
    /// arguments and pass them to this function directly.
    ///
    /// @param data_ ABI encoded data to pass to child contract constructor.
    // Slither false positive. This is intended to overridden.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _createChild(bytes calldata data_)
        internal
        virtual
        returns(address)
    { } // solhint-disable-line no-empty-blocks

    /// Implements `IFactory`.
    ///
    /// Calls the _createChild hook, which inheriting contracts must override.
    /// Registers child contract address such that `isChild` is `true`.
    /// Emits `NewContract` event.
    ///
    /// @param data_ Encoded data to pass down to child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_)
        external
        virtual
        override
        nonReentrant
        returns(address) {
        // Create child contract using hook.
        address child_ = _createChild(data_);
        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewContract` event with child contract address.
        emit IFactory.NewContract(child_);
        return child_;
    }

    /// Implements `IFactory`.
    ///
    /// Checks if address is registered as a child contract of this factory.
    ///
    /// @param maybeChild_ Address of child contract to look up.
    /// @return Returns `true` if address is a contract created by this
    /// contract factory, otherwise `false`.
    function isChild(address maybeChild_)
        external
        virtual
        override
        returns(bool)
    {
        return contracts[maybeChild_];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

interface IFactory {
    /// Whenever a new child contract is deployed, a `NewContract` event
    /// containing the new child contract address MUST be emitted.
    event NewContract(address indexed _contract);

    /// Creates a new child contract.
    ///
    /// @param data_ Domain specific data for the child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_) external returns(address);

    /// Checks if address is registered as a child contract of this factory.
    ///
    /// Addresses that were not deployed by `createChild` MUST NOT return
    /// `true` from `isChild`. This is CRITICAL to the security guarantees for
    /// any contract implementing `IFactory`.
    ///
    /// @param maybeChild_ Address to check registration for.
    /// @return `true` if address was deployed by this contract factory,
    /// otherwise `false`.
    function isChild(address maybeChild_) external returns(bool);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Rights } from "./IRightsManager.sol";
import { ICRPFactory } from "./ICRPFactory.sol";
// solhint-disable-next-line max-line-length
import { PoolParams, IConfigurableRightsPool } from "./IConfigurableRightsPool.sol";

import { IBalancerConstants } from "./IBalancerConstants.sol";

import { Phase, Phased } from "../phased/Phased.sol";
import { RedeemableERC20 } from "../redeemableERC20/RedeemableERC20.sol";

/// Everything required to construct a `RedeemableERC20Pool`.
struct RedeemableERC20PoolConfig {
    // The CRPFactory on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address crpFactory;
    // The BFactory on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address balancerFactory;
    // The reserve erc20 token.
    // The reserve token anchors our newly minted redeemable tokens to an
    // existant value system.
    // The weights and balances of the reserve token and the minted token
    // define a dynamic spot price in the AMM.
    IERC20 reserve;
    // The newly minted redeemable token contract.
    // 100% of the total supply of the token MUST be transferred to the
    // `RedeemableERC20Pool` for it to function.
    // This implies a 1:1 relationship between redeemable pools and tokens.
    // IMPORTANT: It is up to the caller to define a reserve that will remain
    // functional and outlive the RedeemableERC20.
    // For example, USDC could freeze the tokens owned by the RedeemableERC20
    // contract or close their business.
    RedeemableERC20 token;
    // Amount of reserve token to initialize the pool.
    // The starting/final weights are calculated against this.
    uint256 reserveInit;
    // Initial marketcap of the token according to the balancer pool
    // denominated in reserve token.
    // The spot price of the token is ( market cap / token supply ) where
    // market cap is defined in terms of the reserve.
    // The spot price of a balancer pool token is a function of both the
    // amounts of each token and their weights.
    // This bonding curve is described in the Balancer whitepaper.
    // We define a valuation of newly minted tokens in terms of the deposited
    // reserve. The reserve weight is set to the minimum allowable value to
    // achieve maximum capital efficiency for the fund raising.
    uint256 initialValuation;
    // Final valuation is treated the same as initial valuation.
    // The final valuation will ONLY be achieved if NO TRADING OCCURS.
    // Any trading activity that net deposits reserve funds into the pool will
    // increase the spot price permanently.
    uint256 finalValuation;
    // Minimum duration IN BLOCKS of the trading on Balancer.
    // The trading does not stop until the `anonEndDistribution` function is
    // called on the owning `Trust`.
    uint256 minimumTradingDuration;
}

/// @title RedeemableERC20Pool
/// @notice The Balancer functionality is wrapped by the
/// `RedeemableERC20Pool` contract.
///
/// Balancer pools require significant configuration so this contract helps
/// decouple the implementation from the `Trust`.
///
/// It also ensures the pool tokens created during the initialization of the
/// Balancer LBP are owned by the `RedeemableERC20Pool` and never touch either
/// the `Trust` nor an externally owned account (EOA).
///
/// `RedeemableERC20Pool` has several phases:
///
/// - `Phase.ZERO`: Deployed not trading but can be by owner calling
/// `ownerStartDutchAuction`
/// - `Phase.ONE`: Trading open
/// - `Phase.TWO`: Trading open but can be closed by owner calling
/// `ownerEndDutchAuction`
/// - `Phase.THREE`: Trading closed
///
/// @dev Deployer and controller for a Balancer ConfigurableRightsPool.
/// This contract is intended in turn to be owned by a `Trust`.
///
/// Responsibilities of `RedeemableERC20Pool`:
/// - Configure and deploy Balancer contracts with correct weights, rights and
///   balances
/// - Allowing the owner to start and end a dutch auction raise modelled as
///   Balancer's "gradual weights" functionality
/// - Tracking and enforcing 3 phases: unstarted, started, ended
/// - Burning unsold tokens after the raise and forwarding all raised and
///   initial reserve back to the owner
///
/// Responsibilities of the owner:
/// - Providing all token and reserve balances
/// - Calling start and end raise functions
/// - Handling the reserve proceeds of the raise
contract RedeemableERC20Pool is Ownable, Phased {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for RedeemableERC20;

    /// Balancer requires a minimum balance of `10 ** 6` for all tokens at all
    /// times.
    uint256 public constant MIN_BALANCER_POOL_BALANCE = 10 ** 6;
    /// To ensure that the dust at the end of the raise is dust-like, we
    /// enforce a minimum starting reserve balance 100x the minimum.
    uint256 public constant MIN_RESERVE_INIT = 10 ** 8;

    /// RedeemableERC20 token.
    RedeemableERC20 public immutable token;

    /// Minimum trading duration from the initial config.
    uint256 public immutable minimumTradingDuration;

    /// Reserve token.
    IERC20 public immutable reserve;
    /// Initial reserve balance of the pool.
    uint256 public immutable reserveInit;

    /// The `ConfigurableRightsPool` built during construction.
    IConfigurableRightsPool public immutable crp;

    /// The final weight on the last block of the raise.
    /// Note the spot price is unknown until the end because we don't know
    /// either of the final token balances.
    uint256 public immutable finalWeight;
    uint256 public immutable finalValuation;

    /// @param config_ All configuration for the `RedeemableERC20Pool`.
    // Slither false positive. Constructors cannot be reentrant.
    // https://github.com/crytic/slither/issues/887
    // slither-disable-next-line reentrancy-benign
    constructor (RedeemableERC20PoolConfig memory config_) {
        require(
            config_.reserveInit >= MIN_RESERVE_INIT,
            "RESERVE_INIT_MINIMUM"
        );
        require(
            config_.initialValuation >= config_.finalValuation,
            "MIN_INITIAL_VALUTION"
        );

        token = config_.token;
        reserve = config_.reserve;
        reserveInit = config_.reserveInit;

        finalWeight = valuationWeight(
            config_.reserveInit,
            config_.finalValuation
        );
        finalValuation = config_.finalValuation;

        require(config_.minimumTradingDuration > 0, "0_TRADING_DURATION");
        minimumTradingDuration = config_.minimumTradingDuration;

        // Build the CRP.
        // The addresses in the `RedeemableERC20Pool`, as `[reserve, token]`.
        address[] memory poolAddresses_ = new address[](2);
        poolAddresses_[0] = address(config_.reserve);
        poolAddresses_[1] = address(config_.token);

        uint256[] memory poolAmounts_ = new uint256[](2);
        poolAmounts_[0] = config_.reserveInit;
        poolAmounts_[1] = config_.token.totalSupply();
        require(poolAmounts_[1] > 0, "TOKEN_INIT_0");

        uint256[] memory initialWeights_ = new uint256[](2);
        initialWeights_[0] = IBalancerConstants.MIN_WEIGHT;
        initialWeights_[1] = valuationWeight(
            config_.reserveInit,
            config_.initialValuation
        );

        address crp_ = ICRPFactory(config_.crpFactory).newCrp(
            config_.balancerFactory,
            PoolParams(
                "R20P",
                "RedeemableERC20Pool",
                poolAddresses_,
                poolAmounts_,
                initialWeights_,
                IBalancerConstants.MIN_FEE
            ),
            Rights(
                // 0. Pause
                false,
                // 1. Change fee
                false,
                // 2. Change weights
                // (`true` needed to set gradual weight schedule)
                true,
                // 3. Add/remove tokens
                false,
                // 4. Whitelist LPs (default behaviour for `true` is that
                //    nobody can `joinPool`)
                true,
                // 5. Change cap
                false
            )
        );
        crp = IConfigurableRightsPool(crp_);

        // Preapprove all tokens and reserve for the CRP.
        require(
            config_.reserve.approve(address(crp_), config_.reserveInit),
            "RESERVE_APPROVE"
        );
        require(
            config_.token.approve(address(crp_),
            config_.token.totalSupply()),
            "TOKEN_APPROVE"
        );
    }

    /// https://balancer.finance/whitepaper/
    /// Spot = ( Br / Wr ) / ( Bt / Wt )
    /// => ( Bt / Wt ) = ( Br / Wr ) / Spot
    /// => Wt = ( Spot x Bt ) / ( Br / Wr )
    ///
    /// Valuation = Spot * Token supply
    /// Valuation / Supply = Spot
    /// => Wt = ( ( Val / Supply ) x Bt ) / ( Br / Wr )
    ///
    /// Bt = Total supply
    /// => Wt = ( ( Val / Bt ) x Bt ) / ( Br / Wr )
    /// => Wt = Val / ( Br / Wr )
    ///
    /// Wr = Min weight = 1
    /// => Wt = Val / Br
    ///
    /// Br = reserve init (assumes zero trading)
    /// => Wt = Val / reserve init
    /// @param valuation_ Valuation as ( market cap * price ) denominated in
    /// reserve to calculate a weight for.
    function valuationWeight(uint256 reserveInit_, uint256 valuation_)
        private
        pure
        returns (uint256)
    {
        uint256 weight_
            = ( valuation_ * IBalancerConstants.BONE ) / reserveInit_;
        require(
            weight_ >= IBalancerConstants.MIN_WEIGHT,
            "MIN_WEIGHT_VALUATION"
        );
        // The combined weight of both tokens cannot exceed the maximum even
        // temporarily during a transaction so we need to subtract one for
        // headroom.
        require(
            ( IBalancerConstants.MAX_WEIGHT - IBalancerConstants.BONE )
            >= ( IBalancerConstants.MIN_WEIGHT + weight_ ),
            "MAX_WEIGHT_VALUATION"
        );
        return weight_;
    }

    /// Allow anyone to start the Balancer style dutch auction.
    /// The auction won't start unless this contract owns enough of both the
    /// tokens for the pool, so it is safe for anon to call.
    /// `Phase.ZERO` indicates the auction can start.
    /// `Phase.ONE` indicates the auction has started.
    /// `Phase.TWO` indicates the auction can be ended.
    /// `Phase.THREE` indicates the auction has ended.
    /// Creates the pool via. the CRP contract and configures the weight change
    /// curve.
    function startDutchAuction() external onlyPhase(Phase.ZERO)
    {
        uint256 finalAuctionBlock_ = minimumTradingDuration + block.number;
        // Move to `Phase.ONE` immediately.
        scheduleNextPhase(uint32(block.number));
        // Schedule `Phase.TWO` for `1` block after auctions weights have
        // stopped changing.
        scheduleNextPhase(uint32(finalAuctionBlock_ + 1));

        // Define the weight curve.
        uint256[] memory finalWeights_ = new uint256[](2);
        finalWeights_[0] = IBalancerConstants.MIN_WEIGHT;
        finalWeights_[1] = finalWeight;

        // Max pool tokens to minimise dust on exit.
        // No minimum weight change period.
        // No time lock (we handle our own locks in the trust).
        crp.createPool(IBalancerConstants.MAX_POOL_SUPPLY, 0, 0);
        crp.updateWeightsGradually(
            finalWeights_,
            block.number,
            finalAuctionBlock_
        );
    }

    /// Allow the owner to end the Balancer style dutch auction.
    /// Moves from `Phase.TWO` to `Phase.THREE` to indicate the auction has
    /// ended.
    /// `Phase.TWO` is scheduled by `startDutchAuction`.
    /// Removes all LP tokens from the Balancer pool.
    /// Burns all unsold redeemable tokens.
    /// Forwards the reserve balance to the owner.
    function ownerEndDutchAuction() external onlyOwner onlyPhase(Phase.TWO) {
        // Move to `Phase.THREE` immediately.
        // In `Phase.THREE` all `RedeemableERC20Pool` functions are no longer
        // callable.
        scheduleNextPhase(uint32(block.number));

        // Balancer enforces a global minimum pool LP token supply as
        // `MIN_POOL_SUPPLY`.
        // Balancer also indirectly enforces local minimums on pool token
        // supply by enforcing minimum erc20 token balances in the pool.
        // The real minimum pool LP token supply is the largest of:
        // - The global minimum
        // - The LP token supply implied by the reserve
        // - The LP token supply implied by the token
        uint256 minReservePoolTokens
            = ( MIN_BALANCER_POOL_BALANCE * IBalancerConstants.MAX_POOL_SUPPLY)
            / reserve.balanceOf(crp.bPool());
        // The minimum redeemable token supply is `10 ** 18` so it is near
        // impossible to hit this before the reserve or global pool minimums.
        uint256 minRedeemablePoolTokens
            = ( MIN_BALANCER_POOL_BALANCE * IBalancerConstants.MAX_POOL_SUPPLY)
            / token.balanceOf(crp.bPool());
        uint256 minPoolSupply_ = IBalancerConstants.MIN_POOL_SUPPLY
            .max(minReservePoolTokens)
            .max(minRedeemablePoolTokens);

        // This removes as much as is allowable which leaves behind some dust.
        // The reserve dust will be trapped.
        // The redeemable token will be burned when it moves to its own
        // `Phase.ONE`.
        crp.exitPool(
            IERC20(address(crp)).balanceOf(address(this)) - minPoolSupply_,
            new uint256[](2)
        );

        // Burn all unsold token inventory.
        token.burn(token.balanceOf(address(this)));

        // Send reserve back to owner (`Trust`) to be distributed to
        // stakeholders.
        reserve.safeTransfer(
            owner(),
            reserve.balanceOf(address(this))
        );
    }

    /// Enforce `Phase.THREE` as the last phase.
    /// @inheritdoc Phased
    function _beforeScheduleNextPhase(uint32 nextPhaseBlock_)
        internal
        override
        virtual
    {
        super._beforeScheduleNextPhase(nextPhaseBlock_);
        assert(currentPhase() < Phase.THREE);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

// Mirrors `Rights` from Balancer `configurable-rights-pool` repo.
// As we do not include balancer contracts as a dependency, we need to ensure
// that any calculations or values that cross the interface to their system are
// identical.
// solhint-disable-next-line max-line-length
// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/libraries/RightsManager.sol#L29
struct Rights {
    bool canPauseSwapping;
    bool canChangeSwapFee;
    bool canChangeWeights;
    bool canAddRemoveTokens;
    bool canWhitelistLPs;
    bool canChangeCap;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import { PoolParams } from "./IConfigurableRightsPool.sol";
import { Rights } from "./IRightsManager.sol";

/// Mirrors the Balancer `CRPFactory` functions relevant to
/// bootstrapping a pool. This is the minimal interface required for
/// `RedeemableERC20Pool` to function, much of the Balancer contract is elided
/// intentionally. Clients should use Balancer code directly.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/CRPFactory.sol#L27
interface ICRPFactory {
    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/CRPFactory.sol#L50
    function newCrp(
        address factoryAddress,
        PoolParams calldata poolParams,
        Rights calldata rights
    )
    external
    returns (address);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// Mirrors the `PoolParams` struct normally internal to a Balancer
/// `ConfigurableRightsPool`.
/// If nothing else, this fixes errors that prevent slither from compiling when
/// running the security scan.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L47
struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint[] tokenBalances;
    uint[] tokenWeights;
    uint swapFee;
}

/// Mirrors the Balancer `ConfigurableRightsPool` functions relevant to
/// bootstrapping a pool. This is the minimal interface required for
/// `RedeemableERC20Pool` to function, much of the Balancer contract is elided
/// intentionally. Clients should use Balancer code directly.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L41
interface IConfigurableRightsPool {
    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L61
    function bPool() external view returns (address);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L60
    function bFactory() external view returns (address);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L318
    function createPool(
        uint initialSupply,
        uint minimumWeightChangeBlockPeriodParam,
        uint addTokenTimeLockInBlocksParam
    ) external;

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L393
    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    ) external;

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L581
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

// Mirrors all the constants from Balancer `configurable-rights-pool` repo.
// As we do not include balancer contracts as a dependency, we need to ensure
// that any calculations or values that cross the interface to their system are
// identical.
// solhint-disable-next-line max-line-length
// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/libraries/BalancerConstants.sol#L9
library IBalancerConstants {
    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = BONE / 10**6;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    uint public constant MIN_ASSET_LIMIT = 2;
    uint public constant MAX_ASSET_LIMIT = 8;
    uint public constant MAX_UINT
        = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// Defines all possible phases.
/// `Phased` begins in `Phase.ZERO` and moves through each phase sequentially.
enum Phase {
    ZERO,
    ONE,
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX,
    SEVEN,
    EIGHT
}

/// @title Phased
/// @notice `Phased` is an abstract contract that defines up to `9` phases that
/// an implementing contract moves through.
///
/// `Phase.ZERO` is always the first phase and does not, and cannot, be set
/// expicitly. Effectively it is implied that `Phase.ZERO` has been active
/// since block zero.
///
/// Each subsequent phase `Phase.ONE` through `Phase.EIGHT` must be
/// scheduled sequentially and explicitly at a block number.
///
/// Only the immediate next phase can be scheduled with `scheduleNextPhase`,
/// it is not possible to schedule multiple phases ahead.
///
/// Multiple phases can be scheduled in a single block if each scheduled phase
/// is scheduled for the current block.
///
/// Several utility functions and modifiers are provided.
///
/// A single hook `_beforeScheduleNextPhase` is provided so contracts can
/// implement additional phase shift checks.
///
/// One event `PhaseShiftScheduled` is emitted each time a phase shift is
/// scheduled (not when the scheduled phase is reached).
///
/// @dev `Phased` contracts have a defined timeline with available
/// functionality grouped into phases.
/// Every `Phased` contract starts at `Phase.ZERO` and moves sequentially
/// through phases `ONE` to `EIGHT`.
/// Every `Phase` other than `Phase.ZERO` is optional, there is no requirement
/// that all 9 phases are implemented.
/// Phases can never be revisited, the inheriting contract always moves through
/// each achieved phase linearly.
/// This is enforced by only allowing `scheduleNextPhase` to be called once per
/// phase.
/// It is possible to call `scheduleNextPhase` several times in a single block
/// but the `block.number` for each phase must be reached each time to schedule
/// the next phase.
/// Importantly there are events and several modifiers and checks available to
/// ensure that functionality is limited to the current phase.
/// The full history of each phase shift block is recorded as a fixed size
/// array of `uint32`.
abstract contract Phased {
    /// Every phase block starts uninitialized.
    /// Only uninitialized blocks can be set by the phase scheduler.
    uint32 public constant UNINITIALIZED = 0xFFFFFFFF;

    /// `PhaseShiftScheduled` is emitted when the next phase is scheduled.
    event PhaseShiftScheduled(uint32 indexed newPhaseBlock_);

    /// 8 phases each as 32 bits to fit a single 32 byte word.
    uint32[8] public phaseBlocks;

    constructor() {
        for (uint256 i_ = 0; i_ < 8; i_++) {
            phaseBlocks[i_] = UNINITIALIZED;
        }
    }

    /// Pure function to reduce an array of phase blocks and block number to a
    /// specific `Phase`.
    /// The phase will be the highest attained even if several phases have the
    /// same block number.
    /// If every phase block is after the block number then `Phase.ZERO` is
    /// returned.
    /// If every phase block is before the block number then `Phase.EIGHT` is
    /// returned.
    /// @param phaseBlocks_ Fixed array of phase blocks to compare against.
    /// @param blockNumber_ Determine the relevant phase relative to this block
    /// number.
    /// @return The "current" phase relative to the block number and phase
    /// blocks list.
    function phaseAtBlockNumber(
        uint32[8] memory phaseBlocks_,
        uint32 blockNumber_
    )
        public
        pure
        returns(Phase)
    {
        for(uint i_ = 0; i_<8; i_++) {
            if (blockNumber_ < phaseBlocks_[i_]) {
                return Phase(i_);
            }
        }
        return Phase(8);
    }

    /// Pure function to reduce an array of phase blocks and phase to a
    /// specific block number.
    /// `Phase.ZERO` will always return block `0`.
    /// Every other phase will map to a block number in `phaseBlocks_`.
    /// @param phaseBlocks_ Fixed array of phase blocks to compare against.
    /// @param phase_ Determine the relevant block number for this phase.
    /// @return The block number for the phase according to the phase blocks
    ///         list, as uint32.
    function blockNumberForPhase(uint32[8] calldata phaseBlocks_, Phase phase_)
        external
        pure
        returns(uint32)
    {
        return phase_ > Phase.ZERO ? phaseBlocks_[uint(phase_) - 1] : 0;
    }

    /// Impure read-only function to return the "current" phase from internal
    /// contract state.
    /// Simply wraps `phaseAtBlockNumber` for current values of `phaseBlocks`
    /// and `block.number`.
    function currentPhase() public view returns (Phase) {
        return phaseAtBlockNumber(phaseBlocks, uint32(block.number));
    }

    /// Modifies functions to only be callable in a specific phase.
    /// @param phase_ Modified functions can only be called during this phase.
    modifier onlyPhase(Phase phase_) {
        require(currentPhase() == phase_, "BAD_PHASE");
        _;
    }

    /// Modifies functions to only be callable in a specific phase OR if the
    /// specified phase has passed.
    /// @param phase_ Modified function only callable during or after this
    /// phase.
    modifier onlyAtLeastPhase(Phase phase_) {
        require(currentPhase() >= phase_, "MIN_PHASE");
        _;
    }

    /// Writes the block for the next phase.
    /// Only uninitialized blocks can be written to.
    /// Only the immediate next phase relative to `currentPhase` can be written
    /// to.
    /// Emits `PhaseShiftScheduled` with the next phase block.
    /// @param nextPhaseBlock_ The block for the next phase.
    function scheduleNextPhase(uint32 nextPhaseBlock_) internal {
        require(uint32(block.number) <= nextPhaseBlock_, "NEXT_BLOCK_PAST");
        require(nextPhaseBlock_ < UNINITIALIZED, "NEXT_BLOCK_UNINITIALIZED");

        // The next index is the current phase because `Phase.ZERO` doesn't
        // exist as an index.
        uint nextIndex_ = uint(currentPhase());
        require(UNINITIALIZED == phaseBlocks[nextIndex_], "NEXT_BLOCK_SET");

        _beforeScheduleNextPhase(nextPhaseBlock_);
        phaseBlocks[nextIndex_] = nextPhaseBlock_;

        emit PhaseShiftScheduled(nextPhaseBlock_);
    }

    /// Hook called before scheduling the next phase.
    /// Useful to apply additional constraints or state changes on a phase
    /// change.
    /// Note this is called when scheduling the phase change, not on the block
    /// the phase change occurs.
    /// This is called before the phase change so that all functionality that
    /// is behind a phase gate is still available at the moment of applying the
    /// hook for scheduling the next phase.
    /// @param nextPhaseBlock_ The block for the next phase.
    function _beforeScheduleNextPhase(uint32 nextPhaseBlock_)
        internal
        virtual
    { } //solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

import { ERC20Config } from "../erc20/ERC20Config.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// solhint-disable-next-line max-line-length
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// solhint-disable-next-line max-line-length
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import { TierByConstruction } from "../tier/TierByConstruction.sol";
import { ITier } from "../tier/ITier.sol";

import { Phase, Phased } from "../phased/Phased.sol";

/// Everything required by the `RedeemableERC20` constructor.
struct RedeemableERC20Config {
    // Account that will be the admin for the `RedeemableERC20` contract.
    // Useful for factory contracts etc.
    address admin;
    // ERC20 config forwarded to the ERC20 constructor.
    ERC20Config erc20Config;
    // Tier contract to compare statuses against on transfer.
    ITier tier;
    // Minimum status required for transfers in `Phase.ZERO`. Can be `0`.
    ITier.Tier minimumStatus;
    // Number of redeemable tokens to mint.
    uint256 totalSupply;
}

/// @title RedeemableERC20
/// @notice This is the ERC20 token that is minted and distributed.
///
/// During `Phase.ZERO` the token can be traded and so compatible with the
/// Balancer pool mechanics.
///
/// During `Phase.ONE` the token is frozen and no longer able to be traded on
/// any AMM or transferred directly.
///
/// The token can be redeemed during `Phase.ONE` which burns the token in
/// exchange for pro-rata erc20 tokens held by the `RedeemableERC20` contract
/// itself.
///
/// The token balances can be used indirectly for other claims, promotions and
/// events as a proof of participation in the original distribution by token
/// holders.
///
/// The token can optionally be restricted by the `Tier` contract to only allow
/// receipients with a specified membership status.
///
/// @dev `RedeemableERC20` is an ERC20 with 2 phases.
///
/// `Phase.ZERO` is the distribution phase where the token can be freely
/// transfered but not redeemed.
/// `Phase.ONE` is the redemption phase where the token can be redeemed but no
/// longer transferred.
///
/// Redeeming some amount of `RedeemableERC20` burns the token in exchange for
/// some other tokens held by the contract. For example, if the
/// `RedeemableERC20` token contract holds 100 000 USDC then a holder of the
/// redeemable token can burn some of their tokens to receive a % of that USDC.
/// If they redeemed (burned) an amount equal to 10% of the redeemable token
/// supply then they would receive 10 000 USDC.
///
/// To make the treasury assets discoverable anyone can call `newTreasuryAsset`
/// to emit an event containing the treasury asset address. As malicious and/or
/// spam users can emit many treasury events there is a need for sensible
/// indexing and filtering of asset events to only trusted users. This contract
/// is agnostic to how that trust relationship is defined for each user.
///
/// Users must specify all the treasury assets they wish to redeem to the
/// `redeem` function. After `redeem` is called the redeemed tokens are burned
/// so all treasury assets must be specified and claimed in a batch atomically.
/// Note: The same amount of `RedeemableERC20` is burned, regardless of which
/// treasury assets were specified. Specifying fewer assets will NOT increase
/// the proportion of each that is returned.
///
/// `RedeemableERC20` has several owner administrative functions:
/// - Owner can add senders and receivers that can send/receive tokens even
///   during `Phase.ONE`
/// - Owner can end `Phase.ONE` during `Phase.ZERO` by specifying the address
///   of a distributor, which will have any undistributed tokens burned.
///
/// The redeem functions MUST be used to redeem and burn RedeemableERC20s
/// (NOT regular transfers).
///
/// `redeem` will simply revert if called outside `Phase.ONE`.
/// A `Redeem` event is emitted on every redemption (per treasury asset) as
/// `(redeemer, asset, redeemAmount)`.
contract RedeemableERC20 is
    AccessControl,
    Phased,
    TierByConstruction,
    ERC20,
    ReentrancyGuard,
    ERC20Burnable
    {

    using SafeERC20 for IERC20;

    bytes32 public constant SENDER = keccak256("SENDER");
    bytes32 public constant RECEIVER = keccak256("RECEIVER");
    bytes32 public constant DISTRIBUTOR_BURNER =
        keccak256("DISTRIBUTOR_BURNER");

    /// Redeemable token added by creator.
    event TreasuryAsset(address indexed emitter, address indexed asset);

    /// Redeemable token burn for reserve.
    event Redeem(
        // Account burning and receiving.
        address indexed redeemer,
        // The treasury asset being sent to the burner.
        address indexed treasuryAsset,
        // The amounts of the redeemable and treasury asset as
        // `[redeemAmount, assetAmount]`
        uint256[2] redeemAmounts
    );

    /// RedeemableERC20 uses the standard/default 18 ERC20 decimals.
    /// The minimum supply enforced by the constructor is "one" token which is
    /// `10 ** 18`.
    /// The minimum supply does not prevent subsequent redemption/burning.
    uint256 public constant MINIMUM_INITIAL_SUPPLY = 10 ** 18;

    /// The minimum status that a user must hold to receive transfers during
    /// `Phase.ZERO`.
    /// The tier contract passed to `TierByConstruction` determines if
    /// the status is held during `_beforeTokenTransfer`.
    /// Not immutable because it is read during the constructor by the `_mint`
    /// call.
    ITier.Tier public minimumTier;

    /// Mint the full ERC20 token supply and configure basic transfer
    /// restrictions.
    /// @param config_ Constructor configuration.
    constructor (
        RedeemableERC20Config memory config_
    )
        ERC20(config_.erc20Config.name, config_.erc20Config.symbol)
        TierByConstruction(config_.tier)
    {
        require(
            config_.totalSupply >= MINIMUM_INITIAL_SUPPLY,
            "MINIMUM_INITIAL_SUPPLY"
        );
        minimumTier = config_.minimumStatus;

        _setupRole(DEFAULT_ADMIN_ROLE, config_.admin);
        _setupRole(RECEIVER, config_.admin);
        // Minting and burning must never fail.
        _setupRole(SENDER, address(0));
        _setupRole(RECEIVER, address(0));

        _mint(config_.admin, config_.totalSupply);
    }

    /// The admin can burn all tokens of a single address to end `Phase.ZERO`.
    /// The intent is that during `Phase.ZERO` there is some contract
    /// responsible for distributing the tokens.
    /// The admin specifies the distributor to end `Phase.ZERO` and all
    /// undistributed tokens are burned.
    /// The distributor is NOT set during the constructor because it likely
    /// doesn't exist at that point. For example, Balancer needs the paired
    /// erc20 tokens to exist before the trading pool can be built.
    /// @param distributorAccount_ The distributor according to the admin.
    function burnDistributor(address distributorAccount_)
        external
        onlyPhase(Phase.ZERO)
    {
        require(
            hasRole(DISTRIBUTOR_BURNER, msg.sender),
            "ONLY_DISTRIBUTOR_BURNER"
        );
        scheduleNextPhase(uint32(block.number));
        _burn(distributorAccount_, balanceOf(distributorAccount_));
    }

    /// Anyone can emit a `TreasuryAsset` event to notify token holders that
    /// an asset could be redeemed by burning `RedeemableERC20` tokens.
    /// As this is callable by anon the events should be filtered by the
    /// indexer to those from trusted entities only.
    function newTreasuryAsset(address newTreasuryAsset_) external {
        emit TreasuryAsset(msg.sender, newTreasuryAsset_);
    }

    /// Redeem (burn) tokens for treasury assets.
    /// Tokens can be redeemed but NOT transferred during `Phase.ONE`.
    ///
    /// Calculate the redeem value of tokens as:
    ///
    /// ```
    /// ( redeemAmount / redeemableErc20Token.totalSupply() )
    /// * token.balanceOf(address(this))
    /// ```
    ///
    /// This means that the users get their redeemed pro-rata share of the
    /// outstanding token supply burned in return for a pro-rata share of the
    /// current balance of each treasury asset.
    ///
    /// I.e. whatever % of redeemable tokens the sender burns is the % of the
    /// current treasury assets they receive.
    function redeem(
        IERC20[] calldata treasuryAssets_,
        uint256 redeemAmount_
    )
        external
        onlyPhase(Phase.ONE)
        nonReentrant
    {
        // The fraction of the assets we release is the fraction of the
        // outstanding total supply of the redeemable burned.
        // Every treasury asset is released in the same proportion.
        uint256 supplyBeforeBurn_ = totalSupply();

        // Redeem __burns__ tokens which reduces the total supply and requires
        // no approval.
        // `_burn` reverts internally if needed (e.g. if burn exceeds balance).
        // This function is `nonReentrant` but we burn before redeeming anyway.
        _burn(msg.sender, redeemAmount_);

        for(uint256 i_ = 0; i_ < treasuryAssets_.length; i_++) {
            IERC20 ithRedeemable_ = treasuryAssets_[i_];
            uint256 assetAmount_
                = ( ithRedeemable_.balanceOf(address(this)) * redeemAmount_ )
                / supplyBeforeBurn_;
            emit Redeem(
                msg.sender,
                address(ithRedeemable_),
                [redeemAmount_, assetAmount_]
            );
            ithRedeemable_.safeTransfer(
                msg.sender,
                assetAmount_
            );
        }
    }

    /// Sanity check to ensure `Phase.ONE` is the final phase.
    /// @inheritdoc Phased
    // Slither false positive. This is overriding an Open Zeppelin hook.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _beforeScheduleNextPhase(uint32 nextPhaseBlock_)
        internal
        override
        virtual
    {
        super._beforeScheduleNextPhase(nextPhaseBlock_);
        assert(currentPhase() < Phase.TWO);
    }

    /// Apply phase sensitive transfer restrictions.
    /// During `Phase.ZERO` only tier requirements apply.
    /// During `Phase.ONE` all transfers except burns are prevented.
    /// If a transfer involves either a sender or receiver with the relevant
    /// `unfreezables` state it will ignore these restrictions.
    /// @inheritdoc ERC20
    // Slither false positive. This is overriding an Open Zeppelin hook.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint256 amount_
    )
        internal
        override
        virtual
    {
        super._beforeTokenTransfer(sender_, receiver_, amount_);

        // Sending tokens to this contract (e.g. instead of redeeming) is
        // always an error.
        require(receiver_ != address(this), "TOKEN_SEND_SELF");

        // Some contracts may attempt a preflight (e.g. Balancer) of a 0 amount
        // transfer.
        // We don't want to accidentally cause external errors due to zero
        // value transfers.
        if (amount_ > 0
            // The sender and receiver lists bypass all access restrictions.
            && !(hasRole(SENDER, sender_) || hasRole(RECEIVER, receiver_))) {
            // During `Phase.ZERO` transfers are only restricted by the
            // tier of the recipient.
            if (currentPhase() == Phase.ZERO) {
                require(
                    isTier(receiver_, minimumTier),
                    "MIN_TIER"
                );
            }
            // During `Phase.ONE` only token burns are allowed.
            else if (currentPhase() == Phase.ONE) {
                require(receiver_ == address(0), "FROZEN");
            }
            // There are no other phases.
            else { assert(false); }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

struct ERC20Config {
    string name;
    string symbol;
}

// SPDX-License-Identifier: CAL

pragma solidity ^0.8.10;

import { TierUtil } from "../libraries/TierUtil.sol";
import { ITier } from "./ITier.sol";

/// @title TierByConstruction
/// @notice `TierByConstruction` is a base contract for other
/// contracts to inherit from.
///
/// It exposes `isTier` and the corresponding modifier `onlyTier`.
///
/// This ensures that the address has held at least the given tier
/// since the contract was constructed.
///
/// We check against the construction time of the contract rather
/// than the current block to avoid various exploits.
///
/// Users should not be able to gain a tier for a single block, claim
/// benefits then remove the tier within the same block.
///
/// The construction block provides a simple and generic reference
/// point that is difficult to manipulate/predict.
///
/// Note that `ReadOnlyTier` contracts must carefully consider use
/// with `TierByConstruction` as they tend to return `0x00000000` for
/// any/all tiers held. There needs to be additional safeguards to
/// mitigate "flash tier" attacks.
///
/// Note that an account COULD be `TierByConstruction` then lower/
/// remove a tier, then no longer be eligible when they regain the
/// tier. Only _continuously held_ tiers are valid against the
/// construction block check as this is native behaviour of the
/// `report` function in `ITier`.
///
/// Technically the `ITier` could re-enter the `TierByConstruction`
/// so the `onlyTier` modifier runs AFTER the modified function.
///
/// @dev Enforces tiers held by contract contruction block.
/// The construction block is compared against the blocks returned by `report`.
/// The `ITier` contract is paramaterised and set during construction.
contract TierByConstruction {
    ITier public tierContract;
    uint256 public constructionBlock;

    constructor(ITier tierContract_) {
        tierContract = tierContract_;
        constructionBlock = block.number;
    }

    /// Check if an account has held AT LEAST the given tier according to
    /// `tierContract` since construction.
    /// The account MUST have held the tier continuously from construction
    /// until the "current" state according to `report`.
    /// Note that `report` PROBABLY is current as at the block this function is
    /// called but MAYBE NOT.
    /// The `ITier` contract is free to manage reports however makes sense.
    ///
    /// @param account_ Account to check status of.
    /// @param minimumTier_ Minimum tier for the account.
    /// @return True if the status is currently held.
    function isTier(address account_, ITier.Tier minimumTier_)
        public
        view
        returns (bool)
    {
        return constructionBlock >= TierUtil.tierBlock(
            tierContract.report(account_),
            minimumTier_
        );
    }

    /// Modifier that restricts access to functions depending on the tier
    /// required by the function.
    ///
    /// `isTier` involves an external call to tierContract.report.
    /// `require` happens AFTER the modified function to avoid rentrant
    /// `ITier` code.
    /// Also `report` from `ITier` is `view` so the compiler will error on
    /// attempted state modification.
    // solhint-disable-next-line max-line-length
    /// https://consensys.github.io/smart-contract-best-practices/recommendations/#use-modifiers-only-for-checks
    ///
    /// Do NOT use this to guard setting the tier on an `ITier` contract.
    /// The initial tier would be checked AFTER it has already been
    /// modified which is unsafe.
    ///
    /// @param account_ Account to enforce tier of.
    /// @param minimumTier_ Minimum tier for the account.
    modifier onlyTier(address account_, ITier.Tier minimumTier_) {
        _;
        require(
            isTier(account_, minimumTier_),
            "MINIMUM_TIER"
        );
    }
}

// SPDX-License-Identifier: CAL

pragma solidity ^0.8.10;

import { ITier } from "../tier/ITier.sol";

/// @title TierUtil
/// @notice `TierUtil` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtBlockFromReport`: Returns the highest status achieved relative to
/// a block number and report. Statuses gained after that block are ignored.
/// - `tierBlock`: Returns the block that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateBlocksForTierRange`: Updates a report with a block
/// number for every tier in a range.
/// - `updateReportWithTierAtBlock`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this factors
/// that out.
library TierUtil {

    /// UNINITIALIZED is 0xFF.. as it is infinitely in the future.
    uint256 public constant UNINITIALIZED
        = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// Returns the highest tier achieved relative to a block number
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.number` but not always. Tiers gained after the
    /// reference block are ignored.
    ///
    /// When the `report` comes from a later block than the `blockNumber` this
    /// means the user must have held the tier continuously from `blockNumber`
    /// _through_ to the report block.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITier`.
    /// @param blockNumber_ The block number to check the tiers against.
    /// @return The highest tier held since `blockNumber` as per `report`.
    function tierAtBlockFromReport(
        uint256 report_,
        uint256 blockNumber_
    )
        internal pure returns (ITier.Tier)
    {
        for (uint256 i_ = 0; i_ < 8; i_++) {
            if (uint32(uint256(report_ >> (i_*32))) > uint32(blockNumber_)) {
                return ITier.Tier(i_);
            }
        }
        return ITier.Tier(8);
    }

    /// Returns the block that a given tier has been held since from a report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtBlockFromReport`.
    ///
    /// @param report_ The report to read a block number from.
    /// @param tier_ The Tier to read the block number for.
    /// @return The block number this has been held since.
    function tierBlock(uint256 report_, ITier.Tier tier_)
        internal
        pure
        returns (uint256)
    {
        // ZERO is a special case. Everyone has always been at least ZERO,
        // since block 0.
        if (tier_ == ITier.Tier.ZERO) { return 0; }

        uint256 offset_ = (uint256(tier_) - 1) * 32;
        return uint256(uint32(
            uint256(
                report_ >> offset_
            )
        ));
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(uint256 report_, ITier.Tier tier_)
        internal
        pure
        returns (uint256)
    {
        uint256 offset_ = uint256(tier_) * 32;
        uint256 mask_ = (UNINITIALIZED >> offset_) << offset_;
        return report_ | mask_;
    }

    /// Updates a report with a block number for every status integer in a
    /// range.
    ///
    /// Does nothing if the end status is equal or less than the start status.
    /// @param report_ The report to update.
    /// @param startTier_ The `Tier` at the start of the range (exclusive).
    /// @param endTier_ The `Tier` at the end of the range (inclusive).
    /// @param blockNumber_ The block number to set for every status
    /// in the range.
    /// @return The updated report.
    function updateBlocksForTierRange(
        uint256 report_,
        ITier.Tier startTier_,
        ITier.Tier endTier_,
        uint256 blockNumber_
    )
        internal pure returns (uint256)
    {
        uint256 offset_;
        for (uint256 i_ = uint256(startTier_); i_ < uint256(endTier_); i_++) {
            offset_ = i_ * 32;
            report_ =
                (report_ & ~uint256(uint256(uint32(UNINITIALIZED)) << offset_))
                | uint256(blockNumber_ << offset_);
        }
        return report_;
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and
    /// `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the
    /// current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when
    /// calling this function and need to do other things in the calling scope
    /// with it.
    ///
    /// @param report_ The report to update.
    /// @param startTier_ The tier to start updating relative to. Data above
    /// this tier WILL BE LOST so probably should be the current tier.
    /// @param endTier_ The new highest tier held, at the given block number.
    /// @param blockNumber_ The block number to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return The updated report.
    function updateReportWithTierAtBlock(
        uint256 report_,
        ITier.Tier startTier_,
        ITier.Tier endTier_,
        uint256 blockNumber_
    )
        internal pure returns (uint256)
    {
        return endTier_ < startTier_
            ? truncateTiersAbove(report_, endTier_)
            : updateBlocksForTierRange(
                report_,
                startTier_,
                endTier_,
                blockNumber_
            );
    }

}

// SPDX-License-Identifier: CAL

pragma solidity ^0.8.10;

/// @title ITier
/// @notice `ITier` is a simple interface that contracts can
/// implement to provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving,
/// conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITier`:
/// - MUST represent held tiers with the `Tier` enum.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the block each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at ONE; ZERO is implied if no tier has ever
///     been held.
///   - `Tier.ZERO` is NOT encoded in the report, it is simply the fallback
///     value.
///   - If a tier is lost the block data is erased for that tier and will be
///     set if/when the tier is regained to the new block.
///   - If the historical block information is not available the report MAY
///     return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
/// - SHOULD implement `setTier`.
///   - Contracts SHOULD revert with `SET_TIER` error if they cannot
///     meaningfully set a tier directly.
///     For example a contract that can only derive a membership tier by
///     reading the state of an external contract cannot set tiers.
///   - Contracts implementing `setTier` SHOULD error with `SET_ZERO_TIER`
///     if `Tier.ZERO` is being set.
/// - MUST emit `TierChange` when `setTier` successfully writes a new tier.
///   - Contracts that cannot meaningfully set a tier are exempt.
interface ITier {

    /// 9 Possible tiers.
    /// Fits nicely as uint32 in uint256 which is helpful for internal storage
    /// concerns.
    /// 8 tiers can be achieved, ZERO is the tier when no tier has been
    /// achieved.
    enum Tier {
        ZERO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT
    }

    /// Every time a Tier changes we log start and end Tier against the
    /// account.
    /// This MAY NOT be emitted if reports are being read from the state of an
    /// external contract.
    /// @param account The account changing tier.
    /// @param startTier The previous tier the account held.
    /// @param endTier the newly acquired tier the account now holds.
    event TierChange(
        address indexed account,
        Tier indexed startTier,
        Tier indexed endTier
    );

    /// @notice Users can set their own tier by calling `setTier`.
    ///
    /// The contract that implements `ITier` is responsible for checking
    /// eligibility and/or taking actions required to set the tier.
    ///
    /// For example, the contract must take/refund any tokens relevant to
    /// changing the tier.
    ///
    /// Obviously the user is responsible for any approvals for this action
    /// prior to calling `setTier`.
    ///
    /// When the tier is changed a `TierChange` event will be emmited as:
    /// ```
    /// event TierChange(address account, Tier startTier, Tier endTier);
    /// ```
    ///
    /// The `setTier` function includes arbitrary data as the third
    /// parameter. This can be used to disambiguate in the case that
    /// there may be many possible options for a user to achieve some tier.
    ///
    /// For example, consider the case where `Tier.THREE` can be achieved
    /// by EITHER locking 1x rare NFT or 3x uncommon NFTs. A user with both
    /// could use `data` to explicitly state their intent.
    ///
    /// NOTE however that _any_ address can call `setTier` for any other
    /// address.
    ///
    /// If you implement `data` or anything that changes state then be very
    /// careful to avoid griefing attacks.
    ///
    /// The `data` parameter can also be ignored by the contract implementing
    /// `ITier`. For example, ERC20 tokens are fungible so only the balance
    /// approved by the user is relevant to a tier change.
    ///
    /// The `setTier` function SHOULD prevent users from reassigning
    /// `Tier.ZERO` to themselves.
    ///
    /// The `Tier.ZERO` status represents never having any status.
    /// @dev Updates the tier of an account.
    ///
    /// The implementing contract is responsible for all checks and state
    /// changes required to set the tier. For example, taking/refunding
    /// funds/NFTs etc.
    ///
    /// Contracts may disallow directly setting tiers, preferring to derive
    /// reports from other onchain data.
    /// In this case they should `revert("SET_TIER");`.
    ///
    /// @param account Account to change the tier for.
    /// @param endTier Tier after the change.
    /// @param data Arbitrary input to disambiguate ownership
    /// (e.g. NFTs to lock).
    function setTier(
        address account,
        Tier endTier,
        bytes memory data
    )
        external;

    /// @notice A tier report is a `uint256` that contains each of the block
    /// numbers each tier has been held continously since as a `uint32`.
    /// There are 9 possible tier, starting with `Tier.ZERO` for `0` offset or
    /// "never held any tier" then working up through 8x 4 byte offsets to the
    /// full 256 bits.
    ///
    /// Low bits = Lower tier.
    ///
    /// In hexadecimal every 8 characters = one tier, starting at `Tier.EIGHT`
    /// from high bits and working down to `Tier.ONE`.
    ///
    /// `uint32` should be plenty for any blockchain that measures block times
    /// in seconds, but reconsider if deploying to an environment with
    /// significantly sub-second block times.
    ///
    /// ~135 years of 1 second blocks fit into `uint32`.
    ///
    /// `2^8 / (365 * 24 * 60 * 60)`
    ///
    /// When a user INCREASES their tier they keep all the block numbers they
    /// already had, and get new block times for each increased tiers they have
    /// earned.
    ///
    /// When a user DECREASES their tier they return to `0xFFFFFFFF` (never)
    /// for every tier level they remove, but keep their block numbers for the
    /// remaining tiers.
    ///
    /// GUIs are encouraged to make this dynamic very clear for users as
    /// round-tripping to a lower status and back is a DESTRUCTIVE operation
    /// for block times.
    ///
    /// The intent is that downstream code can provide additional benefits for
    /// members who have maintained a certain tier for/since a long time.
    /// These benefits can be provided by inspecting the report, and by
    /// on-chain contracts directly,
    /// rather than needing to work with snapshots etc.
    /// @dev Returns the earliest block the account has held each tier for
    /// continuously.
    /// This is encoded as a uint256 with blocks represented as 8x
    /// concatenated uint32.
    /// I.e. Each 4 bytes of the uint256 represents a u32 tier start time.
    /// The low bits represent low tiers and high bits the high tiers.
    /// Implementing contracts should return 0xFFFFFFFF for lost &
    /// never-held tiers.
    ///
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256);
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}