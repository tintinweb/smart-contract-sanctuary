pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";
import "./IDEXRouter.sol";
import "./IDEXFactory.sol";
import "./BuybackTreasury.sol";
import "./IUnicryptLiquidityLocker.sol";
import "./IAntiSnipe.sol";

contract HangryBirds is Context, IERC20, Ownable {
	using Address for address payable;

	string constant NAME = "HangryBirds";
	string constant SYMBOL = "HANGRY";
	uint8 constant DECIMALS = 9;

	uint256 constant MAX_UINT = 2 ** 256 - 1;
	address constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address constant UNICRYPT_LIQUIDITY_LOCKER_ADDRESS = 0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214;
	address constant ZERO_ADDRESS = address(0);
	address constant DEAD_ADDRESS = address(57005);

	mapping(address => uint256) rOwned;
	mapping(address => uint256) tOwned;

	mapping(address => mapping(address => uint256)) allowances;

	mapping(address => bool) public isExcludedFromFees;
	mapping(address => bool) public isExcludedFromRewards;
	mapping(address => bool) public isExcludedFromMaxWallet;
	address[] excluded;

	uint256 tTotal = 10 ** 12 * 10 ** DECIMALS;
	uint256 rTotal = (MAX_UINT - (MAX_UINT % tTotal));

	uint256 public maxWalletAmount = tTotal / 100;
	uint256 public maxTxAmountBuy = maxWalletAmount / 2;
	uint256 public maxTxAmountSell = maxWalletAmount / 2;

	address payable marketingWalletAddress;

	mapping(address => bool) automatedMarketMakerPairs;

	bool areFeesBeingProcessed = false;
	bool public isFeeProcessingEnabled = true;
	uint256 public feeProcessingThreshold = tTotal / 500;

	IDEXRouter router;
	BuybackTreasury public treasury;
	IAntiSnipe antiSnipe;

	mapping(address => bool) snipers;

	bool hasLaunched;
	uint256 launchedAt;

	FeeSet public buyFees = FeeSet({
		reflectFee: 5,
		marketingFee: 5,
		treasuryFee: 2
	});

	FeeSet public sellFees = FeeSet({
		reflectFee: 8,
		marketingFee: 2,
		treasuryFee: 5
	});

	struct FeeSet {
		uint256 reflectFee;
		uint256 marketingFee;
		uint256 treasuryFee;
	}

	struct ReflectValueSet {
		uint256 rAmount;
		uint256 rTransferAmount;
		uint256 rReflectFee;
		uint256 rOtherFee;
		uint256 tTransferAmount;
		uint256 tReflectFee;
		uint256 tOtherFee;
	}

	event FeesProcessed(uint256 amount);
	event Launched();
	event SniperAdded(address sniper);
	event SniperPunished(address sniper);
	event SniperRemoved(address sniper);

	constructor() {
		address self = address(this);

		rOwned[owner()] = rTotal;

		router = IDEXRouter(ROUTER_ADDRESS);
		treasury = new BuybackTreasury(address(router), self, owner());

		marketingWalletAddress = payable(msg.sender);

		isExcludedFromFees[owner()] = true;
		isExcludedFromFees[marketingWalletAddress] = true;
		isExcludedFromFees[address(treasury)] = true;
		isExcludedFromFees[self] = true;
		isExcludedFromFees[DEAD_ADDRESS] = true;

		isExcludedFromMaxWallet[owner()] = true;
		isExcludedFromMaxWallet[marketingWalletAddress] = true;
		isExcludedFromMaxWallet[address(treasury)] = true;
		isExcludedFromMaxWallet[self] = true;
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

	function _getValues(uint256 tAmount, bool isBuying, bool takeFee) private view returns (ReflectValueSet memory set) {
		set = _getTValues(tAmount, isBuying, takeFee);
		(set.rAmount, set.rTransferAmount, set.rReflectFee, set.rOtherFee) = _getRValues(set, tAmount, takeFee, _getRate());
		return set;
	}

	function _getTValues(uint256 tAmount, bool isBuying, bool takeFee) private view returns (ReflectValueSet memory set) {
		if (!takeFee) {
			set.tTransferAmount = tAmount;
			return set;
		}

		FeeSet memory fees = isBuying ? buyFees : sellFees;

		set.tReflectFee = tAmount * fees.reflectFee / 100;
		set.tOtherFee = tAmount * (fees.marketingFee + fees.treasuryFee) / 100;
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
		require(amount > 0, "Transfer amount must be greater than zero");
		require(amount <= balanceOf(from), "You are trying to transfer more than your balance");
		require(!snipers[from], "Sniper no sniping!");

		bool isBuying = automatedMarketMakerPairs[from];
		bool shouldTakeFees = hasLaunched && !isExcludedFromFees[from] && !isExcludedFromFees[to];

		if (hasLaunched) {
			// validate max wallet
			if (!automatedMarketMakerPairs[to] && !isExcludedFromMaxWallet[to]) {
				require((balanceOf(to) + amount) <= maxWalletAmount, "Cannot transfer more than the max wallet amount");
			}

			// validate max buy/sell
			if (shouldTakeFees) {
				require(amount <= (isBuying ? maxTxAmountBuy : maxTxAmountSell), "Cannot transfer more than the max buy or sell");
			}

			// anti-snipe mechanism
			if (block.number <= (launchedAt + 1)) {
				antiSnipe.process(from, to);
			}

			// process fees
			uint256 balance = balanceOf(address(this));
			if (isFeeProcessingEnabled && !areFeesBeingProcessed && balance >= feeProcessingThreshold && !automatedMarketMakerPairs[from]) {
				areFeesBeingProcessed = true;
				_processFees(balance > maxTxAmountSell ? maxTxAmountSell : balance);
				areFeesBeingProcessed = false;
			}
		}

		_tokenTransfer(from, to, amount, isBuying, shouldTakeFees);
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

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool isBuying, bool shouldTakeFees) private {
		ReflectValueSet memory set = _getValues(tAmount, isBuying, shouldTakeFees);

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

	function _processFees(uint256 amount) private {
		uint256 feeSum = buyFees.marketingFee + buyFees.treasuryFee;
		if (feeSum == 0) return;

		// swap fee tokens to ETH
		_swapExactTokensForETH(amount);

		// calculate correct amounts to send out
		uint256 amountEth = address(this).balance;
		uint256 amountForMarketing = amountEth * buyFees.marketingFee / feeSum;
		uint256 amountForTreasury = amountEth - amountForMarketing;

		// send out fees
		if (amountForMarketing > 0) {
			marketingWalletAddress.transfer(amountForMarketing);
		}

		if (amountForTreasury > 0) {
			treasury.deposit{value : amountForTreasury}();
		}

		emit FeesProcessed(amount);
	}

	function _swapExactTokensForETH(uint256 amountIn) private {
		address self = address(this);

		address[] memory path = new address[](2);
		path[0] = self;
		path[1] = router.WETH();

		_approve(self, address(router), amountIn);
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, self, block.timestamp);
	}

	function _excludeFromRewards(address account) private {
		require(!isExcludedFromRewards[account], "Account is already excluded from rewards");

		if (rOwned[account] > 0) {
			tOwned[account] = tokenFromReflection(rOwned[account]);
		}

		isExcludedFromRewards[account] = true;
		excluded.push(account);
	}

	function _includeInRewards(address account) private {
		require(isExcludedFromRewards[account], "Account is not excluded from rewards");

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

	function launch(uint256 daysToLock) external payable onlyOwner {
		address self = address(this);

		require(!hasLaunched, "Already launched");
		require(daysToLock >= 30, "Must lock liquidity for a minimum of 30 days");

		uint256 tokensForLiquidity = balanceOf(self);
		require(tokensForLiquidity >= (tTotal / 4), "Initial liquidity must be at least 25% of total token supply");

		IUnicryptLiquidityLocker locker = IUnicryptLiquidityLocker(UNICRYPT_LIQUIDITY_LOCKER_ADDRESS);

		// calculate and validate ETH amounts for liquidity and locker
		(uint256 lockFee,,,,,,,,) = locker.gFees();
		require(msg.value > lockFee, "Insufficient ETH for liquidity lock fee");

		uint256 ethForLiquidity = msg.value - lockFee;
		require(ethForLiquidity >= 0.1 ether, "Insufficient ETH for liquidity");

		// create pair
		address pairAddress = IDEXFactory(router.factory()).createPair(self, router.WETH());
		automatedMarketMakerPairs[pairAddress] = true;
		isExcludedFromMaxWallet[pairAddress] = true;

		if (!isExcludedFromRewards[pairAddress]) {
			_excludeFromRewards(pairAddress);
		}

		// add liquidity
		_approve(self, address(router), tokensForLiquidity);
		router.addLiquidityETH{value : ethForLiquidity}(self, tokensForLiquidity, 0, 0, self, block.timestamp);

		// lock liquidity
		IERC20 lpToken = IERC20(pairAddress);

		uint256 balance = lpToken.balanceOf(self);
		require(lpToken.approve(address(locker), balance), "Liquidity token approval failed");

		locker.lockLPToken{value : lockFee}(address(lpToken), balance, block.timestamp + (daysToLock * (1 days)), payable(0), true, payable(owner()));

		// set up anti-snipe
		antiSnipe.launch(pairAddress);

		// set appropriate launch flags
		hasLaunched = true;
		launchedAt = block.number;

		emit Launched();
	}

	function recoverLaunchedTokens() external onlyOwner {
		require(!hasLaunched, "Already launched");

		// this is used as an emergency mechanism in the case of an incorrect amount of liquidity tokens being accidentally sent.
		// it is only possible to call this method before launch, and its indended use is to recover tokens which would otherwise
		// result in a failed launch 
		_transfer(address(this), owner(), balanceOf(address(this)));
	}

	function buyback(uint256 amount) external onlyOwner {
		treasury.buyback(amount);
	}

	function addSniper(address account) external {
		require(msg.sender == address(antiSnipe), "Snipers can only be added by the anti-snipe contract");

		// ensure that snipers can only be added on the launch block plus the block after
		if (block.timestamp <= (launchedAt + 1)) {
			snipers[account] = true;
			emit SniperAdded(account);
		}
	}

	function punishSniper(address account) external onlyOwner {
		require(snipers[account], "This account is not a sniper");

		uint256 balance = balanceOf(account);
		require(balance > 0, "Insufficient token balance");

		_transfer(account, address(this), balance);

		emit SniperPunished(account);
	}

	function removeSniper(address account) external onlyOwner {
		require(snipers[account], "This account is not a sniper");
		snipers[account] = false;
		emit SniperRemoved(account);
	}

	function setAntiSnipe(address value) external onlyOwner {
		require(value != ZERO_ADDRESS, "Antisnipe cannot be the zero address");
		require(value != address(antiSnipe), "Antisnipe is already set to this value");
		antiSnipe = IAntiSnipe(value);
	}

	function setFees(bool areBuyFees, uint256 reflectFee, uint256 marketingFee, uint256 treasuryFee) external onlyOwner {
		require((reflectFee + marketingFee + treasuryFee) <= 25, "Cannot set fees to above a combined total of 25%");

		FeeSet memory fees = FeeSet({
			reflectFee: reflectFee,
			marketingFee: marketingFee,
			treasuryFee: treasuryFee
		});

		if (areBuyFees) {
			buyFees = fees;
		} else {
			sellFees = fees;
		}
	}

	function setIsFeeProcessingEnabled(bool value) external onlyOwner {
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

	function setMarketingWalletAddress(address payable value) external onlyOwner {
		require(marketingWalletAddress != value, "Marketing wallet address is already set to this value");
		marketingWalletAddress = value;
	}

	function setMaxWalletAmount(uint256 value) external onlyOwner {
		require(value >= (tTotal / 200), "Must set max wallet to at least 0.5% of total supply");
		maxWalletAmount = value;
	}

	function setIsExcludedFromFees(address account, bool value) external onlyOwner {
		require(isExcludedFromFees[account] != value, "Account is already set to this value");
		isExcludedFromFees[account] = value;
	}

	function setIsExcludedFromMaxWallet(address account, bool value) external onlyOwner {
		require(isExcludedFromMaxWallet[account] != value, "Account is already set to this value");
		isExcludedFromMaxWallet[account] = value;
	}

	function excludeFromRewards(address account) external onlyOwner {
		_excludeFromRewards(account);
	}

	function includeInRewards(address account) external onlyOwner {
		_includeInRewards(account);
	}

	receive() external payable {}
}