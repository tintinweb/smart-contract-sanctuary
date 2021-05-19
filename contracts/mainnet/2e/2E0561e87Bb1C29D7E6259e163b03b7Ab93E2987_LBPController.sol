// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./abstracts/ConfigurableRightsPool.sol";
import "./abstracts/CRPFactory.sol";
import "./abstracts/BRegistry.sol";
import "./abstracts/IERC20DecimalsExt.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/BConst.sol";

// LBPController is a contract that acts as a very limited deployer and controller of a Balancer CRP Liquidity Pool
// The purpose it was created instead of just using DSProxy is to have a better control over the created pool, such as:
// - All of the LBP Parameters are hardcoded into the contract, thus are independent from human or software errors
// - Stop swapping immedialy at pool deployment, so nobody can swap until the StartBlock of the LBP
// - Allow to enable swapping only at StartBlock of the LBP, by anyone (so we don't rely only on ourselves for starting the LBP - mitigates start delay because of network congestions)
// - As the LBPController is the only controller of the CRP - all code here is set in stone - thus GradualWeights are called only once in constructor and cannot be altered afterwards, etc
// - We have limited anyone to add or remove liquidity or tokens from the pool - even the owner.
// - Although we have an escape-hatch to withdraw liquidity ("but it's also disabled while the pool is running" - TODO: we shall decide on escape-hatch behavior)
// - After EndBlock - anyone can stop the pool and liquidate it - all the assets will be transferred to the LBP Owner
// - Pool is liquidated by removing the tokens
// - TODO: "BONUS: We have an integrated poker-miner, which will use arbitrage on the weight change, for the users to extract more tokens from the pool, which will also incentivise them to do Poking"

