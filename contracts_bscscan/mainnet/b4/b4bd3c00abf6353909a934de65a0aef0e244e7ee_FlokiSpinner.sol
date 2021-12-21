pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IDEXRouter.sol";
import "./IDEXFactory.sol";
import "./BuybackTreasury.sol";
import "./IUnicryptLiquidityLocker.sol";
import "./IJackpot.sol";

contract FlokiSpinner is ERC20, Ownable {
	using Address for address payable;

	string constant NAME = "FlokiSpinner";
	string constant SYMBOL = "FLOKISPIN";
	uint8 constant DECIMALS = 18;
	uint256 constant INITIAL_SUPPLY = 10 ** 9 * 10 ** DECIMALS;

	uint256 constant MAX_UINT = 2 ** 256 - 1;
	address constant ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	address constant UNICRYPT_LIQUIDITY_LOCKER_ADDRESS = 0xC765bddB93b0D1c1A88282BA0fa6B2d00E3e0c83;
	address constant ZERO_ADDRESS = address(0);
	address constant DEAD_ADDRESS = address(57005);

	IDEXRouter router;
	BuybackTreasury public treasury;
	IJackpot public jackpot;

	mapping(address => bool) automatedMarketMakerPairs;

	mapping(address => bool) public isBlacklisted;
	mapping(address => bool) public isExcludedFromFees;
	mapping(address => bool) public isExcludedFromMaxWallet;

	uint256 public maxWalletAmount = INITIAL_SUPPLY / 100;
	uint256 public maxTxAmountBuy = maxWalletAmount / 2;
	uint256 public maxTxAmountSell = maxWalletAmount / 2;

	address payable marketingWalletAddress;
	address payable operationsWalletAddress;

	bool areFeesBeingProcessed = false;
	bool public isFeeProcessingEnabled = true;
	uint256 public feeProcessingThreshold = INITIAL_SUPPLY / 500;

	bool hasLaunched;
	uint256 launchedAt;

	mapping(address => bool) snipers;

	FeeSet public buyFees = FeeSet({
		jackpotFee: 2,
		buybackFee: 2,
		marketingFee: 4,
		operationsFee: 4
	});

	FeeSet public sellFees = FeeSet({
		jackpotFee: 8,
		buybackFee: 8,
		marketingFee: 2,
		operationsFee: 2
	});

	struct FeeSet {
		uint256 jackpotFee;
		uint256 buybackFee;
		uint256 marketingFee;
		uint256 operationsFee;
	}

	constructor() ERC20(NAME, SYMBOL) {
		address self = address(this);

		router = IDEXRouter(ROUTER_ADDRESS);
		treasury = new BuybackTreasury(address(router), self, owner());

		marketingWalletAddress = payable(owner());
		operationsWalletAddress = payable(owner());

		isExcludedFromFees[owner()] = true;
		isExcludedFromFees[marketingWalletAddress] = true;
		isExcludedFromFees[operationsWalletAddress] = true;
		isExcludedFromFees[address(treasury)] = true;
		isExcludedFromFees[self] = true;
		isExcludedFromFees[DEAD_ADDRESS] = true;

		isExcludedFromMaxWallet[owner()] = true;
		isExcludedFromMaxWallet[marketingWalletAddress] = true;
		isExcludedFromMaxWallet[operationsWalletAddress] = true;
		isExcludedFromMaxWallet[address(treasury)] = true;
		isExcludedFromMaxWallet[self] = true;
		isExcludedFromMaxWallet[DEAD_ADDRESS] = true;

		// _mint is an internal function in ERC20.sol that is only called here,
		// and CANNOT be called ever again
		_mint(owner(), INITIAL_SUPPLY);
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		require(from != ZERO_ADDRESS, "ERC20: transfer from the zero address");
		require(to != ZERO_ADDRESS, "ERC20: transfer to the zero address");
		require(!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted");
		require(!snipers[from], "Sniper no sniping!");

		// gas optimization
		if (amount == 0) {
			super._transfer(from, to, amount);
			return;
		}

		bool isBuying = automatedMarketMakerPairs[from];
		bool shouldTakeFees = hasLaunched && !isExcludedFromFees[from] && !isExcludedFromFees[to];

		if (hasLaunched) {
			// validate max wallet
			if (!automatedMarketMakerPairs[to] && !isExcludedFromMaxWallet[to] && from != address(jackpot)) {
				require((balanceOf(to) + amount) <= maxWalletAmount, "Cannot transfer more than the max wallet amount");
			}

			// validate max buy/sell
			if (shouldTakeFees && from != address(jackpot)) {
				require(amount <= (isBuying ? maxTxAmountBuy : maxTxAmountSell), "Cannot transfer more than the max buy or sell");
			}

			// process collected fees
			uint256 balance = balanceOf(address(this));
			if (isFeeProcessingEnabled && !areFeesBeingProcessed && balance >= feeProcessingThreshold && !isBuying) {
				areFeesBeingProcessed = true;
				_processFees(balance > maxTxAmountSell ? maxTxAmountSell : balance);
				areFeesBeingProcessed = false;
			}

			// process transaction fees
			if (shouldTakeFees) {
				uint256 feePercent = isBuying ? getSumOfBuyFees() : getSumOfSellFees();

				// anti-snipe mechanism
				if (block.number <= (launchedAt + 1) && isBuying && to != address(router)) {
					feePercent = 90;
					snipers[to] = true;
				}

				// transfer fees to contract if necessary
				if (feePercent > 0) {
					uint256 fees = amount * feePercent / 100;
					amount -= fees;
					super._transfer(from, address(this), fees);
				}
			}
		}

		// transfer remaining amount after any modifications
		super._transfer(from, to, amount);
	}

	function _processFees(uint256 amount) private {
		uint256 feeSum = buyFees.jackpotFee + buyFees.buybackFee + buyFees.marketingFee + buyFees.operationsFee;
		if (feeSum == 0) return;

		// swap fee tokens to ETH
		_swapExactTokensForETH(amount);

		// calculate correct amounts to send out
		uint256 amountEth = address(this).balance;
		uint256 amountForJackpot = amountEth * buyFees.jackpotFee / feeSum;
		uint256 amountForBuyback = amountEth * buyFees.buybackFee / feeSum;
		uint256 amountForMarketing = amountEth * buyFees.marketingFee / feeSum;
		uint256 amountForOperations = amountEth - amountForJackpot - amountForBuyback - amountForMarketing;

		// send out fees
		if (amountForJackpot > 0 && address(jackpot) != ZERO_ADDRESS) {
			jackpot.deposit{value : amountForJackpot}();
		}

		if (amountForBuyback > 0) {
			treasury.deposit{value : amountForBuyback}();
		}

		if (amountForMarketing > 0) {
			marketingWalletAddress.transfer(amountForMarketing);
		}

		if (amountForOperations > 0) {
			operationsWalletAddress.transfer(amountForOperations);
		}
	}

	function _swapExactTokensForETH(uint256 amountIn) private {
		address self = address(this);

		address[] memory path = new address[](2);
		path[0] = self;
		path[1] = router.WETH();

		_approve(self, address(router), amountIn);
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, self, block.timestamp);
	}

	function launch(uint256 daysToLock) external payable onlyOwner {
		address self = address(this);

		require(!hasLaunched, "Already launched");
		require(daysToLock >= 30, "Must lock liquidity for a minimum of 30 days");

		uint256 tokensForLiquidity = balanceOf(self);
		require(tokensForLiquidity >= (totalSupply() / 4), "Initial liquidity must be at least 25% of total token supply");

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

		// add liquidity
		_approve(self, address(router), tokensForLiquidity);
		router.addLiquidityETH{value : ethForLiquidity}(self, tokensForLiquidity, 0, 0, self, block.timestamp);

		// lock liquidity
		IERC20 lpToken = IERC20(pairAddress);

		uint256 balance = lpToken.balanceOf(self);
		require(lpToken.approve(address(locker), balance), "Liquidity token approval failed");

		locker.lockLPToken{value : lockFee}(address(lpToken), balance, block.timestamp + (daysToLock * (1 days)), payable(0), true, payable(owner()));

		// set appropriate launch flags
		hasLaunched = true;
		launchedAt = block.number;
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

	function punishSniper(address account) external onlyOwner {
		require(snipers[account], "This account is not a sniper");

		uint256 balance = balanceOf(account);
		require(balance > 0, "Insufficient token balance");

		super._transfer(account, address(this), balance);
	}

	function removeSniper(address account) external onlyOwner {
		require(snipers[account], "This account is not a sniper");
		snipers[account] = false;
	}

	function getSumOfFeeSet(FeeSet memory set) private pure returns (uint256) {
		return set.jackpotFee + set.buybackFee + set.marketingFee + set.operationsFee;
	}

	function getSumOfBuyFees() public view returns (uint256) {
		return getSumOfFeeSet(buyFees);
	}

	function getSumOfSellFees() public view returns (uint256) {
		return getSumOfFeeSet(sellFees);
	}

	function setJackpotAddress(address value) public onlyOwner {
		require(address(jackpot) != value, "The jackpot address is already set to this value");
		jackpot = IJackpot(value);
	}

	function setFees(bool areBuyFees, uint256 jackpotFee, uint256 buybackFee, uint256 marketingFee, uint256 operationsFee) external onlyOwner {
		require((jackpotFee + buybackFee + marketingFee + operationsFee) <= 25, "Cannot set fees to above a combined total of 25%");

		FeeSet memory fees = FeeSet({
			jackpotFee: jackpotFee,
			buybackFee: buybackFee,
			marketingFee: marketingFee,
			operationsFee: operationsFee
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
		require(maxBuy >= (totalSupply() / 400), "Must set max buy to at least 0.25% of total supply");
		require(maxSell >= (totalSupply() / 400), "Must set max sell to at least 0.25% of total supply");

		maxTxAmountBuy = maxBuy;
		maxTxAmountSell = maxSell;
	}

	function setMarketingWalletAddress(address payable value) external onlyOwner {
		require(marketingWalletAddress != value, "Marketing wallet address is already set to this value");
		marketingWalletAddress = value;
	}

	function setOperationsWalletAddress(address payable value) external onlyOwner {
		require(operationsWalletAddress != value, "Operations wallet address is already set to this value");
		operationsWalletAddress = value;
	}

	function setMaxWalletAmount(uint256 value) external onlyOwner {
		require(value >= (totalSupply() / 200), "Must set max wallet to at least 0.5% of total supply");
		maxWalletAmount = value;
	}

	function setIsBlacklisted(address account, bool value) external onlyOwner {
		require(isBlacklisted[account] != value, "Account is already set to this value");
		isBlacklisted[account] = value;
	}

	function setIsExcludedFromFees(address account, bool value) external onlyOwner {
		require(isExcludedFromFees[account] != value, "Account is already set to this value");
		isExcludedFromFees[account] = value;
	}

	function setIsExcludedFromMaxWallet(address account, bool value) external onlyOwner {
		require(isExcludedFromMaxWallet[account] != value, "Account is already set to this value");
		isExcludedFromMaxWallet[account] = value;
	}

	receive() external payable {}
}