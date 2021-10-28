//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

interface IBEP20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PDOGFarming is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
	string public constant name = "PDOG-Farming";

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;            // Address of LP token contract.
        IBEP20 rewardToken;        // Address of Reward token contract.
        uint256 rewardRate;        // Reward rate.
        uint256 rewardInterval;    // Interval to calculate reward.
        uint256 startBlock;        // Block number after which reward should start
        uint256 lockPeriod;        // Farming lock period
        uint256 endTime;           // Block number after which reward should stop
        uint256 totalFarmedAmount; // Total farmed amount
    }

    // Info of each user.
    struct UserInfo {
        uint256 farmedAmount;           // How many LP tokens the user has provided.
        uint256 farmingStartTime;       // Block number when the user farms
        bool hasFarmed;
        bool isFarming;
        uint256 oldReward;
    }

    // Info of each pool.
    mapping (IBEP20 => PoolInfo) public poolInfo;
    // Info of each user that farms LP tokens.
    mapping (address => mapping (IBEP20 => UserInfo)) public userInfo;
    uint timeBound; //72 hours in seconds
    mapping (address => mapping (IBEP20 => uint256)) public userTimeBounds; //useraddress => lpTokenAddress => timestamprequested
	
	event Reward(address indexed from, address indexed to, uint256 amount);
	event FarmedToken(address indexed from, address indexed to, uint256 amount);
    event RemoveFarmedToken(address indexed from, address indexed to, uint256 amount);
	event WithdrawFromFarmedBalance(address indexed user, uint256 amount);
    event ExternalTokenTransferred(address indexed from, address indexed to, uint256 amount);
    event UpdatedRewardRate(IBEP20 lpToken, uint256 rewardRate);
    event UpdatedRewardToken(IBEP20 lpToken, IBEP20 rewardToken);
    event UpdatedRewardInterval(IBEP20 lpToken, uint256 rewardInterval);
    event UpdatedendTime(IBEP20 lpToken, uint256 endTime);
    event UpdatedLockPeriod(IBEP20 lpToken, uint256 lockPeriod);
    event withdrawRequested(address indexed to, IBEP20 lptoken);
    event TimeBoundChanged(uint256 newTimeBound);

    function initialize() public virtual initializer{
        timeBound = 259200; //72 hours in seconds
    }

