/**

The first MULTI-TOKEN reflection protocol! Hold $BDC tokens to receive both DOGE and CAKE, automatically. 
TG: t.me/BabyAlts

*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.3;

import './IUniswapV2Router02.sol';
import './IUniswapV2Factory.sol';
import './UniswapV2Library.sol';
import './IUniswapV2Pair.sol';
import './SafeMath.sol';
import './IERC20.sol';
import './ERC20.sol';

import './SafeMathUint.sol';
import './SafeMathInt.sol';

contract AutoPayingTokenBase is ERC20 {
	// -=-= ALL EVENTS
	event RecoveryFundWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event MarketingWalletUpdated(address indexed oldWallet, address indexed newWallet);
	event RewardTokenUpdated(address indexed oldToken, address indexed newToken);

    event MarketingFeeUpdated(uint indexed oldValue, uint indexed newValue);

    event MinTokensForRewardsUpdated(uint indexed oldValue, uint indexed newValue);
	event MinTokensBeforeSwapUpdated(uint indexed oldValue, uint indexed newValue);

    event WalletWhitelistUpdated(address indexed wallet, bool indexed newValue);
	
	event MaxTxAmountUpdated(uint indexed oldValue, uint indexed newValue);

	// event PresaleSpendingEnabled(bool indexed oldValue, bool indexed newValue);
    
	event AntiWhaleEnabledUpdated(bool indexed oldValue, bool indexed newValue);
	event BuyBacksEnabledUpdated(bool indexed oldValue, bool indexed newValue);
	
	// event TradingEnabledUpdated(bool indexed oldValue, bool indexed newValue);
    event SwapEnabledUpdated(bool indexed oldValue, bool indexed newValue);
    
	event ClaimDelayUpdated(uint indexed oldValue, uint indexed newValue);
	event BuyBackFeeUpdated(uint indexed oldValue, uint indexed newValue);
    
    event OwnershipTransferred(address indexed from, address indexed to);
	
	event SellFeeUpdated(uint indexed oldValue, uint indexed newValue);
    event BuyFeeUpdated(uint indexed oldValue, uint indexed newValue);
    
	event MinGasUpdated(uint indexed oldValue, uint indexed newValue);
    event MaxGasUpdated(uint indexed oldValue, uint indexed newValue);

	event ExcludedFromRewards(address indexed wallet);
    event ExcludedFromFees(address indexed wallet);
	// -=-= END ALL EVENTS

	// mapping (address => bool) public receivedTokensFromPair; // Useful to tell if someone got tokens from presale/private sale vs pancakeswap
	mapping (address => bool) public excludedFromRewards;
	mapping (address => bool) public excludedFromFees;
    mapping (address => uint) public nextClaimTime;
	mapping (address => bool) public whitelisted;
	mapping (address => uint) public index; // Useful for predicting how long until next payout
	mapping (address => bool) public bot;
    address[] public addresses;
	
	address internal recoveryFundWallet;
	address internal marketingWallet;

	bool internal buyingBack = false;
	bool internal swapping = false;
	uint public totalHolders = 0;
    uint public checkIndex = 0;

    // Configurable values
	uint internal maxTxAmount = totalSupply.mul(5) / 100; //5 percent of the supply (Anti Whale Measures)
	uint internal minTokensBeforeSwap = 2000000000; // 2 billion (no decimal adjustment)
    uint internal minTokensForRewards = 2000000; // in tokens (no decimal adjustment)
    uint internal claimDelay = 1; // in minutes
    uint internal buyFee = 13; // percent fee for buying, goes towards rewards
    uint internal sellFee = 14; // percent fee for selling, goes towards rewards
	uint internal minGas = 0; //200000; // Estimate for how much gas needs to remain after auto-paying
	uint internal maxGas = 800000; // If we don't cap gas, metamask will keep requesting more and more, leading to $30+ gas fees (no good!)

	// FOR THESE VALUES, THEY ARE A PERCENT *OF A PERCENT* - 20% OF 15% aka (.2 * .15) = 3% of every transaction
	uint internal recoveryFundTax = 6; // Once all fees are accumulated and swapped, what percent goes towards the recovery fund (0.16 * 0.05 approx equals 0.1)
	uint internal marketingTax = 20; // Once all fees are accumulated and swapped, what percent goes towards marketing
	uint internal buyBackFee = 20; // Once all fees are accumulated and swapped, what percent goes towards buybacks
	
	IUniswapV2Pair internal tokenPair;

	address[] public prevTokens;
	address public token; // This is the token that people will receive rewards in, defined by the constructor and changable by changeRewardToken (owner only)
	
	// bool internal presaleSpendingEnabled = false;
	bool internal antiWhaleEnabled = false;
	bool internal buyBacksEnabled = true;
	bool internal tradingEnabled = false;
	bool internal swapEnabled = true;
    // End configurable values

	// Adjusted values (don't edit)
    uint internal _minTokensBeforeSwap = minTokensBeforeSwap * 10 ** decimals;
    uint internal _minTokensForRewards = minTokensForRewards * 10 ** decimals;
    uint internal _claimDelay = claimDelay * 60;
	uint internal sellGasExtra = 50000;  // Sell transactions need more gas left
    // End adjusted values
    
    using SafeMath for uint;

    IUniswapV2Router02 router;
	IUniswapV2Factory factory;
    IUniswapV2Pair pair;

    uint8 public constant decimals = 18;
    string public symbol;
    string public name;

	address internal owner;

	uint internal correctionFactor = 10; // correct for volatility

	address internal deadAddress = 0x000000000000000000000000000000000000dEaD;

	function getTime() public returns (uint) {
		return block.timestamp;
	}

	modifier ownerOnly() {
		require(msg.sender == owner, 'Must be owner to run this function');
		_;
	}

	modifier notIdenticalUint(uint oldValue, uint newValue) {
		require(oldValue != newValue, 'Current value is identical to supplied value');
		_;
	}

	modifier notIdenticalBool(bool oldValue, bool newValue) {
		require(oldValue != newValue, 'Current value is identical to supplied value');
		_;
	}

	modifier notIdenticalAddr(address oldValue, address newValue) {
		require(oldValue != newValue, 'Current value is identical to supplied value');
		_;
	}

	function transferOwnership(address newOwner) public ownerOnly {
		address oldOwner = owner;
		owner = newOwner;

        excludedFromRewards[oldOwner] = false;
		excludedFromRewards[newOwner] = true;
        excludedFromFees[oldOwner] = false;
        excludedFromFees[newOwner] = true;
		whitelisted[oldOwner] = false;
		whitelisted[newOwner] = true;

		emit OwnershipTransferred(oldOwner, newOwner);
	}

	function changeMinTokensForRewards(uint newMinTokensForRewards) public ownerOnly notIdenticalUint(_minTokensForRewards, newMinTokensForRewards) {
		uint oldValue = _minTokensForRewards;
    	_minTokensForRewards = newMinTokensForRewards;

		emit MinTokensForRewardsUpdated(oldValue, _minTokensForRewards);
	}

	function changeMinTokensBeforeSwap(uint newMinTokensBeforeSwap) public ownerOnly notIdenticalUint(_minTokensBeforeSwap, newMinTokensBeforeSwap) {
		uint oldValue = _minTokensBeforeSwap;
    	_minTokensBeforeSwap = newMinTokensBeforeSwap;

		emit MinTokensBeforeSwapUpdated(oldValue, _minTokensBeforeSwap);
	}
	
	function changeMaxTxAmount(uint newMaxTxAmount) public ownerOnly notIdenticalUint(maxTxAmount, newMaxTxAmount) {
		uint oldValue = maxTxAmount;
    	maxTxAmount = newMaxTxAmount;

		emit MaxTxAmountUpdated(oldValue, maxTxAmount);
	}

	function changeClaimDelay(uint newClaimDelay) public ownerOnly notIdenticalUint(_claimDelay, newClaimDelay) {
		uint oldValue = _claimDelay;
		_claimDelay = newClaimDelay * 60;

		emit ClaimDelayUpdated(oldValue, _claimDelay);
	}

	function changeSwapEnabled(bool newSwapEnabled) public ownerOnly notIdenticalBool(swapEnabled, newSwapEnabled) {
		bool oldValue = swapEnabled;
		swapEnabled = newSwapEnabled;

		emit SwapEnabledUpdated(oldValue, swapEnabled);
	}

	function changeBuyBacksEnabled(bool newBuyBacksEnabled) public ownerOnly notIdenticalBool(buyBacksEnabled, newBuyBacksEnabled) {
		bool oldValue = buyBacksEnabled;
		buyBacksEnabled = newBuyBacksEnabled;

		emit BuyBacksEnabledUpdated(oldValue, buyBacksEnabled);
	}

	function changeAntiWhaleEnabled(bool newAntiWhaleEnabled) public ownerOnly notIdenticalBool(antiWhaleEnabled, newAntiWhaleEnabled) {
		bool oldValue = newAntiWhaleEnabled;
		antiWhaleEnabled = newAntiWhaleEnabled;

		emit AntiWhaleEnabledUpdated(oldValue, antiWhaleEnabled);
	}

	function changeCorrectionFactor(uint newCorrectionFactor) public ownerOnly notIdenticalUint(correctionFactor, newCorrectionFactor) {
		uint oldValue = claimDelay;
		correctionFactor = newCorrectionFactor;

		emit ClaimDelayUpdated(oldValue, claimDelay);
	}

	function changeSellFee(uint newSellFee) public ownerOnly notIdenticalUint(sellFee, newSellFee) {
		uint oldValue = sellFee;
		sellFee = newSellFee;

		emit SellFeeUpdated(oldValue, sellFee);
	}

	function changeBuyFee(uint newBuyFee) public ownerOnly notIdenticalUint(buyFee, newBuyFee) {
		require(buyFee <= 50, 'Total fee amount is too high!');

		uint oldValue = buyFee;
		buyFee = newBuyFee;

		emit BuyFeeUpdated(oldValue, buyFee);
	}

	function changeMinGas(uint newMinGas) public ownerOnly notIdenticalUint(minGas, newMinGas) {
		uint oldValue = minGas;
		minGas = newMinGas;

		emit MinGasUpdated(oldValue, minGas);
	}

	function changeMaxGas(uint newMaxGas) public ownerOnly notIdenticalUint(maxGas, newMaxGas) {
		uint oldValue = maxGas;
		maxGas = newMaxGas;

		emit MaxGasUpdated(oldValue, maxGas);
	}

	function changeMarketingTax(uint newMarketingTax) public ownerOnly notIdenticalUint(marketingTax, newMarketingTax) {
		require(newMarketingTax <= 50, 'Supplied value is too high');

		uint oldValue = marketingTax;
		marketingTax = newMarketingTax;

		emit MarketingFeeUpdated(oldValue, newMarketingTax);
	}

	function changeBuyBackFee(uint newBuyBackFee) public ownerOnly notIdenticalUint(buyBackFee, newBuyBackFee) {
		uint oldValue = buyBackFee;
		buyBackFee = newBuyBackFee;

		emit BuyBackFeeUpdated(oldValue, buyBackFee);
	}

	function changeMarketingWallet(address newMarketingWallet) public ownerOnly notIdenticalAddr(marketingWallet, newMarketingWallet) {
		address oldValue = marketingWallet;
		marketingWallet = newMarketingWallet;

		excludedFromRewards[marketingWallet] = true;
        excludedFromFees[marketingWallet] = true;
		excludedFromRewards[oldValue] = false;
        excludedFromFees[oldValue] = false;

		emit MarketingWalletUpdated(oldValue, marketingWallet);
	}

	function changeRecoveryFundWallet(address newRecoveryFundWallet) public ownerOnly notIdenticalAddr(recoveryFundWallet, newRecoveryFundWallet) {
		address oldValue = recoveryFundWallet;
		recoveryFundWallet = newRecoveryFundWallet;

		excludedFromRewards[recoveryFundWallet] = true;
        excludedFromFees[recoveryFundWallet] = true;
		excludedFromRewards[oldValue] = false;
        excludedFromFees[oldValue] = false;

		emit RecoveryFundWalletUpdated(oldValue, recoveryFundWallet);
	}

	function setTradingEnabled(bool newTradingEnabled) public ownerOnly notIdenticalBool(tradingEnabled, newTradingEnabled) {
		bool oldValue = tradingEnabled;
        tradingEnabled = newTradingEnabled;

		// emit TradingEnabledUpdated(oldValue, tradingEnabled);
	}

	function excludeFromRewards(address wallet, bool isExcluded) public ownerOnly {
        excludedFromRewards[wallet] = isExcluded;

		emit ExcludedFromRewards(wallet);
	}

	function excludeFromFees(address wallet, bool isExcluded) public ownerOnly {
        excludedFromFees[wallet] = isExcluded;

		emit ExcludedFromFees(wallet);
	}
	
	function whitelistWallet(address wallet, bool isWhitelisted) public ownerOnly {
        whitelisted[wallet] = isWhitelisted;

		emit WalletWhitelistUpdated(wallet, isWhitelisted);
	}

	function flagBot(address wallet, bool isBot) public ownerOnly {
        bot[wallet] = isBot;
	}

    function _transfer(address from, address to, uint value) virtual internal override {
		uint balanceOfFrom = balanceOf[from];

        require(value <= balanceOfFrom, 'Insufficient token balance');

        if (from != msg.sender && allowance[from][msg.sender] != uint(-1)) {
            require(value <= allowance[from][msg.sender]);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }

		if (excludedFromFees[from] || excludedFromFees[to]) {
			balanceOf[from] = balanceOfFrom.sub(value);
			balanceOf[to] = balanceOf[to].add(value);
		} else {
			uint feeAmount = value.mul(buyFee) / 100;

			// Anti-Whaling
			if (!swapping && to == address(pair) && antiWhaleEnabled) {
				require(value < maxTxAmount, 'Anti-Whale: Can not sell more than maxTxAmount');
				if (buyBacksEnabled) processBuyBack();
				feeAmount = value.mul(sellFee) / 100;
			}
			
			require(feeAmount > 0, 'Fees are zero');

			if (from != address(pair) && to != address(pair)) feeAmount = 0; // Don't tax on wallet to wallet transfers, only buy/sell
			uint tokensToAdd = value.sub(feeAmount);
			require(tokensToAdd > 0, 'After fees, received amount is zero');

			// Update balances
			balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
			balanceOf[from] = balanceOfFrom.sub(value);
			balanceOf[to] = balanceOf[to].add(tokensToAdd);
		}

        if (/*from == address(pair) && */nextClaimTime[to] == 0 && !excludedFromRewards[to]) {
			nextClaimTime[to] = block.timestamp + _claimDelay;
			index[to] = addresses.length;
			addresses.push(to);
			
			totalHolders = addresses.length;
        }

        emit Transfer(from, to, value);
    }

	modifier buyBackLock() {
		buyingBack = true;
		_;
		buyingBack = false;
	}

	function processBuyBack() internal buyBackLock {
		uint before = balanceOf[address(pair)];

		address[] memory path = new address[](2);
		path[0] = router.WETH();
		path[1] = address(this);

		router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: address(this).balance / 100 }(0, path, deadAddress, block.timestamp); // Buy to burn address
	}
}

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract BabyAlts is AutoPayingTokenBase {
	using SafeMathUint for uint;
	using SafeMathInt for int;
	using SafeMath for uint;

	// With `magnitude`, we can properly distribute dividends even if the amount of received tokens is small.
	uint constant internal magnitude = 2 ** 128;

	mapping(address => int) internal magnifiedDividendCorrections;
	mapping(address => uint) public withdrawnDividendOf;
	uint internal magnifiedDividendPerShare = 0;

	uint public totalPayouts = 0;
	uint public totalPaid = 0;

	uint public totalSupplyInverse;

	address internal usdtAddress;

	// FOR DASHBOARD SINGLE-CALL DATA AGGREGATE
	function aggregate(address addr) public view returns (string memory symbol, uint[18] memory data) {
		IUniswapV2Pair bnbPair = IUniswapV2Pair(factory.getPair(router.WETH(), usdtAddress));
		(uint usdtReserve, uint bnbReserve,) = bnbPair.getReserves();

		uint tokens = IERC20(token).balanceOf(address(this));

		uint earnedBNB = withdrawnDividendOf[addr];
		uint owedBNB = withdrawableDividendOf(addr);

        symbol = IERC20(token).symbol();

		data = [
			// BEGIN STANDALONE DATA
			IERC20(token).decimals(), // reward token decimals
			getAmountOut(totalPaid, bnbReserve, usdtReserve), // total distributed in USD
			bnbToTokens(totalPaid), // total distributed in tokens
			tokens,
			getAmountOut(tokensToBNB(tokens), bnbReserve, usdtReserve), // contract balance in USD
			totalPayouts,
			totalHolders,
			checkIndex,
			// BEGIN USER SPECIFIC DATA:
			address(addr).balance, // user BNB balance
			balanceOf[addr], // user token balance
			earnedBNB, // earned bnb
			owedBNB, // owed bnb
			bnbToTokens(earnedBNB), // earned tokens (estimated)
			bnbToTokens(owedBNB), // owed tokens (estimated)
			getAmountOut(earnedBNB, bnbReserve, usdtReserve),
			getAmountOut(owedBNB, bnbReserve, usdtReserve),
			nextClaimTime[addr],
			index[addr]
		];
	}

	function getPrevTokens() public view returns (string[] memory names, string[] memory symbols) {
		for (uint i = 0; i < prevTokens.length; i++) {
			IERC20 rewardToken = IERC20(prevTokens[i]);
			symbols[i] = rewardToken.symbol();
			names[i] = rewardToken.name();
		}
	}

	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal view returns(uint) {
		return amountIn.mul(reserveOut) / reserveIn;
	}

	constructor(string memory _name, string memory _symbol, uint _totalSupply, address rewardToken, address routerAddress, address usdtAddr) {
		/**
			Owner has total supply to give out whitelisted private sale tokens, and to pay dxsale the presale tokens
			Owner is whitelisted from trade lock, fees, and rewards for the same purpose
		 */

		recoveryFundWallet = 0xF0A57ABBd30B34b50067686453C4dCB2aAF4CA69;
		marketingWallet = 0x636B8b82003e5730d1B4b2f851e9DC4869CBE7b5;

		router = IUniswapV2Router02(routerAddress);
		usdtAddress = usdtAddr;
		owner = msg.sender;

		totalSupplyInverse = _totalSupply.mul(2); // Equal to totalSupply + totalTokensHeld
		totalSupply = _totalSupply;
		symbol = _symbol;
		name = _name;

		allowance[address(this)][address(router)] = type(uint).max;
		balanceOf[owner] = totalSupply;

		factory = IUniswapV2Factory(router.factory());
		
		address pairAddr = factory.createPair(address(this), router.WETH());
		pair = IUniswapV2Pair(pairAddr);

        excludedFromRewards[marketingWallet] = true;
        excludedFromRewards[address(router)] = true;
        excludedFromRewards[address(pair)] = true;
        excludedFromRewards[address(this)] = true;
		excludedFromRewards[deadAddress] = true;
        excludedFromRewards[owner] = true;

        excludedFromFees[marketingWallet] = true;
		excludedFromFees[address(this)] = true;
        excludedFromFees[owner] = true;
		whitelisted[owner] = true;

		changeRewardToken(rewardToken);
	}

	function isContract(address _addr) internal returns (bool isContract) {
		uint32 size;
		assembly {
			size := extcodesize(_addr)
		}
		return (size > 0);
	}

	function changeRewardToken(address newToken) public ownerOnly notIdenticalAddr(token, newToken) {
		require(isContract(newToken), 'New token must be a contract!');

		address oldToken = token;
		token = newToken;

		tokenPair = IUniswapV2Pair(factory.getPair(router.WETH(), token));

		if (oldToken != address(0)) {
			ERC20(oldToken).approve(address(router), type(uint).max);
			_swap(oldToken, ERC20(oldToken).balanceOf(address(this)));

			prevTokens.push(oldToken);
		}

		emit RewardTokenUpdated(oldToken, token);
	}

	// Process auto claims every transaction, uses as much supplied gas as possible
	function processRewards(uint gasMin, uint gasMax) public {
		if (addresses.length == 0) return;

		// Fetching/editing state variable only once saves gas, opposed to doing checkIndex++ every iteration
		uint initialGas = gasleft();
		bool iterated = false;
		uint i = checkIndex;

		for (; gasleft() > gasMin && initialGas.sub(gasleft()) < gasMax; i++) {
			if (i >= addresses.length) i = 0;

			if (iterated && i == checkIndex) break; // Looped back to initial check index, further looping would waste gas for no benefit
			iterated = true;

            address addr = addresses[i];

            if (
				balanceOf[addr] < _minTokensForRewards || // Not enough tokens
				excludedFromRewards[addr] ||
				nextClaimTime[addr] >= block.timestamp // Not able to claim yet
			) continue;

			uint withdrawnDividend = _withdrawUserDividend(payable(addr));

			if (withdrawnDividend > 0) {
				nextClaimTime[addr] = block.timestamp + _claimDelay;
			}
        }

		checkIndex = i;
    }

	// Make sure we can receive eth to the contract
	fallback() external payable {}
	receive() external payable {
		_distribute(msg.value);
	}

	function distributeDividends(uint received) internal {
		require(totalSupplyInverse > 0);

		uint balance = received.mul(correctionFactor) / 100;

		if (balance > 0) {
			magnifiedDividendPerShare = magnifiedDividendPerShare.add(balance.mul(magnitude) / totalSupplyInverse);
		}
	}

	bool guarding = false;
	modifier reentrancyGuard() {
		require(!guarding, 'Re-entrancy guard');
		guarding = true;
		_;
		guarding = false;
	}

	function withdrawDividendsOfAddress(address payable addr) public {
		_withdrawUserDividend(addr);
	}

	function withdrawDividends() public {
		_withdrawUserDividend(msg.sender);
	}

	// subtracting from balance before calling to user protects against single function reentrancy, aka performing a double-withdraw
	// however, cross-function reentrancy attacks require reentrancyGuard 
	function _withdrawUserDividend(address payable user) internal reentrancyGuard returns (uint) {
		uint bnbAmount = withdrawableDividendOf(user);
		uint tokenAmount = bnbToTokens(bnbAmount);

		uint tokenBalance = ERC20(token).balanceOf(address(this));
		uint i = 0;

		while (tokenBalance > 0 && tokenAmount > tokenBalance) {
			if (i++ == 5) break;

			tokenAmount = tokenAmount.mul(50) / 100; // Only payout a percentage if the contract doesn't have enough to pay in full
		}

		if (tokenAmount > 0 && tokenBalance > tokenAmount) {
			withdrawnDividendOf[user] = withdrawnDividendOf[user].add(bnbAmount);

       		token.call(abi.encodeWithSelector(0x095ea7b3, address(this), type(uint256).max)); // Approve
       		(bool success, bytes memory error) = token.call(abi.encodeWithSelector(0xa9059cbb, user, tokenAmount)); // Transfer
			if (!success) {
				withdrawnDividendOf[user] = withdrawnDividendOf[user].sub(bnbAmount);
				return 0;
			} else {
				totalPaid += bnbAmount;
				totalPayouts++;
			}

			return tokenAmount;
		}

		return 0;
	}

	function bnbToTokens(uint bnbAmount) public view returns(uint) {
		if (bnbAmount == 0) return 0;

		address input = router.WETH();
		address output = token;

		// // The code below is copied from UniswapV2Router02 to calculate output amount
		(address token0,) = UniswapV2Library.sortTokens(input, output);
 		(uint reserve0, uint reserve1,) = tokenPair.getReserves();
		(uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
		// uint amountInput = ERC20(input).balanceOf(address(tokenPair)).sub(reserveInput);
		// uint amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
		
		return router.getAmountOut(bnbAmount, reserveInput, reserveOutput);
	}

	function tokensToBNB(uint tokenAmount) public view returns(uint) {
		if (tokenAmount == 0) return 0;

		address input = token;
		address output = router.WETH();

		// // The code below is copied from UniswapV2Router02 to calculate output amount
		(address token0,) = UniswapV2Library.sortTokens(input, output);
 		(uint reserve0, uint reserve1,) = tokenPair.getReserves();
		(uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
		// uint amountInput = ERC20(input).balanceOf(address(tokenPair)).sub(reserveInput);
		// uint amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
		
		return router.getAmountOut(tokenAmount, reserveInput, reserveOutput);
	}

	// Due to the failure of similar tokens such as MiniDogeCASH, these functions are here to ensure that things can get smoothed out if anything goes wrong.
	function forceSwap(uint tokensToSwap) public ownerOnly {
		uint contractBalance = balanceOf[address(this)];

		if (contractBalance < tokensToSwap) tokensToSwap = balanceOf[address(this)];
		_swap(address(this), tokensToSwap);
	}

	function updateStateVariables(bool _swapping, bool _buyingBack) public ownerOnly { // Just in case things break, we can fix it!
		buyingBack = _buyingBack;
		swapping = _swapping;
	}

	function swapToken() public ownerOnly {
		ERC20(token).approve(address(router), type(uint256).max);
		_swap(token, ERC20(token).balanceOf(address(this)));
	}

	bool internal addingLiquidity = false;
	modifier liquidityLock {
		addingLiquidity = true;
		_;
		addingLiquidity = false;
	}

	function addLiquidity(uint tokensToAdd) public payable ownerOnly liquidityLock {
		buyingBack = true;
		swapping = true;

		uint beforeBalance = balanceOf[address(this)];
		balanceOf[address(this)] = tokensToAdd;

		router.addLiquidityETH{ value: msg.value }(
			address(this),
			tokensToAdd,
			0,
			0,
			msg.sender,
			block.timestamp
		);

		balanceOf[address(this)] = beforeBalance;
		buyingBack = false;
		swapping = false;
	}

	function qualifies(address addr) public view returns(bool) {
		return balanceOf[addr] >= _minTokensForRewards;
	}

	function manualSend(uint amount) public ownerOnly {
		if (amount > address(this).balance) amount = address(this).balance;
		payable(recoveryFundWallet).transfer(amount);
	}

	function manualSendToken() public ownerOnly {
		uint balance = ERC20(token).balanceOf(address(this));
		token.call(abi.encodeWithSelector(0xa9059cbb, recoveryFundWallet, balance));
	}

	function withdrawableDividendOf(address _owner) public view returns(uint) {
		if (excludedFromRewards[_owner]) return 0;

		return accumulativeDividendOf(_owner).sub(withdrawnDividendOf[_owner]);
	}

	// dividendPerShare * tokenBalance + corrections 
	function accumulativeDividendOf(address _owner) public view returns(uint) {
		if (excludedFromRewards[_owner]) return 0;

		uint ownerTokenBalance = balanceOf[_owner];
		if (ownerTokenBalance < _minTokensForRewards) ownerTokenBalance = 0;

		return magnifiedDividendPerShare.mul(ownerTokenBalance).toInt256Safe()
			.add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
	}

	// Handle auto-paying reward part of transferring
	function _transfer(address from, address to, uint value) internal override {
		require(to != address(0) && from != address(0), 'Cannot interact with the zero address.');
		require(value > 0, 'Insufficient transfer amount');
		require(!bot[from], 'Flagged');

		// bool canBypassPresaleLock = receivedTokensFromPair[from] || from == address(pair) || from == address(this);

		// require(addingLiquidity || presaleSpendingEnabled || canBypassPresaleLock, 'Presale/private sale spending is disabled for now.');
		require(addingLiquidity || tradingEnabled || whitelisted[from], 'Trading is locked!');

		// Must swap to eth before processing users sell to prevent swap error
		if (swapEnabled && !swapping && to == address(pair) && balanceOf[address(this)] >= _minTokensBeforeSwap) {
			_swap(address(this), _minTokensBeforeSwap);
		}

		uint oldBalanceOfFrom = balanceOf[from];
		uint oldBalanceOfTo = balanceOf[to];

		super._transfer(from, to, value);
		
		updateCorrections(from, balanceOf[from], oldBalanceOfFrom);
		updateCorrections(to, balanceOf[to], oldBalanceOfTo);
		// Check for any people who have rewards ready, and process their rewards
        bool isBuyOrSell = from == address(pair) || to == address(pair);
		
		if (isBuyOrSell && !swapping && !buyingBack) {
			uint gasExtra = (to == address(pair)) ? sellGasExtra : 0;
			uint gasMin = minGas + gasExtra;

			try this.processRewards(gasMin, maxGas) { } catch(bytes memory error) {
				checkIndex++;
			}
		}

		// if (from == address(pair)) receivedTokensFromPair[to] = true;
	}

	function updateCorrections(address account, uint newBalance, uint oldBalance) internal {
		if (excludedFromRewards[account]) {
			return;
		}

		if (newBalance < _minTokensForRewards) newBalance = 0;
		
		setCorrections(account, newBalance, oldBalance);
		_withdrawUserDividend(payable(account));
	}

	function setCorrections( address account, uint newBalance, uint oldBalance) internal {
		if (newBalance > oldBalance) {
			uint mintAmount = newBalance.sub(oldBalance);
			totalSupplyInverse = totalSupplyInverse.add(mintAmount);

			magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
				.sub((magnifiedDividendPerShare.mul(mintAmount)).toInt256Safe());
		} else if (newBalance < oldBalance) {
			uint burnAmount = oldBalance.sub(newBalance);
			totalSupplyInverse = totalSupplyInverse.sub(burnAmount);

			magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
				.add((magnifiedDividendPerShare.mul(burnAmount)).toInt256Safe());
		}
	}

	function _mint(address account, uint value) internal override {
		uint oldBalance = balanceOf[account];
		super._mint(account, value);

		setCorrections(account, balanceOf[account], oldBalance);
	}

	function _burn(address account, uint value) internal override {
		uint oldBalance = balanceOf[account];
		super._burn(account, value);

		setCorrections(account, balanceOf[account], oldBalance);
	}

	modifier swapLock() {
		swapping = true;
		_;
		swapping = false;
	}

	function _swap(address from, uint tokensToSwap) internal swapLock {
		address[] memory path = new address[](2);
		path[0] = from;
		path[1] = router.WETH();

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
	}

	function _distribute(uint deltaBalance) internal {
		uint marketingFee = deltaBalance.mul(marketingTax) / 100;
		payable(marketingWallet).transfer(marketingFee);

		uint recoveryFundFee = deltaBalance.mul(recoveryFundTax) / 100;
		payable(recoveryFundWallet).transfer(recoveryFundFee);

		uint totalFees = marketingTax.add(recoveryFundTax).add(buyBackFee);
		uint percentLeft = uint(100).sub(totalFees);

		uint remaining = deltaBalance.mul(percentLeft) / 100;

		address[] memory tokenPath = new address[](2);
		tokenPath[0] = router.WETH();
		tokenPath[1] = token;

		router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: remaining }(
			0,
			tokenPath,
			address(this),
			block.timestamp
		);

		distributeDividends(remaining);
	}
}