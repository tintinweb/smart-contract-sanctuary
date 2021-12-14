// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Address.sol";

import "./IRouter.sol";
import "./IRewards.sol";

contract Pool {

	using SafeERC20 for IERC20; 
    using Address for address payable;

    // Contracts
	address public owner;
	address public router;
	address public trading;

	uint256 public withdrawFee = 30; // 0.3%

    address public currency;
    address public rewards; // contract

    uint256 public utilizationMultiplier = 100; // in bps

    uint256 public maxAVAS = 1000000 ether;

    mapping(address => uint256) private balances; // account => amount staked
    uint256 public totalSupply;

    mapping(address => uint256) lastDeposited;
    uint256 public minDepositTime = 1 hours;

    uint256 public openInterest;

	uint256 public constant UNIT = 10**18;

    // Events
    event Deposit(
    	address indexed user, 
    	address indexed currency,
    	uint256 amount, 
    	uint256 clpAmount
    );
    event Withdraw(
    	address indexed user, 
    	address indexed currency,
    	uint256 amount, 
    	uint256 clpAmount
    );

	constructor(address _currency) {
		owner = msg.sender;
		currency = _currency;
	}

	// Governance methods

	function setOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function setRouter(address _router) external onlyOwner {
		router = _router;
		trading = IRouter(router).trading();
		rewards = IRouter(router).getPoolRewards(currency);
	}

	function setParams(
		uint256 _minDepositTime,
		uint256 _utilizationMultiplier,
		uint256 _maxAVAS,
		uint256 _withdrawFee
	) external onlyOwner {
		minDepositTime = _minDepositTime;
		utilizationMultiplier = _utilizationMultiplier;
		maxAVAS = _maxAVAS;
		withdrawFee = _withdrawFee;
	}

	// Open interest
	function updateOpenInterest(uint256 amount, bool isDecrease) external onlyTrading {
		if (isDecrease) {
			if (openInterest <= amount) {
				openInterest = 0;
			} else {
				openInterest -= amount;
			}
		} else {
			openInterest += amount;
		}
	}

	// Methods

	function deposit(uint256 amount) external payable {

		uint256 lastBalance = _getCurrentBalance();

		if (currency == address(0)) {
			amount = msg.value;
			lastBalance -= amount;
		} else {
			_transferIn(amount);
		}

		require(amount > 0, "!amount");
		require(amount + lastBalance <= maxAVAS, "!max-avas");

        uint256 clpAmountToMint = lastBalance == 0 || totalSupply == 0 ? amount : amount * totalSupply / lastBalance;

        lastDeposited[msg.sender] = block.timestamp;

        IRewards(rewards).updateRewards(msg.sender);

        totalSupply += clpAmountToMint;
        balances[msg.sender] += clpAmountToMint;

        emit Deposit(
        	msg.sender,
        	currency,
        	amount,
        	clpAmountToMint
        );

	}

	function withdraw(uint256 currencyAmount) external {

		require(currencyAmount > 0, "!amount");
		require(block.timestamp > lastDeposited[msg.sender] + minDepositTime, "!cooldown");

		IRewards(rewards).updateRewards(msg.sender);

		// Determine corresponding CLP amount

		uint256 currentBalance = _getCurrentBalance();
		require(currentBalance > 0 && totalSupply > 0, "!empty");

		uint256 utilization = getUtilization();
		require(utilization < 10**4, "!utilization");
		
		// CLP amount
		uint256 amount = currencyAmount * totalSupply / currentBalance;

		// Set to max if above max
		if (amount >= balances[msg.sender]) {
			amount = balances[msg.sender];
			currencyAmount = amount * currentBalance / totalSupply;
		}

		uint256 availableBalance = currentBalance * (10**4 - utilization) / 10**4;
		uint256 currencyAmountAfterFee = currencyAmount * (10**4 - withdrawFee) / 10**4;
		require(currencyAmountAfterFee <= availableBalance, "!available-balance");

		totalSupply -= amount;
		balances[msg.sender] -= amount;

		_transferOut(msg.sender, currencyAmountAfterFee);

		// Send fee to this pool's rewards contract
		uint256 feeAmount = currencyAmount - currencyAmountAfterFee;
		_transferOut(rewards, feeAmount);
		IRewards(rewards).notifyRewardReceived(feeAmount);

		emit Withdraw(
			msg.sender,
			currency,
			currencyAmountAfterFee,
			amount
		);
		
	}

	function creditUserProfit(address destination, uint256 amount) external onlyTrading {
		if (amount == 0) return;
		uint256 currentBalance = _getCurrentBalance();
		require(amount < currentBalance, "!balance");
		_transferOut(destination, amount);
	}

	// To receive AVAX
	fallback() external payable {}
	receive() external payable {}

	// Utils

	function _transferIn(uint256 amount) internal {
		// adjust decimals
		uint256 decimals = IRouter(router).getDecimals(currency);
		amount = amount * (10**decimals) / UNIT;
		IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
	}

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

	function _getCurrentBalance() internal view returns(uint256) {
		uint256 currentBalance;
		if (currency == address(0)) {
			currentBalance = address(this).balance;
		} else {
			currentBalance = IERC20(currency).balanceOf(address(this));
		}
		uint256 decimals = IRouter(router).getDecimals(currency);
		return currentBalance * UNIT / (10**decimals);
	}

	// Getters

	function getUtilization() public view returns(uint256) {
		uint256 currentBalance = _getCurrentBalance();
		if (currentBalance == 0) return 0;
		return openInterest * utilizationMultiplier / currentBalance; // in bps
	}

	function getCurrencyBalance(address account) external view returns(uint256) {
		if (totalSupply == 0) return 0;
		uint256 currentBalance = _getCurrentBalance();
		return balances[account] * currentBalance / totalSupply;
	}

	// In Clp
	function getBalance(address account) external view returns(uint256) {
		return balances[account];
	}

	// Modifier

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

	modifier onlyTrading() {
		require(msg.sender == trading, "!trading");
		_;
	}

}