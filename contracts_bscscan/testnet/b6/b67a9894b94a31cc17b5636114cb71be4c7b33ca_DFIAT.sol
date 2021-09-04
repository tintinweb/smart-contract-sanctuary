// ----------------------------------------------------------- //
// SPDX-License-Identifier: MIT
// Name                   : DIGITAL FIAT
// Symbol                 : DFIAT
// Decimals               : 18
// Supply                 : 20,000,0000
// TAX                    : 15%
// -> 3% BUSD Redistribution
// -> 6% BNB Redistribution
// -> 5% PancakeSwap liquidity 
// ----------------------------------------------------------- //

pragma solidity ^0.8.4;

// Importing Necessary Files
import "./Context.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeMathInt.sol";
import "./SafeMathUint.sol";
import "./IterableMapping.sol";
import "./PancakeSwap.sol";
import "./Dividend.sol";

contract DFIAT is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public wbnbDividendToken;
    address public busdDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackAndLiquifyEnabled = false;
    bool public wbnbDividendEnabled = false;
    bool public busdDividendEnabled = false;

    WrappedBNBDividendTracker public wbnbDividendTracker;
    BusdDividendTracker public busdDividendTracker;

    address private divident;
    address public marketingWallet;
    
    uint256 public maxBuyTranscationAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken; 

    uint256 private wbnbDividendRewardsFee;
    uint256 private previousWrappedBNBDividendRewardsFee;
    uint256 private busdDividendRewardsFee;
    uint256 private previousBusdDividendRewardsFee;
    uint256 private marketingFee;
    uint256 private previousMarketingFee;
    uint256 private buyBackAndLiquidityFee;
    uint256 private previousBuyBackAndLiquidityFee;
    uint256 public totalFees;

    uint256 public sellFeeIncreaseFactor = 150;

    uint256 public gasForProcessing = 600000;
    
    address public presaleAddress;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateWrappedBNBDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateBusdDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event WrappedBNBDividendEnabledUpdated(bool enabled);
    event BusdDividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DividentUpdated(address indexed newDivident, address indexed oldDivident);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 amount
    );
    
    event SwapBNBForTokens(
        uint256 amountIn,
        address[] path
    );

    event ProcessedWrappedBNBDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    event ProcessedBusdDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("DIGITAL FIAT", "DFIAT") {
    	wbnbDividendTracker = new WrappedBNBDividendTracker();
    	busdDividendTracker = new BusdDividendTracker();

    	marketingWallet = 0xDd0a4A0d2c4aa58dE4534E8FCe6735D3F99adD18; // Marketing Wallet
    	wbnbDividendToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Wrapped-BNB
        busdDividendToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // Binance-Peg BUSD
        divident = 0x97cAA9BF9e0b427Fb7F00266092f65046539E450;
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // PancakeSwap V2 Router
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        // Exclude These Addresses From Getting Rewards
        excludeFromDividend(address(wbnbDividendTracker));
        excludeFromDividend(address(busdDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        // Exclude These Addresses From Paying Fees
        excludeFromFees(marketingWallet, true);
        excludeFromFees(divident, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 20000000 * (10**18));
    }

    receive() external payable {

  	}

  	function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        wbnbDividendTracker.excludeFromDividends(_presaleAddress);
        busdDividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

        wbnbDividendTracker.excludeFromDividends(_routerAddress);
        busdDividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}

  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    wbnbDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        busdDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}
  	
  	function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxBuyTranscationAmount = _maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxSellTransactionAmount = _maxTxn * (10**18);
  	}
	
  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != marketingWallet, "DIGITALFIAT: The marketing wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
  	    marketingWallet = _newWallet;
  	}
  	
  	function setMaxWalletToken(uint256 _maxToken) external onlyOwner {
  	    maxWalletToken = _maxToken * (10**18);
  	}
  	
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
  	    swapTokensAtAmount = _swapAmount * (10**18);
  	}

    function afterPreSale() external onlyOwner {
        wbnbDividendRewardsFee = 6;
        busdDividendRewardsFee = 3;
        marketingFee = 0;
        buyBackAndLiquidityFee = 6;
        totalFees = 15;
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        wbnbDividendEnabled = true;
        busdDividendEnabled = true;
        swapTokensAtAmount = 2000000 * (10**18);
        maxBuyTranscationAmount = 5000000000 * (10**18);
        maxSellTransactionAmount = 500000000 * (10**18);
        maxWalletToken = 10000000000 * (10**18);
    }
    
    function setTradingIsEnabled(bool _enabled) external onlyOwner {
        tradingIsEnabled = _enabled;
    }
    
    function setBuyBackAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(buyBackAndLiquifyEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyBackAndLiquidityFee = buyBackAndLiquidityFee;
            buyBackAndLiquidityFee = 0;
            buyBackAndLiquifyEnabled = _enabled;
        } else {
            buyBackAndLiquidityFee = previousBuyBackAndLiquidityFee;
            totalFees = buyBackAndLiquidityFee.add(marketingFee).add(busdDividendRewardsFee).add(wbnbDividendRewardsFee);
            buyBackAndLiquifyEnabled = _enabled;
        }
        
        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setWrappedBNBDividendEnabled(bool _enabled) external onlyOwner {
        require(wbnbDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousWrappedBNBDividendRewardsFee = wbnbDividendRewardsFee;
            wbnbDividendRewardsFee = 0;
            wbnbDividendEnabled = _enabled;
        } else {
            wbnbDividendRewardsFee = previousWrappedBNBDividendRewardsFee;
            totalFees = wbnbDividendRewardsFee.add(marketingFee).add(busdDividendRewardsFee).add(buyBackAndLiquidityFee);
            wbnbDividendEnabled = _enabled;
        }

        emit WrappedBNBDividendEnabledUpdated(_enabled);
    }
    
    function setbusdDividendEnabled(bool _enabled) external onlyOwner {
        require(busdDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBusdDividendRewardsFee = busdDividendRewardsFee;
            busdDividendRewardsFee = 0;
            busdDividendEnabled = _enabled;
        } else {
            busdDividendRewardsFee = previousBusdDividendRewardsFee;
            totalFees = busdDividendRewardsFee.add(marketingFee).add(wbnbDividendRewardsFee).add(buyBackAndLiquidityFee);
            busdDividendEnabled = _enabled;
        }

        emit BusdDividendEnabledUpdated(_enabled);
    }
    
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee.add(busdDividendRewardsFee).add(wbnbDividendRewardsFee).add(buyBackAndLiquidityFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateWrappedBNBDividendRewardFee(uint8 newFee) external onlyOwner {
        wbnbDividendRewardsFee = newFee;
        totalFees = wbnbDividendRewardsFee.add(marketingFee).add(busdDividendRewardsFee).add(buyBackAndLiquidityFee);
    }
    
    function updateBusdDividendRewardFee(uint8 newFee) external onlyOwner {
              busdDividendRewardsFee = newFee;
        totalFees = busdDividendRewardsFee.add(wbnbDividendRewardsFee).add(marketingFee).add(buyBackAndLiquidityFee);
    }
    
    function updateMarketingFee(uint8 newFee) private onlyOwner {
        marketingFee = newFee;
        totalFees = marketingFee.add(wbnbDividendRewardsFee).add(busdDividendRewardsFee).add(buyBackAndLiquidityFee);
    }
    
    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee.add(wbnbDividendRewardsFee).add(busdDividendRewardsFee).add(marketingFee);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "DIGITALFIAT: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "DIGITALFIAT: Account is already exluded from fees");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        wbnbDividendTracker.excludeFromDividends(address(account));
        busdDividendTracker.excludeFromDividends(address(account));
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "DIGITALFIAT: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "DIGITALFIAT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            wbnbDividendTracker.excludeFromDividends(pair);
            busdDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "DIGITALFIAT: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
    
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        wbnbDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        busdDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        wbnbDividendTracker.updateClaimWait(claimWait);
        busdDividendTracker.updateClaimWait(claimWait);
    }

    function getWrappedBNBClaimWait() external view returns(uint256) {
        return wbnbDividendTracker.claimWait();
    }
    
    function getBusdClaimWait() external view returns(uint256) {
        return busdDividendTracker.claimWait();
    }

    function getTotalWrappedBNBDividendsDistributed() external view returns (uint256) {
        return wbnbDividendTracker.totalDividendsDistributed();
    }
    
    function getTotalBusdDividendsDistributed() external view returns (uint256) {
        return busdDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableWrappedBNBDividendOf(address account) external view returns(uint256) {
    	return wbnbDividendTracker.withdrawableDividendOf(account);
  	}
  	
  	function withdrawableBusdDividendOf(address account) external view returns(uint256) {
    	return busdDividendTracker.withdrawableDividendOf(account);
  	}

	function wbnbDividendTokenBalanceOf(address account) external view returns (uint256) {
		return wbnbDividendTracker.balanceOf(account);
	}
	
	function busdDividendTokenBalanceOf(address account) external view returns (uint256) {
		return busdDividendTracker.balanceOf(account);
	}

    function getAccountWrappedBNBDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return wbnbDividendTracker.getAccount(account);
    }
    
    function getAccountBusdDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return busdDividendTracker.getAccount(account);
    }

	function getAccountWrappedBNBDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return wbnbDividendTracker.getAccountAtIndex(index);
    }
    
    function getAccountBusdDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return busdDividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 ethIterations, uint256 ethClaims, uint256 ethLastProcessedIndex) = wbnbDividendTracker.process(gas);
		emit ProcessedWrappedBNBDividendTracker(ethIterations, ethClaims, ethLastProcessedIndex, false, gas, tx.origin);
		
		(uint256 dogeBackIterations, uint256 dogeBackClaims, uint256 dogeBackLastProcessedIndex) = busdDividendTracker.process(gas);
		emit ProcessedBusdDividendTracker(dogeBackIterations, dogeBackClaims, dogeBackLastProcessedIndex, false, gas, tx.origin);
    }
    
    function rand() internal view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / 
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / 
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function claim() external {
		wbnbDividendTracker.processAccount(payable(msg.sender), false);
		busdDividendTracker.processAccount(payable(msg.sender), false);
    }
    function getLastWrappedBNBDividendProcessedIndex() external view returns(uint256) {
    	return wbnbDividendTracker.getLastProcessedIndex();
    }
    
    function getLastBusdDividendProcessedIndex() external view returns(uint256) {
    	return busdDividendTracker.getLastProcessedIndex();
    }
    
    function getNumberOfWrappedBNBDividendTokenHolders() external view returns(uint256) {
        return wbnbDividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfBusdDividendTokenHolders() external view returns(uint256) {
        return busdDividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "DIGITALFIAT: Trading has not started yet");
        
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        
        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(
                amount <= maxBuyTranscationAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
        } else if (
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;
                
                if (marketingEnabled) {
                    uint256 swapTokens = contractTokenBalance.div(totalFees).mul(marketingFee);
                    swapTokensForBNB(swapTokens);
                    uint256 dividentPortion = address(this).balance.div(10**2).mul(50);
                    uint256 marketingPortion = address(this).balance.sub(dividentPortion);
                    transferToWallet(payable(marketingWallet), marketingPortion);
                    transferToWallet(payable(divident), dividentPortion);
                }
                
                if (buyBackAndLiquifyEnabled) {
                    uint256 buyBackOrLiquidity = rand();
                    if (buyBackOrLiquidity <= 50) {
                        uint256 buyBackBalance = address(this).balance;
                        if (buyBackBalance > uint256(1 * 10**18)) {
                            buyBackAndBurn(buyBackBalance.div(10**2).mul(rand()));
                        } else {
                            uint256 swapTokens = contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee);
                            swapTokensForBNB(swapTokens);
                        }
                    } else if (buyBackOrLiquidity > 50) {
                        swapAndLiquify(contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee));
                    }
                }

                if (wbnbDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount.div(wbnbDividendRewardsFee.add(busdDividendRewardsFee)).mul(wbnbDividendRewardsFee);
                    swapAndSendWrappedBNBDividends(sellTokens.div(10**2).mul(rand()));
                }
                
                if (busdDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount.div(wbnbDividendRewardsFee.add(busdDividendRewardsFee)).mul(busdDividendRewardsFee);
                    swapAndSendBusdDividends(sellTokens.div(10**2).mul(rand()));
                }
    
                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
        	uint256 fees = amount.div(100).mul(totalFees);

            // if sell, multiply by 1.5
            if(automatedMarketMakerPairs[to]) {
                fees = fees.div(100).mul(sellFeeIncreaseFactor);
            }

        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try wbnbDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try busdDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try wbnbDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try busdDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try wbnbDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedWrappedBNBDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
	    	
	    	try busdDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedBusdDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
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

    function buyBackAndBurn(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 initialBalance = balanceOf(marketingWallet);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            marketingWallet, // Burn address
            block.timestamp.add(300)
        );
        
        uint256 swappedBalance = balanceOf(marketingWallet).sub(initialBalance);
        
        _burn(marketingWallet, swappedBalance);

        emit SwapBNBForTokens(amount, path);
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
        // generate the uniswap pair path of weth -> busd
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

    function swapAndSendWrappedBNBDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), wbnbDividendToken);
        uint256 wbnbDividends = IERC20(wbnbDividendToken).balanceOf(address(this));
        transferDividends(wbnbDividendToken, address(wbnbDividendTracker), wbnbDividendTracker, wbnbDividends);
    }
    
    function swapAndSendBusdDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), busdDividendToken);
        uint256 busdDividends = IERC20(busdDividendToken).balanceOf(address(this));
        transferDividends(busdDividendToken, address(busdDividendTracker), busdDividendTracker, busdDividends);
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

contract WrappedBNBDividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("DIGITALFIAT_WrappedBNB_Dividend_Tracker", "BCDT", 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47) {
    	claimWait = 60;
        minimumTokenBalanceForDividends = 100000 * (10**18); //must hold 100000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "DIGITALFIAT_WrappedBNB_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "DIGITALFIAT_WrappedBNB_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main DIGITALFIAT contract.");
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
        require(newClaimWait != claimWait, "DIGITALFIAT_WrappedBNB_Dividend_Tracker: Cannot update claimWait to same value");
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

contract BusdDividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("DIGITALFIAT_Busd_Dividend_Tracker", "BBDT", 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) {
    	claimWait = 60;
        minimumTokenBalanceForDividends = 100000 * (10**18); //must hold 100000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "DIGITALFIAT_Busd_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "DIGITALFIAT_Busd_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main DIGITALFIAT contract.");
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
        require(newClaimWait != claimWait, "DIGITALFIAT_Busd_Dividend_Tracker: Cannot update claimWait to same value");
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