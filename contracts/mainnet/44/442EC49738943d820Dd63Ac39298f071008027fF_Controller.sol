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

// SPDX-License-Identifier: MIT

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
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

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

import './interfaces/IController.sol';
import './interfaces/IFarm.sol';
import './interfaces/IRewardHandler.sol';

contract Controller is IController, Context, Ownable {
  using SafeMath for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // We need the previous controller for calculation of pending rewards
  address public previousController;

  // Our rewardHandler which distributes rewards
  IRewardHandler public rewardHandler;

  // The address which is alowed to call service functions
  address public worker;

  address private farmHead;
  struct Farm {
    address nextFarm;
    uint256 farmStartedAtBlock;
    uint256 farmEndedAtBlock;
    uint256 rewardCap;
    uint256 rewardProvided;
    uint256 rewardPerDuration;
    uint32 rewardFee;
    bool paused;
    bool active;
  }

  mapping(address => Farm) public farms;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event FarmRegistered(address indexed farm);

  event FarmUpdated(address indexed farm);

  event FarmDisabled(address indexed farm);

  event FarmPaused(address indexed farm, bool pause);

  event FarmTransfered(address indexed farm, address indexed to);

  event Rebalanced(address indexed farm);

  event Refueled(address indexed farm, uint256 amount);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyWorker {
    require(_msgSender() == worker, 'not worker');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev rewardHandler is the instance which finally stores the reward token
   * and distributes them to the different recipients
   *
   * @param _addressRegistry IAdressRegistry to get system addresses
   * @param _rewardHandler Handler of reward distribution
   * @param _previousController The previous controller
   */
  constructor(
    IAddressRegistry _addressRegistry,
    address _rewardHandler,
    address _previousController
  ) {
    // Initialize state
    setRewardHandler(_rewardHandler);
    previousController = _previousController;

    // Initialize {Ownable}
    address _marketingWallet =
      _addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);
    transferOwnership(_marketingWallet);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  function setRewardHandler(address _rewardHandler) public onlyOwner {
    rewardHandler = IRewardHandler(_rewardHandler);
  }

  function setWorker(address _worker) external onlyOwner {
    worker = _worker;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IController}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IController-onDeposit}
   */
  function onDeposit(
    uint256 /* amount*/
  ) external view override returns (uint256 fee) {
    // Load state
    Farm storage farm = farms[_msgSender()];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Caller not a farm');
    require(farm.farmEndedAtBlock == 0, 'Farm closed');
    require(!farm.paused, 'Farm paused');

    return 0;
  }

  /**
   * @dev See {IController-onDeposit}
   */
  function onWithdraw(
    uint256 /* amount*/
  ) external view override returns (uint256 fee) {
    // Validate state
    require(!farms[_msgSender()].paused, 'Farm paused');

    return 0;
  }

  /**
   * @dev See {IController-payOutRewards}
   */
  function payOutRewards(address recipient, uint256 amount) external override {
    // Load state
    Farm storage farm = farms[_msgSender()];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Caller not a farm');
    require(recipient != address(0), 'Recipient 0 address');
    require(!farm.paused, 'Farm paused');
    require(
      amount.add(farm.rewardProvided) <= farm.rewardCap,
      'Reward cap reached'
    );

    // Update state
    rewardHandler.distribute2(recipient, amount, farm.rewardFee);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Farm management
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev registerFarm can be called from outside (for new Farms deployed with
   * this controller) or from transferFarm() call
   *
   * Contracts are active from the time of registering, but to provide rewards,
   * refuelFarms must be called (for new Farms / due Farms).
   *
   * Use this function also for updating reward parameters and / or fee.
   * _rewardProvided should be left 0, it is mainly used if a farm is
   * transferred.
   *
   * @param _farmAddress Contract address of farm
   * @param _rewardCap Maximum amount of tokens rewardable
   * @param _rewardPerDuration Refuel amount of tokens, duration is fixed in
   * farm contract
   * @param _rewardProvided Already provided rewards for this farm, should be 0
   * for external calls
   * @param _rewardFee Fee we take from the reward and distribute through
   * components (1e6 factor)
   */
  function registerFarm(
    address _farmAddress,
    uint256 _rewardCap,
    uint256 _rewardPerDuration,
    uint256 _rewardProvided,
    uint32 _rewardFee
  ) external {
    // Validate access
    require(
      _msgSender() == owner() || _msgSender() == previousController,
      'Not allowed'
    );

    // Validate parameters
    require(_farmAddress != address(0), 'Invalid farm (0)');
    require(IFarm(_farmAddress).controller() == this, 'Invalid farm (C)');

    // Farm existent, add new reward logic
    Farm storage farm = farms[_farmAddress];
    if (farm.farmStartedAtBlock > 0) {
      // Re-enable farm if disabled
      farm.farmEndedAtBlock = 0;
      farm.paused = false;
      farm.active = true;
      farm.rewardCap = _rewardCap;
      farm.rewardFee = _rewardFee;
      farm.rewardPerDuration = _rewardPerDuration;
      if (_rewardProvided > 0) farm.rewardProvided = _rewardProvided;

      // Dispatch event
      emit FarmUpdated(_farmAddress);
    }
    // We have a new farm
    else {
      // If we have one with same name, deactivate old one
      bytes32 farmName =
        keccak256(abi.encodePacked(IFarm(_farmAddress).farmName()));
      address searchAddress = farmHead;
      while (
        searchAddress != address(0) &&
        farmName != keccak256(abi.encodePacked(IFarm(searchAddress).farmName()))
      ) searchAddress = farms[searchAddress].nextFarm;

      // If found (update), disable existing farm
      if (searchAddress != address(0)) {
        farms[searchAddress].farmEndedAtBlock = block.number;
        _rewardProvided = farms[searchAddress].rewardProvided;
      }

      // Insert the new Farm
      farm.nextFarm = farmHead;
      farm.farmStartedAtBlock = block.number;
      farm.farmEndedAtBlock = 0;
      farm.rewardCap = _rewardCap;
      farm.rewardProvided = _rewardProvided;
      farm.rewardPerDuration = _rewardPerDuration;
      farm.rewardFee = _rewardFee;
      farm.paused = false;
      farm.active = true;
      farmHead = _farmAddress;

      // Dispatch event
      emit FarmRegistered(_farmAddress);
    }
  }

  /**
   * @dev Note that disabled farms can only be enabled again by calling
   * registerFarm() with new parameters
   *
   * This function is meant to finally end a farm.
   *
   * @param _farmAddress Contract address of farm to disable
   */
  function disableFarm(address _farmAddress) external onlyOwner {
    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Not a farm');

    // Update state
    farm.farmEndedAtBlock = block.number;

    // Dispatch event
    emit FarmDisabled(_farmAddress);

    _checkActive(farm);
  }

  /**
   * @dev This is an emergency pause, which should be called in case of serious
   * issues.
   *
   * Deposit / withdraw and rewards are disabled while pause is set to true.
   *
   * @param _farmAddress Contract address of farm to disable
   * @param _pause To enable / disable a farm
   */
  function pauseFarm(address _farmAddress, bool _pause) external onlyOwner {
    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Not a farm');

    // Update state
    farm.paused = _pause;

    // Dispatch event
    emit FarmPaused(_farmAddress, _pause);

    _checkActive(farm);
  }

  function transferFarm(address _farmAddress, address _newController)
    public
    onlyOwner
  {
    // Validate parameters
    require(_newController != address(0), 'newController = 0');
    require(_newController != address(this), 'newController = this');

    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Farm not registered');

    // Update state
    IFarm(_farmAddress).setController(_newController);

    // Register this farm in the new controller
    Controller(_newController).registerFarm(
      _farmAddress,
      farm.rewardCap,
      farm.rewardPerDuration,
      farm.rewardProvided,
      farm.rewardFee
    );

    // Remove this farm from controller
    if (_farmAddress == farmHead) {
      farmHead = farm.nextFarm;
    } else {
      address searchAddress = farmHead;
      while (farms[searchAddress].nextFarm != _farmAddress)
        searchAddress = farms[searchAddress].nextFarm;
      farms[searchAddress].nextFarm = farm.nextFarm;
    }

    delete (farms[_farmAddress]);

    // Dispatch event
    emit FarmTransfered(_farmAddress, _newController);
  }

  function transferAllFarms(address _newController) external onlyOwner {
    while (farmHead != address(0)) {
      transferFarm(farmHead, _newController);
    }
  }

  function setFarmRewardDuration(address farmAddress, uint256 newDuration)
    external
    onlyOwner
  {
    require(IFarm(farmAddress).controller() == this, 'Invalid farm (C)');
    IFarm(farmAddress).setRewardsDuration(newDuration);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Utility functions
  //////////////////////////////////////////////////////////////////////////////

  function rebalance() external onlyWorker {
    // Update state
    address iterAddress = farmHead;
    while (iterAddress != address(0)) {
      if (farms[iterAddress].active) {
        IFarm(iterAddress).rebalance();
      }
      iterAddress = farms[iterAddress].nextFarm;
    }

    // Dispatch event
    emit Rebalanced(iterAddress);
  }

  function refuelFarms() external onlyWorker {
    address iterAddress = farmHead;
    bool oneRefueled = false;
    while (iterAddress != address(0)) {
      // Refuel if farm end is one day ahead
      Farm storage farm = farms[iterAddress];
      if (
        farm.active &&
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + 86400 >= IFarm(iterAddress).periodFinish()
      ) {
        // Update state
        IFarm(iterAddress).notifyRewardAmount(farm.rewardPerDuration);
        farm.rewardProvided = farm.rewardProvided.add(farm.rewardPerDuration);
        oneRefueled = true;

        // Dispatch event
        emit Refueled(iterAddress, farm.rewardPerDuration);
      }
      iterAddress = farm.nextFarm;
    }
    require(oneRefueled, 'NOP');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  function _checkActive(Farm storage farm) internal {
    farm.active = !(farm.paused || farm.farmEndedAtBlock > 0);
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
   * @dev Sets a new controller, can only called by current controller
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
   * @dev Rebalance strategies (if implemented)
   */
  function rebalance() external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

interface IRewardHandler {
  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the new implementation of distribute() which uses internal fees
   * defined in the {RewardHandler} contract.
   *
   * @param recipient The recipient of the reward
   * @param amount The amount of WOWS to transfer to the recipient
   * @param fee The reward fee in 1e6 factor notation
   */

  function distribute2(
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Transfer reward and distribute the fee
   *
   * This is the current implementation, needed for backward compatibility.
   *
   * Current ERC1155Minter and Controller call this function, later
   * reward handler clients should call the the new one with internal
   * fees specified in this contract.
   *
   * uint32 values are in 1e6 factor notation.
   */
  function distribute(
    address recipient,
    uint256 amount,
    uint32 fee,
    uint32 toTeam,
    uint32 toMarketing,
    uint32 toBooster,
    uint32 toRewardPool
  ) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library AddressBook {
  bytes32 public constant DEPLOYER = 'DEPLOYER';
  bytes32 public constant TEAM_WALLET = 'TEAM_WALLET';
  bytes32 public constant MARKETING_WALLET = 'MARKETING_WALLET';
  bytes32 public constant UNISWAP_V2_ROUTER02 = 'UNISWAP_V2_ROUTER02';
  bytes32 public constant WETH_WOWS_STAKE_FARM = 'WETH_WOWS_STAKE_FARM';
  bytes32 public constant WOWS_TOKEN = 'WOWS_TOKEN';
  bytes32 public constant UNISWAP_V2_PAIR = 'UNISWAP_V2_PAIR';
  bytes32 public constant WOWS_BOOSTER = 'WOWS_BOOSTER';
  bytes32 public constant REWARD_HANDLER = 'REWARD_HANDLER';
  bytes32 public constant SFT_MINTER = 'SFT_MINTER';
  bytes32 public constant SFT_HOLDER = 'SFT_HOLDER';
  bytes32 public constant BOIS_REWARDS = 'BOIS_REWARDS';
  bytes32 public constant WOLVES_REWARDS = 'WOLVES_REWARDS';
  bytes32 public constant SFT_EVALUATOR_PROXY = 'SFT_EVALUATOR_PROXY';
  bytes32 public constant TRADE_FLOOR_PROXY = 'TRADE_FLOOR_PROXY';
  bytes32 public constant CURVE_Y_TOKEN = 'CURVE_Y_TOKEN';
  bytes32 public constant CURVE_Y_DEPOSIT = 'CURVE_Y_DEPOSIT';
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

interface IAddressRegistry {
  /**
   * @dev Set an abitrary key / address pair into the registry
   */
  function setRegistryEntry(bytes32 _key, address _location) external;

  /**
   * @dev Get a registry enty with by key, returns 0 address if not existing
   */
  function getRegistryEntry(bytes32 _key) external view returns (address);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "remappings": [],
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