pragma solidity >=0.8.0;



import "../helpers/Ownable.sol";
import "./Migrator.sol";
import "./interfaces/ILiquidityMigrationV2.sol";

interface ILiquidityMigrationV1 {
    function migrate(
        address user,
        address lp,
        address adapter,
        address strategy,
        uint256 slippage
    ) external;

    function refund(address user, address lp) external;

    function addAdapter(address adapter) external;

    function removeAdapter(address adapter) external;

    function updateController(address newController) external;

    function updateGeneric(address newGeneric) external;

    function updateUnlock(uint256 newUnlock) external;

    function transferOwnership(address newOwner) external;

    function staked(address user, address lp) external view returns (uint256);

    function controller() external view returns (address);
}

contract MigrationCoordinator is Migrator, Ownable{
    ILiquidityMigrationV1 public immutable liquidityMigrationV1;
    ILiquidityMigrationV2 public immutable liquidityMigrationV2;
    address public immutable migrationAdapter;
    address public migrator;

    modifier onlyMigrator() {
        require(msg.sender == migrator, "Not migrator");
        _;
    }

    constructor(
        address owner_,
        address liquidityMigrationV1_,
        address liquidityMigrationV2_,
        address migrationAdapter_
    ) public {
        _setOwner(owner_);
        migrator = msg.sender;
        liquidityMigrationV1 = ILiquidityMigrationV1(liquidityMigrationV1_);
        liquidityMigrationV2 = ILiquidityMigrationV2(liquidityMigrationV2_);
        migrationAdapter = migrationAdapter_;
    }

    function initiateMigration(address[] memory adapters) external onlyMigrator {
        // Remove current adapters to prevent further staking
        for (uint256 i = 0; i < adapters.length; i++) {
            liquidityMigrationV1.removeAdapter(adapters[i]);
        }
        // Generic receives funds, we want LiquidityMigrationV2 to receive the funds
        liquidityMigrationV1.updateGeneric(address(liquidityMigrationV2));
        // If controller is not zero address, set to zero address
        // Don't want anyone calling migrate until process is complete
        if (liquidityMigrationV1.controller() != address(0))
          liquidityMigrationV1.updateController(address(0));
        // Finally, unlock the migration contract
        liquidityMigrationV1.updateUnlock(block.timestamp);
    }

    function migrateLP(address[] memory users, address lp, address adapter) external onlyMigrator {
        // Set controller to allow migration
        liquidityMigrationV1.updateController(address(this));
        // Set adapter to allow migration
        liquidityMigrationV1.addAdapter(migrationAdapter);
        // Migrate liquidity for all users passed in array
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            // Get the staked amount as it gets deleted during migration
            uint256 staked = liquidityMigrationV1.staked(user, lp);
            // Migrate the LP tokens
            liquidityMigrationV1.migrate(user, lp, migrationAdapter, address(this), 0);
            // Update the staked amount on the new contract
            liquidityMigrationV2.setStake(user, lp, adapter, staked);
        }
        // Remove controller to prevent further migration
        liquidityMigrationV1.updateController(address(0));
        // Remove adapter to prevent further staking
        liquidityMigrationV1.removeAdapter(migrationAdapter);
    }

    // Allow users to withdraw from LiquidityMigrationV1
    function withdraw(address lp) external {
        liquidityMigrationV1.refund(msg.sender, lp);
    }

    // Refund wrapper since MigrationCoordinator is now owner of LiquidityMigrationV1
    function refund(address user, address lp) external onlyOwner {
      liquidityMigrationV1.refund(user, lp);
    }

    function addAdapter(address adapter) external onlyOwner {
      liquidityMigrationV1.addAdapter(adapter);
    }

    function removeAdapter(address adapter) external onlyOwner {
      liquidityMigrationV1.removeAdapter(adapter);
    }

    function updateMigrator(address newMigrator)
        external
        onlyOwner
    {
        require(migrator != newMigrator, "Already exists");
        migrator = newMigrator;
    }

    function transferLiquidityMigrationOwnership(address newOwner) external onlyOwner {
        liquidityMigrationV1.transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

import "../ecosystem/openzeppelin/utils/Context.sol";

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
    function _setOwner(address owner_) 
        internal
    {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
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

pragma solidity >=0.8.0;

import "@enso/contracts/contracts/interfaces/IStrategy.sol";
import "@enso/contracts/contracts/interfaces/IStrategyRouter.sol";

contract Migrator {
    function deposit(
        IStrategy,
        IStrategyRouter,
        uint256,
        uint256,
        bytes memory
    ) external {}

    function initialized(address) external view returns (bool) {
        return true;
    }

    function transfer(address, uint256) external view returns (bool) {
        return true;
    }

    function balanceOf(address) external view returns (uint256) {
        return 0;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface ILiquidityMigrationV2 {
    function setStake(address user, address lp, address adapter, uint256 amount) external;

    function migrateAll(address lp, address adapter) external;
}

// SPDX-License-Identifier: WTFPL

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

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IStrategyToken.sol";
import "./IOracle.sol";
import "./IWhitelist.sol";
import "../helpers/StrategyTypes.sol";

interface IStrategy is IStrategyToken, StrategyTypes {
    function approveToken(
        address token,
        address account,
        uint256 amount
    ) external;

    function approveDebt(
        address token,
        address account,
        uint256 amount
    ) external;

    function approveSynths(
        address account,
        uint256 amount
    ) external;

    function setStructure(StrategyItem[] memory newItems) external;

    function setCollateral(address token) external;

    function withdrawAll(uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external returns (uint256);

    function delegateSwap(
        address adapter,
        uint256 amount,
        address tokenIn,
        address tokenOut
    ) external;

    function settleSynths() external;

    function issueStreamingFee() external;

    function updateTokenValue(uint256 total, uint256 supply) external;

    function updatePerformanceFee(uint16 fee) external;

    function updateRebalanceThreshold(uint16 threshold) external;

    function updateTradeData(address item, TradeData memory data) external;

    function lock() external;

    function unlock() external;

    function locked() external view returns (bool);

    function items() external view returns (address[] memory);

    function synths() external view returns (address[] memory);

    function debt() external view returns (address[] memory);

    function rebalanceThreshold() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function getPercentage(address item) external view returns (int256);

    function getTradeData(address item) external view returns (TradeData memory);

    function getPerformanceFeeOwed(address account) external view returns (uint256);

    function controller() external view returns (address);

    function manager() external view returns (address);

    function oracle() external view returns (IOracle);

    function whitelist() external view returns (IWhitelist);

    function supportsSynths() external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "../interfaces/IStrategyController.sol";

interface IStrategyRouter {
    enum RouterCategory {GENERIC, LOOP, SYNTH, BATCH}

    function rebalance(address strategy, bytes calldata data) external;

    function restructure(address strategy, bytes calldata data) external;

    function deposit(address strategy, bytes calldata data) external;

    function withdraw(address strategy, bytes calldata) external;

    function controller() external view returns (IStrategyController);

    function category() external view returns (RouterCategory);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "./IERC20NonStandard.sol";

interface IStrategyToken is IERC20NonStandard {
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./registries/ITokenRegistry.sol";
import "./IStrategy.sol";

interface IOracle {
    function weth() external view returns (address);

    function susd() external view returns (address);

    function tokenRegistry() external view returns (ITokenRegistry);

    function estimateStrategy(IStrategy strategy) external view returns (uint256, int256[] memory);

    function estimateItem(
        uint256 balance,
        address token
    ) external view returns (int256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IWhitelist {
    function approve(address account) external;

    function revoke(address account) external;

    function approved(address account) external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface StrategyTypes {

    enum ItemCategory {BASIC, SYNTH, DEBT, RESERVE}
    enum EstimatorCategory {
      DEFAULT_ORACLE,
      CHAINLINK_ORACLE,
      UNISWAP_TWAP_ORACLE,
      SUSHI_TWAP_ORACLE,
      STRATEGY,
      BLOCKED,
      AAVE_V1,
      AAVE_V2,
      AAVE_DEBT,
      BALANCER,
      COMPOUND,
      CURVE,
      CURVE_GAUGE,
      SUSHI_LP,
      SUSHI_FARM,
      UNISWAP_V2_LP,
      UNISWAP_V3_LP,
      YEARN_V1,
      YEARN_V2
    }
    enum TimelockCategory {RESTRUCTURE, THRESHOLD, REBALANCE_SLIPPAGE, RESTRUCTURE_SLIPPAGE, TIMELOCK, PERFORMANCE}

    struct StrategyItem {
        address item;
        int256 percentage;
        TradeData data;
    }

    struct TradeData {
        address[] adapters;
        address[] path;
        bytes cache;
    }

    struct InitialState {
        uint32 timelock;
        uint16 rebalanceThreshold;
        uint16 rebalanceSlippage;
        uint16 restructureSlippage;
        uint16 performanceFee;
        bool social;
        bool set;
    }

    struct StrategyState {
        uint32 timelock;
        uint16 rebalanceSlippage;
        uint16 restructureSlippage;
        bool social;
        bool set;
    }

    /**
        @notice A time lock requirement for changing the state of this Strategy
        @dev WARNING: Only one TimelockCategory can be pending at a time
    */
    struct Timelock {
        TimelockCategory category;
        uint256 timestamp;
        bytes data;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IERC20NonStandard {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "../IEstimator.sol";

interface ITokenRegistry {
    function itemCategories(address token) external view returns (uint256);

    function estimatorCategories(address token) external view returns (uint256);

    function estimators(uint256 categoryIndex) external view returns (IEstimator);

    function getEstimator(address token) external view returns (IEstimator);

    function addEstimator(uint256 estimatorCategoryIndex, address estimator) external;

    function addItem(uint256 itemCategoryIndex, uint256 estimatorCategoryIndex, address token) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IEstimator {
    function estimateItem(
        uint256 balance,
        address token
    ) external view returns (int256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IStrategy.sol";
import "./IStrategyRouter.sol";
import "./IOracle.sol";
import "./IWhitelist.sol";
import "../helpers/StrategyTypes.sol";

interface IStrategyController is StrategyTypes {
    function setupStrategy(
        address manager_,
        address strategy_,
        InitialState memory state_,
        address router_,
        bytes memory data_
    ) external payable;

    function deposit(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external payable;

    function withdrawETH(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external;

    function withdrawWETH(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external;

    function rebalance(
        IStrategy strategy,
        IStrategyRouter router,
        bytes memory data
    ) external;

    function restructure(
        IStrategy strategy,
        StrategyItem[] memory strategyItems
    ) external;

    function finalizeStructure(
        IStrategy strategy,
        IStrategyRouter router,
        bytes memory data
    ) external;

    function updateValue(
        IStrategy strategy,
        TimelockCategory category,
        uint256 newValue
    ) external;

    function finalizeValue(address strategy) external;

    function openStrategy(IStrategy strategy) external;

    function setStrategy(IStrategy strategy) external;

    function initialized(address strategy) external view returns (bool);

    function strategyState(address strategy) external view returns (StrategyState memory);

    function verifyStructure(address strategy, StrategyItem[] memory newItems)
        external
        view
        returns (bool);

    function oracle() external view returns (IOracle);

    function whitelist() external view returns (IWhitelist);
}