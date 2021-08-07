// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
  
    contract BabyBTRX is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
 
    address public bttDividendToken;
    address public trxDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
 
    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = true;
    bool public swapAndLiquifyEnabled = true;
    bool public bttDividendEnabled = true;
    bool public trxDividendEnabled = true;
 
    BTTDividendTracker public bttDividendTracker;
    TRXDividendTracker public trxDividendTracker;
 
    address private marketingWallet;
 
    uint256 public maxBuyTranscationAmount = 1 * 10**18;
    uint256 public maxSellTransactionAmount = 10 * 10**12 * 10**18;
    uint256 public maxWalletBalance = 20 * 10**12 * 10**18;
    uint256 public swapTokensAtAmount = 20 * 10**6 * 10**18;
 
    uint256 public liquidityFee = 3;
    uint256 public previousLiquidityFee;
    uint256 public bttDividendRewardsFee = 4;
    uint256 public previousBttDividendRewardsFee;
    uint256 public trxDividendRewardsFee = 4;
    uint256 public previousTrxDividendRewardsFee;
    uint256 private marketingFee = 5;
    uint256 private previousMarketingFee;
    uint256 public totalFees = bttDividendRewardsFee.add(marketingFee).add(trxDividendRewardsFee).add(liquidityFee);
 
 
    uint256 public sellFeeIncreaseFactor = 130;
 
    uint256 public gasForProcessing = 600000;
 
    address public presaleAddress;
 
    mapping (address => bool) private isExcludedFromFees;
 
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdatebttDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdatetrxDividendTracker(address indexed newAddress, address indexed oldAddress);
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event BttDividendEnabledUpdated(bool enabled);
    event TrxDividendEnabledUpdated(bool enabled);
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
 
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
 
    event SendDividends(
    	uint256 amount
    );
 
    event ProcessedbttDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
 
    event ProcessedtrxDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
 
    constructor() ERC20("BabyBTRX", "Baby BTRX") {
    	bttDividendTracker = new BTTDividendTracker();
    	trxDividendTracker = new TRXDividendTracker();
 
    	marketingWallet = 0x5a11888f0a78694aa38bD2Cf4ca15f6407e2Ef11;
    	bttDividendToken = 0x8595F9dA7b868b1822194fAEd312235E43007b49;
        trxDividendToken = 0x85EAC5Ac2F758618dFa09bDbe0cf174e7d574D5B;
 
    	//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Testnet
    	//0x10ED43C718714eb63d5aA57B78B54704E256024E Mainet V2
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
 
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
 
        excludeFromDividend(address(bttDividendTracker));
        excludeFromDividend(address(trxDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);
 
        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(owner(), true);
        setAuthOnDividends(owner());
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1e11 * (10**18));
    }
 
    receive() external payable {
 
  	}
 
  	function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        bttDividendTracker.excludeFromDividends(_presaleAddress);
        trxDividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);
 
        bttDividendTracker.excludeFromDividends(_routerAddress);
        trxDividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}
 
  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    bttDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        trxDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}
 
  	function setWalletBalance(uint256 _maxWalletBalance) external onlyOwner{
  	    maxWalletBalance = _maxWalletBalance;
  	}
 
  	function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxBuyTranscationAmount = _maxTxn * (10**18);
  	}
 
  	function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxSellTransactionAmount = _maxTxn * (10**18);
  	}
 
  	function updateBttDividendToken(address _newContract) external onlyOwner {
  	    bttDividendToken = _newContract;
  	    bttDividendTracker.setDividendTokenAddress(_newContract);
  	}
 
  	function updateTrxDividendToken(address _newContract) external onlyOwner {
  	    trxDividendToken = _newContract;
  	    trxDividendTracker.setDividendTokenAddress(_newContract);
  	}
 
  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != marketingWallet, "BabyBTRX: The marketing wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
  	    marketingWallet = _newWallet;
  	}
 
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
  	    swapTokensAtAmount = _swapAmount * (10**18);
  	}
 
  	function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner {
  	    sellFeeIncreaseFactor = _multiplier;
  	}
 
 
    function setTradingIsEnabled(bool _enabled) external onlyOwner {
        tradingIsEnabled = _enabled;
    }
 
    function setAuthOnDividends(address account) public onlyOwner{
        trxDividendTracker.setAuth(account);
        bttDividendTracker.setAuth(account);
    }
 
 
    function setBttDividendEnabled(bool _enabled) external onlyOwner {
        require(bttDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
             previousBttDividendRewardsFee = bttDividendRewardsFee;
            bttDividendRewardsFee = 0;
            bttDividendEnabled = _enabled;
        } else {
            bttDividendRewardsFee =  previousBttDividendRewardsFee;
            totalFees = bttDividendRewardsFee.add(marketingFee).add(trxDividendRewardsFee).add(liquidityFee);
            bttDividendEnabled = _enabled;
        }
 
        emit BttDividendEnabledUpdated(_enabled);
    }
 
    function setTrxDividendEnabled(bool _enabled) external onlyOwner {
        require(trxDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousTrxDividendRewardsFee = trxDividendRewardsFee;
            trxDividendRewardsFee = 0;
            trxDividendEnabled = _enabled;
        } else {
            trxDividendRewardsFee = previousTrxDividendRewardsFee;
            totalFees = trxDividendRewardsFee.add(marketingFee).add(bttDividendRewardsFee).add(liquidityFee);
            trxDividendEnabled = _enabled;
        }
 
        emit TrxDividendEnabledUpdated(_enabled);
    }
 
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee.add(trxDividendRewardsFee).add(bttDividendRewardsFee).add(liquidityFee);
            marketingEnabled = _enabled;
        }
 
        emit MarketingEnabledUpdated(_enabled);
    }
 
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(swapAndLiquifyEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousLiquidityFee = liquidityFee;
            liquidityFee = 0;
            swapAndLiquifyEnabled = _enabled;
        } else {
            liquidityFee = previousLiquidityFee;
            totalFees = trxDividendRewardsFee.add(marketingFee).add(bttDividendRewardsFee).add(liquidityFee);
            swapAndLiquifyEnabled = _enabled;
        }
 
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
 
 
    function updatebttDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(bttDividendTracker), "BabyBTRX: The dividend tracker already has that address");
 
       BTTDividendTracker newbttDividendTracker =BTTDividendTracker(payable(newAddress));
 
        require(newbttDividendTracker.owner() == address(this), "BabyBTRX: The new dividend tracker must be owned by the BabyBTRX token contract");
 
        newbttDividendTracker.excludeFromDividends(address(newbttDividendTracker));
        newbttDividendTracker.excludeFromDividends(address(this));
        newbttDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newbttDividendTracker.excludeFromDividends(address(deadAddress));
 
        emit UpdatebttDividendTracker(newAddress, address(bttDividendTracker));
 
        bttDividendTracker = newbttDividendTracker;
    }
 
    function updatetrxDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(trxDividendTracker), "BabyBTRX: The dividend tracker already has that address");
 
        TRXDividendTracker newtrxDividendTracker = TRXDividendTracker(payable(newAddress));
 
        require(newtrxDividendTracker.owner() == address(this), "BabyBTRX: The new dividend tracker must be owned by the BabyBTRX token contract");
 
        newtrxDividendTracker.excludeFromDividends(address(newtrxDividendTracker));
        newtrxDividendTracker.excludeFromDividends(address(this));
        newtrxDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newtrxDividendTracker.excludeFromDividends(address(deadAddress));
 
        emit UpdatetrxDividendTracker(newAddress, address(trxDividendTracker));
 
        trxDividendTracker = newtrxDividendTracker;
    }
 
    function updateBttDividendRewardFee(uint8 newFee) external onlyOwner {
        bttDividendRewardsFee = newFee;
        totalFees = bttDividendRewardsFee.add(marketingFee).add(trxDividendRewardsFee).add(liquidityFee);
    }
 
    function updateTRXDividendRewardFee(uint8 newFee) external onlyOwner {
        trxDividendRewardsFee = newFee;
        totalFees = trxDividendRewardsFee.add(bttDividendRewardsFee).add(marketingFee).add(liquidityFee);
    }
 
    function updateMarketingFee(uint8 newFee) external onlyOwner {
        marketingFee = newFee;
        totalFees = marketingFee.add(bttDividendRewardsFee).add(trxDividendRewardsFee).add(liquidityFee);
    }
 
    function updateLiquidityFee(uint8 newFee) external onlyOwner {
        liquidityFee = newFee;
        totalFees = marketingFee.add(bttDividendRewardsFee).add(trxDividendRewardsFee).add(liquidityFee);
    }
 
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "BabyBTRX: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "BabyBTRX: Account is already exluded from fees");
        isExcludedFromFees[account] = excluded;
 
        emit ExcludeFromFees(account, excluded);
    }
 
    function excludeFromDividend(address account) public onlyOwner {
        bttDividendTracker.excludeFromDividends(address(account));
        trxDividendTracker.excludeFromDividends(address(account));
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }
 
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
 
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BabyBTRX: The PanadaSwap pair cannot be removed from automatedMarketMakerPairs");
 
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "BabyBTRX: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
 
        if(value) {
            bttDividendTracker.excludeFromDividends(pair);
            trxDividendTracker.excludeFromDividends(pair);
        }
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "BabyBTRX: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
 
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        bttDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        trxDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }
 
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        bttDividendTracker.updateClaimWait(claimWait);
        trxDividendTracker.updateClaimWait(claimWait);
    }
 
    function getBttClaimWait() external view returns(uint256) {
        return bttDividendTracker.claimWait();
    }
 
    function getTrxClaimWait() external view returns(uint256) {
        return trxDividendTracker.claimWait();
    }
 
    function getTotalBttDividendsDistributed() external view returns (uint256) {
        return bttDividendTracker.totalDividendsDistributed();
    }
 
    function getTotalTrxDividendsDistributed() external view returns (uint256) {
        return trxDividendTracker.totalDividendsDistributed();
    }
 
    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }
 
    function withdrawableBttDividendOf(address account) external view returns(uint256) {
    	return bttDividendTracker.withdrawableDividendOf(account);
  	}
 
  	function withdrawableTrxDividendOf(address account) external view returns(uint256) {
    	return trxDividendTracker.withdrawableDividendOf(account);
  	}
 
	function bttDividendTokenBalanceOf(address account) external view returns (uint256) {
		return bttDividendTracker.balanceOf(account);
	}
 
	function trxDividendTokenBalanceOf(address account) external view returns (uint256) {
		return trxDividendTracker.balanceOf(account);
	}
 
    function getAccountBttDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return bttDividendTracker.getAccount(account);
    }
 
    function getAccountTrxDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return trxDividendTracker.getAccount(account);
    }
 
	function getAccountBttDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return bttDividendTracker.getAccountAtIndex(index);
    }
 
    function getAccountTrxDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return trxDividendTracker.getAccountAtIndex(index);
    }
 
	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 bttIterations, uint256 bttClaims, uint256 bttLastProcessedIndex) = bttDividendTracker.process(gas);
		emit ProcessedbttDividendTracker(bttIterations, bttClaims, bttLastProcessedIndex, false, gas, tx.origin);
 
		(uint256 trxIterations, uint256 trxClaims, uint256 trxLastProcessedIndex) = trxDividendTracker.process(gas);
		emit ProcessedtrxDividendTracker(trxIterations, trxClaims, trxLastProcessedIndex, false, gas, tx.origin);
    }
 
    function claim() external {
		bttDividendTracker.processAccount(payable(msg.sender), false);
		trxDividendTracker.processAccount(payable(msg.sender), false);
    }
    function getLastBttDividendProcessedIndex() external view returns(uint256) {
    	return bttDividendTracker.getLastProcessedIndex();
    }
 
    function getLastTrxDividendProcessedIndex() external view returns(uint256) {
    	return trxDividendTracker.getLastProcessedIndex();
    }
 
    function getNumberOfBttDividendTokenHolders() external view returns(uint256) {
        return bttDividendTracker.getNumberOfTokenHolders();
    }
 
    function getNumberOfTrxDividendTokenHolders() external view returns(uint256) {
        return trxDividendTracker.getNumberOfTokenHolders();
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "BabyBTRX: Trading has not started yet");
 
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
 
        if(!automatedMarketMakerPairs[to] && tradingIsEnabled && !excludedAccount){
            require(balanceOf(to).add(amount) <= maxWalletBalance, 'Wallet balance is exceeding maxWalletBalance');
        }
 
        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(amount <= maxBuyTranscationAmount, "Transfer amount exceeds the maxTxAmount.");
 
        } else if (
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
 
 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
 
        if (!swapping && canSwap && from != uniswapV2Pair) {
            swapping = true;
 
            if (marketingEnabled) {
                uint256 initialBalance = address(this).balance;
                uint256 swapTokens = contractTokenBalance.div(totalFees).mul(marketingFee);
                swapTokensForBNB(swapTokens);
                uint256 marketingPortion = address(this).balance.sub(initialBalance);
                transferToWallet(payable(marketingWallet), marketingPortion);
            }
 
            if(swapAndLiquifyEnabled) {
                uint256 liqTokens = contractTokenBalance.div(totalFees).mul(liquidityFee);
                swapAndLiquify(liqTokens);
            }
 
            if (bttDividendEnabled) {
                uint256 bttTokens = contractTokenBalance.div(totalFees).mul(bttDividendRewardsFee);
                swapAndSendBttDividends(bttTokens);
            }
 
            if (trxDividendEnabled) {
                uint256 trxTokens = contractTokenBalance.div(totalFees).mul(trxDividendRewardsFee);
                swapAndSendTrxDividends(trxTokens);
            }
 
                swapping = false;
        }
 
        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;
 
        if(takeFee) {
        	uint256 fees = amount.div(100).mul(totalFees);
 
            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees.div(100).mul(sellFeeIncreaseFactor);
            }
 
        	amount = amount.sub(fees);
 
            super._transfer(from, address(this), fees);
        }
 
        super._transfer(from, to, amount);
 
        try bttDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try trxDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try bttDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try trxDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
 
        if(!swapping) {
	    	uint256 gas = gasForProcessing;
 
	    	try bttDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedbttDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
 
	    	}
 
	    	try trxDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedtrxDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
 
	    	}
        }
    }
 
 
    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
 
        uint256 initialBalance = address(this).balance;
 
        swapTokensForBNB(half);
 
        uint256 newBalance = address(this).balance.sub(initialBalance);
 
        addLiquidity(otherHalf, newBalance);
 
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
 
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingWallet,
            block.timestamp
        );
    }
 
 
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
 
    }
 
    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendAddress;
 
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
 
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp
        );
    }
 
    function swapAndSendBttDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), bttDividendToken);
        uint256 bttDividends = IERC20(bttDividendToken).balanceOf(address(this));
        transferDividends(bttDividendToken, address(bttDividendTracker), bttDividendTracker, bttDividends);
    }
 
    function swapAndSendTrxDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), trxDividendToken);
        uint256 trxDividends = IERC20(trxDividendToken).balanceOf(address(this));
        transferDividends(trxDividendToken, address(trxDividendTracker), trxDividendTracker, trxDividends);
    }
 
    function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
 
    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);
 
        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }
}
 
    contract BTTDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
 
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
 
    mapping (address => bool) public excludedFromDividends;
 
    mapping (address => uint256) public lastClaimTimes;
 
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
 
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
 
    constructor() DividendPayingToken("BabyBTRX_Btt_Dividend_Tracker", "BabyBTRX_Btt_Dividend_Tracker",  0x8595F9dA7b868b1822194fAEd312235E43007b49) {
    	claimWait = 1800;
        minimumTokenBalanceForDividends = 2000000 * (10**18); 
    }
 
    function _transfer(address, address, uint256) pure internal override {
        require(false, "BabyBTRX_Btt_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() pure public override {
        require(false, "BabyBTRX_Btt_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BabyBTRX contract.");
    }
 
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
 
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
 
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
 
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
 
    	emit ExcludeFromDividends(account);
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "BabyBTRX_Btt_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BabyBTRX_Btt_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
 
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
 
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
 
 
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
 
        index = tokenHoldersMap.getIndexOfKey(account);
 
        iterationsUntilProcessed = -1;
 
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;
 
 
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
 
 
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
 
        lastClaimTime = lastClaimTimes[account];
 
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;
 
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }
 
    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
 
        address account = tokenHoldersMap.getKeyAtIndex(index);
 
        return getAccount(account);
    }
 
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
 
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
 
    	if(newBalance >= minimumTokenBalanceForDividends) {
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
 
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}
 
    	uint256 _lastProcessedIndex = lastProcessedIndex;
 
    	uint256 gasUsed = 0;
 
    	uint256 gasLeft = gasleft();
 
    	uint256 iterations = 0;
    	uint256 claims = 0;
 
    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
 
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
 
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
 
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}
 
    		iterations++;
 
    		uint256 newGasLeft = gasleft();
 
    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
 
    		gasLeft = newGasLeft;
    	}
 
    	lastProcessedIndex = _lastProcessedIndex;
 
    	return (iterations, claims, lastProcessedIndex);
    }
 
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
 
    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
 
    	return false;
    }
}
 
