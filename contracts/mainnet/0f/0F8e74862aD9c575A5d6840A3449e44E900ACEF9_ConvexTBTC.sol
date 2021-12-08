pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/ITrigger.sol";
import "./interfaces/IConvexBooster.sol";

interface ICrvToken is IERC20 {
  function minter() external view returns (address);
}

interface ICrvBase {
  function get_virtual_price() external view returns (uint256);
}

interface ICrvMeta {
  function balances(uint256 index) external view returns (uint256);

  function base_pool() external view returns (address);

  function coins(uint256 index) external view returns (address);

  function get_virtual_price() external view returns (uint256);
}

/**
 * @notice Defines a trigger that is toggled if any of the following conditions occur:
 *   1. Convex token total supply does not equal the Curve gauge balanceOf the Convex staker
 *   2. Virtual price of an underlying Curve pool (whether base pool or meta pool) drops significantly
 *   3. Internal token balances tracked by an underlying Curve pool (whether base pool or meta pool) are
 *      significantly lower than the true balances
 *
 * @dev This abstract contract requires a few functions to be implemented. These are methods used to
 * abstract calls to Curve pools which have different function signature that return the same data
 */
abstract contract Convex is ITrigger {
  // --- Parameters ---
  uint256 public constant scale = 1000; // scale used to define percentages, percentages are defined as tolerance / scale
  uint256 public constant virtualPriceTol = scale - 500; // toggle if virtual price drops by >50%
  uint256 public constant balanceTol = scale - 500; // toggle if true balances are >50% lower than internally tracked balances
  address public constant convex = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31; // Convex deposit contract (booster)

  uint256 public immutable convexPoolId; // Convex deposit contract (booster) pool id
  address public immutable convexToken; // Convex receipt token minted on deposits
  address public immutable staker; // Convex contract that manages staking
  address public immutable gauge; // Curve gauge that Convex deposits into

  address public immutable curveMetaPool; // Curve meta pool
  address public immutable curveBasePool; // Base Curve pool

  address public immutable metaToken0; // meta pool token 0
  address public immutable metaToken1; // meta pool token 1

  address public immutable baseToken0; // base pool token 0
  address public immutable baseToken1; // base pool token 1
  address public immutable baseToken2; // base pool token 2

  uint256 public lastVpBasePool; // last virtual price read from base pool
  uint256 public lastVpMetaPool; // last virtual price read from meta pool

  // --- Methods to implement ---
  // Gets the address of the coin at the specified index in the base pool
  function basePoolCoins(uint256 index) internal view virtual returns (address);

  // Gets the the base pool's internal balance of the token at the specified index
  function basePoolBalances(uint256 index) internal view virtual returns (uint256);

  // --- Core trigger logic ---

  /**
   * @param _convexPoolId TODO
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    uint256 _convexPoolId
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Get addresses from the pool ID
    (address _curveLpToken, address _convexToken, address _gauge, , , ) = IConvexBooster(convex).poolInfo(
      _convexPoolId
    );
    staker = IConvexBooster(convex).staker();
    convexPoolId = _convexPoolId;
    convexToken = _convexToken;
    gauge = _gauge;

    curveMetaPool = ICrvToken(_curveLpToken).minter();
    curveBasePool = ICrvMeta(curveMetaPool).base_pool();

    metaToken0 = ICrvMeta(curveMetaPool).coins(0);
    metaToken1 = ICrvMeta(curveMetaPool).coins(1);

    baseToken0 = basePoolCoins(0);
    baseToken1 = basePoolCoins(1);
    baseToken2 = basePoolCoins(2);

    // Get virtual prices
    lastVpMetaPool = ICrvMeta(curveMetaPool).get_virtual_price();
    lastVpBasePool = ICrvBase(curveBasePool).get_virtual_price();
  }

  function checkTriggerCondition() internal override returns (bool) {
    // In other trigger contracts we check all conditions, save them to storage, and return the result.
    // This is convenient because it ensures we have the data that caused the trigger saved into
    // the state, but this is just convenient and not a requirement. We do not follow that pattern
    // here because certain trigger conditions can cause this method to revert if we tried that
    // (and a revert means the trigger can never toggle). Instead, we check conditions one at a
    // time, and return immediately if a trigger condition is met.
    //
    // Specifically, imagine the failure case where the base pool is hacked, and the attacker is
    // able to mint 2^128 LP tokens for themself. When this trigger contract calls get_virtual_price()
    // on the meta pool, it will revert. This revert happens as follows:
    //   1. The base pool will have a virtual price close to zero (or zero, depending on the new
    //      total supply). This value is the vp_rate variable in the meta pool's get_virtual_price() method
    //   2. This virtual price is passed into the self._xp() method, which multiplies this by
    //      the metacurrency token balance then divides by PRECISION. If virtual price is too
    //      small relative to the PRECISION, the integer division is floored, returning zero.
    //   3. This xp value of zero is passed into self._get_D(), and is used in division. We of
    //      course cannot divide by zero, so the call reverts
    //
    // Given this potential failure mode, we check trigger conditions as follows:
    //   1. First we do the balance checks since that check cannot revert
    //   2. Next we check the virtual price of that base pool. This can still revert if the balance of
    //      a token is too low, resulting in a zero value for xp leading to division by zero, but
    //      because we already checked that balances are not too low this should be safe.
    //      NOTE: There is a potential edge case where a token balance decrease is less than our 50%
    //      threshold so the balance trigger condition is not toggled, BUT the balance is low enough
    //      that xp is still floored to zero during integer division, resulting in a revert. In a
    //      properly functioning curve market, get_virtual_price() should never revert. Therefore,
    //      all external calls are wrapped in a try/catch, and if the call reverts then something is
    //      wrong with the underlying protocol and we toggle the trigger
    //   3. Lastly we check the virtual price of the meta pool for similar reasons to above
    //
    // For try/catch blocks, we return early if the trigger condition was met. If it wasn't, we
    // save off the new state variable. This can result in "inconsistent" states after a trigger
    // occurs. For example, if the first check is ok, but the second check fails, the final state
    // of this contract will have the new state from the first check, but the prior state from the
    // second (failed) check (i.e. not the most recent check that triggered the). This is a bit
    // awkward, but ultimatly is not a problem

    // Verify supply of Convex receipt tokens is equal to the amount of curve receipt tokens Convex
    // can claim. Convex receipt tokens are minted 1:1 with deposited funds, so this protects
    // against e.g. "infinite mint" type bugs, where an attacker is able to mint themselves more
    // Convex receipt tokens than what they should receive.
    if (IERC20(convexToken).totalSupply() != IERC20(gauge).balanceOf(staker)) return true;

    // Internal balance vs. true balance checks
    if (checkCurveBaseBalances() || checkCurveMetaBalances()) return true;

    // Base pool virtual price check
    try ICrvBase(curveBasePool).get_virtual_price() returns (uint256 _newVpBasePool) {
      bool _triggerVpBasePool = _newVpBasePool < ((lastVpBasePool * virtualPriceTol) / scale);
      if (_triggerVpBasePool) return true;
      lastVpBasePool = _newVpBasePool; // if not triggered, save off the virtual price for the next call
    } catch {
      return true;
    }

    // Meta pool virtual price check
    try ICrvMeta(curveMetaPool).get_virtual_price() returns (uint256 _newVpMetaPool) {
      bool _triggerVpMetaPool = _newVpMetaPool < ((lastVpMetaPool * virtualPriceTol) / scale);
      if (_triggerVpMetaPool) return true;
      lastVpMetaPool = _newVpMetaPool; // if not triggered, save off the virtual price for the next call
    } catch {
      return true;
    }

    // Trigger condition has not occured
    return false;
  }

  /**
   * @dev Checks if the Curve base pool internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkCurveBaseBalances() internal view returns (bool) {
    return
      (IERC20(baseToken0).balanceOf(curveBasePool) < ((basePoolBalances(0) * balanceTol) / scale)) ||
      (IERC20(baseToken1).balanceOf(curveBasePool) < ((basePoolBalances(1) * balanceTol) / scale)) ||
      (IERC20(baseToken2).balanceOf(curveBasePool) < ((basePoolBalances(2) * balanceTol) / scale));
  }

  /**
   * @dev Checks if the Curve meta pool internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkCurveMetaBalances() internal view returns (bool) {
    return
      (IERC20(metaToken0).balanceOf(curveMetaPool) < ((ICrvMeta(curveMetaPool).balances(0) * balanceTol) / scale)) ||
      (IERC20(metaToken1).balanceOf(curveMetaPool) < ((ICrvMeta(curveMetaPool).balances(1) * balanceTol) / scale));
  }
}

/**
 * @notice Trigger for the Convex USDP pool
 */
contract ConvexUSDP is Convex {
  bytes4 internal constant basePoolCoinsSelector = 0xc6610657; // bytes4(keccak256("coins(uint256)"))
  bytes4 internal constant basePoolBalancesSelector = 0x4903b0d1; // bytes4(keccak256("balances(uint256)"))

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    uint256 _convexPoolId
  ) Convex(_name, _symbol, _description, _platformIds, _recipient, _convexPoolId) {}

  function basePoolCoins(uint256 index) internal view override returns (address) {
    (bool ok, bytes memory ret) = curveBasePool.staticcall(abi.encodeWithSelector(basePoolCoinsSelector, index));
    require(ok, "coins call reverted");
    return abi.decode(ret, (address));
  }

  function basePoolBalances(uint256 index) internal view override returns (uint256) {
    (bool ok, bytes memory ret) = curveBasePool.staticcall(abi.encodeWithSelector(basePoolBalancesSelector, index));
    require(ok, "balances call reverted");
    return abi.decode(ret, (uint256));
  }
}

