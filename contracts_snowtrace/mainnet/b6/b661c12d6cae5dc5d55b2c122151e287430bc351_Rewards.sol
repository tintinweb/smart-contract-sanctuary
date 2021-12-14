// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Address.sol";

import "./IRouter.sol";
import "./ITrading.sol";
import "./IPool.sol";

contract Rewards {

	using SafeERC20 for IERC20; 
    using Address for address payable;

    address public owner;
	address public router;
	address public trading;
	address public treasury;

	address public pool; // pool contract associated with these rewards
	address public currency; // rewards paid in this

	uint256 public cumulativeRewardPerTokenStored;
	uint256 public pendingReward;

	mapping(address => uint256) private claimableReward;
	mapping(address => uint256) private previousRewardPerToken;

	uint256 public constant UNIT = 10**18;

	event CollectedReward(
		address user,
		address poolContract,
		address currency,
		uint256 amount
	);

	constructor(address _pool, address _currency) {
		owner = msg.sender;
		pool = _pool;
		currency = _currency;
	}

	// Governance methods

	function setOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function setRouter(address _router) external onlyOwner {
		router = _router;
		trading = IRouter(router).trading();
		treasury = IRouter(router).treasury();
	}

	// Methods

	function notifyRewardReceived(uint256 amount) external onlyTreasuryOrPool {
		pendingReward += amount; // 18 decimals
	}

	function updateRewards(address account) public {

		if (account == address(0)) return;

		ITrading(trading).distributeFees(currency);

		uint256 supply = IPool(pool).totalSupply();

		if (supply > 0) {
			cumulativeRewardPerTokenStored += pendingReward * UNIT / supply;
			pendingReward = 0;
		}

		if (cumulativeRewardPerTokenStored == 0) return; // no rewards yet

		uint256 accountBalance = IPool(pool).getBalance(account); // in CLP

		claimableReward[account] += accountBalance * (cumulativeRewardPerTokenStored - previousRewardPerToken[account]) / UNIT;
		previousRewardPerToken[account] = cumulativeRewardPerTokenStored;

	}

	function collectReward() external {

		updateRewards(msg.sender);

		uint256 rewardToSend = claimableReward[msg.sender];
		claimableReward[msg.sender] = 0;

		if (rewardToSend > 0) {

			_transferOut(msg.sender, rewardToSend);

			emit CollectedReward(
				msg.sender, 
				pool, 
				currency, 
				rewardToSend
			);

		}

	}

	function getClaimableReward() external view returns(uint256) {

		uint256 currentClaimableReward = claimableReward[msg.sender];

		uint256 supply = IPool(pool).totalSupply();
		if (supply == 0) return currentClaimableReward;

		uint256 share;
		if (pool == IRouter(router).avasPool()) {
			share = IRouter(router).getAVASShare(currency);
		} else {
			share = IRouter(router).getPoolShare(currency);
		}

		uint256 _pendingReward = pendingReward + ITrading(trading).getPendingFee(currency) * share / 10**4;

		uint256 _rewardPerTokenStored = cumulativeRewardPerTokenStored + _pendingReward * UNIT / supply;
		if (_rewardPerTokenStored == 0) return currentClaimableReward; // no rewards yet

		uint256 accountStakedBalance = IPool(pool).getBalance(msg.sender);

		return currentClaimableReward + accountStakedBalance * (_rewardPerTokenStored - previousRewardPerToken[msg.sender]) / UNIT;
		
	}

	// To receive AVAX
	fallback() external payable {}
	receive() external payable {}

	// Utils

	function _transferOut(address to, uint256 amount) internal {
		if (amount == 0 || to == address(0)) return;
		// adjust decimals
		uint256 decimals = IRouter(router).getDecimals(currency);
		amount = amount * (10**decimals) / UNIT;
		if (currency == address(0)) {
			payable(to).sendValue(amount);
		} else {
			IERC20(currency).safeTransfer(to, amount);
		}
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

	modifier onlyTreasuryOrPool() {
		require(msg.sender == treasury || msg.sender == pool, "!treasury|pool");
		_;
	}

}