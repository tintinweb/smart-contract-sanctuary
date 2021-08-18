/*
*  __ __  ____  ______   ____  _      ____  __  _      ____    ____  __  _   ____  ___ ___   ___   ______   ___  
* |  |  ||    ||      | /    || |    |    ||  |/ ]    |    \  /    ||  |/ ] /    ||   |   | /   \ |      | /   \ 
* |  |  | |  | |      ||  o  || |     |  | |  ' /     |  _  ||  o  ||  ' / |  o  || _   _ ||     ||      ||     |
* |  |  | |  | |_|  |_||     || |___  |  | |    \     |  |  ||     ||    \ |     ||  \_/  ||  O  ||_|  |_||  O  |
* |  :  | |  |   |  |  |  _  ||     | |  | |     \    |  |  ||  _  ||     \|  _  ||   |   ||     |  |  |  |     |
*  \   /  |  |   |  |  |  |  ||     | |  | |  .  |    |  |  ||  |  ||  .  ||  |  ||   |   ||     |  |  |  |     |
*   \_/  |____|  |__|  |__|__||_____||____||__|\_|    |__|__||__|__||__|\_||__|__||___|___| \___/   |__|   \___/ 
*                                                                                                              
* WEBSITE: www.vitaliknakamoto.io
*
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './Context.sol';
import './Ownable.sol';
import './IERC20.sol';
import './ERC20.sol';
import './IDividendPayingToken.sol';
import './IDividendPayingTokenOptional.sol';
import './DividendPayingToken.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router01.sol';
import './IUniswapV2Router02.sol';
import './IterableMapping.sol';
import './SafeMath.sol';
import './SafeMathInt.sol';
import './SafeMathUint.sol';

contract VitalikNakamoto is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public ethDividendToken;
    address public btcDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackAndLiquifyEnabled = false;
    bool public ethDividendEnabled = false;
    bool public btcDividendEnabled = false;

    EthDividendTracker private ethDividendTracker;
    BtcDividendTracker private btcDividendTracker;

    address private VTC_p;
    
    uint256 public maxBuyTranscationAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken; 

    uint256 public ethDividendRewardsFee;
    uint256 public previousEthDividendRewardsFee;
    uint256 public btcDividendRewardsFee;
    uint256 public previousBtcDividendRewardsFee;
    uint256 public burnFee;
    uint256 public previousburnFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 public totalFees;

    uint256 public sellFeeIncreaseFactor = 130;

    uint256 public gasForProcessing = 600000;
    
    address public presaleAddress;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateethDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdatebtcDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event EthDividendEnabledUpdated(bool enabled);
    event BtcDividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event VTC_pUpdated(address indexed newVTC_p, address indexed oldVTC_p);

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

    event ProcessedEthDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    event ProcessedBtcDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor(
        address _burnAddress
        ) ERC20("Vitalik Nakamoto Coin", "VTC") {
        VTC_p = _burnAddress;
    	ethDividendTracker = new EthDividendTracker();
    	btcDividendTracker = new BtcDividendTracker();

    	ethDividendToken = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
        btcDividendToken = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        excludeFromDividend(address(ethDividendTracker));
        excludeFromDividend(address(btcDividendTracker));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(VTC_p, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {

  	}

  	function ConfigPresale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        ethDividendTracker.excludeFromDividends(_presaleAddress);
        btcDividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

        ethDividendTracker.excludeFromDividends(_routerAddress);
        btcDividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}

  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    ethDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        btcDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}
  	
  	function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxBuyTranscationAmount = _maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
  	    maxSellTransactionAmount = _maxTxn * (10**18);
  	}
  	
  	function updateBtcDividendToken(address _newContract) external onlyOwner {
  	    btcDividendToken = _newContract;
  	    btcDividendTracker.setDividendTokenAddress(_newContract);
  	}
  	
  	function updateEthDividendToken(address _newContract) external onlyOwner {
  	    ethDividendToken = _newContract;
  	    ethDividendTracker.setDividendTokenAddress(_newContract);
  	}
  	
	
  	function updateVTC_p(address _newWallet) external onlyOwner {
  	    require(_newWallet != VTC_p, "VitalikNakamoto: Already this address");
        excludeFromFees(_newWallet, true);
        emit VTC_pUpdated(VTC_p, _newWallet);
  	    VTC_p = _newWallet;
  	}
  	
  	function setMaxWalletTokend(uint256 _maxToken) external onlyOwner {
  	    maxWalletToken = _maxToken * (10**18);
  	}
  	
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
  	    swapTokensAtAmount = _swapAmount * (10**18);
  	}
  	
  	function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner {
  	    sellFeeIncreaseFactor = _multiplier;
  	}

    function afterPreSale() external onlyOwner {
        ethDividendRewardsFee = 5;
        btcDividendRewardsFee = 5;
        burnFee = 2;
        buyBackAndLiquidityFee = 3;
        totalFees = 15;
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        ethDividendEnabled = true;
        btcDividendEnabled = true;
        swapTokensAtAmount = 20000000 * (10**18);
        maxBuyTranscationAmount = 100000000 * (10**18);
        maxSellTransactionAmount = 3000000 * (10**18);
        maxWalletToken = 100000000 * (10**18);
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
            totalFees = buyBackAndLiquidityFee.add(burnFee).add(btcDividendRewardsFee).add(ethDividendRewardsFee);
            buyBackAndLiquifyEnabled = _enabled;
        }
        
        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setEthDividendEnabled(bool _enabled) external onlyOwner {
        require(ethDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousEthDividendRewardsFee = ethDividendRewardsFee;
            ethDividendRewardsFee = 0;
            ethDividendEnabled = _enabled;
        } else {
            ethDividendRewardsFee = previousEthDividendRewardsFee;
            totalFees = ethDividendRewardsFee.add(burnFee).add(btcDividendRewardsFee).add(buyBackAndLiquidityFee);
            ethDividendEnabled = _enabled;
        }

        emit EthDividendEnabledUpdated(_enabled);
    }
    
    function setBtcDividendEnabled(bool _enabled) external onlyOwner {
        require(btcDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBtcDividendRewardsFee = btcDividendRewardsFee;
            btcDividendRewardsFee = 0;
            btcDividendEnabled = _enabled;
        } else {
            btcDividendRewardsFee = previousBtcDividendRewardsFee;
            totalFees = btcDividendRewardsFee.add(burnFee).add(ethDividendRewardsFee).add(buyBackAndLiquidityFee);
            btcDividendEnabled = _enabled;
        }

        emit BtcDividendEnabledUpdated(_enabled);
    }
    
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousburnFee = burnFee;
            burnFee = 0;
            marketingEnabled = _enabled;
        } else {
            burnFee = previousburnFee;
            totalFees = burnFee.add(btcDividendRewardsFee).add(ethDividendRewardsFee).add(buyBackAndLiquidityFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateethDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(ethDividendTracker), "VitalikNakamoto: The dividend tracker already has that address");

        EthDividendTracker newEthDividendTracker = EthDividendTracker(payable(newAddress));

        require(newEthDividendTracker.owner() == address(this), "VitalikNakamoto: The new dividend tracker must be owned by the VitalikNakamoto token contract");

        newEthDividendTracker.excludeFromDividends(address(newEthDividendTracker));
        newEthDividendTracker.excludeFromDividends(address(this));
        newEthDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newEthDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateethDividendTracker(newAddress, address(ethDividendTracker));

        ethDividendTracker = newEthDividendTracker;
    }
    
    function updatebtcDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(btcDividendTracker), "VitalikNakamoto: The dividend tracker already has that address");

        BtcDividendTracker newBtcDividendTracker = BtcDividendTracker(payable(newAddress));

        require(newBtcDividendTracker.owner() == address(this), "VitalikNakamoto: The new dividend tracker must be owned by the VitalikNakamoto token contract");

        newBtcDividendTracker.excludeFromDividends(address(newBtcDividendTracker));
        newBtcDividendTracker.excludeFromDividends(address(this));
        newBtcDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newBtcDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdatebtcDividendTracker(newAddress, address(btcDividendTracker));

        btcDividendTracker = newBtcDividendTracker;
    }
    
    function updateEthDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= 20, "VitalikNakamoto: Fee must be less than 20%");
        ethDividendRewardsFee = newFee;
        totalFees = ethDividendRewardsFee.add(burnFee).add(btcDividendRewardsFee).add(buyBackAndLiquidityFee);
    }
    
    function updateBtcDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= 20, "VitalikNakamoto: Fee must be less than 20%");
        btcDividendRewardsFee = newFee;
        totalFees = btcDividendRewardsFee.add(ethDividendRewardsFee).add(burnFee).add(buyBackAndLiquidityFee);
    }
    
    function updateBurnFee(uint8 newFee) external onlyOwner {
        require(newFee <= 20, "VitalikNakamoto: Fee must be less than 20%");
        burnFee = newFee;
        totalFees = burnFee.add(ethDividendRewardsFee).add(btcDividendRewardsFee).add(buyBackAndLiquidityFee);
    }
    
    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= 20, "VitalikNakamoto: Fee must be less than 20%");
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee.add(ethDividendRewardsFee).add(btcDividendRewardsFee).add(burnFee);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "VitalikNakamoto: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "VitalikNakamoto: Account is already exluded from fees");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        ethDividendTracker.excludeFromDividends(address(account));
        btcDividendTracker.excludeFromDividends(address(account));
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "VitalikNakamoto: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "VitalikNakamoto: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            ethDividendTracker.excludeFromDividends(pair);
            btcDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "VitalikNakamoto: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
    
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        ethDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        btcDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        ethDividendTracker.updateClaimWait(claimWait);
        btcDividendTracker.updateClaimWait(claimWait);
    }

    function getEthClaimWait() external view returns(uint256) {
        return ethDividendTracker.claimWait();
    }
    
    function getBtcClaimWait() external view returns(uint256) {
        return btcDividendTracker.claimWait();
    }

    function getTotalEthDividendsDistributed() external view returns (uint256) {
        return ethDividendTracker.totalDividendsDistributed();
    }
    
    function getTotalBtcDividendsDistributed() external view returns (uint256) {
        return btcDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableEthDividendOf(address account) external view returns(uint256) {
    	return ethDividendTracker.withdrawableDividendOf(account);
  	}
  	
  	function withdrawableBtcDividendOf(address account) external view returns(uint256) {
    	return btcDividendTracker.withdrawableDividendOf(account);
  	}

	function ethDividendTokenBalanceOf(address account) external view returns (uint256) {
		return ethDividendTracker.balanceOf(account);
	}
	
	function btcDividendTokenBalanceOf(address account) external view returns (uint256) {
		return btcDividendTracker.balanceOf(account);
	}

    function getAccountEthDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return ethDividendTracker.getAccount(account);
    }
    
    function getAccountBtcDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return btcDividendTracker.getAccount(account);
    }

	function getAccountEthDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return ethDividendTracker.getAccountAtIndex(index);
    }
    
    function getAccountBtcDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return btcDividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 ethIterations, uint256 ethClaims, uint256 ethLastProcessedIndex) = ethDividendTracker.process(gas);
		emit ProcessedEthDividendTracker(ethIterations, ethClaims, ethLastProcessedIndex, false, gas, tx.origin);
		
		(uint256 btcIterations, uint256 btcClaims, uint256 btcLastProcessedIndex) = btcDividendTracker.process(gas);
		emit ProcessedBtcDividendTracker(btcIterations, btcClaims, btcLastProcessedIndex, false, gas, tx.origin);
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
		ethDividendTracker.processAccount(payable(msg.sender), false);
		btcDividendTracker.processAccount(payable(msg.sender), false);
    }
    function getLastEthDividendProcessedIndex() external view returns(uint256) {
    	return ethDividendTracker.getLastProcessedIndex();
    }
    
    function getLastBtcDividendProcessedIndex() external view returns(uint256) {
    	return btcDividendTracker.getLastProcessedIndex();
    }
    
    function getNumberOfethDividendTokenHolders() external view returns(uint256) {
        return ethDividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfbtcDividendTokenHolders() external view returns(uint256) {
        return btcDividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "VitalikNakamoto: Trading has not started yet");
        
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
                    uint256 swapTokens = contractTokenBalance.div(totalFees).mul(burnFee);
                    swapTokensForBNB(swapTokens);
                    uint256 marketingPortion = address(this).balance;
                    transferToWallet(payable(VTC_p), marketingPortion);
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

                if (ethDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount.div(ethDividendRewardsFee.add(btcDividendRewardsFee)).mul(ethDividendRewardsFee);
                    swapAndSendEthDividends(sellTokens.div(10**2).mul(rand()));
                }
                
                if (btcDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount.div(ethDividendRewardsFee.add(btcDividendRewardsFee)).mul(btcDividendRewardsFee);
                    swapAndSendBtcDividends(sellTokens.div(10**2).mul(rand()));
                }
    
                swapping = false;
            }
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

        try ethDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try btcDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try ethDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try btcDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try ethDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedEthDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
	    	
	    	try btcDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedBtcDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
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
            VTC_p,
            block.timestamp
        );
    }

    function buyBackAndBurn(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 initialBalance = balanceOf(VTC_p);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            VTC_p, // Burn address
            block.timestamp.add(300)
        );
        
        uint256 swappedBalance = balanceOf(VTC_p).sub(initialBalance);
        
        _burn(VTC_p, swappedBalance);

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

    function swapAndSendEthDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), ethDividendToken);
        uint256 ethDividends = IERC20(ethDividendToken).balanceOf(address(this));
        transferDividends(ethDividendToken, address(ethDividendTracker), ethDividendTracker, ethDividends);
    }
    
    function swapAndSendBtcDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), btcDividendToken);
        uint256 btcDividends = IERC20(btcDividendToken).balanceOf(address(this));
        transferDividends(btcDividendToken, address(btcDividendTracker), btcDividendTracker, btcDividends);
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

contract EthDividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("VitalikNakamoto_ETH_Dividend_Tracker", "VitalikNakamoto_ETH_Dividend_Tracker", 0x2170Ed0880ac9A755fd29B2688956BD959F933F8) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "VitalikNakamoto_ETH_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "VitalikNakamoto_ETH_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main VitalikNakamoto contract.");
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
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "VitalikNakamoto_ETH_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "VitalikNakamoto_ETH_Dividend_Tracker: Cannot update claimWait to same value");
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

contract BtcDividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("VitalikNakamoto_BTC_Dividend_Tracker", "VitalikNakamoto_BTC_Dividend_Tracker", 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "VitalikNakamoto_BTC_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "VitalikNakamoto_BTC_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main VitalikNakamoto contract.");
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
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "VitalikNakamoto_BTC_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "VitalikNakamoto_BTC_Dividend_Tracker: Cannot update claimWait to same value");
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