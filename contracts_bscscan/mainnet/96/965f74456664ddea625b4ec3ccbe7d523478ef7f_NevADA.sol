// SPDX-License-Identifier: MIT

/**
 * .------..------..------..------..------..------.
 * |N.--. ||E.--. ||V.--. ||A.--. ||D.--. ||A.--. |
 * | :(): || (\/) || :(): || (\/) || :/\: || (\/) |
 * | ()() || :\/: || ()() || :\/: || (__) || :\/: |
 * | '--'N|| '--'E|| '--'V|| '--'A|| '--'D|| '--'A|
 * `------'`------'`------'`------'`------'`------'
 *
 * The first BSC token to feature a reward-based gambling platform.
 *
 * https://nevada.casino
 * https://t.me/NevADAtoken
 * https://twitter.com/NevADAbsc
 * https://www.reddit.com/r/NevADAtoken
 *
 * In memory of Selma
 */

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./IterableMapping.sol";
import "./TransferHelper.sol";
import "./IERC1155.sol";

contract NevADA is ERC20, Ownable {
	using SafeMath for uint256;

	enum TxLimitMode {
		DISABLED,
		HARD,
		TAX
	}

	struct TokenLock {
		uint256 amount;
        uint256 releaseTime;
    }

	struct FeeSet {
		uint256 dividendsFee;
		uint256 developmentFee;
		uint256 marketingFee;
		uint256 maintenanceFee;
		uint256 liquidityFee;
        uint256 buybackFee;
	}

	bool private inSwap;
	uint256 private launchedAt;

	uint256 constant initialSupply = 100000000000 * (10 ** 18);
	address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ADA = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;
	address constant LOCKER = 0xce47f1F042768f5AA347301B5EE3de850eB81796;
	address public marketingWallet = 0x0169731a94e9FCcb13943C56ffc632d33BB9E63A;
	address public developmentWallet = 0xa04E2048F44e7E13b0Cb444ed75Bd334df824F9C;
	address public maintenanceWallet = 0x4fA7a656b204a3813e983700e89a5c46799f5342;

	IERC1155 selmaNFT = IERC1155(0x824Db8c2Cf7eC655De2A7825f8E9311c8e526523);
	NevadaDividendTracker public dividendTracker;
	IUniswapV2Router02 public router;
	TransferHelper transferHelper;
	address public pair;
	uint256 pairCounter;

	FeeSet public feeDistribution;
	uint256 public buyFee = 1100;
	uint256 public sellFee = 1100;
	uint256 public whaleFee = 1000;

	TxLimitMode public maxWalletMode = TxLimitMode.HARD;
	uint256 public maxWalletAmount = initialSupply.div(100);
	TxLimitMode public maxSellMode = TxLimitMode.TAX;
	uint256 public maxSellAmount = initialSupply.div(200);
	mapping(address => bool) public isExcludedFromTxLimits;

	uint256 public swapTokensAtAmount = 2000000 * (10 ** 18);
	uint256 public gasForProcessing = 400000;

	// exlcude from fees and max transaction amount
	mapping(address => bool) public isExcludedFromFees;
	mapping(address => bool) public automatedMarketMakerPairs;
	mapping(address => bool) public isBlacklisted;
	mapping(address => TokenLock) public lockedTokens;

	event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
	event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFees(address indexed account, bool isExcluded);
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

	modifier onlyMarketing() {
        require(msg.sender == marketingWallet);
        _;
    }

	modifier swapping() { 
        inSwap = true;
        _;
        inSwap = false;
    }

	constructor() public ERC20("NevADA", "NVD") {
		dividendTracker = new NevadaDividendTracker();
		transferHelper = new TransferHelper();

		router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
		pairCounter++;

		_setAutomatedMarketMakerPair(pair, true);
		_setMarketingWallet(payable(marketingWallet));

		dividendTracker.excludeFromDividends(address(dividendTracker));
		dividendTracker.excludeFromDividends(address(transferHelper));
		dividendTracker.excludeFromDividends(address(router));
		dividendTracker.excludeFromDividends(address(this));
		dividendTracker.excludeFromDividends(owner());
		dividendTracker.excludeFromDividends(DEAD);

		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(address(router), true);
		excludeFromFees(address(transferHelper), true);

		excludeFromTxLimits(DEAD, true);
		excludeFromTxLimits(owner(), true);
		excludeFromTxLimits(address(this), true);
		excludeFromTxLimits(address(router), true);
		excludeFromTxLimits(address(transferHelper), true);

		// dividends, development, marketing, maintenance, liquidity, buyback
		setFeeDistribution(1800, 1800, 2700, 1000, 2700, 0);

		_mint(owner(), initialSupply);
	}

	receive() external payable {}

	function _transfer(address _from, address _to, uint256 _amount) internal override {
		require(_from != address(0), "ERC20: transfer from the zero address");
		require(_to != address(0), "ERC20: transfer to the zero address");
		require(!isBlacklisted[_from] && !isBlacklisted[_to], "Blacklisted address");

		if (_amount == 0) {
			super._transfer(_from, _to, 0);
			return;
		}

		if (lockedTokens[_from].releaseTime > block.timestamp) {
            require(balanceOf(_from).sub(_amount) >= lockedTokens[_from].amount, "Tokens are locked");
        }

		if (launchedAt == 0 && automatedMarketMakerPairs[_to] && balanceOf(_from) > 0) {
			launchedAt = block.number;
		}

		checkTxLimitations(_from, _to, _amount);

		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;

		if (canSwap && !inSwap && _from != owner() && _to != owner()) {
			processFees(contractTokenBalance);
		}

		bool isBuy = automatedMarketMakerPairs[_from];
		bool isSell = automatedMarketMakerPairs[_to];
		bool takeFee = !inSwap && !isExcludedFromFees[_from] && !isExcludedFromFees[_to] && (isBuy || isSell);

		if (takeFee) {
			uint256 feePercent = automatedMarketMakerPairs[_to] ? sellFee : buyFee;
			feePercent = adjustFeeForWhales(_from, _to, _amount, feePercent);
			feePercent = adjustFeeForSelmaHolders(_from, _to, feePercent);

			if (block.number <= (launchedAt + 1) && automatedMarketMakerPairs[_from] && _to != address(router) && _to != address(this) && _to != owner()) {
				feePercent = 99;
			}

			if (feePercent > 0) {
				uint256 fees = _amount.mul(feePercent).div(10000);
				_amount = _amount.sub(fees);
				super._transfer(_from, address(this), fees);
			}
		}

		super._transfer(_from, _to, _amount);

		try dividendTracker.setBalance(payable(_from), balanceOf(_from)) {} catch {}
		try dividendTracker.setBalance(payable(_to), balanceOf(_to)) {} catch {}

		if (!inSwap) {
			uint256 gas = gasForProcessing;

			try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
				emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
			} catch {}
		}
	}

	function checkTxLimitations(address from, address to, uint256 amount) private view {
		if (maxWalletMode == TxLimitMode.HARD && !automatedMarketMakerPairs[to] && !isExcludedFromTxLimits[to]) {
			require(balanceOf(to).add(amount) <= maxWalletAmount, "You are transferring too many tokens, please try to transfer a smaller amount");
		}

		if (maxSellMode == TxLimitMode.HARD && automatedMarketMakerPairs[to] && !isExcludedFromTxLimits[from]) {
			require(amount <= maxSellAmount, "You are transferring too many tokens, please try to transfer a smaller amount");
		}
	}

	function adjustFeeForWhales(address from, address to, uint256 amount, uint256 feePercent) private view returns (uint256) {
		if (
			maxWalletMode == TxLimitMode.TAX &&
			!automatedMarketMakerPairs[to] &&
			!isExcludedFromTxLimits[to] &&
			balanceOf(to).add(amount) > maxWalletAmount
		) {
			return feePercent.add(whaleFee);
		}

		if (
			maxSellMode == TxLimitMode.TAX &&
			automatedMarketMakerPairs[to] &&
			!isExcludedFromTxLimits[from] &&
			amount > maxSellAmount
		) {
			return feePercent.add(whaleFee);
		}

		return feePercent;
	}

	function adjustFeeForSelmaHolders(address from, address to, uint256 feePercent) private view returns (uint256) {
		address initiator = automatedMarketMakerPairs[to] ? from : to;

		if (selmaNFT.balanceOf(initiator, 0) > 0) { return feePercent.sub(feePercent.div(4)); }
		if (selmaNFT.balanceOf(initiator, 2) > 0) { return 0; }

		return feePercent;
	}

	function processFees(uint256 amountIn) private {
		uint256 ethAmount = swapExactTokensForETH(amountIn);

		uint256 ethForDividends = ethAmount.mul(feeDistribution.dividendsFee).div(10000);
		uint256 ethForDevelopment = ethAmount.mul(feeDistribution.developmentFee).div(10000);
		uint256 ethForMarketing = ethAmount.mul(feeDistribution.marketingFee).div(10000);
		uint256 ethForMaintenance = ethAmount.mul(feeDistribution.maintenanceFee).div(10000);
		uint256 ethForLiquidity = ethAmount.mul(feeDistribution.liquidityFee).div(10000);

		if (ethForDividends > 0) {
			swapAndSendDividends(ethForDividends);
		}

		if (ethForDevelopment > 0) {
			payable(developmentWallet).call{value: ethForDevelopment, gas: 25000}("");
		}

		if (ethForMarketing > 0) {
			payable(marketingWallet).call{value: ethForMarketing, gas: 25000}("");
		}

		if (ethForMaintenance > 0) {
			payable(maintenanceWallet).call{value: ethForMaintenance, gas: 25000}("");
		}

		if (ethForLiquidity > 0) {
			swapAndLiquify(ethForLiquidity);
		}
	}

	function swapAndSendDividends(uint256 amountIn) private {
		uint256 adaBalance = swapExactETHForTokens(amountIn, ADA, address(this));
		if (adaBalance == 0) { return; }
		bool success = IERC20(ADA).transfer(address(dividendTracker), adaBalance);

		if (success) {
			dividendTracker.distributeDividends(adaBalance);
			emit SendDividends(amountIn, adaBalance);
		}
	}

	function swapAndLiquify(uint256 amountIn) private swapping {
		uint256 half = amountIn.div(2);
		uint256 tokens = swapExactETHForTokens(half, address(this), address(this));
		if (tokens == 0) { return; }
		_approve(address(this), address(router), tokens);
		router.addLiquidityETH{value: half}(address(this), tokens, 0, 0, LOCKER, block.timestamp);
	}

	function swapExactTokensForETH(uint256 amountIn) private swapping returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = router.WETH();

		_approve(address(this), address(router), amountIn);

		uint256 previousBalance = address(this).balance;
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp);
		return address(this).balance.sub(previousBalance);
	}

	function swapExactETHForTokens(uint256 amountIn, address tokenAddress, address to) private returns (uint256) {
		return transferHelper.buy{value: amountIn}(tokenAddress, to);
	}

	function _setMarketingWallet(address payable wallet) private {
		require(wallet != owner(), "Marketing wallet cannot be the owner");

		dividendTracker.excludeFromDividends(wallet);
		excludeFromFees(wallet, true);
		excludeFromTxLimits(wallet, true);

		marketingWallet = wallet;
	}

	function _setAutomatedMarketMakerPair(address newPair, bool value) private {
		require(automatedMarketMakerPairs[newPair] != value, "Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[newPair] = value;

		if (value) {
			dividendTracker.excludeFromDividends(newPair);
		}

		emit SetAutomatedMarketMakerPair(newPair, value);
	}

	// Maintenance

	function updateDividendTracker(address newAddress) external onlyOwner {
		require(newAddress != address(dividendTracker), "The dividend tracker already has that address");

		NevadaDividendTracker newDividendTracker = NevadaDividendTracker(payable(newAddress));

		require(newDividendTracker.owner() == address(this), "The new dividend tracker must be owned by the Nevada token contract");

		newDividendTracker.excludeFromDividends(address(newDividendTracker));
		newDividendTracker.excludeFromDividends(address(transferHelper));
		newDividendTracker.excludeFromDividends(address(router));
		newDividendTracker.excludeFromDividends(address(this));
		newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(DEAD);
		newDividendTracker.excludeFromDividends(pair);
		newDividendTracker.excludeFromDividends(marketingWallet);

		emit UpdateDividendTracker(newAddress, address(dividendTracker));

		dividendTracker = newDividendTracker;
	}

	function updateUniswapV2Router(address newAddress) external onlyOwner {
		require(newAddress != address(router), "The router already has that address");
		emit UpdateUniswapV2Router(newAddress, address(router));

		router = IUniswapV2Router02(newAddress);
		pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
		pairCounter++;

		dividendTracker.excludeFromDividends(newAddress);
		excludeFromTxLimits(address(router), true);
		excludeFromFees(address(router), true);

		transferHelper.updateRouter(newAddress);
	}

	function updateGasForProcessing(uint256 newValue) external onlyOwner {
		require(newValue >= 200000 && newValue <= 750000, "gasForProcessing must be between 200,000 and 750,000");
		require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
		emit GasForProcessingUpdated(newValue, gasForProcessing);
		gasForProcessing = newValue;
	}

	function updateSelmaNFT(address newAddress) external onlyOwner {
		selmaNFT = IERC1155(newAddress);
	}

	function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
		require(newPair != pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(newPair, value);
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
		isExcludedFromFees[account] = excluded;

		emit ExcludeFromFees(account, excluded);
	}

	function blacklistAddress(address account, bool value) external onlyOwner {
		require(account != pair && account != address(this), "Can't blacklist pair or contract");
		isBlacklisted[account] = value;
	}

	function excludeFromTxLimits(address account, bool value) public onlyOwner {
		isExcludedFromTxLimits[account] = value;
	}

	function setMaxWalletAmount(uint256 amount) external onlyOwner {
		require(amount >= totalSupply().div(2000) && amount <= totalSupply(), "Amount must be between 0.05% and max total supply");
		maxWalletAmount = amount;
	}

	function setMaxWalletMode(TxLimitMode mode) external onlyOwner {
		maxWalletMode = mode;
	}

	function setMaxSellAmount(uint256 amount) external onlyOwner {
		require(amount >= totalSupply().div(2000), "Amount must be more than 0.05% from total supply");
		maxSellAmount = amount;
	}

	function setMaxSellMode(TxLimitMode mode) external onlyOwner {
		maxSellMode = mode;
	}

	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
		uint256 tokenAmount = amount * 10**18;
		swapTokensAtAmount = tokenAmount;
	}

	function recover() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function setWhaleFee(uint256 _whaleFee) external onlyOwner {
		require(_whaleFee <= 10, "Whale fee can't be over 10%");
		whaleFee = _whaleFee;
	}

	function setBuyFee(uint256 _buyFee) external onlyOwner {
		require(_buyFee <= 20, "Sell fee can't be over 20%");
		buyFee = _buyFee;
	}

	function setSellFee(uint256 _sellFee) external onlyOwner {
		require(_sellFee <= 20, "Sell fee can't be over 20%");
		sellFee = _sellFee;
	}

	function setFeeDistribution(
		uint256 _dividendsFee,
		uint256 _developmentFee,
		uint256 _marketingFee,
		uint256 _maintenanceFee,
		uint256 _liquidityFee,
		uint256 _buybackFee
	) public onlyOwner {
	    uint256 manualFees = _developmentFee.add(_marketingFee).add(_maintenanceFee);
	    uint256 automaticFees = _dividendsFee.add(_liquidityFee).add(_buybackFee);
	    uint256 feeSum = manualFees.add(automaticFees);
		require(feeSum <= 10000, "Invalid sum");

		feeDistribution = FeeSet({
			dividendsFee: _dividendsFee,
			developmentFee: _developmentFee,
			marketingFee: _marketingFee,
			maintenanceFee: _maintenanceFee,
			liquidityFee: _liquidityFee,
            buybackFee: _buybackFee
		});
	}

	function sendLockedTokens(address recipient, uint256 amount, uint256 releaseTime) external onlyOwner {
		uint256 tokenAmount = amount * 10**18;
        lockedTokens[recipient] = TokenLock(tokenAmount, releaseTime);
        _transfer(msg.sender, recipient, tokenAmount);
    }

    function unlockTokens(address account) external onlyOwner {
        lockedTokens[account].releaseTime = 0;
        lockedTokens[account].amount = 0;
    }

	// Marketing

	function triggerBuyback(uint256 amount) public onlyMarketing swapping {
		swapExactETHForTokens(amount, address(this), DEAD);
    }

	// DividendTracker

	function excludeFromDividends(address account) external onlyOwner {
		dividendTracker.excludeFromDividends(account);
	}

	function updateClaimWait(uint256 claimWait) external onlyOwner {
		dividendTracker.updateClaimWait(claimWait);
	}

	function withdrawableDividendOf(address account) external view returns (uint256) {
		return dividendTracker.withdrawableDividendOf(account);
	}

	function dividendTokenBalanceOf(address account) external view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function getClaimWait() external view returns (uint256) {
		return dividendTracker.claimWait();
	}

	function getTotalDividendsDistributed() external view returns (uint256) {
		return dividendTracker.totalDividendsDistributed();
	}

	function getAccountDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		return dividendTracker.getAccount(account);
	}

	function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
		return dividendTracker.getAccountAtIndex(index);
	}

	function getLastProcessedIndex() external view returns (uint256) {
		return dividendTracker.getLastProcessedIndex();
	}

	function getNumberOfDividendTokenHolders() external view returns (uint256) {
		return dividendTracker.getNumberOfTokenHolders();
	}

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
	}

	function claim() external {
		dividendTracker.processAccount(msg.sender, false);
	}
}

