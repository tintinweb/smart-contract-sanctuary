/*   Polyminer - Community Experimental yield farm on Polygon - Matic.
 *   The only official platform of original Polyminer team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://polyminer.finance                                  │
 *   │                                                                       │
 *   │   Telegram Public Chat: @polyminer                                    │
 *   │                                                                       │
 *   │   E-mail: [email protected]                                     │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect any supported wallet
 *   2) Choose one of the tariff plans, enter the MATIC amount (0.2 MATIC minimum) using our website "Stake" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Minimal deposit: 0.2 MATIC, no maximal limit
 *   - Total income: based on your tarrif plan (from 2% to 4% daily)
 *   - Earnings every moment, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral reward: 7% - 3% - 1.5% - 1% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 90% Platform main balance, using for participants payouts, affiliate program bonuses
 *   - 10% Advertising and promotion expenses, Support work, technical functioning, administration fee
 *
 *   Note: This is experimental community project,
 *   which means this project has high risks as well as high profits.
 *   Once contract balance drops to zero payments will stops,
 *   deposit at your own risk.
 */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Polyminer {
	uint256 public constant INVEST_MIN_AMOUNT = 2e16; // 0.02 matic
	uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
	uint256 public constant PROJECT_FEE = 100; // 10 %
	uint256 public constant PERCENTS_DIVIDER = 1000; // Ej. 70/1000 = 7 %
	uint256 public constant TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalRefBonus;

	struct Plan {
		uint256 time;
		uint256 percent;
	}

	Plan[] internal plans;

	struct Deposit {
		uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping(address => User) internal users;

	bool public started; // contract initialization status
	address payable public manager; // set owner

	// events
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(
		address indexed referrer,
		address indexed referral,
		uint256 indexed level,
		uint256 amount
	);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor() {
		require(!isContract(msg.sender));
		manager = payable(msg.sender);

		// set plans
		plans.push(Plan(18250, 20));
		plans.push(Plan(40, 40));
		plans.push(Plan(60, 35));
		plans.push(Plan(90, 30));
	}

	function invest(address referrer, uint8 plan) public payable {
		if (!started) {
			if (msg.sender == manager) {
				started = true;
			} else revert("Not started yet");
		}

		require(msg.value >= INVEST_MIN_AMOUNT);
		require(plan < 4, "Invalid plan");

		// platform fee transfer
		uint256 fee = (msg.value * PROJECT_FEE) / PERCENTS_DIVIDER;
		manager.transfer(fee);
		emit FeePayed(msg.sender, fee);

		// Initialize or find user
		User storage user = users[msg.sender];

		// check if user has referrer
		// if not has already referrer
		if (user.referrer == address(0)) {
			// set user referrer if is passed in params
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			// set user referrer as upline
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					// if user referrer has value
					users[upline].levels[i] = users[upline].levels[i] + 1;
					upline = users[upline].referrer;
				} else break;
			}
		}

		// if has referrer
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					// if user referrer has value
					// assign referral percent level amount
					uint256 amount = (msg.value * REFERRAL_PERCENTS[i]) /
						PERCENTS_DIVIDER;
					users[upline].bonus = users[upline].bonus + amount;
					users[upline].totalBonus =
						users[upline].totalBonus +
						amount;
					totalRefBonus = totalRefBonus + users[upline].totalBonus;
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		// check if is fist user investment
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		// add investment to deposits
		user.deposits.push(Deposit(plan, msg.value, block.timestamp));

		// increment total invested amount
		totalInvested = totalInvested + msg.value;

		// emit new deposit event
		emit NewDeposit(msg.sender, plan, msg.value);
	}

	function withdraw() public {
		// find user
		User storage user = users[msg.sender];

		// set withdraw amount
		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount + referralBonus;
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount - contractBalance;
			totalAmount = contractBalance;
		}

		// set last user action
		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn + totalAmount;

		payable(msg.sender).transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
	}

	function compound() public {
		// find user
		User storage user = users[msg.sender];

		uint256 amountToCompound = getUserAvailable(msg.sender);

		require(amountToCompound > 0, "User has no dividends to compound");

		user.bonus = 0;
		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn + amountToCompound;

		// add compound to deposits
		user.deposits.push(Deposit(3, amountToCompound, block.timestamp));

		// increment total invested amount
		totalInvested = totalInvested + amountToCompound;

		// emit new deposit event
		emit NewDeposit(msg.sender, 3, amountToCompound);
		emit Withdrawn(msg.sender, amountToCompound);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan)
		public
		view
		returns (uint256 time, uint256 percent)
	{
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress)
		public
		view
		returns (uint256)
	{
		// find user
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start +
				(plans[user.deposits[i].plan].time * (1 days));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount *
					(plans[user.deposits[i].plan].percent / PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint
					? user.deposits[i].start
					: user.checkpoint;
				uint256 to = finish < block.timestamp
					? finish
					: block.timestamp;
				if (from < to) {
					totalAmount =
						(totalAmount + share * (to - from)) /
						TIME_STEP;
				}
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress)
		public
		view
		returns (uint256)
	{
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress)
		public
		view
		returns (uint256)
	{
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress)
		public
		view
		returns (address)
	{
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress)
		public
		view
		returns (uint256[5] memory referrals)
	{
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress)
		public
		view
		returns (uint256)
	{
		return
			users[userAddress].levels[0] +
			users[userAddress].levels[1] +
			users[userAddress].levels[2] +
			users[userAddress].levels[3] +
			users[userAddress].levels[4];
	}

	function getUserReferralBonus(address userAddress)
		public
		view
		returns (uint256)
	{
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress)
		public
		view
		returns (uint256)
	{
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress)
		public
		view
		returns (uint256)
	{
		return users[userAddress].totalBonus - users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress)
		public
		view
		returns (uint256)
	{
		return
			getUserReferralBonus(userAddress) + getUserDividends(userAddress);
	}

	function getUserAmountOfDeposits(address userAddress)
		public
		view
		returns (uint256)
	{
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress)
		public
		view
		returns (uint256 amount)
	{
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount + users[userAddress].deposits[i].amount;
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index)
		public
		view
		returns (
			uint8 plan,
			uint256 percent,
			uint256 amount,
			uint256 start,
			uint256 finish
		)
	{
		User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish =
			user.deposits[index].start +
			(plans[user.deposits[index].plan].time * (1 days));
	}

	function getSiteInfo()
		public
		view
		returns (uint256 _totalInvested, uint256 _totalBonus)
	{
		return (totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress)
		public
		view
		returns (
			uint256 totalDeposit,
			uint256 totalWithdrawn,
			uint256 totalReferrals
		)
	{
		return (
			getUserTotalDeposits(userAddress),
			getUserTotalWithdrawn(userAddress),
			getUserTotalReferrals(userAddress)
		);
	}

	function isContract(address addr) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(addr)
		}
		return size > 0;
	}
}