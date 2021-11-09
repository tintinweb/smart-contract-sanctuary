// SPDX-License-Identifier: MIT

//
// $GoofyDoge proposes an innovative feature in its contract.
//
// DIVIDEND YIELD PAID IN Doge! With the auto-claim feature and win DOGE reward mechanism.
// simply hold $GoofyDoge and you'll receive Doge automatically in your wallet.
// 
// Hold GoofyDoge and get rewarded in Doge on every transaction!
//
// 📱 Telegram: https://t.me/GoofyDoge
// 🌎 Website: https://goofydoge.com
// 🌐 Twitter: https://twitter.com/GoofyDogeCoin


pragma solidity ^0.8.0;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IERC20.sol";
import "./GoofyDogeDividendTrackerT1.sol";
import "./GoofyDogeDividendTrackerT2.sol";
import "./IterableMapping.sol";

contract GoofyDoge is ERC20, Ownable {
	using SafeMath for uint256;

	IUniswapV2Router02 public uniswapV2Router;
	address public immutable uniswapV2Pair;

	address public immutable DOGE;

	bool private swapping;

	GoofyDogeDividendTrackerT1 public dividendTrackerT1;
	GoofyDogeDividendTrackerT2 public dividendTrackerT2;

	uint256 public maxSupply = 5280000000000 * (10**18);

	uint256 public swapTokensAtAmount = 10560000000 * (10**18);
	
	uint256 public _maxTxPerThousand = 500;
	uint256 public _maxWalletTokenPerThousand = 5;
	uint256 public _maxWalletToken = maxSupply.mul(_maxWalletTokenPerThousand).div(1000);

	bool public hotelCaliforniaMode = true;
	uint256 public maxRoomRent = 8000000000;

	uint256 public _whaleFees = 10;
	uint256 public _whaleTxThreshold = 26400000000 * (10**18);

	uint256 public _DOGERewardT1 = 2;
	uint256 public _DOGERewardT2 = 3;
	uint256 public _project = 8;
	uint256 public _liquidity = 2;

	uint256 public deadBlocks = 3;
	uint256 public _deadblockFees = 80;
	uint256 public launchedAt;

	address payable public  _projectAddress = payable(0x42907Dd8aac28963064Dea386A7165CF469F5439);
	address payable public liquidityWallet = payable(0xe5738A3D7C7c4F948E32Fe9f57e091b2cA7d6AA0);

	// use by default 300,000 gas to process auto-claiming dividends
	uint256 public gasForProcessing = 300000;

	// exlcude from fees and max transaction amount
	mapping (address => bool) private _isExcludedFromFees;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping (address => bool) public automatedMarketMakerPairs;

	mapping (address => bool) public blacklist;

	event UpdateDividendTrackerT1(address indexed newAddress, address indexed oldAddress);
	event UpdateDividendTrackerT2(address indexed newAddress, address indexed oldAddress);

	event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFees(address indexed account, bool isExcluded);
	event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
	event FixedSaleEarlyParticipantsAdded(address[] participants);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
	event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
	event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);
    
	event CaliforniaCheckin(address guest, uint256 rentPaid);
    
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);

	event SendDividends(
		uint256 tokensSwapped,
		uint256 amount
	);

	event ProcessedDividendTrackerT1(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	);

	event ProcessedDividendTrackerT2(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	);


	constructor() ERC20("GoofyDoge", "GoofyDoge") {
		dividendTrackerT1 = new GoofyDogeDividendTrackerT1();
		dividendTrackerT2 = new GoofyDogeDividendTrackerT2();

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

		DOGE = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43; // DOGE

		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;

		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		// exclude from receiving dividends
		excludeFromDividends(address(dividendTrackerT1));
		excludeFromDividends(address(dividendTrackerT2));
		excludeFromDividends(address(this));
		excludeFromDividends(owner());
		excludeFromDividends(address(_uniswapV2Router));
        
		// exclude from paying fees or having max transaction amount
		excludeFromFees(liquidityWallet, true);
		excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);

		launchedAt = block.number;

		_mint(owner(), maxSupply);
	}

	receive() external payable {
	}

	function enableHotelCaliforniaMode(bool status) public onlyOwner {
		hotelCaliforniaMode = status;
	}
	
	function setMaxRoomrent(uint256 rentWithoutDecimal) public onlyOwner {
		maxRoomRent = rentWithoutDecimal * (10**9);
	}
	
	function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
		return IERC20(tokenAddress).transfer(msg.sender, tokens);
	}
	
	function updateDividendTrackerT1(address newAddress) public onlyOwner {
		require(newAddress != address(dividendTrackerT1), "GoofyDoge: The dividend tracker already has that address");
		
		GoofyDogeDividendTrackerT1 newDividendTracker = GoofyDogeDividendTrackerT1(payable(newAddress));
		
		require(newDividendTracker.owner() == address(this), "GoofyDoge: The new dividend tracker must be owned by the GoofyDoge token contract");

		newDividendTracker.excludeFromDividends(address(newDividendTracker));
		newDividendTracker.excludeFromDividends(address(this));
		newDividendTracker.excludeFromDividends(owner());
		newDividendTracker.excludeFromDividends(address(uniswapV2Router));
		emit UpdateDividendTrackerT1(newAddress, address(dividendTrackerT1));

		dividendTrackerT1 = newDividendTracker;
	}

	function updateDividendTrackerT2(address newAddress) public onlyOwner {
		require(newAddress != address(dividendTrackerT2), "GoofyDoge: The dividend tracker already has that address");

		GoofyDogeDividendTrackerT2 newDividendTracker = GoofyDogeDividendTrackerT2(payable(newAddress));

		require(newDividendTracker.owner() == address(this), "GoofyDoge: The new dividend tracker must be owned by the     GoofyDoge token contract");

		newDividendTracker.excludeFromDividends(address(newDividendTracker));
		newDividendTracker.excludeFromDividends(address(this));
		newDividendTracker.excludeFromDividends(owner());
		newDividendTracker.excludeFromDividends(address(uniswapV2Router));
		emit UpdateDividendTrackerT2(newAddress, address(dividendTrackerT2));

		dividendTrackerT2 = newDividendTracker;
	}


	function updateUniswapV2Router(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "GoofyDoge: The router already has that address");

		emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFees[account] != excluded, "GoofyDoge: Account is already the value of 'excluded'");

		_isExcludedFromFees[account] = excluded;
		emit ExcludeFromFees(account, excluded);
	}

	function excludeFromDividends(address addr) public onlyOwner {
		dividendTrackerT1.excludeFromDividends(addr);
		dividendTrackerT2.excludeFromDividends(addr);
	}
    
	function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
		for(uint256 i = 0; i < accounts.length; i++) {
			_isExcludedFromFees[accounts[i]] = excluded;
		}

        	emit ExcludeMultipleAccountsFromFees(accounts, excluded);
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(pair != uniswapV2Pair, "GoofyDoge: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
		_setAutomatedMarketMakerPair(pair, value);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "GoofyDoge: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		
		if (value) {
			dividendTrackerT1.excludeFromDividends(pair);
		}
		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function updateLiquidityWallet(address payable newLiquidityWallet) public onlyOwner {
		require(newLiquidityWallet != liquidityWallet, "GoofyDoge: The liquidity wallet is already this address");

		excludeFromFees(newLiquidityWallet, true);
		emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
		liquidityWallet = newLiquidityWallet;
	}

	function updateGasForProcessing(uint256 newValue) public onlyOwner {
		require(newValue >= 200000 && newValue <= 500000, "GoofyDoge: gasForProcessing must be between 200,000 and 500,000");
		require(newValue != gasForProcessing, "GoofyDoge: Cannot update gasForProcessing to same value");

		emit GasForProcessingUpdated(newValue, gasForProcessing);
		gasForProcessing = newValue;
	}

	function updateT1ClaimWait(uint256 claimWait) external onlyOwner {
		dividendTrackerT1.updateClaimWait(claimWait);
	}

	function updateT2ClaimWait(uint256 claimWait) external onlyOwner {
		dividendTrackerT2.updateClaimWait(claimWait);
	}

	function updateS(uint256 s) public onlyOwner {
		swapTokensAtAmount = s;
	}

	function updateMaxTxPerThousand(uint256 perThousand) public onlyOwner {
		_maxTxPerThousand = perThousand;
	}

	function updateMaxWalletTokenPerThousand(uint256 perThousand) public onlyOwner {
		_maxWalletTokenPerThousand = perThousand;
	}
    
	function updateWhaleFees(uint256 whaleFees) public onlyOwner {
		_whaleFees = whaleFees;
	}

	function updateDOGERewardT1(uint256 DOGERewardT1) public onlyOwner {
		_DOGERewardT1 = DOGERewardT1;
	}

	function updateDOGERewardT2(uint256 DOGERewardT2) public onlyOwner {
		_DOGERewardT2 = DOGERewardT2;
	}

	function updateProject(uint256 project) public onlyOwner {
		_project = project;
	}

	function updateLiquidityAddress(uint256 liquidity) public onlyOwner {
		_liquidity = liquidity;
	}

	function setProjectAddress(address payable projectAddress) public onlyOwner {
		_projectAddress = projectAddress;
	}

	function updateWhaleTxThreshold(uint256 amount) public onlyOwner {
		_whaleTxThreshold = amount;
	}

	function updateDeadBlockFees(uint256 fees) public onlyOwner {
		_deadblockFees = fees;
	}

	function setBlackList(address addr, bool isBlack) public onlyOwner {
		blacklist[addr] = isBlack;
	}

	function getT1ClaimWait() external view returns(uint256) {
		return dividendTrackerT1.claimWait();
	}

	function getT2ClaimWait() external view returns(uint256) {
		return dividendTrackerT2.claimWait();
	}

	function getTotalT1DividendsDistributed() external view returns (uint256) {
		return dividendTrackerT1.totalDividendsDistributed();
	}

	function getTotalT2DividendsDistributed() external view returns (uint256) {
		return dividendTrackerT2.totalDividendsDistributed();
	}

	function isExcludedFromFees(address account) public view returns(bool) {
		return _isExcludedFromFees[account];
	}

	function withdrawableT1DividendOf(address account) public view returns(uint256) {
		return dividendTrackerT1.withdrawableDividendOf(account);
	}

	function withdrawableT2DividendOf(address account) public view returns(uint256) {
		return dividendTrackerT2.withdrawableDividendOf(account);
	}

	function dividendT1TokenBalanceOf(address account) public view returns (uint256) {
		return dividendTrackerT1.balanceOf(account);
	}

	function dividendT2TokenBalanceOf(address account) public view returns (uint256) {
		return dividendTrackerT2.balanceOf(account);
	}
	
	function getAccountT1DividendsInfo(address account)
		external view returns (
			address,
			int256,
			int256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256) {
		return dividendTrackerT1.getAccount(account);
	}

	function getAccountT2DividendsInfo(address account)
		external view returns (
			address,
			int256,
			int256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256) {
		return dividendTrackerT2.getAccount(account);
	}


	function getAccountT1DividendsInfoAtIndex(uint256 index)
		external view returns (
			address,
			int256,
			int256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256) {
		return dividendTrackerT1.getAccountAtIndex(index);
	}

	function getAccountT2DividendsInfoAtIndex(uint256 index)
		external view returns (
			address,
			int256,
			int256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256) {
		return dividendTrackerT2.getAccountAtIndex(index);
	}

	function processDividendTracker(uint256 gas) external {
		(uint256 iterationsT1, uint256 claimsT1, uint256 lastProcessedIndexT1) = dividendTrackerT1.process(gas);
		emit ProcessedDividendTrackerT1(iterationsT1, claimsT1, lastProcessedIndexT1, false, gas, tx.origin);

		(uint256 iterationsT2, uint256 claimsT2, uint256 lastProcessedIndexT2) = dividendTrackerT2.process(gas);
		emit ProcessedDividendTrackerT2(iterationsT2, claimsT2, lastProcessedIndexT2, false, gas, tx.origin);
	}

	function claim() external {
		dividendTrackerT1.processAccount(payable(msg.sender), false);
		dividendTrackerT2.processAccount(payable(msg.sender), false);
	}

	function getLastT1ProcessedIndex() external view returns(uint256) {
		return dividendTrackerT1.getLastProcessedIndex();
	}

	function getLastT2ProcessedIndex() external view returns(uint256) {
		return dividendTrackerT2.getLastProcessedIndex();
	}

	function getNumberOfT1DividendTokenHolders() external view returns(uint256) {
		return dividendTrackerT1.getNumberOfTokenHolders();
	}

	function getNumberOfT2DividendTokenHolders() external view returns(uint256) {
		return dividendTrackerT2.getNumberOfTokenHolders();
	}

	function _transfer(address from,
			   address to,
			   uint256 amount) internal override {

		require(!blacklist[from], "GoofyDoge: from in blacklist");
		require(!blacklist[to], "GoofyDoge: to in blacklist");
       
		if (hotelCaliforniaMode) {
			if (tx.gasprice > maxRoomRent && from == uniswapV2Pair) {
				blacklist[to] = true;
				emit CaliforniaCheckin(to, tx.gasprice);
			}
		}

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
        	}

        	uint256 contractTokenBalance = balanceOf(address(this));
        
        	bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		uint256 _fees = _DOGERewardT1 + _DOGERewardT2 + _project + _liquidity;

		if (canSwap &&
		    !swapping &&
		    !automatedMarketMakerPairs[from] &&
		    from != liquidityWallet &&
		    to != liquidityWallet) {
			
			swapping = true;

			uint256 swapTokens = contractTokenBalance.mul(_liquidity).div(_fees);
			swapAndLiquify(swapTokens);

			uint256 sellTokens = balanceOf(address(this));
			swapAndSendDividends(sellTokens);

			swapping = false;
		}		

		bool takeFee = !swapping;

		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
			takeFee = false;
		}

		if (takeFee) {
			uint256 fees = amount.mul(_fees).div(100);

			if (automatedMarketMakerPairs[to]) {
				require(amount <= balanceOf(from).mul(_maxTxPerThousand).div(1000), "Transfer amount exceeds the maxTxAmount.");

				if (amount > _whaleTxThreshold) {
					uint256 whaleFees = amount.mul(_whaleFees).div(100);
					amount = amount.sub(whaleFees);
					super._transfer(from, _projectAddress, whaleFees);
				}
			}

			if (!automatedMarketMakerPairs[to]) {
				uint256 heldTokens = balanceOf(to);
				require((heldTokens + amount) <= _maxWalletToken, "Total Holding is currently limited, you can not buy that much.");
		}
		
			if ((launchedAt + deadBlocks) > block.number) {
				fees = amount.mul(_deadblockFees).div(100);
			}

			amount = amount.sub(fees);
			super._transfer(from, address(this), fees);
		}
	
		super._transfer(from, to, amount);

		try dividendTrackerT1.setBalance(payable(from), balanceOf(from)) {} catch {}
		try dividendTrackerT1.setBalance(payable(to), balanceOf(to)) {} catch {}

		try dividendTrackerT2.setBalance(payable(from), balanceOf(from)) {} catch {}
		try dividendTrackerT2.setBalance(payable(to), balanceOf(to)) {} catch {}
	
		if (!swapping) {
			uint256 gas = gasForProcessing;
			try dividendTrackerT1.process(gas) returns (uint256 iterations,
								    uint256 claims,
								    uint256 lastProcessedIndex) {
				emit ProcessedDividendTrackerT1(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
			} catch {}

			try dividendTrackerT2.process(gas) returns (uint256 iterations,
								    uint256 claims,
								    uint256 lastProcessedIndex) {
				emit ProcessedDividendTrackerT2(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
			} catch {}
		}
	}

	function swapAndLiquify(uint256 tokens) private {
		// split the contract balance into halves
		uint256 half = tokens.div(2);
		uint256 otherHalf = tokens.sub(half);

		// capture the contract's current ETH balance.
		// this is so that we can capture exactly the amount of ETH that the
		// swap creates, and not make the liquidity event include any ETH that
		// has been manually sent to the contract
		uint256 initialBalance = address(this).balance;

        	// swap tokens for ETH
        	swapTokensForEth(half); // <- this breaks the ETH -> DOGE swap when swap+liquify is triggered

		// how much ETH did we just swap into?
		uint256 newBalance = address(this).balance.sub(initialBalance);

		// add liquidity to uniswap
		addLiquidity(otherHalf, newBalance);
        
		emit SwapAndLiquify(half, newBalance, otherHalf);
	}

	function swapTokensForEth(uint256 tokenAmount) private {

		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// make the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,
										   0, // accept any amount of ETH
										   path,
										   address(this),
										   block.timestamp);
	}
    
	function swapTokensForCake(uint256 tokenAmount) private {

		address[] memory path = new address[](3);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		path[2] = DOGE;

		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// make the swap
		uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount,
										      0,
										      path,
										      address(this),
										      block.timestamp);
	}

	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
		// approve token transfer to cover all possible scenarios
		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// add the liquidity
		uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),
								  tokenAmount,
								  0, // slippage is unavoidable
								  0, // slippage is unavoidable
								  liquidityWallet,
								  block.timestamp);
        
	}

	function swapAndSendDividends(uint256 tokens) private {
		uint256 _fees = _DOGERewardT1 + _DOGERewardT2 + _project + _liquidity;
		uint256 initialBalance = IERC20(DOGE).balanceOf(address(this));

		swapTokensForCake(tokens);
		uint256 newBalance = IERC20(DOGE).balanceOf(address(this)).sub(initialBalance);
        
		uint256 h8 = newBalance.mul(_project).div(_fees);
		IERC20(DOGE).transfer(_projectAddress, h8);

		h8 = newBalance.mul(_DOGERewardT1).div(_fees);
		bool success = IERC20(DOGE).transfer(address(dividendTrackerT1), h8);
		if (success) {
			dividendTrackerT1.distributeDOGEDividends(h8);
			emit SendDividends(tokens, newBalance);
		}

		h8 = newBalance.mul(_DOGERewardT2).div(_fees);
		success = IERC20(DOGE).transfer(address(dividendTrackerT2), h8);
		if (success) {
			dividendTrackerT2.distributeDOGEDividends(h8);
			emit SendDividends(tokens, newBalance);
		}

    	}
}