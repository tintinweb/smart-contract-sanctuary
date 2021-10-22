pragma solidity ^0.8.7;

import * as ownable from "./../commons/Ownable.sol";
import * as whitelist from "./../commons/WhitelistAdminRole.sol";
import * as safeMath from "./../commons/SafeMath.sol"; 
import * as IERC20Sol from "./../commons/IERC20.sol";
import * as safeERC20 from "./../commons/SafeERC20.sol";
import * as multiBalance from "./../commons/IMultiTokenBalanceOfContract.sol";
import * as rewardsHolder from ".//PendingRewardsProvider.sol";
import * as routerInterface from "./../utility/interface/IRouter.sol";
import * as vaultInterface from "./interface/IVault.sol";
import * as stakingInterface from "./interface/IStaking.sol";
import * as rewardsInterface from "./interface/IPendingRewardProvider.sol";


contract Stopelon_Stacking_v2 is ownable.Ownable, whitelist.WhitelistAdminRole, stakingInterface.IStaking,
		rewardsHolder.PendingRewardsProvider {
	using safeMath.SafeMath for uint256;	
	using safeERC20.SafeERC20 for IERC20Sol.IERC20;

	struct RewardTokenRoundInfo {
		uint256 startingPayout;
		uint256 startingReminder;
	}

	struct StackingRound {
	    mapping(address => RewardTokenRoundInfo) rewardTokens;
		address[] roundRewards;
	    uint256 startingTimestamp;
	}

	uint256 private constant scaling = uint256(10) ** 12;
	
	IERC20Sol.IERC20 public tokenContract;
	routerInterface.IRouter public routerContract;
	
	uint256 public reflectionTriggerTime;
	uint256 public reflectionTriggerAmount;

	mapping(address => uint256) private _totalRewards;
	mapping(uint256 => StackingRound) private rounds;
	mapping(address => uint256) private lastClaimedRound;
	uint256 private _currentRound;

	
	constructor(IERC20Sol.IERC20 _tokenContract, routerInterface.IRouter _routerContract, uint256 _reflectionTriggerTime, uint256 _reflectionTriggerAmount) {
		require(_reflectionTriggerTime >= 0, "Seconds has to be higher than 0");
		require(_reflectionTriggerAmount >= 0, "Seconds has to be higher than 0");

		routerContract = _routerContract;
		tokenContract = _tokenContract;
		reflectionTriggerTime = _reflectionTriggerTime;
		reflectionTriggerAmount = _reflectionTriggerAmount;

		_currentRound = 1;
		rounds[_currentRound].startingTimestamp = block.timestamp;
		rounds[_currentRound].roundRewards.push(address(_tokenContract));
	}

	receive() payable external {}

	// VIEWS [PUBLIC]
	function roundCanBeIncremented() public view returns (bool) {
	    uint256 reflectionsToGive = totalPendingRewardsForToken(address(tokenContract));
	    uint256 secondsFromLastRound = block.timestamp - rounds[_currentRound].startingTimestamp;
	    return reflectionsToGive >= reflectionTriggerAmount && secondsFromLastRound >= reflectionTriggerTime;
	}	

	function totalPendingRewardsForToken(address token) public view returns (uint256) {
		uint256 reflectionsToGive = 0;
		address[] memory rewardProviders = routerContract.rewardProviders();
		for (uint256 i = 0; i < rewardProviders.length; i++) {
			rewardsInterface.IPendingRewardProvider provider = rewardsInterface.IPendingRewardProvider(rewardProviders[i]);
			reflectionsToGive = reflectionsToGive.add(provider.getPendingRewards(token, address(this)));
		} 
		return reflectionsToGive;
	}

	function getLastClaimedRound(address account) public view returns (uint256) {
	    return lastClaimedRound[account];
	}

	function currentRound() external view returns (uint256) {
		return _currentRound;
	}

	function roundStartingTimestamp(uint256 round) public view returns (uint256){	
		return rounds[round].startingTimestamp;
	}

	function pendingReflections(address token, address account) public view returns (uint256) {
	    return getPendingReflection(token, account);
	}

	function totalRewards(address token) public view returns (uint256) {
		return _totalRewards[token];
	}

	function currentRoundReminder(address token) external view returns (uint256) {
		return rounds[_currentRound].rewardTokens[token].startingReminder.div(scaling);
	}



	// VIEWS [INTERNAL]
	function getPendingReflection(address token, address account) internal view returns(uint256) {
		uint256 pending = 0;
		address vaultContract = routerContract.vaultImplementation();
		uint256 currentHoldings = vaultInterface.IVault(vaultContract).balanceOf(account);
		uint256 currentVaultShares = vaultInterface.IVault(vaultContract).vaultSharesOf(account);

	    for (uint256 i = lastClaimedRound[account] + 1; i <= _currentRound; i++) {    	
			if (i == 1)
				continue;    
           	uint256 reflectionPerTokenScaled = rounds[i].rewardTokens[token].startingPayout - rounds[i - 1].rewardTokens[token].startingPayout;
		   	uint256 userReflections = 
					token == address(tokenContract) ?
						currentHoldings.mul(reflectionPerTokenScaled).div(scaling) :
						currentVaultShares.mul(reflectionPerTokenScaled).div(scaling);
           	pending = pending.add(userReflections);		   
        }	
		
       return pending;
	}

	// SETTERS
	function setReflectionTriggerTime(uint256 secondsAmount) public onlyWhitelistAdmin {
	    require(secondsAmount >= 0, "Seconds has to be higher than 0");
		reflectionTriggerTime = secondsAmount;
	}

	function setReflectionTriggerAmount(uint256 amount) public onlyWhitelistAdmin {
	    require(amount >= 0, "Amount of trigger reflections has to be higher than 0");
		reflectionTriggerAmount = amount;
	}


	// FUNCTIONS [PUBLIC] 
	function incrementRound() external onlyWhitelistAdmin {	    
	    require(roundCanBeIncremented(), "Round cannot be incremented yet!");
		incrementRoundInternal();
	}

	function claimPendingReflectionsFor(address account) external onlyWhitelistAdmin {
		require(account != address(0), "Not available for empty address!");
		require(lastClaimedRound[account] < _currentRound);

		claimPendingReflectionsInternal(account);
	}

	function pullReminderForRound(address token) external onlyWhitelistAdmin {
		uint256 amount = rounds[_currentRound].rewardTokens[token].startingReminder.div(scaling);
		require(amount > 0, "Not available for empty address!");
		if (token == address(0)) {
			require(address(this).balance >= amount, "Not enough balance to get out reminder!");
            payable(msg.sender).transfer(amount);
        } else {
			require(IERC20Sol.IERC20(token).balanceOf(address(this)) >= amount, "Not enough balance to get out reminder!");
            IERC20Sol.IERC20(token).safeTransfer(msg.sender, amount);
        }
		rounds[_currentRound].rewardTokens[token].startingReminder = 0;
	}

	function claimPersonalPendingReflections() external {
		require(lastClaimedRound[msg.sender] < _currentRound);

		claimPendingReflectionsInternal(msg.sender);
	}

	// FUNCTIONS [INTERNAL]
	function incrementRoundInternal() internal {
		_currentRound++;
		rounds[_currentRound].startingTimestamp = block.timestamp;

		address[] memory rewardProviders = routerContract.rewardProviders();
		for (uint256 i = 0; i < rewardProviders.length; i++) {
			rewardsInterface.IPendingRewardProvider provider = rewardsInterface.IPendingRewardProvider(rewardProviders[i]);
			address[] memory rewardsTokens = provider.getRewardTokens();

			for (uint256 j = 0; j < rewardsTokens.length; j++) {
				address token = rewardsTokens[j];
				uint256 rewardsToGive = provider.getPendingRewards(token, address(this));

				uint256 scaledRemainder = 0;
				uint256 reflectionPerTokenScaled = 0;
				if (rewardsToGive > 0) {
					provider.withdrawTokenRewards(token);
					_totalRewards[token] = _totalRewards[token].add(rewardsToGive);

					uint256 previousReminder = rounds[_currentRound - 1].rewardTokens[token].startingReminder.div(scaling);
					rounds[_currentRound - 1].rewardTokens[token].startingReminder = 0;
					uint256 available = rewardsToGive.add(previousReminder);		   
					uint256 availableScaled = available.mul(scaling); 
					uint256 totalShares = 
						token == address(tokenContract) ?
							vaultInterface.IVault(routerContract.vaultImplementation()).totalSupply() :
							vaultInterface.IVault(routerContract.vaultImplementation()).totalVaultShares();	

					reflectionPerTokenScaled = availableScaled.div(totalShares);
					scaledRemainder = availableScaled.mod(totalShares);	
				}
				rounds[_currentRound].rewardTokens[token].startingReminder = rounds[_currentRound].rewardTokens[token].startingReminder.add(scaledRemainder);
				if (rounds[_currentRound].rewardTokens[token].startingPayout == 0) {
					rounds[_currentRound].rewardTokens[token].startingPayout = rounds[_currentRound - 1].rewardTokens[token].startingPayout.add(reflectionPerTokenScaled);					
					rounds[_currentRound].roundRewards.push(token);
				} else {
					rounds[_currentRound].rewardTokens[token].startingPayout = rounds[_currentRound].rewardTokens[token].startingPayout.add(reflectionPerTokenScaled);		
				}
			}	
		}
	}

	function claimPendingReflectionsInternal(address account) internal { 
		address vaultContract = routerContract.vaultImplementation();
		uint256 currentHoldings = vaultInterface.IVault(vaultContract).balanceOf(account);
		uint256 currentVaultShares = vaultInterface.IVault(vaultContract).vaultSharesOf(account);

		if (currentHoldings > 0) {
			for (uint256 i = lastClaimedRound[account] + 1; i <= _currentRound; i++) {
				for (uint256 j = 0; j < rounds[i].roundRewards.length; j++) {
					address token = rounds[i].roundRewards[j];
					uint256 reflectionPerTokenScaled = rounds[i].rewardTokens[token].startingPayout - rounds[i - 1].rewardTokens[token].startingPayout;

					uint256 userReflections = 
						token == address(tokenContract) ?
							currentHoldings.mul(reflectionPerTokenScaled).div(scaling) :
							currentVaultShares.mul(reflectionPerTokenScaled).div(scaling);
					addPendingRewards(token, account, userReflections);
				}		   
			}
		}

       	lastClaimedRound[account] = _currentRound;		
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

interface IStaking {
    function roundCanBeIncremented() external view returns (bool); 
    function incrementRound() external;
    function currentRound() external view returns (uint256);

    function getLastClaimedRound(address token) external view returns (uint256);
    function pendingReflections(address token, address account) external view returns (uint256);
    function claimPendingReflectionsFor(address account) external;
}

pragma solidity ^0.8.7;

interface IPendingRewardProvider {
    function getRewardTokens() external view returns(address[] memory);
    function getPendingRewards(address rewardToken, address receiver) external view returns(uint256);
    function withdrawTokenRewards(address rewardToken) external;
}

pragma solidity ^0.8.7;

import * as context from "./../commons/Context.sol";
import * as whitelist from "./../commons/WhitelistAdminRole.sol";
import * as IERC20Sol from "./../commons/IERC20.sol";
import * as safeERC20 from "./../commons/SafeERC20.sol";
import * as math from "./../commons/SafeMath.sol";
import * as rewardsInterface from "./interface/IPendingRewardProvider.sol";

contract PendingRewardsProvider is whitelist.WhitelistAdminRole, rewardsInterface.IPendingRewardProvider {
    using safeERC20.SafeERC20 for IERC20Sol.IERC20;
    using math.SafeMath for uint256;

    struct RewardToken {
        bool enabled;
        bool interactedWith;
        address tokenContract;
        mapping(address => uint256) pendingWithdrawals;
    }

    mapping(address => RewardToken) pendingTokenRewards;        
    address[] interactedRewardTokens;

    function getRewardTokens() external view returns(address[] memory) {
        return interactedRewardTokens;
    }

    function getPendingRewards(address rewardToken, address receiver) external view returns(uint256) {
        return pendingTokenRewards[rewardToken].pendingWithdrawals[receiver];
    }

    function addPendingRewards(address rewardToken, address receiver, uint256 amount) internal {
        if (!pendingTokenRewards[rewardToken].interactedWith) {
            interactedRewardTokens.push(rewardToken);
            pendingTokenRewards[rewardToken].interactedWith = true;
        }
        pendingTokenRewards[rewardToken].enabled = true;
        pendingTokenRewards[rewardToken].pendingWithdrawals[receiver] = pendingTokenRewards[rewardToken].pendingWithdrawals[receiver].add(amount);
    }

    function movePendingRewards(address rewardToken, address original, address newOwner) internal {
        pendingTokenRewards[rewardToken].pendingWithdrawals[newOwner] =
            pendingTokenRewards[rewardToken].pendingWithdrawals[newOwner].add(pendingTokenRewards[rewardToken].pendingWithdrawals[original]);
        pendingTokenRewards[rewardToken].pendingWithdrawals[original] = 0;
    }

    function withdrawTokenRewards(address rewardToken) external {
        require(pendingTokenRewards[rewardToken].pendingWithdrawals[_msgSender()] > 0, "No pending rewards for you in selected token!");
        withdrawTokenRewardsInternal(rewardToken, _msgSender());		  
    }

    function withdrawAllRewards() external {
        for (uint256 i = 0; i < interactedRewardTokens.length; i++) { 
			if (pendingTokenRewards[interactedRewardTokens[i]].enabled && pendingTokenRewards[interactedRewardTokens[i]].pendingWithdrawals[_msgSender()] > 0) {      		
                withdrawTokenRewardsInternal(interactedRewardTokens[i], _msgSender());		  		
			}
		}
    }

    function withdrawTokenRewardForReceiver(address rewardToken, address receiver) external onlyWhitelistAdmin {
        require(pendingTokenRewards[rewardToken].pendingWithdrawals[receiver] > 0, "No pending rewards for receiver in selected token!");
        withdrawTokenRewardsInternal(rewardToken, receiver);		  		
    }

    function withdrawTokenRewardsInternal(address rewardToken, address receiver) internal {
        uint256 amount = pendingTokenRewards[rewardToken].pendingWithdrawals[receiver];
        if (rewardToken == address(0)) {
            payable(receiver).transfer(amount);
        } else {
            IERC20Sol.IERC20(rewardToken).safeTransfer(receiver, amount);
        }
        pendingTokenRewards[rewardToken].pendingWithdrawals[receiver] = 0;
    }
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

interface IMultiTokenBalanceOfContract {
    function multiBalanceOf(address token, address account) external view returns (uint256);
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