pragma solidity ^0.8.7;

import * as ownable from "./../commons/Ownable.sol";
import * as whitelist from "./../commons/WhitelistAdminRole.sol";
import * as pauseSol from "./../commons/Pauseable.sol";
import * as safeMath from "./../commons/SafeMath.sol"; 
import * as IERC20Sol from "./../commons/IERC20.sol";
import * as safeERC20 from "./../commons/SafeERC20.sol";
import * as storageInterface from "./interface/IVault.sol";
import * as routerInterface from "./../utility/interface/IRouter.sol";

contract Stopelon_Vault_v1 is ownable.Ownable, whitelist.WhitelistAdminRole, pauseSol.Pausable,
        storageInterface.IVault {
	using safeMath.SafeMath for uint256;	
	using safeERC20.SafeERC20 for IERC20Sol.IERC20;

    struct Lock {
		address account;
		uint256 shares;
		uint256 balance;
	}

    struct LockHistory {
        address account;
		uint256 amount;
        uint256 startRound;
        uint256 length;
    }

	struct LockRound {
		uint256 totalShares;	
		uint256 startingTimestamp;	
		mapping(address => Lock) userLocks;
	}

    IERC20Sol.IERC20 public token;
    routerInterface.IRouter public router;

    bool public locksEnabled;
    uint256 public maxRoundsLock;
    uint256 public lockRoundTriggerTime;
    uint256 public lockRoundRewardRate;
    uint256 public currentLockRound;

    uint256 public minStake;
	uint256 public maxStake;

    uint256 private _totalSupply;
    mapping(address => uint256) private holdings;

    mapping(uint256 => LockRound) private lockRounds;
    mapping(address => LockHistory[]) private lockHistory;
    mapping(address => uint256[]) private activeLocks;

	mapping(address => bool) public vaultRewardBlacklist;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Locked(address indexed user, uint256 amount);

    constructor(IERC20Sol.IERC20 tokenAddress, routerInterface.IRouter _routerContract) ownable.Ownable() whitelist.WhitelistAdminRole() pauseSol.Pausable() {
        token = tokenAddress;
        router = _routerContract;
    }

    //MODIFIERS 
    modifier lockRound() {	
	    if (locksEnabled && lockRoundCanBeIncremented()) {
			incrementVaultRoundInternal();
	    }
		_;
	}
 
    modifier externalSyncCalls(address account) {	
        router.vaultSync(account);
		_;
	}

    modifier onlyLockEnabled() {
        require(locksEnabled, "Locking is currently disabled!");
        _;
    }

    // ---------------REWARDS IMPLEMENTATIONS --------------------
    function getRewardTokens() external view returns(address[] memory) {
        address[] memory rewards = new address[](1);
        rewards[0] = address(token);
        return rewards;
    }

    function getPendingRewards(address rewardToken, address receiver) external view returns(uint256) {
        if (rewardToken != address(token) || receiver != router.stakingImplementation())
            return 0;
        return token.balanceOf(address(this)).sub(_totalSupply);
    }

    function withdrawTokenRewards(address rewardToken) external onlyWhitelistAdmin {
        uint256 available = this.getPendingRewards(rewardToken, msg.sender);
        require(available > 0, "Cannot pull empty reflections");

        token.safeTransfer(msg.sender, available);
    }
    // -----------------------------------------------------------

    // PUBLIC VIEWS
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return holdings[account];
    }

    function vaultSharesOf(address account) external view returns (uint256) {
        return lockRounds[currentLockRound].userLocks[account].shares;
    }

    //NOT TO BE MISSTAKEN FOR TOTAL TOKENS! FOR THAT USE totalSupply()!
    function totalVaultShares() external view returns (uint256) {
        return lockRounds[currentLockRound].totalShares;
    }

    function unlockedBalanceOf(address account) public view returns (uint256){
		if (locksEnabled) {
			return this.balanceOf(account).sub(lockRounds[currentLockRound].userLocks[account].balance);
        } else {
		    return this.balanceOf(account);
        }
	}

    function lockRoundCanBeIncremented() public view returns (bool) {
	    uint256 secondsFromLastRound = block.timestamp - lockRounds[currentLockRound].startingTimestamp;
	    return secondsFromLastRound >= lockRoundTriggerTime;
	}	

    function lockRoundStartingTimestamp(uint256 round) public view returns (uint256){
		return lockRounds[round].startingTimestamp;
	}

    function activeLocksOf(address user) external view returns (uint256[] memory) {
        return activeLocks[user];
    }

    function lockHistoryAmount(address user, uint256 index) external view returns (uint256) {
        return lockHistory[user][index].amount;
    }

    function lockHistoryStartRound(address user, uint256 index) external view returns (uint256) {
        return lockHistory[user][index].startRound;
    }

    function lockHistoryLength(address user, uint256 index) external view returns (uint256) {
        return lockHistory[user][index].length;
    }

    function isBlacklistedForVaultRewards(address receiver) external view returns (bool) {
	    return vaultRewardBlacklist[receiver];
	}

    //PUBLIC FUNCTIONS
    function deposit(uint256 amount) external whenNotPaused lockRound externalSyncCalls(msg.sender) {
        require(token.balanceOf(_msgSender()) >= amount, "Address does not hold enough tokens to deposit!");
        require(token.allowance(_msgSender(), address(this)) >= amount, "Contract allows only transfers when allowance is greater than ammount.");
        require(holdings[_msgSender()].add(amount) > minStake, "After deposit, ammount should be greater than minStake!");
        require(maxStake == 0 || holdings[_msgSender()].add(amount) <= maxStake, "After deposit, ammount should be lower than maxStake!");

        _totalSupply = _totalSupply.add(amount);
		holdings[_msgSender()] = holdings[_msgSender()].add(amount);
		
        uint256 originalBalance = token.balanceOf(_msgSender());
        uint256 expectedBalance = originalBalance.sub(amount);
        uint256 expectedSupply = token.balanceOf(address(this)).add(amount);

		token.safeTransferFrom(_msgSender(), address(this), amount);        
        require(token.balanceOf(address(this)) == expectedSupply, "Total supply did not match after transfer! Check fees!");
        require(token.balanceOf(_msgSender()) == expectedBalance, "Balance of user in personal wallet did not match expected after transfer! Reverting!");

        emit Deposit(_msgSender(), amount);
    }

    function withdraw(uint256 amount) external lockRound externalSyncCalls(msg.sender) {
		require(amount > 0, "Cannot withdraw 0");
		require(amount <= unlockedBalanceOf(_msgSender()), "Cannot withdraw more than available/unlocked amount!");
		
		_withdrawnInternal(msg.sender, amount);

		emit Withdrawn(msg.sender, amount);
	}

    function exit() public lockRound {
        this.withdraw(holdings[_msgSender()]);
    }

    function lock(uint256 amount, uint256 rounds) external whenNotPaused onlyLockEnabled lockRound externalSyncCalls(msg.sender) {	
		require(unlockedBalanceOf(_msgSender()) >= amount, "Not enough funds outside of vault! Provide amount lesser than your current locked!");
		require(amount > 0, "No reason to lock 0 funds!");		
		require(rounds <= maxRoundsLock && rounds > 0, "Too few or too many rounds");
		
        uint256 multiplier = rounds.mul(lockRoundRewardRate).add(100);
		for (uint256 i = 0; i < rounds; i++) {    
			Lock storage userLock = lockRounds[currentLockRound + i].userLocks[_msgSender()];
			userLock.balance = userLock.balance.add(amount);			
            if (!vaultRewardBlacklist[msg.sender]) {
                uint256 roundShares = amount.mul(multiplier).div(100);
			    userLock.shares = userLock.shares.add(roundShares);   
			    lockRounds[currentLockRound + i].totalShares = lockRounds[currentLockRound + i].totalShares.add(roundShares);
            }
        }

        LockHistory memory history = LockHistory(msg.sender, amount, currentLockRound, rounds);
        uint256 number = lockHistory[msg.sender].length;
        lockHistory[msg.sender].push(history);
        cleanUpActiveLocks();
        activeLocks[msg.sender].push(number);
        
		emit Locked(_msgSender(), amount);
    }

    //PUBLIC FUNCTIONS [ADMIN]
    function rescue(address owner, uint256 amount) public onlyWhitelistAdmin lockRound externalSyncCalls(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
		require(amount <= unlockedBalanceOf(owner), "Cannot withdraw more than available!");

        _withdrawnInternal(owner, amount);

		emit Withdrawn(owner, amount);
    }

    function incrementLockRound() public onlyWhitelistAdmin onlyLockEnabled externalSyncCalls(msg.sender) {
        require(lockRoundCanBeIncremented(), "Lock round cannot be incremented yet!");
		incrementVaultRoundInternal();
	}

    //SETTERS [ADMIN]
    function enableLocks(uint256 vaultRoundTime, uint256 _maxVaultRoundsLock, uint256 _vaultRoundRewardRate) external onlyWhitelistAdmin {
		require(!locksEnabled, "This token is already using vault!");
	
		currentLockRound = currentLockRound.add(maxRoundsLock).add(1);
		lockRoundTriggerTime = vaultRoundTime;
		locksEnabled = true;
		maxRoundsLock = _maxVaultRoundsLock;
		lockRoundRewardRate = _vaultRoundRewardRate;
		lockRounds[currentLockRound].startingTimestamp = block.timestamp;
		lockRounds[currentLockRound].totalShares = 0;
	}

	function disableLocks() external onlyWhitelistAdmin onlyLockEnabled {
		locksEnabled = false;
	}

    function setMinMaxStake(uint256 _minStake, uint256 _maxStake) external onlyWhitelistAdmin{
		require(_minStake >= 0 && _maxStake >= 0 && _maxStake >= _minStake, "Problem with min and max stake setup");
		minStake = _minStake;
	    maxStake = _maxStake;
	}

    
	function blacklistForVaultRewards(address receiver) public onlyWhitelistAdmin {
	    vaultRewardBlacklist[receiver] = true;
	}

	function whitelistForVaultRewards(address receiver) public onlyWhitelistAdmin {
	    vaultRewardBlacklist[receiver] = false;
	}	

    //INTERNAL FUNCTIONS
    function _withdrawnInternal(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
		holdings[account] = holdings[account].sub(amount);

		token.safeTransfer(account, amount);
    }

    function incrementVaultRoundInternal() internal {
		currentLockRound++;	
		lockRounds[currentLockRound].startingTimestamp = block.timestamp;
	}

    function cleanUpActiveLocks() internal {
        uint originalLength = activeLocks[msg.sender].length;
        for (uint256 i = 0; i < originalLength; i++) {    
			LockHistory storage activeLock = lockHistory[msg.sender][activeLocks[msg.sender][i]];
            if (activeLock.startRound.add(activeLock.length).sub(1) < currentLockRound) {
                activeLocks[msg.sender][i] = activeLocks[msg.sender][activeLocks[msg.sender].length-1];
                activeLocks[msg.sender].pop();
                originalLength--;
            }		
        }
    }
}