//	constructor() {}

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(IBEP20 _lpToken, IBEP20 _rewardToken, uint256 _rewardRate, uint256 _rewardIntervalInSeconds, uint256 _startBlock, uint256 _lockPeriodInSeconds, uint256 _endTime, uint256 _totalFarmedAmount) external onlyOwner {
        poolInfo[_lpToken] = PoolInfo({
            lpToken: _lpToken,
            rewardToken: _rewardToken,
            rewardRate: _rewardRate,
            rewardInterval: _rewardIntervalInSeconds,
            startBlock: _startBlock,
            lockPeriod: _lockPeriodInSeconds,
            endTime: _endTime,
            totalFarmedAmount: _totalFarmedAmount
        });
    }

	// Farm Tokens (Deposit): An investor will deposit the lpToken into the smart contracts to starting earning rewards.	
	// Core Thing: Transfer the lpToken from the investor's wallet to this smart contract.

	function farmTokensForReward(IBEP20 lpToken, uint256 _amount) external virtual nonReentrant whenNotPaused {
        require(block.number >= poolInfo[lpToken].startBlock, "Farming: Start Reward Block has not reached");
        if(poolInfo[lpToken].endTime > 0) require(block.timestamp <= poolInfo[lpToken].endTime, "Farming: Has ended");
        require(_amount > 0, "Farming: Balance cannot be 0"); // Farming amount cannot be zero
        require(lpToken.balanceOf(msg.sender) >= _amount, "Farming: Insufficient token balance"); // Checking msg.sender balance

		if(userInfo[msg.sender][lpToken].isFarming){
            require((block.timestamp - userInfo[msg.sender][lpToken].farmingStartTime) >= poolInfo[lpToken].lockPeriod, "Farming is locked");
		    uint256 oldReward = calculateReward(lpToken, msg.sender);
		    userInfo[msg.sender][lpToken].oldReward += oldReward;
		}

        bool transferStatus = lpToken.transferFrom(msg.sender, address(this), _amount);
		if (transferStatus) {
            emit FarmedToken(msg.sender, address(this), _amount);
            userInfo[msg.sender][lpToken].farmedAmount += _amount; // update user farming balance
            userInfo[msg.sender][lpToken].farmingStartTime = block.timestamp; // save the time when they started farming
            // update farming status
            userInfo[msg.sender][lpToken].isFarming = true;
            userInfo[msg.sender][lpToken].hasFarmed = true;
            poolInfo[lpToken].totalFarmedAmount += _amount;
        }
    }

    // Returns the reward of the caller
    function calculateReward(IBEP20 lpToken, address _rewardAddress) public view returns(uint256){
        uint balances = userInfo[_rewardAddress][lpToken].farmedAmount / 10**18;
		uint256 rewards = 0;
        uint256 timeDifferences;
		if(balances > 0){
            if(poolInfo[lpToken].endTime > 0){
                if(block.timestamp > poolInfo[lpToken].endTime){
                    timeDifferences = poolInfo[lpToken].endTime - userInfo[_rewardAddress][lpToken].farmingStartTime;
                }
                else{
                    timeDifferences = block.timestamp - userInfo[_rewardAddress][lpToken].farmingStartTime;
                }
            }
            else {
                timeDifferences = block.timestamp - userInfo[_rewardAddress][lpToken].farmingStartTime;
            }

            // reward calculation
            uint256 timeFactor = timeDifferences / 60 / 60 / 24 / 7;
            uint apyFactorInWei = (poolInfo[lpToken].rewardRate*timeFactor)/52;
            rewards = (((((balances*100)/(poolInfo[lpToken].totalFarmedAmount/10**18))*(10**18)) + (timeFactor*(10**18)) + apyFactorInWei) * balances / 100);
		}
		return rewards;
    }

    function withdrawFarmedTokens(IBEP20 lpToken) external virtual nonReentrant whenNotPaused {
        require(userInfo[msg.sender][lpToken].isFarming, "Farming: No farmed balance available");
        require((block.timestamp - userInfo[msg.sender][lpToken].farmingStartTime) >= poolInfo[lpToken].lockPeriod, "Farming: Is in lock period");
        require(userTimeBounds[msg.sender][lpToken] > 0, "Request withdraw before performing withdraw");
        require(block.timestamp >= userTimeBounds[msg.sender][lpToken]+timeBound, "Cannot perform withdraw before the time bound");
        
        uint256 balance = userInfo[msg.sender][lpToken].farmedAmount;
        uint256 reward = calculateReward(lpToken, msg.sender) + userInfo[msg.sender][lpToken].oldReward;

        // send farmed tokens
        removeFarmedTokens(lpToken, balance);
        // send reward
        sendRewardTokens(lpToken, reward);
        userTimeBounds[msg.sender][lpToken] = 0;
	}

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(IBEP20 lpToken) external nonReentrant whenNotPaused {
        require(userInfo[msg.sender][lpToken].isFarming, "Farming: No farmed balance available");
        require(userTimeBounds[msg.sender][lpToken] > 0, "Request withdraw before performing withdraw");
        require(block.timestamp >= userTimeBounds[msg.sender][lpToken]+timeBound, "Cannot perform withdraw before the time bound");
        uint256 balance = userInfo[msg.sender][lpToken].farmedAmount;
        require(balance > 0, "Farming: Farmed balance is 0");
        require(lpToken.balanceOf(address(this)) >= balance, "Farming: Not enough lp token balance");
        // send farmed tokens
        removeFarmedTokens(lpToken, balance);
        userTimeBounds[msg.sender][lpToken] = 0;
    }

    function sendRewardTokens(IBEP20 lpToken, uint256 calculatedReward) internal virtual {
        require(poolInfo[lpToken].rewardToken.balanceOf(address(this)) >= calculatedReward, "Farming: Not enough reward balance");

        if(calculatedReward > 0){
            bool transferStatus = poolInfo[lpToken].rewardToken.transfer(msg.sender, calculatedReward);
            require(transferStatus, "Farming: Transfer Failed");
            userInfo[msg.sender][lpToken].oldReward = 0;
            emit Reward(address(this), msg.sender, calculatedReward);
        }
    }

    function removeFarmedTokens(IBEP20 lpToken, uint256 balance) internal virtual {
        require(balance > 0, "Farming: Farmed balance is 0");
        require(lpToken.balanceOf(address(this)) >= balance, "Farming: Not enough lp token balance");

        // remove farmed tokens 
		bool transferStatus = lpToken.transfer(msg.sender, balance);
        if(transferStatus){
            emit RemoveFarmedToken(address(this), msg.sender, balance);
            userInfo[msg.sender][lpToken].farmedAmount = 0; // reset staking balance
            userInfo[msg.sender][lpToken].isFarming = false; // update staking status and stakingStartTime (restore to zero)
            userInfo[msg.sender][lpToken].farmingStartTime = 0;
            userInfo[msg.sender][lpToken].oldReward = 0;
        }
    }

    // withdraw bep20 tokens in contract address
    function withdrawBEP20Token(address _tokenContract, uint256 _amount) external virtual onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address"); // 0 address validation
		require(_amount > 0, "Amount cannot be 0"); // require amount greater than 0
        IBEP20 tokenContract = IBEP20(_tokenContract);
        require(tokenContract.balanceOf(address(this)) > _amount, "Amount exceeds the balance");
		bool transferStatus = tokenContract.transfer(msg.sender, _amount);
        require(transferStatus, "Transfer Failed");
        emit ExternalTokenTransferred(_tokenContract, msg.sender, _amount);
	}
	
    // set reward rate for pool in weiAmount
    function setRewardRate(IBEP20 lpToken, uint256 _rewardRate) external virtual onlyOwner whenNotPaused {
        poolInfo[lpToken].rewardRate = _rewardRate;
        emit UpdatedRewardRate(lpToken, _rewardRate);
    }

    // set reward token address
    function setRewardToken(IBEP20 lpToken, IBEP20 _rewardToken) external virtual onlyOwner whenNotPaused {
        poolInfo[lpToken].rewardToken = _rewardToken;
        emit UpdatedRewardToken(lpToken, _rewardToken);
    }

    // set reward interval
    function setRewardInterval(IBEP20 lpToken, uint256 _rewardInterval) external virtual onlyOwner whenNotPaused {
        poolInfo[lpToken].rewardInterval = _rewardInterval;
        emit UpdatedRewardInterval(lpToken, _rewardInterval);
    }

    // set end block
    function setEndTime(IBEP20 lpToken, uint256 _endTime) external virtual onlyOwner whenNotPaused {
        poolInfo[lpToken].endTime = _endTime;
        emit UpdatedendTime(lpToken, _endTime);
    }

    // set lock period
    function setLockPeriod(IBEP20 lpToken, uint256 _lockPeriodInSeconds) external virtual onlyOwner whenNotPaused {
        poolInfo[lpToken].lockPeriod = _lockPeriodInSeconds;
        emit UpdatedLockPeriod(lpToken, _lockPeriodInSeconds);
    }

    function requestWithdraw(IBEP20 _lpToken) external virtual whenNotPaused {
        require(poolInfo[_lpToken].lpToken == _lpToken, "No Such pool found");
        userTimeBounds[msg.sender][_lpToken] = block.timestamp;
        emit withdrawRequested(msg.sender, _lpToken);
    }

    function setTimeBound(uint256 _newTimeBound) external virtual onlyOwner whenNotPaused {
        timeBound = _newTimeBound;
        emit TimeBoundChanged(timeBound);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    uint256[49] private __gap;
}