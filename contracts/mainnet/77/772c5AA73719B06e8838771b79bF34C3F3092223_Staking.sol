// SPDX-License-Identifier: MIT
pragma solidity ^0.5.13;

/*
    Main functionality:
    	2% fee on entry and 2% fee on exit deducted from input/output amount and distributed
    	to all current share holders proportional to their position in the pool

	Extended stake bonuses [optional]:
		30 days = 50%
		60 days = 125%
		90 days = 238%

	    -15% penalty when unstaking extended stake early (distributed to share holders similar to entry/exit fee)

	Feature #1 - The airdrop:
	    Admin (or anyone else) can distribute 100% of their deposit among all active share holders

	Feature #2 - The drip:
	    Earn "emissionRate" set by admin per second per 1 token deposited into the pool
	    default emissionRate is 0.00000001 tokens per second per 1 token user has deposited
*/

contract Staking {
	constructor(address _stakingToken, uint256 _emissionRate) public {
		erc20 = TOKEN(address(_stakingToken)); // set the staking token
		admin = msg.sender; // set the admin
		emissionRate = _emissionRate; // set the default emission rate (admin can change this later)

		// set the extended staking options
		stakeOptions[0] = StakeOption(30 days, 50); // 50% after 30 days
		stakeOptions[1] = StakeOption(60 days, 125); // 125% after 60 days
		stakeOptions[2] = StakeOption(90 days, 238); // 238% after 90 days
	}

	using SafeMath for uint256;

	// Declare the staking token
	TOKEN erc20;

	// Admin is payable so they can withdraw any ETH that may be sent here accidentally
	address payable admin;

	// Total balance of all users in the pool
	// This has the entry fee already applied so should always be < erc20.balanceOf(address(this))
	uint256 public totalBalance;

	// How many staking tokens to reward per second per 1 deposited token
	uint256 public emissionRate;

	// All providers aka. the users / stakers in the system
	mapping(address => Provider) public provider;

	// All stakes mapped to their owners
	mapping(address => Stake[]) public stakes;

	// Extended stake options
	mapping(uint8 => StakeOption) public stakeOptions;

	// For admin only functions
	modifier isAdmin() {
		require(admin == msg.sender, "Admin only function");
		_;
	}

	// Events
	event Deposit(address _user, uint256 _amount, uint256 _timestamp);
	event Withdraw(address _user, uint256 _amount, uint256 _timestamp);
	event ExtendedStake(address _user, uint256 _amount, uint8 _stakeOption, uint256 _timestamp);
	event StakeEndWithBonus(address _user, uint256 _bonus, uint256 _timestamp);
	event StakeEndWithPenalty(address _user, uint256 _amount, uint256 _timestamp);
	event ClaimDrip(address _user, uint256 _amount, uint256 _timestamp);
	event Airdrop(address _sender, uint256 _amount, uint256 _timestamp);
	event EmissionRateChanged(uint256 _newEmissionRate);

	// Extended stake
	struct Stake {
		uint256 amount; // amount of tokens staked
		uint32 unlockDate; // unlocks at this timestamp
		uint8 stakeBonus; // the +% bonus this stake gives
	}

	// Stake option, we have 3 of them
	struct StakeOption {
		uint32 duration;
		uint8 bonusPercent;
	}

	// User data
	struct Provider {
		uint256 commitAmount; // user's extended stake aka. the locked amount
		uint256 balance; // user's available balance (to extended stake or to withdraw)
		uint256 dripBalance; // total drips collected before last deposit
		uint32 lastUpdateAt; // timestamp for last update when dripBalance was calculated
	}

	// Function to deposit tokens into the pool
	function depositIntoPool(uint256 _depositAmount) public {
		// Check and transfer tokens here
		require(
			erc20.transferFrom(msg.sender, address(this), _depositAmount) == true,
			"transferFrom did not succeed. Are we approved?"
		);

		// Declare the user
		Provider storage user = provider[msg.sender];

		if (user.balance > 0) {
			// User has previously staked so calculate the new dripBalance
			user.dripBalance = dripBalance(msg.sender);
		}

		// deduct the 2% entry fee
		uint256 balanceToAdd = SafeMath.sub(_depositAmount, SafeMath.div(_depositAmount, 50));
		user.balance = SafeMath.add(user.balance, balanceToAdd);

		user.lastUpdateAt = uint32(now);
		totalBalance = SafeMath.add(totalBalance, balanceToAdd);

		emit Deposit(msg.sender, _depositAmount, now);
	}

	// Function to withdraw all available balance (including dripped rewards) from the pool
	// Does not include the extended stake (locked) balances, if any exist
	function withdrawFromPool(uint256 _amount) public {
		Provider storage user = provider[msg.sender];
		uint256 availableBalance = SafeMath.sub(user.balance, user.commitAmount);
		require(_amount <= availableBalance, "Amount withdrawn exceeds available balance");

		// Claim all dripped rewards first
		claimDrip();

		// deduct the 2% exit fee
		uint256 amountToWithdraw = SafeMath.div(SafeMath.mul(_amount, 49), 50);

		uint256 contractBalance = erc20.balanceOf(address(this));

		// tokens in the contract * withdraw amount with fee / total balance with fee(s)
		uint256 amountToSend =
			SafeMath.div(SafeMath.mul(contractBalance, amountToWithdraw), totalBalance);

		// Subtract the amount
		user.balance = SafeMath.sub(user.balance, _amount);
		totalBalance = SafeMath.sub(totalBalance, _amount);

		// Transfer
		erc20.transfer(msg.sender, amountToSend);

		emit Withdraw(msg.sender, _amount, now);
	}

	// Function to enter an extended stake for a fixed period of time
	function extendedStake(uint256 _amount, uint8 _stakeOption) public {
		// We only have 0, 1, 2 options
		require(_stakeOption <= 2, "Invalid staking option");

		Provider storage user = provider[msg.sender];

		uint256 availableBalance = SafeMath.sub(user.balance, user.commitAmount);
		require(_amount <= availableBalance, "Stake amount exceeds available balance");

		// Set unlock date and bonus from chosen option
		uint32 unlockDate = uint32(now) + stakeOptions[_stakeOption].duration;
		uint8 stakeBonus = stakeOptions[_stakeOption].bonusPercent;

		// Add as commitAmount
		user.commitAmount = SafeMath.add(user.commitAmount, _amount);

		// Push the new stake
		stakes[msg.sender].push(Stake(_amount, unlockDate, stakeBonus));

		emit ExtendedStake(msg.sender, _amount, _stakeOption, now);
	}

	// Function to exit an extended stake
	// Distributes reward if unlockDate has passed or deducts a -15% penalty if it's a premature exit
	function claimStake(uint256 _stakeId) public {
		// Make sure the _stakeId provided is within range
		uint256 playerStakeCount = stakes[msg.sender].length;
		require(_stakeId < playerStakeCount, "Stake does not exist");

		// Declare a user's stake & require it to have an amount
		Stake memory stake = stakes[msg.sender][_stakeId];
		require(stake.amount > 0, "Invalid stake amount");

		// Maintains the stake array length
		if (playerStakeCount > 1) {
			stakes[msg.sender][_stakeId] = stakes[msg.sender][playerStakeCount - 1];
		}
		delete stakes[msg.sender][playerStakeCount - 1];
		stakes[msg.sender].length--;

		Provider storage user = provider[msg.sender];

		if (stake.unlockDate <= now) {
			// Stake duration has passed here. Distribute the stakeBonus reward!
			uint256 balanceToAdd = SafeMath.div(SafeMath.mul(stake.amount, stake.stakeBonus), 100);
			totalBalance = SafeMath.add(totalBalance, balanceToAdd);
			user.commitAmount = SafeMath.sub(user.commitAmount, stake.amount);
			user.balance = SafeMath.add(user.balance, balanceToAdd);
			emit StakeEndWithBonus(msg.sender, balanceToAdd, now);
		} else {
			// Stake duration has not passed. Apply the 15% penalty
			uint256 weightToRemove = SafeMath.div(SafeMath.mul(3, stake.amount), 20);
			user.balance = SafeMath.sub(user.balance, weightToRemove);
			totalBalance = SafeMath.sub(totalBalance, weightToRemove);
			user.commitAmount = SafeMath.sub(user.commitAmount, stake.amount);
			emit StakeEndWithPenalty(msg.sender, weightToRemove, now);
		}
	}

	// Function to claim dripped rewards
	function claimDrip() public {
		Provider storage user = provider[msg.sender];
		uint256 amountToSend = dripBalance(msg.sender);
		user.dripBalance = 0;
		user.lastUpdateAt = uint32(now);
		erc20.transfer(msg.sender, amountToSend);
		emit ClaimDrip(msg.sender, amountToSend, now);
	}

	// Airdrop to pool
	// Anyone can airdrop tokens into the pool. Since withdrawFromPool() uses contractBalance = erc20.balanceOf(address(this))
	// in its calculations, everything extra sent to our contract will get distributed proportionally when user withdraws from pool
	function airdrop(uint256 _amount) external {
		require(
			erc20.transferFrom(msg.sender, address(this), _amount) == true,
			"transferFrom did not succeed. Are we approved?"
		);
		emit Airdrop(msg.sender, _amount, now);
	}

	// Admin can edit the emissionRate
	function changeEmissionRate(uint256 _emissionRate) external isAdmin {
		if (emissionRate != _emissionRate) {
			emissionRate = _emissionRate;
			emit EmissionRateChanged(_emissionRate);
		}
	}

	// Admin can withdraw any ETH that might be accidentally sent here
	function withdrawETH() external isAdmin {
		admin.transfer(address(this).balance);
	}

	// transfer admin to another address
	function transferAdmin(address _newAdmin) external isAdmin {
		admin = address(uint160(_newAdmin));
	}

	// Admin can withdraw any ERC20 token that might be accidentally sent here
	// Excluding of course the staking token itself (funds are safu)
	function withdrawERC20(TOKEN token) public isAdmin {
		require(address(token) != address(0), "Invalid address");
		require(address(token) != address(erc20), "Cannot withdraw the staking token");
		uint256 balance = token.balanceOf(address(this));
		token.transfer(admin, balance);
	}

	// Calculates the undebited drip rewards
	// Formula: Seconds staked X emission rate X user's total deposit / 10^18
	function _unDebitedDrips(Provider memory user) internal view returns (uint256) {
		// (now - user.lastUpdateAt) * emissionRate * user.balance / 1e18
		return
			SafeMath.div(
				SafeMath.mul(
					SafeMath.mul(SafeMath.sub(now, uint256(user.lastUpdateAt)), emissionRate),
					user.balance
				),
				1e18
			);
	}

	// Calculte how many dripped tokens an address currently has
	function dripBalance(address _user) public view returns (uint256) {
		Provider memory user = provider[_user];
		return SafeMath.add(user.dripBalance, _unDebitedDrips(user));
	}

	// Fetch all active stakes for a given user
	function stakesOf(address _user) public view returns (uint256[3][] memory) {
		uint256 userStakeCount = stakes[_user].length;
		uint256[3][] memory data = new uint256[3][](userStakeCount);
		for (uint256 i = 0; i < userStakeCount; i++) {
			Stake memory stake = stakes[_user][i];
			data[i][0] = stake.amount;
			data[i][1] = stake.unlockDate;
			data[i][2] = stake.stakeBonus;
		}
		return (data);
	}
}

contract TOKEN {
	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