contract TRXDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
 
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
 
    mapping (address => bool) public excludedFromDividends;
 
    mapping (address => uint256) public lastClaimTimes;
 
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
 
    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
 
    constructor() DividendPayingToken("BabyBTRX_Trx_Dividend_Tracker", "BabyBTRX_Trx_Dividend_Tracker", 0x85EAC5Ac2F758618dFa09bDbe0cf174e7d574D5B) {
    	claimWait = 1800;
        minimumTokenBalanceForDividends = 2000000 * (10**18); //must hold 2000000+ tokens
    }
 
    function _transfer(address, address, uint256) pure internal override {
        require(false, "BabyBTRX_Trx_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() pure public override {
        require(false, "BabyBTRX_Trx_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BabyBTRX contract.");
    }
 
    function setDividendTokenAddress(address newToken) external override onlyOwner {
      dividendToken = newToken;
    }
 
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
 
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;
 
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
 
    	emit ExcludeFromDividends(account);
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "BabyBTRX_Trx_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BabyBTRX_Trx_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
 
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }
 
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
 
 
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
 
        index = tokenHoldersMap.getIndexOfKey(account);
 
        iterationsUntilProcessed = -1;
 
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;
 
 
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
 
 
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
 
        lastClaimTime = lastClaimTimes[account];
 
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;
 
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }
 
    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }
 
        address account = tokenHoldersMap.getKeyAtIndex(index);
 
        return getAccount(account);
    }
 
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
 
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
 
    	if(newBalance >= minimumTokenBalanceForDividends) {
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
 
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}
 
    	uint256 _lastProcessedIndex = lastProcessedIndex;
 
    	uint256 gasUsed = 0;
 
    	uint256 gasLeft = gasleft();
 
    	uint256 iterations = 0;
    	uint256 claims = 0;
 
    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
 
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
 
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
 
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}
 
    		iterations++;
 
    		uint256 newGasLeft = gasleft();
 
    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
 
    		gasLeft = newGasLeft;
    	}
 
    	lastProcessedIndex = _lastProcessedIndex;
 
    	return (iterations, claims, lastProcessedIndex);
    }
 
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
 
    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
 
    	return false;
    }
}