/**
 * @notice Trigger for the Convex tBTC pool
 */
contract ConvexTBTC is Convex {
  bytes4 internal constant basePoolCoinsSelector = 0x23746eb8; // bytes4(keccak256("coins(int128)"))
  bytes4 internal constant basePoolBalancesSelector = 0x065a80d8; // bytes4(keccak256("balances(int128)"))

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    uint256 _convexPoolId
  ) Convex(_name, _symbol, _description, _platformIds, _recipient, _convexPoolId) {}

  function basePoolCoins(uint256 index) internal view override returns (address) {
    (bool ok, bytes memory ret) = curveBasePool.staticcall(abi.encodeWithSelector(basePoolCoinsSelector, index));
    require(ok, "coins call reverted");
    return abi.decode(ret, (address));
  }

  function basePoolBalances(uint256 index) internal view override returns (uint256) {
    (bool ok, bytes memory ret) = curveBasePool.staticcall(abi.encodeWithSelector(basePoolBalancesSelector, index));
    require(ok, "coins call reverted");
    return abi.decode(ret, (uint256));
  }
}

pragma solidity ^0.8.5;

interface IERC20 {
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

pragma solidity ^0.8.5;

/**
 * @notice Abstract contract for creating or interacting with a Trigger contract
 * @dev All trigger contracts created must inerit from this contract and conform to this interface
 */
abstract contract ITrigger {
  /// @notice Trigger name, analgous to an ERC-20 token's name
  string public name;

  /// @notice Trigger symbol, analgous to an ERC-20 token's symbol
  string public symbol;

  /// @notice Trigger description
  string public description;

  /// @notice Array of IDs of platforms covered by this trigger
  uint256[] public platformIds;

  /// @notice Returns address of recipient who receives subsidies for creating a protection market using this trigger
  address public immutable recipient;

  /// @notice Returns true if trigger condition has been met
  bool public isTriggered;

  /// @notice Emitted when the trigger is activated
  event TriggerActivated();

  /**
   * @notice Returns array of IDs, where each ID corresponds to a platform covered by this trigger
   * @dev See documentation for mapping of ID numbers to platforms
   */
  function getPlatformIds() external view returns (uint256[] memory) {
    return platformIds;
  }

  /**
   * @dev Executes trigger-specific logic to check if market has been triggered
   * @return True if trigger condition occured, false otherwise
   */
  function checkTriggerCondition() internal virtual returns (bool);

  /**
   * @notice Checks trigger condition, sets isTriggered flag to true if condition is met, and returns the trigger status
   * @return True if trigger condition occured, false otherwise
   */
  function checkAndToggleTrigger() external returns (bool) {
    // Return true if trigger already toggled
    if (isTriggered) return true;

    // Return false if market has not been triggered
    if (!checkTriggerCondition()) return false;

    // Otherwise, market has been triggered
    emit TriggerActivated();
    isTriggered = true;
    return isTriggered;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient
  ) {
    name = _name;
    description = _description;
    symbol = _symbol;
    platformIds = _platformIds;
    recipient = _recipient;
  }
}

pragma solidity ^0.8.9;

interface IConvexBooster {
  function staker() external view returns (address);

  function poolInfo(uint256)
    external
    view
    returns (
      address, // lptoken
      address, // token
      address, // gauge
      address, // crvRewards
      address, // stash
      bool // shutdown
    );
}