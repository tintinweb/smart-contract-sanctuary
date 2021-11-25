pragma solidity ^0.6.2;

// SPDX-License-Identifier: MIT

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./ITraderJoePair.sol";
import "./ITraderJoeFactory.sol";
import "./ITraderJoeRouter.sol";
import "./ITimeStakingContract.sol";
import "./ITimeStakingHelper.sol";
import "./WhiteRabbitTransferHelper.sol";
import "./WhiteRabbitBuybackFund.sol";

contract WhiteRabbit is ERC20, Ownable {
	using SafeMath for uint256;

	uint256 constant MAX_UINT = 2 ** 256 - 1;
	address constant INITIAL_TIME_STAKING_HELPER_CONTRACT_ADDRESS = 0x096BBfB78311227b805c968b070a81D358c13379;
	address constant ROUTER_ADDRESS = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
	address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

	ITimeStakingHelper public timeStakingHelper;
	ITimeStakingContract public timeStakingContract;
	WhiteRabbitDividendTracker public dividendTracker;
	WhiteRabbitTransferHelper private transferHelper;
	WhiteRabbitBuybackFund public buybackFund;

	ITraderJoeRouter public router;
	address public pairAddress;
	
	uint256 public maxWalletAmount;
	uint256 public maxBuyAmount;
	uint256 public maxSellAmount;

	bool public isSwappingEnabled;
	uint256 public swapThreshold;

	mapping(address => bool) public isBlacklisted;
	mapping(address => bool) public isExcludedFromFees;
	mapping(address => bool) public isExcludedFromMaxWallet;

	FeeSet public buyFees;
	FeeSet public sellFees;

	bool hasLaunched;
	bool isSwapping;

	address payable marketingWalletAddress;

	// use by default 400,000 gas to process auto-claiming dividends
	uint256 public gasForProcessing = 400000;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;

	struct FeeSet {
		uint256 dividendsFee;
		uint256 marketingFee;
		uint256 buybackFee;
		uint256 liquidityFee;
	}

	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
	event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

	event SendDividends(uint256 amountIn, uint256 dividends);

	event ProcessedDividendTracker(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	);

	constructor(address payable _marketingWalletAddress) public ERC20("WhiteRabbit", "WRABBIT") {
		setTimeStakingHelper(INITIAL_TIME_STAKING_HELPER_CONTRACT_ADDRESS);
		dividendTracker = new WhiteRabbitDividendTracker(timeStakingContract.Memories());
		transferHelper = new WhiteRabbitTransferHelper(ROUTER_ADDRESS);
		buybackFund = new WhiteRabbitBuybackFund(ROUTER_ADDRESS, address(this));

		router = ITraderJoeRouter(ROUTER_ADDRESS);

		setMarketingWallet(_marketingWalletAddress);

		// exclude from receiving dividends
		dividendTracker.excludeFromDividends(address(dividendTracker));
		dividendTracker.excludeFromDividends(address(transferHelper));
		dividendTracker.excludeFromDividends(address(buybackFund));
		dividendTracker.excludeFromDividends(address(this));
		dividendTracker.excludeFromDividends(owner());
		dividendTracker.excludeFromDividends(DEAD_ADDRESS);
		dividendTracker.excludeFromDividends(address(router));

		// exclude from paying fees or having max transaction amount
		setIsAccountExcludedFromFees(owner(), true);
		setIsAccountExcludedFromFees(address(this), true);
		setIsAccountExcludedFromFees(address(transferHelper), true);
		setIsAccountExcludedFromFees(address(buybackFund), true);

		// exclude from max wallet
		setIsAccountExcludedFromMaxWallet(owner(), true);
		setIsAccountExcludedFromMaxWallet(address(this), true);
		setIsAccountExcludedFromMaxWallet(DEAD_ADDRESS, true);
		setIsAccountExcludedFromMaxWallet(address(0), true);
		setIsAccountExcludedFromMaxWallet(address(transferHelper), true);
		setIsAccountExcludedFromMaxWallet(address(buybackFund), true);

		// set default fees (dividends, marketing, compensation, liquidity)
		setBuyFees(4, 4, 2, 2);
		setSellFees(6, 4, 3, 2);

		/*
			_mint is an internal function in ERC20.sol that is only called here,
			and CANNOT be called ever again
		*/
		_mint(owner(), 100000000000 * (10 ** 18));

		// set initial max wallet and max tx
		setMaxWalletAmount(totalSupply() / 100);
		setMaxTransactionAmounts(totalSupply() / 400, totalSupply() / 400);	
	}

	receive() external payable {

	}

	function setTimeStakingHelper(address value) public onlyOwner {
		require(value != address(0), "New time staking helper address cannot be zero");
		require(value != address(timeStakingHelper), "Cannot set the time staking helper address to the same value");

		timeStakingHelper = ITimeStakingHelper(value);
		timeStakingContract = ITimeStakingContract(timeStakingHelper.staking());
	}

	function setIsAccountExcludedFromFees(address account, bool value) public onlyOwner {
		isExcludedFromFees[account] = value;
	}

	function getSumOfFeeSet(FeeSet memory set) private pure returns (uint256) {
		return set.dividendsFee.add(set.marketingFee).add(set.buybackFee).add(set.liquidityFee);
	}

	function getSumOfBuyFees() public view returns (uint256) {
		return getSumOfFeeSet(buyFees);
	}

	function getSumOfSellFees() public view returns (uint256) {
		return getSumOfFeeSet(sellFees);
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(pair != pairAddress, "The pair address cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(pair, value);
	}

	function setIsAccountBlacklisted(address account, bool value) external onlyOwner {
		isBlacklisted[account] = value;
	}

	function setIsAccountExcludedFromMaxWallet(address account, bool value) public onlyOwner {
		isExcludedFromMaxWallet[account] = value;
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;

		if (value) {
			dividendTracker.excludeFromDividends(pair);
		}

		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function updateGasForProcessing(uint256 newValue) public onlyOwner {
		require(newValue >= 200000 && newValue <= 500000, "gasForProcessing must be between 200,000 and 500,000");
		require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
		emit GasForProcessingUpdated(newValue, gasForProcessing);
		gasForProcessing = newValue;
	}

	function updateClaimWait(uint256 claimWait) external onlyOwner {
		dividendTracker.updateClaimWait(claimWait);
	}

	function getClaimWait() external view returns (uint256) {
		return dividendTracker.claimWait();
	}

	function getTotalDividendsDistributed() external view returns (uint256) {
		return dividendTracker.totalDividendsDistributed();
	}

	function withdrawableDividendOf(address account) public view returns (uint256) {
		return dividendTracker.withdrawableDividendOf(account);
	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner {
		dividendTracker.excludeFromDividends(account);
	}

	function getAccountDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		return dividendTracker.getAccount(account);
	}

	function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		return dividendTracker.getAccountAtIndex(index);
	}

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
	}

	function claim() external {
		dividendTracker.processAccount(msg.sender, false);
	}

	function getLastProcessedIndex() external view returns (uint256) {
		return dividendTracker.getLastProcessedIndex();
	}

	function getNumberOfDividendTokenHolders() external view returns (uint256) {
		return dividendTracker.getNumberOfTokenHolders();
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted address");

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		if (hasLaunched) {
			// enforce max wallet
			if (maxWalletAmount > 0 && !automatedMarketMakerPairs[to] && !isExcludedFromMaxWallet[to]) {
				require(balanceOf(to).add(amount) <= maxWalletAmount, "You are transferring too many tokens, please try to transfer a smaller amount");
			}

			// enforce max tx
			if (!isExcludedFromMaxWallet[from]) {
				require(amount <= (automatedMarketMakerPairs[from] ? maxBuyAmount : maxSellAmount), "You are transferring too many tokens, please try to transfer a smaller amount");
			}

			// take transaction fee
			if(!isSwapping && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
				uint256 feePercent = automatedMarketMakerPairs[from] ? getSumOfBuyFees() : getSumOfSellFees();

				if (feePercent > 0) {
					uint256 fees = amount.mul(feePercent).div(100);
					amount = amount.sub(fees);
					super._transfer(from, address(this), fees);
				}
			}

			// process transaction fees
			if(!isSwapping && isSwappingEnabled) {
				uint256 balance = balanceOf(address(this));

				if(balance > maxSellAmount) {
					balance = maxSellAmount;
				}

				if(balance >= swapThreshold && !automatedMarketMakerPairs[from]) {
					isSwapping = true;
					processFees(balance);
					isSwapping = false;
				}
			}
		}

		// transfer remaining amount as standard
		super._transfer(from, to, amount);

		// update tracked dividends
		try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
		try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

		// attempt dividend distribution
		if (!isSwapping) {
			uint256 gas = gasForProcessing;

			try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
				emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
			} catch {}
		}
	}

	function processFees(uint256 amountIn) private {
		uint256 totalFees = getSumOfBuyFees();
		if (totalFees == 0) return;

		uint256 amountOut = swapExactTokensForAVAX(amountIn);
		uint256 avaxForDividends = amountOut.mul(buyFees.dividendsFee).div(totalFees);
		uint256 avaxForBuyback = amountOut.mul(buyFees.buybackFee).div(totalFees);
		uint256 avaxForLiquidity = amountOut.mul(buyFees.liquidityFee).div(totalFees);

		if (avaxForDividends > 0) {
			swapAndSendDividends(avaxForDividends);
		}

		if (avaxForBuyback > 0) {
			buybackFund.deposit{value: avaxForBuyback}();
		}

		if (avaxForLiquidity > 0) {
			swapAndLiquify(avaxForLiquidity);
		}

		uint256 balance = address(this).balance;

		if (balance > 0) {
			marketingWalletAddress.transfer(balance);
		}
	}

	function swapAndSendDividends(uint256 amountIn) private {
		IERC20 time = IERC20(timeStakingContract.Time());
		IERC20 memo = IERC20(timeStakingContract.Memories());

		//Buy TIME tokens
		swapExactAVAXForTokens(amountIn, address(time));

		//Stake TIME tokens
		uint256 amountToStake = time.balanceOf(address(this));
		if (amountToStake > 0) {
			require(time.approve(address(timeStakingHelper), amountToStake), "TIME token approval failed");
			timeStakingHelper.stake(amountToStake, address(this));
		}

		//Transfer out MEMO tokens
		uint256 dividends = memo.balanceOf(address(this));

		bool success = memo.transfer(address(dividendTracker), dividends);

		if (success) {
			dividendTracker.distributeDividends(dividends);
			emit SendDividends(amountIn, dividends);
		}
	}

	function swapAndLiquify(uint256 amountIn) private {
		uint256 halfForEth = amountIn.div(2);
		uint256 halfForTokens = amountIn.sub(halfForEth);

		uint256 tokensOut = swapExactAVAXForTokens(halfForTokens, address(this));
		_approve(address(this), address(router), tokensOut);
		router.addLiquidityAVAX{value : halfForEth}(address(this), tokensOut, 0, 0, owner(), block.timestamp);
	}

	function swapExactTokensForAVAX(uint256 amountIn) private returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = router.WAVAX();

		_approve(address(this), address(router), amountIn);

		uint256 previousBalance = address(this).balance;
		router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp);
		return address(this).balance.sub(previousBalance);
	}

	function swapExactAVAXForTokens(uint256 amountIn, address tokenAddress) private returns (uint256) {
		return transferHelper.buy{value : amountIn}(tokenAddress);
	}

	function launch() external payable onlyOwner {
		address self = address(this);

		uint256 tokensForLiquidity = balanceOf(self);

		require(!hasLaunched, "Token has already launched");
		require(tokensForLiquidity > 0, "Insufficient token balance for initial liquidity");
		require(msg.value > 0, "Insufficient value sent for initial liquidity");

		//Create pair
		pairAddress = ITraderJoeFactory(router.factory()).createPair(self, router.WAVAX());
		_setAutomatedMarketMakerPair(pairAddress, true);

		//Add liquidity
		_approve(self, address(router), MAX_UINT);
		router.addLiquidityAVAX{value : msg.value}(self, tokensForLiquidity, 0, 0, owner(), block.timestamp);

		isSwappingEnabled = true;
		swapThreshold = totalSupply() / 500;
		hasLaunched = true;
	}

	function buyback(uint256 amount) external onlyOwner {
		buybackFund.buyback(amount);
	}

	function setMarketingWallet(address payable value) public onlyOwner {
		require(value != owner(), "Marketing wallet cannot be the owner");
		marketingWalletAddress = value;
		setIsAccountExcludedFromFees(marketingWalletAddress, true);
		setIsAccountExcludedFromMaxWallet(marketingWalletAddress, true);
	}

	function setBuyFees(uint256 _dividendsFee, uint256 _marketingFee, uint256 _buybackFee, uint256 _liquidityFee) public onlyOwner {
		require((_dividendsFee + _marketingFee + _buybackFee + _liquidityFee) <= 30, "Sum of buy fees may not be over 30%");

		buyFees = FeeSet({
			dividendsFee: _dividendsFee,
			marketingFee: _marketingFee,
			buybackFee: _buybackFee,
			liquidityFee: _liquidityFee
		});
	}

	function setSellFees(uint256 _dividendsFee, uint256 _marketingFee, uint256 _buybackFee, uint256 _liquidityFee) public onlyOwner {
		require((_dividendsFee + _marketingFee + _buybackFee + _liquidityFee) <= 30, "Sum of sell fees may not be over 30%");

		sellFees = FeeSet({
			dividendsFee: _dividendsFee,
			marketingFee: _marketingFee,
			buybackFee: _buybackFee,
			liquidityFee: _liquidityFee
		});
	}

	function setMaxWalletAmount(uint256 amount) public onlyOwner {
		require(amount >= totalSupply() / 1000, "Cannot set max wallet amount to less than 0.1% of the total supply");
		maxWalletAmount = amount;
	}

	function setMaxTransactionAmounts(uint256 maxBuy, uint256 maxSell) public onlyOwner {
		require(maxBuy >= totalSupply() / 1000, "Cannot sell max buy to less than 0.1% of the total supply");
		require(maxSell >= totalSupply() / 1000, "Cannot sell max sell to less than 0.1% of the total supply");
		maxBuyAmount = maxBuy;
		maxSellAmount = maxSell;
	}

	function setIsSwappingEnabled(bool value) public onlyOwner {
		isSwappingEnabled = value;
	}

	function setSwapThreshold(uint256 value) public onlyOwner {
		swapThreshold = value;
	}
}