contract NevadaDividendTracker is Ownable, DividendPayingToken {
	using SafeMath for uint256;
	using SafeMathInt for int256;
	using IterableMapping for IterableMapping.Map;

	IterableMapping.Map tokenHoldersMap;
	uint256 public lastProcessedIndex;
	uint256 public claimWait = 3600;

	mapping(address => bool) public excludedFromDividends;
	mapping(address => uint256) public lastClaimTimes;

	event ExcludeFromDividends(address indexed account);
	event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
	event Claim(address indexed account, uint256 amount, bool indexed automatic);

	constructor() public DividendPayingToken("Nevada Dividend Tracker", "NDT") {}

	function withdrawDividend() public override {
		require(false, "WithdrawDividend disabled. Use the 'claim' function on the main Nevada contract.");
	}

	function excludeFromDividends(address account) external onlyOwner {
		require(!excludedFromDividends[account]);
		excludedFromDividends[account] = true;

		_setBalance(account, 0);
		tokenHoldersMap.remove(account);

		emit ExcludeFromDividends(account);
	}

	function updateClaimWait(uint256 newClaimWait) external onlyOwner {
		require(newClaimWait >= 3600 && newClaimWait <= 86400, "ClaimWait must be updated to between 1 and 24 hours");
		require(newClaimWait != claimWait, "Cannot update claimWait to same value");
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

		_setBalance(account, newBalance);

		if (newBalance == 0) {
			tokenHoldersMap.remove(account); 
		} else {
			tokenHoldersMap.set(account, newBalance);
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