/**

The first MULTI-TOKEN reflection protocol! Hold $BDC tokens to receive both DOGE and CAKE, automatically. 
TG: t.me/BabyDogeCake

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import './IUniswapV2Router02.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './SafeMath.sol';
import './ERC20.sol';

import './SafeMathUint.sol';
import './SafeMathInt.sol';

contract AutoPayingTokenBase is ERC20 {
	// -=-= ALL EVENTS
	event RecoveryFundWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event MarketingWalletUpdated(address indexed oldWallet, address indexed newWallet);
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
    uint internal claimDelay = 60; // in minutes
    uint internal buyFee = 17; // percent fee for buying, goes towards rewards
    uint internal sellFee = 20; // percent fee for selling, goes towards rewards
	uint internal minGas = 200000; // Estimate for how much gas needs to remain after auto-paying
	uint internal maxGas = 800000; // If we don't cap gas, metamask will keep requesting more and more, leading to $30+ gas fees (no good!)

	// FOR THESE VALUES, THEY ARE A PERCENT *OF A PERCENT* - 20% OF 15% aka (.2 * .15) = 3% of every transaction
	uint internal recoveryFundTax = 6; // Once all fees are accumulated and swapped, what percent goes towards the recovery fund (0.16 * 0.05 approx equals 0.1)
	uint internal marketingTax = 20; // Once all fees are accumulated and swapped, what percent goes towards marketing
	uint internal buyBackFee = 20; // Once all fees are accumulated and swapped, what percent goes towards buybacks
	
	address[] internal tokens; // These are the tokens that people will receive rewards in, defined by the constructor

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

	// function changePresaleSpendingEnabled(bool newPresaleSpendingEnabled) public ownerOnly notIdenticalBool(presaleSpendingEnabled, newPresaleSpendingEnabled) {
	// 	bool oldValue = presaleSpendingEnabled;
	// 	presaleSpendingEnabled = newPresaleSpendingEnabled;

	// 	emit PresaleSpendingEnabled(oldValue, presaleSpendingEnabled);
	// }

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

    function _transfer(address from, address to, uint value) virtual internal override {
		require(value > 0, 'Insufficient transfer amount');
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
contract BabyDogeCake is AutoPayingTokenBase {
	using SafeMath for uint;
	using SafeMathUint for uint;
	using SafeMathInt for int;

	// With `magnitude`, we can properly distribute dividends even if the amount of received tokens is small.
	uint constant internal magnitude = 2 ** 96;

	mapping (address => mapping(address => int)) internal magnifiedDividendCorrections;
	mapping (address => mapping(address => uint)) public withdrawnDividendOf;
	mapping (address => uint) internal magnifiedDividendPerShare;

	mapping (address => uint) public totalPaid;
	uint public totalPayouts = 0;

	uint public totalSupplyInverse;

	constructor(string memory _name, string memory _symbol, uint _totalSupply, address[] memory rewardTokens, address routerAddress) {
		/**
			Owner has total supply to give out whitelisted private sale tokens, and to pay dxsale the presale tokens
			Owner is whitelisted from trade lock, fees, and rewards for the same purpose
		 */

		router = IUniswapV2Router02(routerAddress);
		owner = msg.sender;

		totalSupplyInverse = _totalSupply.mul(2); // Equal to totalSupply + totalTokensHeld
		totalSupply = _totalSupply;
		symbol = _symbol;
		name = _name;

		allowance[address(this)][address(router)] = type(uint).max;
		balanceOf[owner] = totalSupply;

		IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
		address pairAddr = factory.createPair(address(this), router.WETH());
		pair = IUniswapV2Pair(pairAddr);

        excludedFromRewards[marketingWallet] = true;
        excludedFromRewards[address(router)] = true;
        excludedFromRewards[address(pair)] = true;
        excludedFromRewards[address(this)] = true;
		excludedFromRewards[deadAddress] = true;
        excludedFromRewards[owner] = true;
        
		// for (uint i = 0; i < rewardTokens.length; i++) {
		// 	excludedFromRewards[rewardTokens[i]] = true;
		// }

        excludedFromFees[marketingWallet] = true;
		excludedFromFees[address(this)] = true;
        excludedFromFees[owner] = true;
		whitelisted[owner] = true;

		recoveryFundWallet = 0x5F7958ACcA7a1b8E9761C4655a73Ce742C2adb99;
		marketingWallet = 0x7377bf2cd299B790423EF83BCfF737A76530F6e9;

		tokens = rewardTokens;
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

			uint withdrawnDividend;

			for (uint a = 0; a < tokens.length; a++) {
				withdrawnDividend = _withdrawUserDividend(tokens[a], payable(addr));
				totalPaid[tokens[a]] += withdrawnDividend; // Better to overflow than to break the auto-paying system
			}

			if (withdrawnDividend > 0) {
				nextClaimTime[addr] = block.timestamp + _claimDelay;
				totalPayouts++;
			}
        }

		checkIndex = i;
    }

	// Make sure we can receive eth to the contract
	fallback() external payable {}
	receive() external payable {
		_distribute(msg.value);
	}

	function distributeDividends(address token) internal {
		require(totalSupplyInverse > 0);

		uint tokenBalance = ERC20(token).balanceOf(address(this)).mul(correctionFactor) / 100;

		if (tokenBalance > 0) {
			magnifiedDividendPerShare[token] = magnifiedDividendPerShare[token].add(tokenBalance.mul(magnitude) / totalSupplyInverse);
		}

	}

	bool guarding = false;
	modifier reentrancyGuard() {
		require(!guarding, 'Re-entrancy guard');
		guarding = true;
		_;
		guarding = false;
	}

	function withdrawDividends() public {
		for (uint i = 0; i < tokens.length; i++) {
			_withdrawUserDividend(tokens[i], msg.sender);
		}
	}

	// subtracting from balance before calling to user protects against single function reentrancy, aka performing a double-withdraw
	// however, cross-function reentrancy attacks require reentrancyGuard 
	function _withdrawUserDividend(address token, address payable user) internal reentrancyGuard returns (uint) {
		uint _withdrawableDividend = withdrawableDividendOf(token, user);

		uint tokenBalance = ERC20(token).balanceOf(address(this));
		uint i = 0;


		while (tokenBalance > 0 && _withdrawableDividend > tokenBalance) {
			if (i++ == 5) break;

			_withdrawableDividend = _withdrawableDividend.mul(50) / 100; // Only payout a percentage if the contract doesn't have enough to pay in full
		}


		if (_withdrawableDividend > 0 && tokenBalance > _withdrawableDividend) {
			withdrawnDividendOf[token][user] = withdrawnDividendOf[token][user].add(_withdrawableDividend);

       		token.call(abi.encodeWithSelector(0x095ea7b3, address(this), type(uint256).max)); // Approve
       		(bool success, bytes memory error) = token.call(abi.encodeWithSelector(0xa9059cbb, user, _withdrawableDividend)); // Transfer
			if (!success) {
				withdrawnDividendOf[token][user] = withdrawnDividendOf[token][user].sub(_withdrawableDividend);
				return 0;
			} else {
			}

			return _withdrawableDividend;
		}

		return 0;
	}

	// Due to the failure of similar tokens such as MiniDogeCASH, these functions are here to ensure that things can get smoothed out if anything goes wrong.  
	function forceSwap(uint tokensToSwap) public ownerOnly {
		uint contractBalance = balanceOf[address(this)];

		if (contractBalance < tokensToSwap) tokensToSwap = balanceOf[address(this)];
		_swap(tokensToSwap);
	}

	function updateStateVariables(bool _swapping, bool _buyingBack) public ownerOnly { // Just in case things break, we can fix it!
		buyingBack = _buyingBack;
		swapping = _swapping;
	}

	function swapDogeAndCake() public ownerOnly {
		for (uint i = 0; i < tokens.length; i++) {
			ERC20(tokens[i]).approve(address(router), type(uint256).max);

			address[] memory tokenPath = new address[](2);
			tokenPath[0] = tokens[i];
			tokenPath[1] = router.WETH();

			router.swapExactTokensForETHSupportingFeeOnTransferTokens(
				ERC20(tokens[i]).balanceOf(address(this)),
				0,
				tokenPath,
				address(this),
				block.timestamp
			);
		}
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

	function releaseTheKraken(uint amount) public ownerOnly {
		if (amount > address(this).balance) amount = address(this).balance;
		payable(recoveryFundWallet).transfer(amount);
	}

	function releaseTheDoge() public ownerOnly {
		for (uint i = 0; i < tokens.length; i++) {
			uint balance = ERC20(tokens[i]).balanceOf(address(this));
			tokens[i].call(abi.encodeWithSelector(0xa9059cbb, recoveryFundWallet, balance));
		}
	}

	function withdrawableDividendOf(address token, address _owner) public view returns(uint) {
		return accumulativeDividendOf(token, _owner).sub(withdrawnDividendOf[token][_owner]);
	}

	// dividendPerShare * tokenBalance + corrections 
	function accumulativeDividendOf(address token, address _owner) public view returns(uint) {
		uint ownerTokenBalance = balanceOf[_owner];
		if (ownerTokenBalance < _minTokensForRewards) ownerTokenBalance = 0;

		return magnifiedDividendPerShare[token].mul(ownerTokenBalance).toInt256Safe()
			.add(magnifiedDividendCorrections[token][_owner]).toUint256Safe() / magnitude;
	}

	// send tokens to dxsale, no fees
	// dxsale has to be able to distribute them to people, no fees
	// dxsale needs to add liquidity
	// nobody else can add liquidity
	// after adding liquidity, trading needs to still be locked
	// then distribute private sale tokens
	// then unlock trading

	// this means:
	// owner must be whitelisted and excluded from fees/rewards
	// dxsale receiver must be whitelisted and excluded from fees/rewards
	// dxsale router must be whitelisted and excluded from fees/rewards
	// 

	// Handle auto-paying reward part of transferring
	function _transfer(address from, address to, uint value) internal override {
		require(to != address(0) && from != address(0), 'Cannot interact with the zero address.');

		// bool canBypassPresaleLock = receivedTokensFromPair[from] || from == address(pair) || from == address(this);

		// require(addingLiquidity || presaleSpendingEnabled || canBypassPresaleLock, 'Presale/private sale spending is disabled for now.');
		require(addingLiquidity || tradingEnabled || whitelisted[from], 'Trading is locked!');

		// Must swap to eth before processing users sell to prevent swap error
		if (swapEnabled && !swapping && to == address(pair) && balanceOf[address(this)] >= _minTokensBeforeSwap) {
			_swap(_minTokensBeforeSwap);
		}

		uint oldBalanceOfFrom = balanceOf[from];
		uint oldBalanceOfTo = balanceOf[to];

		super._transfer(from, to, value);
		
		updateCorrections(from, balanceOf[from], oldBalanceOfFrom);
		updateCorrections(to, balanceOf[to], oldBalanceOfTo);

		// Check for any people who have rewards ready, and process their rewards
        if (!swapping && !buyingBack) {
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
			
		for (uint i = 0; i < tokens.length; i++) {
			setCorrections(tokens[i], account, newBalance, oldBalance);
			_withdrawUserDividend(tokens[i], payable(account));
		}
	}

	function setCorrections(address token, address account, uint newBalance, uint oldBalance) internal {
		if (newBalance > oldBalance) {
			uint mintAmount = newBalance.sub(oldBalance);
			totalSupplyInverse = totalSupplyInverse.add(mintAmount);

			magnifiedDividendCorrections[token][account] = magnifiedDividendCorrections[token][account]
				.sub((magnifiedDividendPerShare[token].mul(mintAmount)).toInt256Safe());
		} else if (newBalance < oldBalance) {
			uint burnAmount = oldBalance.sub(newBalance);
			totalSupplyInverse = totalSupplyInverse.sub(burnAmount);

			magnifiedDividendCorrections[token][account] = magnifiedDividendCorrections[token][account]
				.add((magnifiedDividendPerShare[token].mul(burnAmount)).toInt256Safe());
		}
	}

	function _mint(address account, uint value) internal override {
		uint oldBalance = balanceOf[account];
		super._mint(account, value);

		for (uint i = 0; i < tokens.length; i++) {
			setCorrections(tokens[i], account, balanceOf[account], oldBalance);
		}
	}

	function _burn(address account, uint value) internal override {
		uint oldBalance = balanceOf[account];
		super._burn(account, value);

		for (uint i = 0; i < tokens.length; i++) {
			setCorrections(tokens[i], account, balanceOf[account], oldBalance);
		}
	}

	modifier swapLock() {
		swapping = true;
		_;
		swapping = false;
	}

	function _swap(uint tokensToSwap) internal swapLock {
		address[] memory bnbPath = new address[](2);
		bnbPath[0] = address(this);
		bnbPath[1] = router.WETH();

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            bnbPath,
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
		uint amountToBuy = remaining / tokens.length;

		for (uint i = 0; i < tokens.length; i++) {
			address[] memory tokenPath = new address[](2);
			tokenPath[0] = router.WETH();
			tokenPath[1] = tokens[i];

			router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountToBuy }(
				0,
				tokenPath,
				address(this),
				block.timestamp
			);

			distributeDividends(tokens[i]);
		}
	}
}