contract WhiteRabbitDividendTracker is Ownable, DividendPayingToken {
	using SafeMath for uint256;
	using SafeMathInt for int256;
	using IterableMapping for IterableMapping.Map;

	IterableMapping.Map private tokenHoldersMap;
	uint256 public lastProcessedIndex;

	mapping(address => bool) public excludedFromDividends;

	mapping(address => uint256) public lastClaimTimes;

	uint256 public claimWait = 3600;
	uint256 public immutable minimumTokenBalanceForDividends = 200000 * (10 ** 18);

	event ExcludeFromDividends(address indexed account);
	event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

	event Claim(address indexed account, uint256 amount, bool indexed automatic);

	constructor(address rewardsTokenAddress) public DividendPayingToken("WhiteRabbit_Dividend_Tracker", "WRABBIT_Dividend_Tracker", rewardsTokenAddress) {

	}

	function _transfer(address, address, uint256) internal override {
		require(false, "DividendTracker: No transfers allowed");
	}

	function withdrawDividend() public override {
		require(false, "DividendTracker: withdrawDividend disabled. Use the 'claim' function on the main token contract.");
	}

	function excludeFromDividends(address account) external onlyOwner {
		require(!excludedFromDividends[account]);
		excludedFromDividends[account] = true;

		_setBalance(account, 0);
		tokenHoldersMap.remove(account);

		emit ExcludeFromDividends(account);
	}

	function updateClaimWait(uint256 newClaimWait) external onlyOwner {
		require(newClaimWait >= 3600 && newClaimWait <= 86400, "DividendTracker: claimWait must be updated to between 1 and 24 hours");
		require(newClaimWait != claimWait, "DividendTracker: Cannot update claimWait to same value");
		emit ClaimWaitUpdated(newClaimWait, claimWait);
		claimWait = newClaimWait;
	}

	function getLastProcessedIndex() external view returns (uint256) {
		return lastProcessedIndex;
	}

	function getNumberOfTokenHolders() external view returns (uint256) {
		return tokenHoldersMap.keys.length;
	}

	function getAccount(address _account) public view returns (
		address account,
		int256 index,
		int256 iterationsUntilProcessed,
		uint256 withdrawableDividends,
		uint256 totalDividends,
		uint256 lastClaimTime,
		uint256 nextClaimTime,
		uint256 secondsUntilAutoClaimAvailable
	) {
		account = _account;

		index = tokenHoldersMap.getIndexOfKey(account);

		iterationsUntilProcessed = - 1;

		if (index >= 0) {
			if (uint256(index) > lastProcessedIndex) {
				iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
			} else {
				uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
				iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
			}
		}

		withdrawableDividends = withdrawableDividendOf(account);
		totalDividends = accumulativeDividendOf(account);

		lastClaimTime = lastClaimTimes[account];

		nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

		secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
	}

	function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		if (index >= tokenHoldersMap.size()) {
			return (address(0), - 1, - 1, 0, 0, 0, 0, 0);
		}

		return getAccount(tokenHoldersMap.getKeyAtIndex(index));
	}

	function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
		if (lastClaimTime > block.timestamp) {
			return false;
		}

		return block.timestamp.sub(lastClaimTime) >= claimWait;
	}

	function setBalance(address payable account, uint256 newBalance) external onlyOwner {
		if (excludedFromDividends[account]) {
			return;
		}

		if (newBalance >= minimumTokenBalanceForDividends) {
			_setBalance(account, newBalance);
			tokenHoldersMap.set(account, newBalance);
		}
		else {
			_setBalance(account, 0);
			tokenHoldersMap.remove(account);
		}

		processAccount(account, true);
	}

	function process(uint256 gas) public returns (uint256, uint256, uint256) {
		uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

		if (numberOfTokenHolders == 0) {
			return (0, 0, lastProcessedIndex);
		}

		uint256 _lastProcessedIndex = lastProcessedIndex;

		uint256 gasUsed = 0;

		uint256 gasLeft = gasleft();

		uint256 iterations = 0;
		uint256 claims = 0;

		while (gasUsed < gas && iterations < numberOfTokenHolders) {
			_lastProcessedIndex++;

			if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
				_lastProcessedIndex = 0;
			}

			address account = tokenHoldersMap.keys[_lastProcessedIndex];

			if (canAutoClaim(lastClaimTimes[account])) {
				if (processAccount(payable(account), true)) {
					claims++;
				}
			}

			iterations++;

			uint256 newGasLeft = gasleft();

			if (gasLeft > newGasLeft) {
				gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
			}

			gasLeft = newGasLeft;
		}

		lastProcessedIndex = _lastProcessedIndex;

		return (iterations, claims, lastProcessedIndex);
	}

	function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
		uint256 amount = _withdrawDividendOfUser(account);

		if (amount > 0) {
			lastClaimTimes[account] = block.timestamp;
			emit Claim(account, amount, automatic);
			return true;
		}

		return false;
	}
}