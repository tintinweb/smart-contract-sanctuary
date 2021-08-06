// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract RZEToken is ERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public _dividendToken = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43; // DOGE
   
    bool private swapping;
    bool public tradingIsEnabled = true;
    bool public buyBackEnabled = false;
    bool public buyBackRandomEnabled = true;

    RZEDividendTracker public dividendTracker;
    
    uint256 public marketingDivisor = 30;
    
    uint256 public _buyBackMultiplier = 100;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    
    address public presaleAddress = address(0);
    
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event BuyBackEnabledUpdated(bool enabled);
    event BuyBackRandomEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event FeesEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event BuyBackWalletUpdated(address indexed newBuyBackWallet, address indexed oldBuyBackWallet);
    // event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    // event charityWalletUpdated(address indexed newCharityWallet, address indexed oldCharityWallet);
    // event partyWalletUpdated(address indexed newPartyWallet, address indexed oldPartyWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    
    constructor() ERC20("RIZE ABOVE EVOLUTION", "RZE") {
        
        _reflectedBalances[owner()] = _reflectedSupply;
        
        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));
        
        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
        
        dividendTracker = new RZEDividendTracker();
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //
      // 0x10ED43C718714eb63d5aA57B78B54704E256024E
      
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        

        // exclude from paying fees or having max transaction amount
        excludeFromFees(buyBackWallet, true);
        excludeFromFees(address(this), true);
        
        // exclude the pair address from rewards - we don't want to redistribute
        // tx fees to these two; redistribution is only for holders, dah!
        _exclude(_uniswapV2Pair);
        _exclude(deadAddress);

    }

    receive() external payable {

  	}
  	

  	function whitelistDxSale(address _presaleAddress, address _routerAddress) public onlyOwner {
  	    presaleAddress = _presaleAddress;
        dividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

        dividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}
  	
  	
  	function prepareForPreSale() external onlyOwner {
        takeFee = false;
        isInPresale = true;
        dividendRewardsFee = 0;
        buyBackFee = 0;
        marketingFee = 0;
        charityFee = 0;
        partyFee = 0;
        rfiFee = 0;
        maxTransactionAmount = 690000000 * (10**18);
        maxWalletBalance = 690000000 * (10**18);
    }
    
    function afterPreSale() external onlyOwner {
        takeFee = true;
        isInPresale = false;
        dividendRewardsFee = 4;
        buyBackFee = 5;
        marketingFee = 1;
        charityFee = 1;
        partyFee = 1;
        rfiFee = 2;
        maxTransactionAmount= 40142 * (10**18);
        maxWalletBalance= 4014201 * (10**18);
    }
    
    function setTradingIsEnabled(bool _enabled) public onlyOwner {
        tradingIsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    
    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function setBuyBackRandomEnabled(bool _enabled) public onlyOwner {
        buyBackRandomEnabled = _enabled;
        emit BuyBackRandomEnabledUpdated(_enabled);
    }
    
    function triggerBuyBack(uint256 amount) public onlyOwner {
        require(!swapping, "RZE: A swapping process is currently running, wait till that is complete");
        
        uint256 buyBackBalance = address(this).balance;
        swapBNBForTokens(buyBackBalance.div(10**2).mul(amount));
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "RZE: The dividend tracker already has that address");

        RZEDividendTracker newDividendTracker = RZEDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "RZE: The new dividend tracker must be owned by the FLOKIBUSD token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }
    
    function updateDividendRewardFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "RZE: Dividend reward tax must be between 0 and 10");
        dividendRewardsFee = newFee;
    }
    
    function updateBuyBackFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "RZE: Buy Back Fee must be between 0 and 10");
        buyBackFee = newFee;
    }
    
    function updateRfiFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "RZE: RFI Fee must be between 0 and 10");
        rfiFee = newFee;
    }
    
    function updateMarketingFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "RZE: Marketing Fee must be between 0 and 10");
        marketingFee = newFee;
    }
    
    function updateCharityFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "RZE: Charity Fee must be between 0 and 10");
        charityFee = newFee;
    }
    
    function updatePartyFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "RZE: Party Fee must be between 0 and 10");
        partyFee = newFee;
    }
    

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "RZE: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "RZE: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "RZE: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "RZE: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateBuyBackWallet(address newBuyBackWallet) public onlyOwner {
        require(newBuyBackWallet != buyBackWallet, "RZE: The buy back wallet is already this address");
        excludeFromFees(newBuyBackWallet, true);
        buyBackWallet = newBuyBackWallet;
        emit BuyBackWalletUpdated(newBuyBackWallet, buyBackWallet);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "RZE: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "RZE: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }
    
    function rand() public view returns(uint256) {
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

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function _beforeTokenTransfer(address sender, address , uint256 , bool ) internal override {
        if ( !isInPresale ){
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
        if (!swapping && canSwap) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance.mul(buyBackFee).div(totalFees);
            swapTokensForBNB(swapTokens);
            transferToBuyBackWallet(payable(buyBackWallet), address(this).balance.div(10**2).mul(marketingDivisor));
                
            uint256 buyBackBalance = address(this).balance;
            if (buyBackEnabled && buyBackBalance > uint256(1 * 10**18)) {
                swapBNBForTokens(buyBackBalance.div(10**2).mul(rand()));
                }
                
                
            if (_dividendToken == uniswapV2Router.WETH()) {
                uint256 sellTokens = balanceOf(address(this));
                swapAndSendDividendsInBNB(sellTokens);
                } else {
                uint256 sellTokens = balanceOf(address(this));
                swapAndSendDividends(sellTokens);
                }
                
                swapping = false;
            }
        }
    }
    
     function _takeTransactionFees(address sender, address recipient, uint256 amount, uint256 currentRate) internal override {
        
        if( isInPresale ){ return; }
        
        	uint256 fees = amount.div(100).mul(totalFees);
        	uint256 newMarketing;
        	uint256 newParty;

            // take fees for selling
            if(automatedMarketMakerPairs[recipient]) {
                fees = amount.div(100).mul(sellersTotalFees);
                newMarketing = 2;
                newParty = partyFee;
            }
            // take fees for buying
            if(automatedMarketMakerPairs[sender]) { 
               fees = amount.div(100).mul(totalFees);
               newMarketing = marketingFee;
               newParty = 0;
            }
            
            // rfiFee
            _redistribute( amount, currentRate, rfiFee);
            
            // marketing
            _takeFee( amount, currentRate, newMarketing, marketingWallet);
            
            // marketing
            _takeFee( amount, currentRate, dividendRewardsFee, address(this));
            
            // Buy back
            _takeFee( amount, currentRate, buyBackFee, address(this));
            
            // Charity
            _takeFee( amount, currentRate, charityFee, charityWallet);
            
            // party
            if(newParty > 0){
 
            _takeFee( amount, currentRate, partyFee, partyWallet); 
            }
            
     }
     
     function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient) private {

        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

         _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    
    function _getSumOfFees(address sender, uint256 amount) internal view override returns (uint256){ 
        return amount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled, "ERC20: Trading has to be enabled");
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if (
            automatedMarketMakerPairs[to] &&
            automatedMarketMakerPairs[from] &&
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFee[to] && //no max for those excluded from fees
            !_isExcludedFromFee[from] 
        ) {
            require(amount <= maxTransactionAmount, "Transfer amount exceeds the Max Transaction Amount.");
            
        }
        
        if ( maxWalletBalance > 0 && !_isExcludedFromFee[to] && !_isExcludedFromFee[from] && to != address(uniswapV2Pair) ){
                uint256 recipientBalance = balanceOf(to);
                require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
            }
 
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
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
    
    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }

    function swapTokensForDividendToken(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of weth -> busd
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of dividend token
            path,
            recipient,
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this));
        uint256 dividends = IERC20(_dividendToken).balanceOf(address(this));
        bool success = IERC20(_dividendToken).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function swapAndSendDividendsInBNB(uint256 tokens) private {
        uint256 currentBNBBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 newBNBBalance = address(this).balance;
        
        uint256 dividends = newBNBBalance.sub(currentBNBBalance);
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        
        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function transferToBuyBackWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
}


contract RZEDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("RZE_Dividend_Tracker", "RZE_Dividend_Tracker") {
    	claimWait = 86400; // every 24 hours
        minimumTokenBalanceForDividends = 32000  * (10**18); //must hold 32000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "RZE_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "RZE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main RZE contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "RZE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "RZE_Dividend_Tracker: Cannot update claimWait to same value");
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
    function _takeTransactionFees(address sender, address recipient, uint256 amount, uint256 currentRate) internal override {}
    function _getSumOfFees(address sender, uint256 amount) internal view override returns (uint256){ 
        return amount;
    }
    function _beforeTokenTransfer(address sender, address , uint256 , bool ) internal override {}
}