pragma solidity ^0.8.7;

interface IRouter {
    function vaultImplementation() external view returns (address);
    function stakingImplementation() external view returns (address);
    function nftFarmingImplementation() external view returns (address);
    function rewardProviders() external view returns (address[] memory);

    function vaultSync(address account) external;
}

pragma solidity ^0.8.7;

import * as balanceOf from "./../../commons/IBalanceOfContract.sol";
import * as rewards from "./IPendingRewardProvider.sol";
interface IVault is balanceOf.IBalanceOfContract, rewards.IPendingRewardProvider {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function lock(uint256 amount, uint256 rounds) external;

    function totalSupply() external view returns (uint256);

    function vaultSharesOf(address account) external view returns (uint256);
    function totalVaultShares() external view returns (uint256);
}

pragma solidity ^0.8.7;

interface IPendingRewardProvider {
    function getRewardTokens() external view returns(address[] memory);
    function getPendingRewards(address rewardToken, address receiver) external view returns(uint256);
    function withdrawTokenRewards(address rewardToken) external;
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";
import * as roles from "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
abstract contract WhitelistAdminRole is context.Context {
    using roles.Roles for roles.Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    roles.Roles.Role private _whitelistAdmins;

    function initWhiteListAdmin() internal{
        _addWhitelistAdmin(_msgSender());
    }

    constructor () {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity ^0.8.7;

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
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

pragma solidity ^0.8.7;


import * as safemath from "./SafeMath.sol";
import * as addressSol from "./Address.sol";
import * as ierc20 from "./IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using safemath.SafeMath for uint256;
    using addressSol.Address for address;

    function safeTransfer(ierc20.IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ierc20.IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(ierc20.IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ierc20.IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ierc20.IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ierc20.IERC20 token, bytes memory data) private {
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

pragma solidity ^0.8.7;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";
import * as roles from "./Roles.sol";

abstract contract PauserRole is context.Context {
    using roles.Roles for roles.Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    roles.Roles.Role private _pausers;

    function initPauserRole() internal{
        _addPauser(_msgSender());
    }

    constructor () {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

pragma solidity ^0.8.7;

import * as puserRole from "./PauserRole.sol";
import * as context from "./Context.sol";


abstract contract Pausable is context.Context, puserRole.PauserRole {

    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor ()  {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.7;

import * as context from "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is context.Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IBalanceOfContract {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

pragma solidity ^0.8.7;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.7;

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
        (bool success, ) = recipient.call{value:amount}("");
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
        (bool success, bytes memory returndata) = target.call{value:value}(data);
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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