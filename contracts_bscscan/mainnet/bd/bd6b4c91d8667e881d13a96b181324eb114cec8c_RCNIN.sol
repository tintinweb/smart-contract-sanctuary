// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./RaccoonTransferHelper.sol";

contract RCNIN is ERC20, Ownable {
	using SafeMath for uint256;

	enum MaxWalletMode {
		DISABLED,
		HARD,
		TAX
	}
	
	struct FeeSet {
		uint256 dividendsFee;
		uint256 marketingFee;
		uint256 liquidityFee;
	}

	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2Pair;

	bool private swapping;
	uint256 private launchedAt;
	bool private isTradingEnabled = true;

	RaccoonDividendTracker public dividendTracker;
	RaccoonTransferHelper private transferHelper;

	address public deadWallet = 0x000000000000000000000000000000000000dEaD;
	
	uint256 public swapTokensAtAmount = 200000 * (10 ** 18);
	uint256 public _maxWalletAmount = 0;

	mapping(address => bool) public _isBlacklisted;
	mapping(address => bool) public _isExcludedFromMaxWallet;

	FeeSet public buyFees;
	FeeSet public sellFees;
	uint256 public whaleFee = 10;

	MaxWalletMode public maxWalletMode = MaxWalletMode.DISABLED;

	address public _marketingWalletAddress;

	// use by default 400,000 gas to process auto-claiming dividends
	uint256 public gasForProcessing = 400000;

	// exlcude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;

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
	
	constructor(address routerAddress, address payable marketingWalletAddress) public ERC20("Raccoon Ninja", "$RCNIN") {
		dividendTracker = new RaccoonDividendTracker();
		transferHelper = new RaccoonTransferHelper(routerAddress);

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
		.createPair(address(this), _uniswapV2Router.WETH());

		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;

		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);
		setMarketingWallet(marketingWalletAddress);

		// exclude from receiving dividends
		dividendTracker.excludeFromDividends(address(dividendTracker));
		dividendTracker.excludeFromDividends(address(transferHelper));
		dividendTracker.excludeFromDividends(address(this));
		dividendTracker.excludeFromDividends(owner());
		dividendTracker.excludeFromDividends(deadWallet);
		dividendTracker.excludeFromDividends(address(_uniswapV2Router));

		// exclude from paying fees or having max transaction amount
		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(address(transferHelper), true);

		// exclude from max wallet
		excludeFromMaxWallet(owner(), true);
		excludeFromMaxWallet(address(this), true);
		excludeFromMaxWallet(deadWallet, true);
		excludeFromMaxWallet(address(0), true);
		excludeFromMaxWallet(address(transferHelper), true);

		// set default fees (dividends, marketing, liquidity)
		setBuyFees(7, 5, 3);
		setSellFees(7, 5, 3);
		
		_mint(owner(), 100000000000 * (10 ** 18));
	}

	receive() external payable {

	}

	function updateDividendTracker(address newAddress) public onlyOwner {
		require(newAddress != address(dividendTracker), "RCNIN: The dividend tracker already has that address");

		RaccoonDividendTracker newDividendTracker = RaccoonDividendTracker(payable(newAddress));

		require(newDividendTracker.owner() == address(this), "RCNIN: The new dividend tracker must be owned by the RCNIN token contract");

		newDividendTracker.excludeFromDividends(address(newDividendTracker));
		newDividendTracker.excludeFromDividends(address(this));
		newDividendTracker.excludeFromDividends(owner());
		newDividendTracker.excludeFromDividends(address(uniswapV2Router));

		emit UpdateDividendTracker(newAddress, address(dividendTracker));

		dividendTracker = newDividendTracker;
	}

	function updateUniswapV2Router(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "RCNIN: The router already has that address");
		emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
		address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
		uniswapV2Pair = _uniswapV2Pair;
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFees[account] != excluded, "RCNIN: Account is already the value of 'excluded'");
		_isExcludedFromFees[account] = excluded;
		emit ExcludeFromFees(account, excluded);
	}

	function setMarketingWallet(address payable wallet) public onlyOwner {
		require(wallet != owner(), "Marketing wallet cannot be the owner");
		_marketingWalletAddress = wallet;
		excludeFromFees(_marketingWalletAddress, true);
		excludeFromMaxWallet(wallet, true);
	}

	function setBuyFees(uint256 _dividendsFee, uint256 _marketingFee, uint256 _liquidityFee) public onlyOwner {
		buyFees = FeeSet({
			dividendsFee: _dividendsFee,
			marketingFee: _marketingFee,
			liquidityFee: _liquidityFee
		});
	}

	function setSellFees(uint256 _dividendsFee, uint256 _marketingFee, uint256 _liquidityFee) public onlyOwner {
		sellFees = FeeSet({
			dividendsFee: _dividendsFee,
			marketingFee: _marketingFee,
			liquidityFee: _liquidityFee
		});
	}

	function setWhaleFee(uint256 _whaleFee) public onlyOwner {
		whaleFee = _whaleFee;
	}

	function getSumOfFeeSet(FeeSet memory set) private pure returns (uint256) {
		return set.dividendsFee.add(set.marketingFee).add(set.liquidityFee);
	}

	function getSumOfBuyFees() public view returns (uint256) {
		return getSumOfFeeSet(buyFees);
	}

	function getSumOfSellFees() public view returns (uint256) {
		return getSumOfFeeSet(sellFees);
	}

	function setMaxWalletMode(MaxWalletMode mode) public onlyOwner {
		maxWalletMode = mode;
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(pair != uniswapV2Pair, "RCNIN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(pair, value);
	}

	function blacklistAddress(address account, bool value) external onlyOwner {
		_isBlacklisted[account] = value;
	}

	function excludeFromMaxWallet(address account, bool value) public onlyOwner {
		_isExcludedFromMaxWallet[account] = value;
	}

	function setMaxWalletAmount(uint256 amount) public onlyOwner {
		require(amount <= totalSupply(), "RCNIN: Amount cannot be over the total supply.");
		_maxWalletAmount = amount;
	}

	function getMaxWalletAmount() public view returns (uint256) {
		return _maxWalletAmount;
	}

	function setIsTradingEnabled(bool value) external onlyOwner {
		isTradingEnabled = value;
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "RCNIN: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;

		if (value) {
			dividendTracker.excludeFromDividends(pair);
		}

		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function updateGasForProcessing(uint256 newValue) public onlyOwner {
		require(newValue >= 200000 && newValue <= 500000, "RCNIN: gasForProcessing must be between 200,000 and 500,000");
		require(newValue != gasForProcessing, "RCNIN: Cannot update gasForProcessing to same value");
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

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
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

	function _transfer(address _from, address _to, uint256 _amount) internal override {
		require(_from != address(0), "ERC20: transfer from the zero address");
		require(_to != address(0), "ERC20: transfer to the zero address");
		require(!_isBlacklisted[_from] && !_isBlacklisted[_to], "Blacklisted address");
		require(isTradingEnabled, "Trading is disabled");
		
		if (launchedAt == 0 && _from == owner() && automatedMarketMakerPairs[_to]) 
		{
			launchedAt = block.number;
		}
		
		if (_amount == 0) 
		{
			super._transfer(_from, _to, 0);
			return;
		}
		
		// enforce hard max wallet if enabled
		if (maxWalletMode == MaxWalletMode.HARD && !automatedMarketMakerPairs[_to] && !_isExcludedFromMaxWallet[_to]) 
		{
			require(balanceOf(_to).add(_amount) <= _maxWalletAmount, "You are transferring too many tokens, please try to transfer a smaller amount");
		}
		
		// process fees stored in contract
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;

		if (canSwap && !swapping && !automatedMarketMakerPairs[_from] && _from != owner() && _to != owner()) {
			swapping = true;
			processFees(contractTokenBalance);
			swapping = false;
		}

		// process transaction tax
		bool takeFee = !swapping && !_isExcludedFromFees[_from] && !_isExcludedFromFees[_to];

		if (takeFee) {
			uint256 feePercent = automatedMarketMakerPairs[_to] ? getSumOfSellFees() : getSumOfBuyFees();

			// collect whale tax
			if (maxWalletMode == MaxWalletMode.TAX && !automatedMarketMakerPairs[_to] && !_isExcludedFromMaxWallet[_to]) {
				if (balanceOf(_to).add(_amount) > _maxWalletAmount) {
					feePercent += whaleFee;
				}
			}

			if (feePercent > 0) {
				uint256 fees = _amount.mul(feePercent).div(100);
				_amount = _amount.sub(fees);
				super._transfer(_from, address(this), fees);
			}
		}

		// transfer remaining amount as standard
		super._transfer(_from, _to, _amount);

		// update tracked dividends
		try dividendTracker.setBalance(payable(_from), balanceOf(_from)) {} catch {}
		try dividendTracker.setBalance(payable(_to), balanceOf(_to)) {} catch {}

		// attempt dividend distribution
		if (!swapping) {
			uint256 gas = gasForProcessing;

			try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
				emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
			} catch {}
		}
	}

	function processFees(uint256 amountIn) private 
	{
		uint256 totalFees = getSumOfBuyFees();
		if (totalFees == 0) return;

		uint256 amountOut = swapExactTokensForETH(amountIn);
		uint256 ethForDividends = amountOut.mul(buyFees.dividendsFee).div(totalFees);
		uint256 ethForMarketing = amountOut.mul(buyFees.marketingFee).div(totalFees);
		uint256 ethForLiquidity = amountOut.sub(ethForDividends).sub(ethForMarketing);

		if (ethForDividends > 0) {
			swapAndSendDividends(amountIn, ethForDividends);
		}
		
		if (ethForMarketing > 0) {
			payable(_marketingWalletAddress).transfer(ethForMarketing);
		}
		
		if (ethForLiquidity > 0) {
			swapAndLiquify(ethForLiquidity);
		}
	}
	
	function swapAndSendDividends(uint256 token, uint256 dividends) private {
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        if(success) {
   	 		emit SendDividends(token, dividends);
        }
    }

	function swapAndLiquify(uint256 amountIn) private {
		uint256 halfForEth = amountIn.div(2);
		uint256 halfForTokens = amountIn.sub(halfForEth);

		uint256 tokensOut = swapExactETHForTokens(halfForTokens, address(this));
		_approve(address(this), address(uniswapV2Router), tokensOut);
		uniswapV2Router.addLiquidityETH{value: halfForEth}(address(this), tokensOut, 0, 0, address(0), block.timestamp);
	}

	function swapExactTokensForETH(uint256 amountIn) private returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		_approve(address(this), address(uniswapV2Router), amountIn);

		uint256 previousBalance = address(this).balance;
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp);
		return address(this).balance.sub(previousBalance);
	}

	function swapExactETHForTokens(uint256 amountIn, address tokenAddress) private returns (uint256) {
		return transferHelper.buy{value: amountIn}(tokenAddress);
	}

	function recover() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}
}

contract RaccoonDividendTracker is Ownable, DividendPayingToken {
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

	constructor() public DividendPayingToken("RCNIN_Dividend_Tracker", "RCNIN_Dividend_Tracker") {

	}

	function _transfer(address, address, uint256) internal override {
		require(false, "RCNIN_Dividend_Tracker: No transfers allowed");
	}

	function withdrawDividend() public override {
		require(false, "RCNIN_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main RCNIN contract.");
	}

	function excludeFromDividends(address account) external onlyOwner {
		require(!excludedFromDividends[account]);
		excludedFromDividends[account] = true;

		_setBalance(account, 0);
		tokenHoldersMap.remove(account);

		emit ExcludeFromDividends(account);
	}

	function updateClaimWait(uint256 newClaimWait) external onlyOwner {
		require(newClaimWait >= 3600 && newClaimWait <= 86400, "RCNIN_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
		require(newClaimWait != claimWait, "RCNIN_Dividend_Tracker: Cannot update claimWait to same value");
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
		else 
		{
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