/// @title LBP Controller
/// @author oiler.network
/// @notice Helper contract used to initialize and manage the Balancer LBP and its underlying contracts such as BPool and CRP
contract LBPController is BConst, Ownable {
  /// @dev Enum-like constants used as array-indices for better readability
  uint constant TokenIndex = 0; 
  uint constant CollateralIndex = 1;

  /// @dev Number of different tokens used in the pool -> collateral and token
  uint constant ConstituentsCount = 2;

  /// @dev Balancer's Configurable Rights Pools Factory address
  address public CRPFactoryAddress;

  /// @dev Balancer's Registry address
  address public BRegistryAddress;

  /// @dev Balancer Pools Factory address
  address public BFactoryAddress;

  /// @dev Address of the token to be distributed during the LBP
  address public tokenAddress;

  /// @dev Address of the collateral token to be used during the LBP
  address public collateralAddress;

  uint public constant initialTokenAmount = 3_500_000;    // LBP initial token amount
  uint public constant initialCollateralAmount = 800_000; // LBP initial collateral amount
  uint public constant startTokenWeight = 36 * BONE;      // 90% LBP initial token weight
  uint public constant startCollateralWeight = 4 * BONE;  // 10% LBP initial collateral weight
  uint public constant endTokenWeight = 16 * BONE;        // 40% LBP end token weight
  uint public constant endCollateralWeight = 24 * BONE;   // 60% LBP end collateral weight
  uint public constant swapFee = 0.01 * 1e18;             // x% fee taken on BPool swaps - it is protecting the pool against the bot activity during the LBP. We can't use BONE here, cause this fractional multiplication is still treatened like an integer literal

  uint immutable public startBlock; // LBP start block is when Gradual Weights start to shift and pool can be started
  uint immutable public endBlock;   // LBP end block is when Gradual Weights shift stops and pool can be ended with funds withdrawal
  uint public listed;               // Listed just returns 1 when the pool is listed in the BRegistry

  // [multisig] ----owns----> [LBPCONTROLLER] ----controls----> [CRP] ----controls----> [BPOOL]
  ConfigurableRightsPool public crp;
  BPool public pool;

  ConfigurableRightsPool.PoolParams public poolParams;
  ConfigurableRightsPool.CrpParams public crpParams;
  RightsManager.Rights public rights;


  /**
   * @param _CRPFactoryAddress - Balancer CRP Factory address
   * @param _BRegistryAddress - Balancer registry address
   * @param _BFactoryAddress - Balancer Pools Factory address
   * @param _tokenAddress - Address of the token to be distributed during the LBP
   * @param _collateralAddress - Collateral address
   * @param _startBlock - LBP start block. NOTE: must be bigger than the block number in which the LBPController deployment tx will be included to the chain
   * @param _endBlock - LBP end block. NOTE: LBP duration cannot be longer than 500k blocks (2-3 months)
   * @param _owner - Address of the Multisig contract to become the owner of the LBP Controller
   */
  constructor (
      address _CRPFactoryAddress,
      address _BRegistryAddress,
      address _BFactoryAddress,
      address _tokenAddress,
      address _collateralAddress,
      uint _startBlock,
      uint _endBlock,
      address _owner
    ) Ownable() // Owner - multisig address for LBP Management and retrieval of funds after the LBP ends
  {
    require(_startBlock > block.number, "LBPController: startBlock must be in the future");
    require(_startBlock < _endBlock, "LBPController: endBlock must be greater than startBlock");
    require(_endBlock < _startBlock + 500_000, "LBPController: endBlock is too far in the future");

    Ownable.transferOwnership(_owner);
    CRPFactoryAddress = _CRPFactoryAddress;
    BRegistryAddress = _BRegistryAddress;
    BFactoryAddress = _BFactoryAddress;
    tokenAddress = _tokenAddress;
    collateralAddress = _collateralAddress;

    startBlock = _startBlock;
    endBlock = _endBlock;

    // We don't use SafeMath in this contract because the tokens are specified by us in constructor, and multiplications will not overflow
    uint initialTokenAmountWei = (10**IERC20DecimalsExt(tokenAddress).decimals()) * initialTokenAmount;
    uint initialCollateralAmountWei = (10**IERC20DecimalsExt(collateralAddress).decimals()) * initialCollateralAmount;
    
    address[] memory constituentTokens = new address[](ConstituentsCount);
    constituentTokens[TokenIndex] = tokenAddress;
    constituentTokens[CollateralIndex] = collateralAddress;

    uint[] memory tokenBalances = new uint[](ConstituentsCount);
    tokenBalances[TokenIndex] = initialTokenAmountWei;
    tokenBalances[CollateralIndex] = initialCollateralAmountWei;

    uint[] memory tokenWeights = new uint[](ConstituentsCount);
    tokenWeights[TokenIndex] = startTokenWeight;
    tokenWeights[CollateralIndex] = startCollateralWeight;
    
    poolParams = ConfigurableRightsPool.PoolParams(
      "APWLBP",         // string poolTokenSymbol;
      "APWineTokenLBP",  // string poolTokenName;
      constituentTokens,// address[] constituentTokens;
      tokenBalances,    // uint[] tokenBalances;
      tokenWeights,     // uint[] tokenWeights;
      swapFee           // uint swapFee;
    );

    crpParams = ConfigurableRightsPool.CrpParams(
      100 * BONE,          // uint initialSupply - amount of LiquidityTokens the owner of the pool gets when creating pool
      _endBlock - _startBlock - 1, // uint minimumWeightChangeBlockPeriod - (NOTE: this does not restrict poking interval) We lock the gradualUpdate time to be equal to the LBP length
      _endBlock - _startBlock - 1  // uint addTokenTimeLockInBlocks - when adding a new token (we don't do it) after creation of the pool - there's a commit period before it appears. We limit it to LBP length
    );

    rights = RightsManager.Rights(
      true, // bool canPauseSwapping; = true - so we can enable swapping only during the LBP event
      false,// bool canChangeSwapFee; = false - we cannot change fees
      true, // bool canChangeWeights; = true - to be able to do updateGradualWeights (and then poke)
      true, // bool canAddRemoveTokens; = true - so we can remove tokens to kill the pool. It also allows adding tokens, but we don't have these functions
      true, // bool canWhitelistLPs; = true - so nobody, even owner - cannot add more liquidity to the pool without whitelisting, and we don't have whitelisting functions - so Whitelist is always empty
      false // bool canChangeCap; = false - not needed, as we protect that nobody can add Liquidity by using an empty and immutable Whitelisting above already
    );
  }

  /// @notice Creates the CRP smart pool and initializes its parameters
  /// @dev Needs owner to have approved the tokens and collateral before calling this (manually and externally)
  /// @dev This LBPController becomes the Controller of the CRP and holds its liquidity tokens
  /// @dev Most of the logic was taken from https://github.com/balancer-labs/bactions-proxy/blob/master/contracts/BActions.sol
  function createSmartPool() external onlyOwner {
    require(address(crp) == address(0), "LBPController.createSmartPool, pool already exists");
    CRPFactory factory = CRPFactory(CRPFactoryAddress);

    require(poolParams.constituentTokens.length == ConstituentsCount, "ERR_LENGTH_MISMATCH");
    require(poolParams.tokenBalances.length == ConstituentsCount, "ERR_LENGTH_MISMATCH");
    require(poolParams.tokenWeights.length == ConstituentsCount, "ERR_LENGTH_MISMATCH");

    crp = factory.newCrp(BFactoryAddress, poolParams, rights);

    // Pull the tokens and collateral from Owner and Approve them to CRP
    IERC20 token = IERC20(poolParams.constituentTokens[TokenIndex]);
    require(token.transferFrom(msg.sender, address(this), poolParams.tokenBalances[TokenIndex]), "ERR_TRANSFER_FAILED");
    _safeApprove(token, address(crp), poolParams.tokenBalances[TokenIndex]);

    IERC20 collateral = IERC20(poolParams.constituentTokens[CollateralIndex]);
    require(collateral.transferFrom(msg.sender, address(this), poolParams.tokenBalances[CollateralIndex]), "ERR_TRANSFER_FAILED");
    _safeApprove(collateral, address(crp), poolParams.tokenBalances[CollateralIndex]);

    crp.createPool(
      crpParams.initialSupply,
      crpParams.minimumWeightChangeBlockPeriod,
      crpParams.addTokenTimeLockInBlocks
    );

    pool = BPool(crp.bPool());

    // Disable swapping. Can be enabled back only when LBP starts
    crp.setPublicSwap(false);
    
    // Initialize Gradual Weights shift for the whole LBP duration
    uint[] memory endWeights = new uint[](ConstituentsCount);
    endWeights[TokenIndex] = endTokenWeight;
    endWeights[CollateralIndex] = endCollateralWeight;
    crp.updateWeightsGradually(endWeights, startBlock, endBlock);
  }

  /// @notice Registers the newly created BPool into the Balancer Registry, so it appears on Balancer app website
  /// @dev Can only be called by the Owner after createSmartPool()
  function registerPool() external onlyOwner {
    require (address(pool) != address(0), "Pool doesn't exist yet");
    require (listed == 0, "Pool already registered");
    listed = BRegistry(BRegistryAddress).addPoolPair(address(pool), tokenAddress, collateralAddress);
  }

  /// @notice Starts the trading on the pool
  /// @dev Can be called by anyone after LBP start block
  function startPool() external {
    require(block.number >= startBlock, "LBP didn't start yet");
    require(block.number <= endBlock, "LBP already ended");
    crp.setPublicSwap(true);
  }
  
  /// @notice End the trading on the pool, destroys pool, and sends all funds to Owner
  /// @notice Works only if LBPController has 100% of LP Pool Tokens in it,
  /// @notice otherwise one of the removeToken() will lack them and revert the entire endPool() transaction
  /// @dev Can be called by anyone after LBP end block
  function endPool() external {
    require(block.number > endBlock, "LBP didn't end yet");
    crp.setPublicSwap(false);

    // Destroy the pool by removing all tokens, and transfer the funds to Owner
    crp.removeToken(collateralAddress);
    crp.removeToken(tokenAddress);
    IERC20 collateral = IERC20(collateralAddress);
    IERC20 token = IERC20(tokenAddress);
    uint collateralBalance = collateral.balanceOf(address(this));
    uint tokenBalance = token.balanceOf(address(this));
    collateral.transfer(owner(), collateralBalance);
    token.transfer(owner(), tokenBalance);
  }

  /// @notice Escape Hatch - in case the Owner wants to withdraw Liquidity Tokens
  /// @dev If we withdraw the LP Tokens - we cannot kill the pool with endPool() unless we put 100% of LP Tokens back.
  /// @dev All the underlying assets of bPool can be withdrawn if you have LP Tokens - via exitPool() function of CRP.
  /// @dev You cannot withdraw 100% of assets because of bPool MIN_BALANCE restriction (minimum balance of any token in bPool should be at least 1 000 000 wei).
  /// @dev But you can withdraw 99.999% of assets (BONE*99999/1000) which leaves just 1 Collateral token and 17 Tokens in bPool if called before LBP has any trades.
  /// @dev This escape hatch is deliberately not disabled during the LBP run (although we could) - just for the sake of our peace of mind - that we can withdraw anytime.
  /// @dev If you do a withdrawal (partial or full) - you can still endPool() if you put all the remaining LP Token balance back to LBPController.
 function withdrawLBPTokens() public onlyOwner {
    uint amount = crp.balanceOf(address(this));
    require(crp.transfer(msg.sender, amount), "ERR_TRANSFER_FAILED");
  }

  /// @notice Poke Weights must be called at regular intervals - so the LBP price gradually changes
  /// @dev Can be called by anyone after LBP start block
  /// @dev Just calling CRP function - for simpler FrontEnd access
  function pokeWeights() external {
    crp.pokeWeights();
  }

  /// @notice Get the current weights of the LBP
  /// @return tokenWeight
  /// @return collateralWeight
  function getWeights() external view returns (uint tokenWeight, uint collateralWeight) {
    tokenWeight = pool.getNormalizedWeight(tokenAddress);
    collateralWeight = pool.getNormalizedWeight(collateralAddress);
  }

  // --- Internal ---

  /// @notice Safe approval is needed for tokens that require prior reset to 0, before setting another approval
  /// @dev Imported from https://github.com/balancer-labs/bactions-proxy/blob/master/contracts/BActions.sol
  function _safeApprove(IERC20 token, address spender, uint amount) internal {
    if (token.allowance(address(this), spender) > 0) {
      token.approve(spender, 0);
    }
      token.approve(spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./AbstractPool.sol";
import "./BPool.sol";
import "./BFactory.sol";

abstract contract ConfigurableRightsPool is AbstractPool {
  struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint[] tokenBalances;
    uint[] tokenWeights;
    uint swapFee;
  }

  struct CrpParams {
    uint initialSupply;
    uint minimumWeightChangeBlockPeriod;
    uint addTokenTimeLockInBlocks;
  }

  struct GradualUpdateParams {
    uint startBlock;
    uint endBlock;
    uint[] startWeights;
    uint[] endWeights;
  }

  struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
  }

  struct NewTokenParams {
        address addr;
        bool isCommitted;
        uint commitBlock;
        uint denorm;
        uint balance;
  }

  function createPool(uint initialSupply, uint minimumWeightChangeBlockPeriod, uint addTokenTimeLockInBlocks) external virtual;
  function createPool(uint initialSupply) external virtual;
  function updateWeightsGradually(uint[] calldata newWeights, uint startBlock, uint endBlock) external virtual;
  function removeToken(address token) external virtual;
  function bPool() external view virtual returns (BPool);
  function bFactory() external view virtual returns(BFactory);
  function minimumWeightChangeBlockPeriod() external view virtual returns(uint);
  function addTokenTimeLockInBlocks() external view virtual returns(uint);
  function bspCap() external view virtual returns(uint);
  function pokeWeights() external virtual;
  function gradualUpdate() external view virtual returns(GradualUpdateParams memory);
  function setCap(uint newCap) external virtual;
  function updateWeight(address token, uint newWeight) external virtual;
  function commitAddToken(address token, uint balance, uint denormalizedWeight) external virtual;
  function applyAddToken() external virtual;
  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;
  function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external virtual;
  function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn) external virtual;
  function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external virtual;
  function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn) external virtual;
  function whitelistLiquidityProvider(address provider) external virtual;
  function removeWhitelistedLiquidityProvider(address provider) external virtual;
  function mintPoolShareFromLib(uint amount) public virtual;
  function pushPoolShareFromLib(address to, uint amount) public virtual;
  function pullPoolShareFromLib(address from, uint amount) public virtual;
  function burnPoolShareFromLib(uint amount) public virtual;
  function rights() external view virtual returns(Rights memory);
  function newToken() external view virtual returns(NewTokenParams memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ConfigurableRightsPool.sol";
import "../lib/RightsManager.sol";


abstract contract CRPFactory {
  function newCrp(address factoryAddress, ConfigurableRightsPool.PoolParams calldata params, RightsManager.Rights calldata rights) external virtual returns (ConfigurableRightsPool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract BRegistry {
  /// @return listed is always 1 - Balancer guys said this return is not really used 
  function addPoolPair(address pool, address token1, address token2) external virtual returns(uint256 listed);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20DecimalsExt is IERC20 {
    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity 0.7.6;

import "./BColor.sol";

contract BConst is BBronze {
    uint public constant BONE              = 10**18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 8;

    uint public constant MIN_FEE           = BONE / 10**6;
    uint public constant MAX_FEE           = BONE / 10;
    uint public constant EXIT_FEE          = 0;

    uint public constant MIN_WEIGHT        = BONE;
    uint public constant MAX_WEIGHT        = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint public constant MIN_BALANCE       = BONE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20DecimalsExt.sol";
import "./BalancerOwnable.sol";

abstract contract AbstractPool is IERC20DecimalsExt, BalancerOwnable {
  function setSwapFee(uint swapFee) external virtual;
  function setPublicSwap(bool public_) external virtual;
  function isPublicSwap() external virtual view returns (bool);
  function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./AbstractPool.sol";

abstract contract BPool is AbstractPool {
  function finalize() external virtual;
  function bind(address token, uint balance, uint denorm) external virtual;
  function rebind(address token, uint balance, uint denorm) external virtual;
  function unbind(address token) external virtual;
  function isBound(address t) external view virtual returns (bool);
  function getCurrentTokens() external view virtual returns (address[] memory);
  function getFinalTokens() external view virtual returns(address[] memory);
  function getBalance(address token) external view virtual returns (uint);
  function getSpotPrice(address tokenIn, address tokenOut) external view virtual returns (uint spotPrice);
  function getSpotPriceSansFee(address tokenIn, address tokenOut) external view virtual returns (uint spotPrice);
  function getNormalizedWeight(address token) external view virtual returns (uint);
  function isFinalized() external view virtual returns (bool);
  function swapExactAmountIn(address tokenIn, uint tokenAmountIn, address tokenOut, uint minAmountOut, uint maxPrice) external virtual returns (uint tokenAmountOut, uint spotPriceAfter);
  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;
  function swapExactAmountOut(address tokenIn, uint maxAmountIn, address tokenOut, uint tokenAmountOut, uint maxPrice) external virtual;
  function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external virtual;
  function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn) external virtual;
  function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external virtual;
  function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn) external virtual;
  function getNumTokens() external virtual view returns(uint);
  function getDenormalizedWeight(address token) external virtual view returns (uint);
  function getSwapFee() external virtual view returns(uint);
  function getController() external virtual view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BPool.sol";

abstract contract BFactory {
  function newBPool() external virtual returns (BPool);
    function setBLabs(address b) external virtual;
    function collect(BPool pool) external virtual;
    function isBPool(address b) external virtual view returns (bool);
    function getBLabs() external virtual view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract BalancerOwnable {
  // We don't call it, but this contract is required in other inheritances
  function setController(address controller) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
pragma solidity 0.7.6;

library RightsManager {
  struct Rights {
  bool canPauseSwapping;
  bool canChangeSwapFee;
  bool canChangeWeights;
  bool canAddRemoveTokens;
  bool canWhitelistLPs;
  bool canChangeCap;
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.7.6;

abstract contract BColor {
    function getColor()
        external view virtual
        returns (bytes32);
}

contract BBronze is BColor {
    function getColor()
        external pure override
        returns (bytes32) {
            return bytes32("BRONZE");
        }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}