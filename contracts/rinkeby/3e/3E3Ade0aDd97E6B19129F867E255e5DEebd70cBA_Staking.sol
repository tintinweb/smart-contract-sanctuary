//Be name khoda
// SPDX-License-Identifier: GPL-2.0-or-later

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ======================= STAKING ======================
// ======================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// Hosein: https://github.com/hedzed

// Reviewer(s) / Contributor(s)
// S.A. Yaghoubnejad: https://github.com/SAYaghoubnejad

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface DEUSToken {
	function pool_mint(address m_address, uint256 m_amount) external;
}

contract Staking is Ownable {

	struct User {
		uint256 depositAmount;
		uint256 paidReward;
	}

	mapping (address => User) public users;

	uint256 public rewardTillNowPerToken = 0;
	uint256 public lastUpdatedBlock;
	uint256 public rewardPerBlock;
	uint256 public scale = 1e18;

	uint256 public particleCollector = 0;
	uint256 public daoShare;
	uint256 public earlyFoundersShare;
	address public daoWallet;
	address public earlyFoundersWallet;
	uint256 public totalStakedToken = 1;  // init with 1 instead of 0 to avoid division by zero

	address public stakedToken;
	address public rewardToken;

	/* ========== CONSTRUCTOR ========== */

	constructor (
		address _stakedToken,
		address _rewardToken,
		uint256 _rewardPerBlock,
		uint256 _daoShare,
		uint256 _earlyFoundersShare,
		address _daoWallet,
		address _earlyFoundersWallet)
	{
		require(
			_stakedToken != address(0) &&
			_rewardToken != address(0) &&
			_daoWallet != address(0) &&
			_earlyFoundersWallet != address(0),
			"STAKING::constructor: Zero address detected"
		);
		stakedToken = _stakedToken;
		rewardToken = _rewardToken;
		rewardPerBlock = _rewardPerBlock;
		daoShare = _daoShare;
		earlyFoundersShare = _earlyFoundersShare;
		lastUpdatedBlock = block.number;
		daoWallet = _daoWallet;
		earlyFoundersWallet = _earlyFoundersWallet;
	}

	/* ========== VIEWS ========== */

	// View function to see pending reward on frontend.
	function pendingReward(address _user) external view returns (uint256) {
		User storage user = users[_user];
		uint256 accRewardPerToken = rewardTillNowPerToken;

		if (block.number > lastUpdatedBlock) {
			uint256 rewardAmount = (block.number - lastUpdatedBlock) * rewardPerBlock;
			accRewardPerToken = accRewardPerToken + (rewardAmount * scale / totalStakedToken);
		}
		uint256 reward = (user.depositAmount * accRewardPerToken / scale) - user.paidReward;
		return reward * (1e18 - (daoShare + earlyFoundersShare)) / scale;
	}

	/* ========== PUBLIC FUNCTIONS ========== */

	// Update reward variables of the pool to be up-to-date.
	function update() public {
		if (block.number <= lastUpdatedBlock) {
			return;
		}

		uint256 rewardAmount = (block.number - lastUpdatedBlock) * rewardPerBlock;

		rewardTillNowPerToken = rewardTillNowPerToken + (rewardAmount * scale / totalStakedToken);
		lastUpdatedBlock = block.number;
	}

	function deposit(uint256 amount) external {
		depositFor(msg.sender, amount);
	}

	function depositFor(address _user, uint256 amount) public {
		User storage user = users[_user];
		update();

		if (user.depositAmount > 0) {
			uint256 _pendingReward = (user.depositAmount * rewardTillNowPerToken / scale) - user.paidReward;
			sendReward(_user, _pendingReward);
		}

		user.depositAmount = user.depositAmount + amount;
		user.paidReward = user.depositAmount * rewardTillNowPerToken / scale;

		IERC20(stakedToken).transferFrom(msg.sender, address(this), amount);
		totalStakedToken = totalStakedToken + amount;
		emit Deposit(msg.sender, amount);
	}

	function withdraw(uint256 amount) external {
		User storage user = users[msg.sender];
		require(user.depositAmount >= amount, "STAKING::withdraw: withdraw amount exceeds deposited amount");
		update();

		uint256 _pendingReward = (user.depositAmount * rewardTillNowPerToken / scale) - user.paidReward;
		sendReward(msg.sender, _pendingReward);

		uint256 particleCollectorShare = _pendingReward * (daoShare + earlyFoundersShare) / scale;
		particleCollector = particleCollector + particleCollectorShare;

		if (amount > 0) {
			user.depositAmount = user.depositAmount - amount;
			IERC20(stakedToken).transfer(address(msg.sender), amount);
			totalStakedToken = totalStakedToken - amount;
			emit Withdraw(msg.sender, amount);
		}

		user.paidReward = user.depositAmount * rewardTillNowPerToken / scale;
	}

	function withdrawParticleCollector() public {
		uint256 _daoShare = particleCollector * daoShare / (daoShare + earlyFoundersShare);
		DEUSToken(rewardToken).pool_mint(daoWallet, _daoShare);

		uint256 _earlyFoundersShare = particleCollector * earlyFoundersShare / (daoShare + earlyFoundersShare);
		DEUSToken(rewardToken).pool_mint(earlyFoundersWallet, _earlyFoundersShare);

		particleCollector = 0;

		emit WithdrawParticleCollectorAmount(_earlyFoundersShare, _daoShare);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw() external {
		User storage user = users[msg.sender];

		totalStakedToken = totalStakedToken - user.depositAmount;
		IERC20(stakedToken).transfer(msg.sender, user.depositAmount);

		emit EmergencyWithdraw(msg.sender, user.depositAmount);

		user.depositAmount = 0;
		user.paidReward = 0;
	}

	function sendReward(address user, uint256 amount) internal {
		uint256 _daoShareAndEarlyFoundersShare = amount * (daoShare + earlyFoundersShare) / scale;
		DEUSToken(rewardToken).pool_mint(user, amount - _daoShareAndEarlyFoundersShare);
		emit RewardClaimed(user, amount);
	}

	/* ========== EMERGENCY FUNCTIONS ========== */

	// Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
	// Contract ownership will transfer to address(0x) after full auditing of codes.
	function withdrawAllStakedtokens(address to) external onlyOwner {
		uint256 totalStakedTokens = IERC20(stakedToken).balanceOf(address(this));
		IERC20(stakedToken).transfer(to, totalStakedTokens);
	}

	function withdrawERC20(address to, address _token, uint256 amount) external onlyOwner {
		IERC20(_token).transfer(to, amount);
	}

	function setWallets(address _daoWallet, address _earlyFoundersWallet) public onlyOwner {
		daoWallet = _daoWallet;
		earlyFoundersWallet = _earlyFoundersWallet;

		emit WalletsSet(_daoWallet, _earlyFoundersWallet);
	}

	function setShares(uint256 _daoShare, uint256 _earlyFoundersShare) public onlyOwner {
		withdrawParticleCollector();
		daoShare = _daoShare;
		earlyFoundersShare = _earlyFoundersShare;

		emit SharesSet(_daoShare, _earlyFoundersShare);
	}

	function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
		update();
		emit RewardPerBlockChanged(rewardPerBlock, _rewardPerBlock);
		rewardPerBlock = _rewardPerBlock;
	}


	/* ========== EVENTS ========== */

	event SharesSet(uint256 _daoShare, uint256 _earlyFoundersShare);
	event WithdrawParticleCollectorAmount(uint256 _earlyFoundersShare, uint256 _daoShare);
	event WalletsSet(address _daoWallet, address _earlyFoundersWallet);
	event Deposit(address user, uint256 amount);
	event Withdraw(address user, uint256 amount);
	event EmergencyWithdraw(address user, uint256 amount);
	event RewardClaimed(address user, uint256 amount);
	event RewardPerBlockChanged(uint256 oldValue, uint256 newValue);
}

//Dar panah khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

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
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}