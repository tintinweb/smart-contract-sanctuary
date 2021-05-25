// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance.js`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;

import "./Governable.sol";

contract SystemParameters is Governable {

    // Minimum ankr staking amount to be abel to initialize a pool
    uint256 public PROVIDER_MINIMUM_STAKING;

    // Minimum staking amount for pool participants
    uint256 public REQUESTER_MINIMUM_POOL_STAKING; // 0.1 ETH

    // Ethereum staking amount
    uint256 public ETHEREUM_STAKING_AMOUNT;

    uint256 public EXIT_BLOCKS;

    function initialize() external initializer {
        PROVIDER_MINIMUM_STAKING = 100000 ether;
        REQUESTER_MINIMUM_POOL_STAKING = 500 finney;
        ETHEREUM_STAKING_AMOUNT = 4 ether;
        EXIT_BLOCKS = 24;
    }
}

pragma solidity ^0.6.11;

abstract contract Lockable {
    mapping(address => bool) private _locks;

    modifier unlocked(address addr) {
        require(!_locks[addr], "Reentrancy protection");
        _locks[addr] = true;
        _;
        _locks[addr] = false;
    }

    uint256[50] private __gap;
}

pragma solidity 0.6.11;
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract Pausable is  OwnableUpgradeSafe {
    mapping (bytes32 => bool) internal _paused;

    modifier whenNotPaused(bytes32 action) {
        require(!_paused[action], "This action currently paused");
        _;
    }

    function togglePause(bytes32 action) public onlyOwner {
        _paused[action] = !_paused[action];
    }

    function isPaused(bytes32 action) public view returns(bool) {
        return _paused[action];
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IAETH is IERC20 {

    function burn(uint256 amount) external;

    function updateMicroPoolContract(address microPoolContract) external;

    function ratio() external view returns (uint256);

    function mintFrozen(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external returns (uint256);

    function mintApprovedTo(address account, address spender, uint256 amount) external;

    function mintPool() payable external;

    function fundPool(uint256 poolIndex, uint256 amount) external;
}

pragma solidity ^0.6.11;

interface IConfig {
    function getConfig(bytes32 config) external view returns (uint256);

    function setConfig(bytes32 config, uint256 value) external;
}

pragma solidity ^0.6.11;

interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

pragma solidity ^0.6.11;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IFETH is IERC20 {

    function mint(address account, uint256 shares, uint256 sent) external;

    function updateReward(uint256 newReward) external returns (uint256);

    function lockShares(address account, uint256 shares) external;

    function unlockShares(uint256 shares) external;
}

pragma solidity ^0.6.11;

interface IStaking {
    function compensateLoss(address provider, uint256 ethAmount) external returns (bool, uint256, uint256);

    function freeze(address user, uint256 amount) external returns (bool);

    function unfreeze(address user, uint256 amount) external returns (bool);

    function frozenStakesOf(address staker) external view returns (uint256);

    function stakesOf(address staker) external view returns (uint256);

    function frozenDepositsOf(address staker) external view returns (uint256);

    function depositsOf(address staker) external view returns (uint256);

    function deposit() external;

    function deposit(address user) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../lib/interfaces/IDepositContract.sol";
import "../SystemParameters.sol";
import "../lib/Lockable.sol";
import "../lib/interfaces/IAETH.sol";
import "../lib/interfaces/IFETH.sol";
import "../lib/interfaces/IConfig.sol";
import "../lib/interfaces/IStaking.sol";
import "../lib/interfaces/IDepositContract.sol";
import "../lib/Pausable.sol";

contract GlobalPool_R31 is Lockable, Pausable {

    using SafeMath for uint256;
    using Math for uint256;

    /* staker events */
    event StakePending(address indexed staker, uint256 amount);
    event StakeConfirmed(address indexed staker, uint256 amount);
    event StakeRemoved(address indexed staker, uint256 amount);

    /* pool events */
    event PoolOnGoing(bytes pool);
    event PoolCompleted(bytes pool);

    /* provider events */
    event ProviderSlashedAnkr(address indexed provider, uint256 ankrAmount, uint256 etherEquivalence);
    event ProviderSlashedEth(address indexed provider, uint256 amount);
    event ProviderToppedUpEth(address indexed provider, uint256 amount);
    event ProviderToppedUpAnkr(address indexed provider, uint256 amount);
    event ProviderExited(address indexed provider);

    /* rewards (AETH) */
    event RewardClaimed(address indexed staker, uint256 amount, bool isAETH);

    // deleted fields
    mapping(address => uint256) private _pendingUserStakes; // deleted

    mapping(address => uint256) private _userStakes;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _claims;
    mapping(address => uint256) private _etherBalances;
    mapping(address => uint256) private _slashings;
    mapping(address => uint256) private _exits;

    // deleted fields
    address[] private _pendingStakers; // deleted
    uint256 private _pendingAmount; // deleted
    uint256 private _totalStakes; // deleted
    uint256 private _totalRewards; // deleted

    IAETH private _aethContract;
    IStaking private _stakingContract;
    SystemParameters private _systemParameters;
    address private _depositContract;

    // deleted fields
    address[] private _pendingTemp; // deleted
    uint256[50] private __gap; // deleted
    uint256 private _lastPendingStakerPointer; // deleted

    IConfig private _configContract;

    // deleted fields
    mapping(address => uint256) private _pendingEtherBalances; // deleted

    address private _operator;

    // deleted fields
    mapping(address => uint256[2]) private _fETHRewards; // deleted

    mapping(address => uint256) private _aETHRewards;
    IFETH private _fethContract;

    // deleted fields
    uint256 private _fethMintBase; // deleted

    modifier notExitRecently(address provider) {
        require(block.number > _exits[provider].add(_configContract.getConfig("EXIT_BLOCKS")), "Recently exited");
        delete _exits[msg.sender];
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(IAETH aethContract, SystemParameters parameters, address depositContract) public initializer {
        __Ownable_init();

        _depositContract = depositContract;
        _aethContract = aethContract;
        _systemParameters = parameters;

        _paused["topUpETH"] = true;
        _paused["topUpANKR"] = true;
    }

    function pushToBeacon(bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root) public onlyOperator {
        require(address(this).balance >= 32 ether, "pending ethers not enough");
        IDepositContract(_depositContract).deposit{value : 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);
        emit PoolOnGoing(pubkey);
    }

    function stake() public whenNotPaused("stake") notExitRecently(msg.sender) unlocked(msg.sender) payable {
        _stake(msg.sender, msg.value, true);
    }

    function customStake(address[] memory addresses, uint256[] memory amounts) public payable onlyOperator {
        require(addresses.length == amounts.length, "Addresses and amounts length must be equal");
        uint256 totalSent = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalSent += amounts[i];
            _stake(addresses[i], amounts[i], false);
        }
        require(msg.value == totalSent, "Total value must be same with sent");
    }

    function _stake(address staker, uint256 value, bool payRewards) private {
        uint256 minimumStaking = _configContract.getConfig("REQUESTER_MINIMUM_POOL_STAKING");
        require(value >= minimumStaking, "Value must be greater than zero");
        require(value % minimumStaking == 0, "Value must be multiple of minimum staking amount");
        _userStakes[staker] = _userStakes[staker].add(value);
        uint256 _ratio = _aethContract.ratio();
        if (payRewards) {
            uint256 shares = value.mul(_ratio).div(1e18);
            _aethContract.mint(address(this), shares);
            _aETHRewards[staker] = _aETHRewards[staker].add(shares);
        }
        emit StakePending(staker, value);
        emit StakeConfirmed(staker, value);
    }

    function topUpETH() public whenNotPaused("topUpETH") notExitRecently(msg.sender) payable {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ETH_STAKING") <= msg.value, "Value must be greater than minimum amount");
        _etherBalances[msg.sender] = _etherBalances[msg.sender].add(msg.value);
        _stake(msg.sender, msg.value, true);
        emit ProviderToppedUpEth(msg.sender, msg.value);
    }

    function topUpANKR(uint256 amount) public whenNotPaused("topUpANKR") notExitRecently(msg.sender) {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ANKR_STAKING") <= amount, "Value must be greater than minimum amount");
        require(_stakingContract.freeze(msg.sender, amount), "Not enough allowance or balance");
        emit ProviderToppedUpAnkr(msg.sender, amount);
    }

    function providerExit() public {
        int256 available = availableEtherBalanceOf(msg.sender);
        address staker = msg.sender;
        require(available > 0, "Provider balance should be positive for exit");
        _exits[staker] = block.number;
        _etherBalances[staker] = 0;
        _slashings[staker] = 0;
        uint256 value = uint256(available);
        uint256 _ratio = _aethContract.ratio();
        _aETHRewards[staker] = _aETHRewards[staker].add(value.mul(_ratio).div(1e18));
        emit ProviderExited(msg.sender);
    }

    function claimableAETHRewardOf(address staker) public view returns (uint256) {
        uint256 blocked = _etherBalances[staker];
        uint256 reward = _rewards[staker].sub(_claims[staker]);
        reward = blocked >= reward ? 0 : reward.sub(blocked);
        return _aETHRewards[staker].add(reward);
    }

    function claimableFETHRewardOf(address staker) public view returns (uint256) {
        return claimableAETHRewardOf(staker).mul(1e18).div(_aethContract.ratio());
    }

    function claimableAETHFRewardOf(address staker) public view returns (uint256) {
        return claimableFETHRewardOf(staker);
    }

    function claimAETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }
        _aethContract.mint(staker, claimableShares);
        emit RewardClaimed(staker, claimableShares, true);
    }

    function claimFETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimableShares = claimableAETHRewardOf(staker);
        require(claimableShares > 0, "claimable reward zero");
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }
        _aethContract.mintApprovedTo(staker, address(_fethContract), claimableShares);
        _fethContract.lockShares(staker, claimableShares);
        emit RewardClaimed(staker, claimableShares, false);
    }

    function availableEtherBalanceOf(address provider) public view returns (int256) {
        return int256(etherBalanceOf(provider)) - int256(slashingsOf(provider));
    }

    function etherBalanceOf(address provider) public view returns (uint256) {
        return _etherBalances[provider];
    }

    function slashingsOf(address provider) public view returns (uint256) {
        return _slashings[provider];
    }

    /**
        @dev Slash eth, returns remaining needs to be slashed
    */
    function slashETH(address provider, uint256 amount) public unlocked(provider) onlyOwner returns (uint256 remaining) {
        require(amount > 0, "Amount should be greater than zero");
        uint256 available = availableEtherBalanceOf(provider) > 0 ? uint256(availableEtherBalanceOf(provider)) : 0;
        uint256 toBeSlashed = amount.min(available);
        if (toBeSlashed == 0) return amount;
        _slashings[provider] = _slashings[provider].add(toBeSlashed);
        remaining = amount.sub(toBeSlashed);
        emit ProviderSlashedEth(provider, toBeSlashed);
    }

    function updateAETHContract(address payable aEthContract) external onlyOwner {
        _aethContract = IAETH(aEthContract);
    }

    function updateFETHContract(address payable fEthContract) external onlyOwner {
        _fethContract = IFETH(fEthContract);
    }

    function updateConfigContract(address configContract) external onlyOwner {
        _configContract = IConfig(configContract);
    }

    function updateStakingContract(address stakingContract) external onlyOwner {
        _stakingContract = IStaking(stakingContract);
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    function depositContractAddress() public view returns (address) {
        return _depositContract;
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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