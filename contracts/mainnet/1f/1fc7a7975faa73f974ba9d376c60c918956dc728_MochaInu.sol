pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";
import "./IUniswapRouter.sol";
import "./IUniswapFactory.sol";

contract MochaInu is Context, IERC20, Ownable {
	using Address for address payable;

	string constant NAME = "Mocha Inu";
	string constant SYMBOL = "MOCHA";
	uint8 constant DECIMALS = 9;

	uint256 constant MAX_UINT = 2 ** 256 - 1;
	address constant ROUTER_ADDRESS = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address constant ZERO_ADDRESS = address(0);
	address constant DEAD_ADDRESS = address(57005);

	mapping(address => uint256) rOwned;
	mapping(address => uint256) tOwned;

	mapping(address => mapping(address => uint256)) allowances;

	mapping(address => bool) public isExcludedFromFees;
	mapping(address => bool) public isExcludedFromRewards;
	mapping(address => bool) public isExcludedFromMaxWallet;
	address[] excluded;

	mapping(address => bool) public isBot;

	uint256 tTotal = 10 ** 12 * 10 ** DECIMALS;
	uint256 rTotal = (MAX_UINT - (MAX_UINT % tTotal));

	uint256 public maxTxAmountBuy = tTotal / 200; // 0.5% of supply
	uint256 public maxTxAmountSell = tTotal / 200; // 0.5% of supply
	uint256 public maxWalletAmount = tTotal / 100; // 1% of supply

	uint256 launchedAt;

	address payable marketingAddress;
	address payable buybackAddress;

	mapping(address => bool) automatedMarketMakerPairs;

	bool areFeesBeingProcessed;
	bool public isFeeProcessingEnabled = true;
	uint256 public feeProcessingThreshold = tTotal / 500;

	IUniswapRouter router;
	address pairAddress;

	struct FeeSet {
		uint256 reflectFee;
		uint256 buybackFee;
		uint256 marketingFee;
		uint256 liquidityFee;
	}

	FeeSet public fees = FeeSet({
		reflectFee: 2,
		buybackFee: 3,
		marketingFee: 5,
		liquidityFee: 2
	});

	struct ReflectValueSet {
		uint256 rAmount;
		uint256 rTransferAmount;
		uint256 rReflectFee;
		uint256 rOtherFee;
		uint256 tTransferAmount;
		uint256 tReflectFee;
		uint256 tOtherFee;
	}

	modifier lockTheSwap {
		areFeesBeingProcessed = true;
		_;
		areFeesBeingProcessed = false;
	}

	constructor() {
		address self = address(this);

		rOwned[owner()] = rTotal;

		router = IUniswapRouter(ROUTER_ADDRESS);
		pairAddress = IUniswapFactory(router.factory()).createPair(self, router.WETH());

		automatedMarketMakerPairs[pairAddress] = true;

		marketingAddress = payable(msg.sender);
		buybackAddress = payable(msg.sender);

		isExcludedFromFees[owner()] = true;
		isExcludedFromFees[marketingAddress] = true;
		isExcludedFromFees[self] = true;
		isExcludedFromFees[DEAD_ADDRESS] = true;

		isExcludedFromMaxWallet[owner()] = true;
		isExcludedFromMaxWallet[marketingAddress] = true;
		isExcludedFromMaxWallet[self] = true;
		isExcludedFromMaxWallet[pairAddress] = true;
		isExcludedFromMaxWallet[DEAD_ADDRESS] = true;

		emit Transfer(ZERO_ADDRESS, owner(), tTotal);
	}

	function name() public pure returns (string memory) {
		return NAME;
	}

	function symbol() public pure returns (string memory) {
		return SYMBOL;
	}

	function decimals() public pure returns (uint8) {
		return DECIMALS;
	}

	function totalSupply() public view override returns (uint256) {
		return tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		if (isExcludedFromRewards[account]) return tOwned[account];
		return tokenFromReflection(rOwned[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}

		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		uint256 currentAllowance = allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
		require(rAmount <= rTotal, "Amount must be less than total reflections");
		uint256 currentRate = _getRate();
		return rAmount / currentRate;
	}

	function excludeFromRewards(address account) external onlyOwner {
		require(!isExcludedFromRewards[account], "Account is already excluded");

		if (rOwned[account] > 0) {
			tOwned[account] = tokenFromReflection(rOwned[account]);
		}

		isExcludedFromRewards[account] = true;
		excluded.push(account);
	}

	function includeInRewards(address account) external onlyOwner {
		require(isExcludedFromRewards[account], "Account is not excluded");

		for (uint256 i = 0; i < excluded.length; i++) {
			if (excluded[i] == account) {
				excluded[i] = excluded[excluded.length - 1];
				tOwned[account] = 0;
				isExcludedFromRewards[account] = false;
				excluded.pop();
				break;
			}
		}
	}

	function _getValues(uint256 tAmount, bool takeFee) private view returns (ReflectValueSet memory set) {
		set = _getTValues(tAmount, takeFee);
		(set.rAmount, set.rTransferAmount, set.rReflectFee, set.rOtherFee) = _getRValues(set, tAmount, takeFee, _getRate());
		return set;
	}

	function _getTValues(uint256 tAmount, bool takeFee) private view returns (ReflectValueSet memory set) {
		if (!takeFee) {
			set.tTransferAmount = tAmount;
			return set;
		}

		set.tReflectFee = tAmount * fees.reflectFee / 100;
		set.tOtherFee = tAmount * (fees.buybackFee + fees.marketingFee + fees.liquidityFee) / 100;
		set.tTransferAmount = tAmount - set.tReflectFee - set.tOtherFee;

		return set;
	}

	function _getRValues(ReflectValueSet memory set, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rReflectFee, uint256 rOtherFee) {
		rAmount = tAmount * currentRate;

		if (!takeFee) {
			return (rAmount, rAmount, 0, 0);
		}

		rReflectFee = set.tReflectFee * currentRate;
		rOtherFee = set.tOtherFee * currentRate;
		rTransferAmount = rAmount - rReflectFee - rOtherFee;
		return (rAmount, rTransferAmount, rReflectFee, rOtherFee);
	}

	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply / tSupply;
	}

	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 rSupply = rTotal;
		uint256 tSupply = tTotal;

		for (uint256 i = 0; i < excluded.length; i++) {
			if (rOwned[excluded[i]] > rSupply || tOwned[excluded[i]] > tSupply) return (rTotal, tTotal);
			rSupply -= rOwned[excluded[i]];
			tSupply -= tOwned[excluded[i]];
		}

		if (rSupply < rTotal / tTotal) return (rTotal, tTotal);
		return (rSupply, tSupply);
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != ZERO_ADDRESS, "ERC20: approve from the zero address");
		require(spender != ZERO_ADDRESS, "ERC20: approve to the zero address");

		allowances[owner][spender] = amount;

		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {
		require(from != ZERO_ADDRESS, "ERC20: transfer from the zero address");
		require(to != ZERO_ADDRESS, "ERC20: transfer to the zero address");
		require(!isBot[from], "ERC20: address blacklisted (bot)");
		require(amount > 0, "Transfer amount must be greater than zero");
		require(amount <= balanceOf(from), "You are trying to transfer more than your balance");

		if (maxWalletAmount > 0 && !automatedMarketMakerPairs[to] && !isExcludedFromMaxWallet[to]) {
			require((balanceOf(to) + amount) <= maxWalletAmount, "You are trying to transfer more than the max wallet amount");
		}

		if (launchedAt == 0 && automatedMarketMakerPairs[to]) {
			launchedAt = block.number;
		}

		bool shouldTakeFees = !isExcludedFromFees[from] && !isExcludedFromFees[to];
		if (shouldTakeFees) {
			require(amount <= (automatedMarketMakerPairs[from] ? maxTxAmountBuy : maxTxAmountSell), "You are trying to transfer too many tokens");

			if (automatedMarketMakerPairs[from] && block.number <= launchedAt) {
				isBot[to] = true;
			}
		}

		uint256 balance = balanceOf(address(this));

		if (balance > maxTxAmountSell) {
			balance = maxTxAmountSell;
		}

		if (isFeeProcessingEnabled && !areFeesBeingProcessed && balance >= feeProcessingThreshold && !automatedMarketMakerPairs[from]) {
			areFeesBeingProcessed = true;
			_processFees(balance);
			areFeesBeingProcessed = false;
		}

		_tokenTransfer(from, to, amount, shouldTakeFees);
	}

	function _takeReflectFees(uint256 rReflectFee) private {
		rTotal -= rReflectFee;
	}

	function _takeOtherFees(uint256 rOtherFee, uint256 tOtherFee) private {
		address self = address(this);

		rOwned[self] += rOtherFee;

		if (isExcludedFromRewards[self]) {
			tOwned[self] += tOtherFee;
		}
	}

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool shouldTakeFees) private {
		ReflectValueSet memory set = _getValues(tAmount, shouldTakeFees);

		if (isExcludedFromRewards[sender]) {
			tOwned[sender] -= tAmount;
		}

		if (isExcludedFromRewards[recipient]) {
			tOwned[recipient] += set.tTransferAmount;
		}

		rOwned[sender] -= set.rAmount;
		rOwned[recipient] += set.rTransferAmount;

		if (shouldTakeFees) {
			_takeReflectFees(set.rReflectFee);
			_takeOtherFees(set.rOtherFee, set.tOtherFee);
			emit Transfer(sender, address(this), set.tOtherFee);
		}

		emit Transfer(sender, recipient, set.tTransferAmount);
	}

	function _processFees(uint256 amount) private lockTheSwap {
		uint256 feeSum = fees.buybackFee + fees.marketingFee + fees.liquidityFee;
		if (feeSum == 0) return;

		uint256 amountForBuyback = amount * fees.buybackFee / feeSum;
		uint256 amountForMarketing = amount * fees.marketingFee / feeSum;
		uint256 amountForLiquidity = amount - amountForBuyback - amountForMarketing;

		_addLiquidity(amountForLiquidity);

		uint256 amountOut = _swapExactTokensForETH(amountForBuyback + amountForMarketing);
		uint256 ethForBuyback = amountOut * fees.buybackFee / (fees.buybackFee + fees.marketingFee);

		buybackAddress.transfer(ethForBuyback);
		marketingAddress.transfer(address(this).balance);
	}

	function _addLiquidity(uint256 amount) private {
		address self = address(this);

		uint256 tokensToSell = amount / 2;
		uint256 tokensForLiquidity = amount - tokensToSell;

		uint256 ethForLiquidity = _swapExactTokensForETH(tokensToSell);

		_approve(self, address(router), MAX_UINT);
		router.addLiquidityETH{value : ethForLiquidity}(self, tokensForLiquidity, 0, 0, DEAD_ADDRESS, block.timestamp);
	}

	function _swapExactTokensForETH(uint256 amountIn) private returns (uint256) {
		address self = address(this);

		address[] memory path = new address[](2);
		path[0] = self;
		path[1] = router.WETH();

		_approve(self, address(router), MAX_UINT);

		uint256 previousBalance = self.balance;
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, self, block.timestamp);
		return self.balance - previousBalance;
	}

	function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
		require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;

		if (value) {
			isExcludedFromMaxWallet[pair] = true;
		}
	}

	function setFees(uint256 reflectFee, uint256 buybackFee, uint256 marketingFee, uint256 liquidityFee) external onlyOwner {
	    require((reflectFee + buybackFee + marketingFee + liquidityFee) <= 15, "Cannot set fees to above a combined total of 15%");
	    
		fees = FeeSet({
			reflectFee: reflectFee,
			buybackFee: buybackFee,
			marketingFee: marketingFee,
			liquidityFee: liquidityFee
		});
	}

	function setIsFeeProcessingEnabled(bool value) public onlyOwner {
		isFeeProcessingEnabled = value;
	}

	function setFeeProcessingThreshold(uint256 value) external onlyOwner {
		feeProcessingThreshold = value;
	}

	function setMaxTransactionAmounts(uint256 maxBuy, uint256 maxSell) external onlyOwner {
	    require(maxBuy >= (tTotal / 400), "Must set max buy to at least 0.25% of total supply");
	    require(maxSell >= (tTotal / 400), "Must set max sell to at least 0.25% of total supply");
		maxTxAmountBuy = maxBuy;
		maxTxAmountSell = maxSell;
	}

	function setMarketingAddress(address payable value) external onlyOwner {
		require(marketingAddress != value, "Marketing address is already set to this value");
		marketingAddress = value;
	}

	function setBuybackAddress(address payable value) external onlyOwner {
		require(buybackAddress != value, "Buyback address is already set to this value");
		buybackAddress = value;
	}

	function setIsBot(address account, bool value) external onlyOwner {
		require(isBot[account] != value, "Account is already set to this value");
		isBot[account] = value;
	}

	function setMaxWalletAmount(uint256 value) external onlyOwner {
	    require(value >= (tTotal / 200), "Must set max wallet to at least 0.5% of total supply");
		require(maxWalletAmount != value, "Max wallet amount is already set to this value");
		maxWalletAmount = value;
	}

	function setIsExcludedFromMaxWallet(address account, bool value) external onlyOwner {
		require(isExcludedFromMaxWallet[account] != value, "Account is already set to this value");
		isExcludedFromMaxWallet[account] = value;
	}

	function setIsExcludedFromFees(address account, bool value) external onlyOwner {
		require(isExcludedFromFees[account] != value, "Account is already set to this value");
		isExcludedFromFees[account] = value;
	}

	receive() external payable {}
}