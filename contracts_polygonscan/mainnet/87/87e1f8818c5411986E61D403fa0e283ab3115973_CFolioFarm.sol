// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import '../utils/Context.sol';

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
    require(owner() == _msgSender(), 'Ownable: Access denied');
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
    require(newOwner != address(0), 'Ownable: Zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT AND Apache-2.0

pragma solidity 0.7.6;

/**
 * Utility library of inline functions on addresses
 */
library Address {
  // Default hash for EOA accounts returned by extcodehash
  bytes32 internal constant ACCOUNT_HASH =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(_address)
    }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`.
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
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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

pragma solidity 0.7.6;

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

// SPDX-License-Identifier: MIT AND Apache-2.0

pragma solidity 0.7.6;

import '../interfaces/IERC20.sol';
import '../utils/SafeMath.sol';
import '../utils/Address.sol';

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
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
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
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
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

    bytes memory returndata = address(token).functionCall(
      data,
      'SafeERC20: low-level call failed'
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        'SafeERC20: ERC20 operation did not succeed'
      );
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath#mul: OVERFLOW');

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, 'SafeMath#div: DIVISION_BY_ZERO');
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath#sub: UNDERFLOW');
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath#add: OVERFLOW');

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'SafeMath#mod: DIVISION_BY_ZERO');
    return a % b;
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import '../../0xerc1155/access/Ownable.sol';
import '../../0xerc1155/utils/SafeMath.sol';
import '../../0xerc1155/utils/SafeERC20.sol';

import '../utils/ERC20Recovery.sol';

import './interfaces/ICFolioFarm.sol';
import './interfaces/IController.sol';
import './interfaces/IFarm.sol';

/**
 * @notice Farm is owned by a CFolio contract.
 *
 * All state modifing calls are only allowed from this owner.
 */
contract CFolioFarm is IFarm, ICFolioFarm, Ownable, ERC20Recovery {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  uint256 public override periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public override rewardsDuration = 14 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 private availableRewards;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  // Unique name of this farm instance, used in controller
  string private _farmName;

  uint256[] private _totalSupplys;
  uint256[] public slotWeights;

  mapping(address => mapping(uint256 => uint256)) private _balances;

  // The address of the controller
  IController public override controller;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event RewardAdded(uint256 reward);

  event AssetAdded(
    address indexed user,
    uint256 amount,
    uint256 totalAmount,
    uint256 slotId
  );

  event AssetRemoved(
    address indexed user,
    uint256 amount,
    uint256 totalAmount,
    uint256 slotId
  );

  event ShareAdded(address indexed user, uint256 amount, uint256 slotId);

  event ShareRemoved(address indexed user, uint256 amount, uint256 slotId);

  event RewardPaid(
    address indexed account,
    address indexed user,
    uint256 reward
  );

  event RewardsDurationUpdated(uint256 newDuration);

  event ControllerChanged(address newController);

  event SlotWeightChanged(uint256 slotId, uint256 newWeight);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyController() {
    require(_msgSender() == address(controller), 'not controller');
    _;
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();

    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    address _owner,
    string memory _name,
    address _controller
  ) {
    // Validate parameters
    require(_owner != address(0), 'Invalid owner');
    require(_controller != address(0), 'Invalid controller');

    // Initialize {Ownable}
    transferOwnership(_owner);

    // Initialize state
    _farmName = _name;
    controller = IController(_controller);
    // TotalSupply for slot 0
    _totalSupplys.push(0);
    slotWeights.push(1E18);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Views
  //////////////////////////////////////////////////////////////////////////////

  function farmName() external view override returns (string memory) {
    return _farmName;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply();
  }

  function balanceOf(address account, uint256 slotId)
    external
    view
    override
    returns (uint256)
  {
    return _balances[account][slotId];
  }

  function balancesOf(address account)
    external
    view
    override
    returns (uint256[] memory result)
  {
    uint256 _slotCount = slotWeights.length;
    result = new uint256[](_slotCount);
    for (uint256 slotId = 0; slotId < _slotCount; ++slotId)
      result[slotId] = _balances[account][slotId];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function rewardPerToken() public view returns (uint256) {
    uint256 ts = _totalSupply();
    if (ts == 0) {
      return rewardPerTokenStored;
    }

    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(ts)
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      _balance(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  function getUIData(address account)
    external
    view
    override
    returns (uint256[5] memory)
  {
    uint256[5] memory result = [
      _totalSupply(),
      _balance(account),
      rewardsDuration,
      rewardRate.mul(rewardsDuration),
      earned(account)
    ];
    return result;
  }

  function slotCount() external view override returns (uint256) {
    return slotWeights.length;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Mutators
  //////////////////////////////////////////////////////////////////////////////

  function addAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external override onlyOwner {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot add 0');
    require(!controller.paused(), 'CFolioFarm: Controller paused');

    // Update state
    _balances[account][slotId] = _balances[account][slotId].add(amount);

    // Dispatch event
    emit AssetAdded(account, amount, _balances[account][slotId], slotId);
  }

  function removeAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external override onlyOwner {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot remove 0');

    // Update state
    _balances[account][slotId] = _balances[account][slotId].sub(amount);

    // Dispatch event
    emit AssetRemoved(account, amount, _balances[account][slotId], slotId);
  }

  function addShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external override onlyOwner updateReward(account) {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot add 0');
    require(!controller.paused(), 'CFolioFarm: Controller paused');
    require(slotId < slotWeights.length, 'CFolioFarm: Invalid slotId');

    // Update state
    _totalSupplys[slotId] = _totalSupplys[slotId].add(amount);
    _balances[account][slotId] = _balances[account][slotId].add(amount);

    // Notify controller
    controller.onDeposit(amount);

    // Dispatch event
    emit ShareAdded(account, amount, slotId);
  }

  function removeShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) public override onlyOwner updateReward(account) {
    // Validate parameters
    require(amount > 0, 'CFolioFarm: Cannot remove 0');
    require(slotId < slotWeights.length, 'CFolioFarm: Invalid slotId');

    // Update state
    _totalSupplys[slotId] = _totalSupplys[slotId].sub(amount);
    _balances[account][slotId] = _balances[account][slotId].sub(amount);

    // Notify controller
    controller.onWithdraw(amount);

    // Dispatch event
    emit ShareRemoved(account, amount, slotId);
  }

  function getReward(address account, address rewardRecipient)
    public
    override
    onlyOwner
    updateReward(account)
  {
    // Load state
    uint256 reward = rewards[account];

    if (reward > 0) {
      // Update state
      rewards[account] = 0;
      availableRewards = availableRewards.sub(reward);

      // Notify controller
      controller.payOutRewards(rewardRecipient, reward);

      // Dispatch event
      emit RewardPaid(account, rewardRecipient, reward);
    }
  }

  function weightSlotId(uint256 slotId, uint256 weight)
    external
    override
    onlyController
    updateReward(address(0))
  {
    uint256 _slotCount = slotWeights.length;
    require(slotId <= _slotCount, 'CFolioFarm: Invalid slotId');
    if (slotId == _slotCount) {
      _totalSupplys.push(0);
      slotWeights.push(weight);
    } else slotWeights[slotId] = weight;

    // Emit event
    emit SlotWeightChanged(slotId, weight);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Restricted functions
  //////////////////////////////////////////////////////////////////////////////

  function setController(address newController)
    external
    override
    onlyController
  {
    // Update state
    controller = IController(newController);

    // Dispatch event
    emit ControllerChanged(newController);

    if (newController == address(0))
      // slither-disable-next-line suicidal
      selfdestruct(payable(msg.sender));
  }

  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyController
    updateReward(address(0))
  {
    // Update state
    // solhint-disable-next-line not-rely-on-time
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      // solhint-disable-next-line not-rely-on-time
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }
    availableRewards = availableRewards.add(reward);

    // Validate state
    //
    // Ensure the provided reward amount is not more than the balance in the
    // contract.
    //
    // This keeps the reward rate in the right range, preventing overflows due
    // to very high values of rewardRate in the earned and rewardsPerToken
    // functions.
    //
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    //
    require(
      rewardRate <= availableRewards.div(rewardsDuration),
      'Provided reward too high'
    );

    // Update state
    // solhint-disable-next-line not-rely-on-time
    lastUpdateTime = block.timestamp;
    // solhint-disable-next-line not-rely-on-time
    periodFinish = block.timestamp.add(rewardsDuration);

    // Dispatch event
    emit RewardAdded(reward);
  }

  /**
   * @dev Added to support recovering LP Rewards from other systems to be
   * distributed to holders
   */
  function recoverERC20(
    address recipient,
    address tokenAddress,
    uint256 tokenAmount
  ) external onlyController {
    // Call ancestor
    _recoverERC20(recipient, tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration)
    external
    override
    onlyController
  {
    // Validate state
    require(
      // solhint-disable-next-line not-rely-on-time
      periodFinish == 0 || block.timestamp > periodFinish,
      'Reward period not finished'
    );

    // Update state
    rewardsDuration = _rewardsDuration;

    // Dispatch event
    emit RewardsDurationUpdated(rewardsDuration);
  }

  function _totalSupply() private view returns (uint256 ts) {
    ts = 0;
    for (uint256 i = 0; i < slotWeights.length; ++i)
      ts += _totalSupplys[i] * slotWeights[i];
    ts /= 1E18;
  }

  function _balance(address account) private view returns (uint256 balance) {
    balance = 0;
    mapping(uint256 => uint256) storage balances = _balances[account];

    for (uint256 i = 0; i < slotWeights.length; ++i)
      balance += balances[i] * slotWeights[i];
    balance /= 1e18;
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

/**
 * @title ICFolioFarm
 *
 * @dev ICFolioFarm is the business logic interface to c-folio farms.
 */
interface ICFolioFarm {
  /**
   * @dev Return number of slots
   */
  function slotCount() external view returns (uint256);

  /**
   * @dev Return total invested balance
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Return invested balance of account
   */
  function balanceOf(address account, uint256 slotId)
    external
    view
    returns (uint256);

  /**
   * @dev Return invested balances per slot of account
   */
  function balancesOf(address account) external view returns (uint256[] memory);

  /**
   * @dev Return total, balances[account], rewardDuration, rewardForDuration, earned[account]
   */
  function getUIData(address account) external view returns (uint256[5] memory);

  /**
   * @dev Increase amount of non-rewarded asset
   */
  function addAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Remove amount of previous added assets
   */
  function removeAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Increase amount of shares and earn rewards
   */
  function addShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Remove amount of previous added shares, rewards will not be claimed
   */
  function removeShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Claim rewards harvested during reward time
   */
  function getReward(address account, address rewardRecipient) external;
}

/**
 * @title ICFolioFarmOwnable
 */

interface ICFolioFarmOwnable is ICFolioFarm {
  /**
   * @dev Transfer ownership
   */
  function transferOwnership(address newOwner) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

interface IController {
  /**
   * @dev Used to control fees and accessibility instead having an implementation
   * in each farm contract
   *
   * Deposit is only allowed if farm is open and not not paused. Must revert on
   * failure.
   *
   * @param amount Number of tokens the user wants to deposit
   *
   * @return fee The deposit fee (1e18 factor) on success
   */
  function onDeposit(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Used to control fees and accessibility instead having an
   * implementation in each farm contract
   *
   * Withdraw is only allowed if farm is not paused. Must revert on failure
   *
   * @param amount Number of tokens the user wants to withdraw
   *
   * @return fee The withdrawal fee (1e18 factor) on success
   */
  function onWithdraw(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Returns the paused state of the calling farm
   */
  function paused() external view returns (bool);

  /**
   * @dev Distribute rewards to sender and fee to internal contracts
   */
  function payOutRewards(address recipient, uint256 amount) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import './IController.sol';

interface IFarm {
  /**
   * @dev Return the farm's controller
   */
  function controller() external view returns (IController);

  /**
   * @dev Return a unique, case-sensitive farm name
   */
  function farmName() external view returns (string memory);

  /**
   * @dev Return when reward period is finished (UTC timestamp)
   */
  function periodFinish() external view returns (uint256);

  /**
   * @dev Return the rewards duration in seconds
   */
  function rewardsDuration() external view returns (uint256);

  /**
   * @dev Sets a new controller, can only be called by current controller
   */
  function setController(address newController) external;

  /**
   * @dev This function must be called initially and close at the time the
   * reward period ends
   */
  function notifyRewardAmount(uint256 reward) external;

  /**
   * @dev Set the duration of farm rewards, to continue rewards,
   * notifyRewardAmount() has to called for the next period
   */
  function setRewardsDuration(uint256 _rewardsDuration) external;

  /**
   * @dev Set the weight of investment token relative to 0
   */
  function weightSlotId(uint256 slotId, uint256 weight) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/utils/SafeERC20.sol';

contract ERC20Recovery {
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Fired when a recipient receives recovered ERC-20 tokens
   *
   * @param recipient The target recipient receving the recovered coins
   * @param tokenAddress The address of the ERC-20 token
   * @param tokenAmount The amount of the token being recovered
   */
  event Recovered(
    address indexed recipient,
    address indexed tokenAddress,
    uint256 tokenAmount
  );

  //////////////////////////////////////////////////////////////////////////////
  // Internal interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Recover ERC20 token from contract which have been transfered
   * either by accident or via airdrop
   *
   * Proper access must be verified. All tokens used by the system must
   * be blocked from recovery.
   *
   * @param recipient The target recipient of the recovered coins
   * @param tokenAddress The address of the ERC-20 token
   * @param tokenAmount The amount of the token to recover
   */
  function _recoverERC20(
    address recipient,
    address tokenAddress,
    uint256 tokenAmount
  ) internal {
    // Validate parameters
    require(recipient != address(0), "Can't recover to address 0");

    // Update state
    IERC20(tokenAddress).safeTransfer(recipient, tokenAmount);

    // Dispatch event
    emit Recovered(recipient, tokenAddress, tokenAmount);
  }
}

