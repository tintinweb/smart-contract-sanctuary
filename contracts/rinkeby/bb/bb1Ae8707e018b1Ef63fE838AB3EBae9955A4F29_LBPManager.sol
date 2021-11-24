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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILBPFactory} from "./interfaces/ILBPFactory.sol";
import {ILBP} from "./interfaces/ILBP.sol";
import {IVault, JoinPoolRequest, IAsset, WeightedPoolExitKind, WeightedPoolJoinKind, ExitPoolRequest} from "./interfaces/IVault.sol";

/**
 * @title LBP Manager
 * @notice This contract manages a Balancer Liquidity Bootstrapping Pool (LBP) so that only a DAO can deploy and shutdown an LBP. After the LBP is deployed, trading must be enabled. While only the DAO has permission to deploy, shutdown and unwind the LBP, anyone can permissionlessly enable trading after the configured start time. When the LBP is completed (via `withdrawFromPool()`), the total balance of the LBP tokens will be sent to the DAO treasury.
 */
contract LBPManager {
  /* ========== STRUCTS ========== */

  /**
   * @title PoolConfiguration
   * @param name LBP pool token name
   * @param symbol LBP pool token symbol
   * @param tokens the token pairs for the LBP (e.g. POP & USDC - addresses must be listed in ascending order)
   * @param tokenAmounts the token amounts for the pair that will be transferred from the dao agent to this contract
   * @param startWeights the starting weights for the token pairs, e.g. 99 * 10**16 / 1 * 10**16 [.99 ether / .01 ether]
   * @param endWeights the ending weights for the token pairs, e.g. 50 * 10**16 / 50 * 10**16 [.5 ether / .5 ether]
   * @param durationInSeconds how long the LBP should last in seconds. this determines how long it takes for the weights to reach the end weight
   * @param swapFee fee to charge per trade. this fee is collected as part of the LBP proceeds
   * @param owner address that is allowed to manage the LBP. it defaults to the deployed address of this contract
   * @param swapEnabledOnStart determines wether trading can commence after LBP is deployed. defaults to false
   * @param startTime the time that trading can commence for the LBP. the `enableTrading()` function will require that the start time is in the past before trading can be enabled
   * @param deployed boolean set when LBP is deployed
   * @param pauser address that may pause trading
   */
  struct PoolConfiguration {
    string name;
    string symbol;
    IERC20[] tokens;
    uint256[] tokenAmounts;
    uint256[] startWeights;
    uint256[] endWeights;
    uint256 durationInSeconds;
    uint256 swapFee;
    address owner;
    bool swapEnabledOnStart;
    uint256 startTime;
    bool deployed;
    address pauser;
  }

  /**
   * @title Balancer
   * @dev addresses to deployed balancer contracts
   * @param lbpFactory LiquidityBootstrapFactory address
   * @param vault Balancer Vault address
   */
  struct Balancer {
    ILBPFactory lbpFactory;
    IVault vault;
  }

  /**
   * @title DAO
   * @dev DAO addresses
   * @param agent the dao address that can interact with the contract
   * @param treasury the dao treasury address where LBP proceeds will be sent
   */
  struct DAO {
    address agent;
    address treasury;
  }

  /* ========== STATE VARIABLES ========== */

  /**
   * @notice lbp deployed LBP address
   */
  ILBP public lbp;
  Balancer public balancer;
  PoolConfiguration public poolConfig;
  DAO public dao;

  /* ========== EVENTS ========== */

  event SwapEnabled(bool enabled);
  event CreatedPool(address poolAddress);
  event JoinedPool(bytes32 poolID);
  event ExitedPool(bytes32 poolID);

  /* ========== CONSTRUCTOR ========== */

  /**
   * @param _balancer see struct Balancer - balancer contract addresses
   * @param _name PoolConfiguration.name
   * @param _symbol PoolConfiguration.symbol
   * @param _tokens PoolConfiguration.tokens
   * @param _tokenAmounts PoolConfiguration.tokenAmounts
   * @param _startWeights PoolConfiguration.startWeights
   * @param _endWeights PoolConfiguration.endWeights
   * @param _swapFee PoolConfiguration.swapFee
   * @param _durationInSeconds PoolConfiguration.durationInSeconds
   * @param _startTime PoolConfiguration.startTime
   * @param _dao see struct DAO - DAO addresses
   */
  constructor(
    Balancer memory _balancer,
    string memory _name,
    string memory _symbol,
    IERC20[] memory _tokens,
    uint256[] memory _tokenAmounts,
    uint256[] memory _startWeights,
    uint256[] memory _endWeights,
    uint256 _swapFee,
    uint256 _durationInSeconds,
    uint256 _startTime,
    DAO memory _dao
  ) {
    balancer = _balancer;

    require(_durationInSeconds > 1 hours && _durationInSeconds < 5 days, "duration is out of bounds");
    require(_startTime > block.timestamp, "start time must be in future");

    dao = _dao;

    poolConfig = PoolConfiguration({
      name: _name,
      symbol: _symbol,
      tokens: _tokens,
      tokenAmounts: _tokenAmounts,
      startWeights: _startWeights,
      endWeights: _endWeights,
      durationInSeconds: _durationInSeconds,
      swapFee: _swapFee,
      owner: address(this),
      swapEnabledOnStart: false,
      startTime: _startTime,
      deployed: false,
      pauser: msg.sender
    });

    _approveBalancerVaultAsSpender();
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @dev Will deploy a balancer LBP. Can only be called by DAO.agent address
   * @notice This function requires that the DAO.agent has approved this address for spending pool tokens (e.g. POP & USDC). It will revert if the DAO.agent has not approved this contract for spending those tokens. The PoolConfiguration.tokenAmounts for the pool tokens will be transferred from the DAO.agent to this contract and forwarded to the LBP
   */
  function deployLBP() external {
    require(msg.sender == dao.agent, "Only DAO can call this");
    require(poolConfig.deployed != true, "The pool has already been deployed");
    require(_hasTokensForPool(), "Manager does not have enough pool tokens");

    poolConfig.deployed = true;

    lbp = ILBP(
      balancer.lbpFactory.create(
        poolConfig.name,
        poolConfig.symbol,
        poolConfig.tokens,
        poolConfig.startWeights,
        poolConfig.swapFee,
        poolConfig.owner,
        poolConfig.swapEnabledOnStart
      )
    );

    emit CreatedPool(address(lbp));

    uint256 endtime = poolConfig.startTime + poolConfig.durationInSeconds;

    lbp.updateWeightsGradually(poolConfig.startTime, endtime, poolConfig.endWeights);

    _joinPool();
  }

  /**
   * @notice Anyone can enable trading after the LBP has been deployed and the start time has been reached. Trading must be enabled for the pool to work.
   */
  function enableTrading() external {
    require(poolConfig.deployed, "Pool has not been deployed yet");
    require(poolConfig.startTime <= block.timestamp, "Trading can not be enabled yet");
    lbp.setSwapEnabled(true);
    emit SwapEnabled(true);
  }

  /**
   * @notice The DAO.agent can call this function to shutdown and unwind the pool. The proceeds will be forwarded to the DAO.treasury
   */
  function withdrawFromPool() external {
    require(poolConfig.deployed, "Pool has not been deployed yet");
    require(msg.sender == dao.agent, "not today, buddy");

    bytes32 poolId = lbp.getPoolId();

    uint256[] memory minAmountsOut = new uint256[](poolConfig.tokens.length);
    for (uint256 i; i < poolConfig.tokens.length; i++) {
      minAmountsOut[i] = uint256(0);
    }

    lbp.setSwapEnabled(false);

    ExitPoolRequest memory request = ExitPoolRequest({
      assets: _convertERC20sToAssets(poolConfig.tokens),
      minAmountsOut: minAmountsOut,
      userData: abi.encode(uint256(WeightedPoolExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT), _getLPTokenBalance(poolId)),
      toInternalBalance: false
    });

    balancer.vault.exitPool(poolId, address(this), dao.treasury, request);
    emit ExitedPool(poolId);
  }

  /**
   * @notice allows pauser to pause pool
   */
  function pause() external {
    require(msg.sender == poolConfig.pauser, "not allowed to pause trading");
    require(poolConfig.deployed, "pool not yet deployed");
    require(lbp.getSwapEnabled() == true, "pool must be unpaused");
    lbp.setSwapEnabled(false);
  }

  /**
   * @notice allows pauser to unpause pool
   */
  function unpause() external {
    require(msg.sender == poolConfig.pauser, "not allowed to unpause trading");
    require(poolConfig.deployed, "pool hasn't been deployed yet");
    require(lbp.getSwapEnabled() == false, "swap is already disabled");
    lbp.setSwapEnabled(true);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  function _joinPool() internal {
    uint256[] memory maxAmountsIn = new uint256[](poolConfig.tokens.length);
    for (uint256 i; i < poolConfig.tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    }

    JoinPoolRequest memory request = JoinPoolRequest({
      assets: _convertERC20sToAssets(poolConfig.tokens),
      maxAmountsIn: maxAmountsIn,
      userData: abi.encode(uint256(WeightedPoolJoinKind.INIT), poolConfig.tokenAmounts),
      fromInternalBalance: false
    });

    balancer.vault.joinPool(lbp.getPoolId(), address(this), address(this), request);
    emit JoinedPool(lbp.getPoolId());
  }

  function _approveBalancerVaultAsSpender() internal {
    (IERC20 pop, IERC20 usdc) = _getPoolTokens();
    pop.approve(address(balancer.vault), type(uint256).max);
    usdc.approve(address(balancer.vault), type(uint256).max);
  }

  function _getLPTokenBalance(bytes32 poolId) internal returns (uint256) {
    (address poolAddress, ) = balancer.vault.getPool(poolId);
    IERC20 poolToken = IERC20(poolAddress);
    return poolToken.balanceOf(address(this));
  }

  /**
   * @dev This helper function is a fast and cheap way to convert between IERC20[] and IAsset[] types.
   */
  function _convertERC20sToAssets(IERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := tokens
    }
  }

  function _hasTokensForPool() internal view returns (bool) {
    (IERC20 tokenA, IERC20 tokenB) = _getPoolTokens();

    return
      tokenA.balanceOf(address(this)) >= poolConfig.tokenAmounts[0] &&
      tokenB.balanceOf(address(this)) >= poolConfig.tokenAmounts[1];
  }

  /* ========== VIEW FUNCTIONS ========== */
  function _getPoolTokens() internal view returns (IERC20, IERC20) {
    return (poolConfig.tokens[0], poolConfig.tokens[1]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILBP {
  function setSwapEnabled(bool swapEnabled) external;

  function getSwapEnabled() external returns (bool);

  /**
   * @dev Schedule a gradual weight change, from the current weights to the given
   * endWeights, over startTime to endTime
   */
  function updateWeightsGradually(
    uint256 startTime,
    uint256 endTime,
    uint256[] memory endWeights
  ) external;

  function getPoolId() external returns (bytes32 poolID);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILBPFactory {
  function create(
    string memory name,
    string memory symbol,
    IERC20[] memory tokens,
    uint256[] memory weights,
    uint256 swapFeePercentage,
    address owner,
    bool swapEnabledOnStart
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
  // solhint-disable-previous-line no-empty-blocks
}

enum PoolSpecialization {
  GENERAL,
  MINIMAL_SWAP_INFO,
  TWO_TOKEN
}

enum WeightedPoolJoinKind {
  INIT,
  EXACT_TOKENS_IN_FOR_BPT_OUT,
  TOKEN_IN_FOR_EXACT_BPT_OUT,
  ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
}

enum WeightedPoolExitKind {
  EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
  EXACT_BPT_IN_FOR_TOKENS_OUT,
  BPT_IN_FOR_EXACT_TOKENS_OUT,
  MANAGEMENT_FEE_TOKENS_OUT
}

struct JoinPoolRequest {
  IAsset[] assets;
  uint256[] maxAmountsIn;
  bytes userData;
  bool fromInternalBalance;
}
struct ExitPoolRequest {
  IAsset[] assets;
  uint256[] minAmountsOut;
  bytes userData;
  bool toInternalBalance;
}

interface IVault {
  function setPaused(bool paused) external;

  function getPool(bytes32 poolId) external returns (address, PoolSpecialization);

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  function exitPool(
    bytes32 poolId,
    address sender,
    address recipient,
    ExitPoolRequest memory request
  ) external payable;

  function getPoolTokens(bytes32 poolId)
    external
    returns (
      IERC20[] memory tokens,
      uint256[] memory balances,
      uint256 maxBlockNumber
    );
}