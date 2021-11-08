// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract SWEETSHIBA is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;

    SWEETSHIBADividendTracker public dividendTracker;

    uint256 public maxSellTransactionAmount = 1000000000 * (10**18);
    uint256 public swapTokensAtAmount = 200000 * (10**18);
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public immutable BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD

    address public immutable buybackWalletAddress = address(0x6824045D2809BC9f47E8F744C16298047066b64e);
    address public immutable marketingWalletAddress = address(0x88d200c7f22e8ffF163c92CD086648a6d09B716F);

    mapping(address => bool) public _isBlacklisted;

    uint256 public BNBBuyRewardsFee;
    uint256 public liquidityBuyFee;
    uint256 public marketingBuyFee;

    uint256 public BNBSellRewardsFee;
    uint256 public liquiditySellFee;
    uint256 public marketingSellFee;
    uint256 public buybackSellFee;
    
    uint256 public totalBuyFees;
    uint256 public totalSellFees;

    //Max Cap
    uint256 public maxBNBRewards = 10;
    uint256 public maxLiquidityFee = 10;
    uint256 public maxMarketingFee = 10;
    uint256 public maxBuybackFee = 10;
    

    // sellTax = (totalSellFees * sellFeesIncreaseFactor)/100 - totalSellFees
    // sells have fees of 0% initally
    uint256 public sellFeeIncreaseFactor = 100;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;


    /*   Fixed Sale   */

    // timestamp for when purchases on the fixed-sale are available to early participants
    uint256 public immutable fixedSaleStartTimestamp = 1623960000; //June 17, 20:00 UTC, 2021

    // the fixed-sale will be open to the public 10 minutes after fixedSaleStartTimestamp,
    // or after 600 buys, whichever comes first.
    uint256 public immutable fixedSaleEarlyParticipantDuration = 600;
    uint256 public immutable fixedSaleEarlyParticipantBuysThreshold = 600;

    // track number of buys. once this reaches fixedSaleEarlyParticipantBuysThreshold,
    // the fixed-sale will be open to the public even if it's still in the first 10 minutes
    uint256 public numberOfFixedSaleBuys;
    // track who has bought
    mapping (address => bool) public fixedSaleBuyers;

    /******************/



    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public immutable tradingEnabledTimestamp = 1623967200; //June 17, 22:00 UTC, 2021

    // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateSellFeesIncreaseFactor(uint newSellingFees, uint sellFeeIncreaseFactor);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    event UpdateMaxSellTransactionAmount(uint newMaxSellTransactionAmount, uint oldMaxSellTransactionAmount);


    constructor() public ERC20("SweetShiba", "Swiba") {

        // Buy Tokenomics
        uint256 _BNBBuyRewardsFee = 1;
        uint256 _liquidityBuyFee = 4;
        uint256 _marketingBuyFee = 3;

        BNBBuyRewardsFee = _BNBBuyRewardsFee;
        liquidityBuyFee = _liquidityBuyFee;
        marketingBuyFee = _marketingBuyFee;
        totalBuyFees = _BNBBuyRewardsFee.add(_liquidityBuyFee).add(_marketingBuyFee);

        // Sell Tokenomics
        uint256 _BNBSellRewardsFee = 1;
        uint256 _liquiditySellFee = 8;
        uint256 _marketingSellFee = 2;
        uint256 _buybackSellFee = 3;
        
        BNBSellRewardsFee = _BNBSellRewardsFee;
        liquiditySellFee = _liquiditySellFee;
        marketingSellFee = _marketingSellFee;
        buybackSellFee = _buybackSellFee;
        totalSellFees = _BNBSellRewardsFee.add(_liquiditySellFee).add(_marketingSellFee).add(_buybackSellFee);
        
    	dividendTracker = new SWEETSHIBADividendTracker();
        
        //Address for PancakeSwap
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(deadWallet);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        //1 Billion
        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateMaxSellTransactionAmount(uint newValue) public onlyOwner {
        require(newValue>=0, "SweetShiba: The new maxSellTransaction amount should be greater than or equal to zero");
        emit UpdateMaxSellTransactionAmount(newValue, maxSellTransactionAmount);
        maxSellTransactionAmount = newValue * (10**18);
    }

    function updateSellFeesIncreaseFactor(uint256 newSellingFees) public onlyOwner {
        require(newSellingFees>=0, "SweetShiba: New Selling fees should be greater than 0");
        emit UpdateSellFeesIncreaseFactor(newSellingFees, sellFeeIncreaseFactor);
        sellFeeIncreaseFactor = newSellingFees;
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "SweetShiba: The dividend tracker already has that address");

        SWEETSHIBADividendTracker newDividendTracker = SWEETSHIBADividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "SweetShiba: The new dividend tracker must be owned by the SweetShiba token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(deadWallet);

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "SweetShiba: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "SweetShiba: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setBNBBuyRewardsFee(uint256 value) external onlyOwner {
        require(value<=maxBNBRewards, "SweetShiba: The new setBNBBuyRewardsFee amount should be lesser than or equal to maxBNBRewards");
        BNBBuyRewardsFee = value;
        totalBuyFees = BNBBuyRewardsFee.add(liquidityBuyFee).add(marketingBuyFee);
    }

    function setBNBSellRewardsFee(uint256 value) external onlyOwner {
        require(value<=maxBNBRewards, "SweetShiba: The new setBNBSellRewardsFee amount should be lesser than or equal to maxBNBRewards");
        BNBSellRewardsFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setLiquidityBuyFee(uint256 value) external onlyOwner {
        require(value<=maxLiquidityFee, "SweetShiba: The new setLiquidityBuyFee amount should be lesser than or equal to maxLiquidityFee");
        liquidityBuyFee = value;
        totalBuyFees = BNBBuyRewardsFee.add(liquidityBuyFee).add(marketingBuyFee);
    }

    function setLiquiditySellFee(uint256 value) external onlyOwner {
        require(value<=maxLiquidityFee, "SweetShiba: The new setLiquiditySellFee amount should be lesser than or equal to maxLiquidityFee");
        liquiditySellFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setMarketingBuyFee(uint256 value) external onlyOwner {
        require(value<=maxMarketingFee, "SweetShiba: The new setMarketingBuyFee amount should be lesser than or equal to maxMarketingFee");
        marketingBuyFee = value;
        totalBuyFees = BNBBuyRewardsFee.add(liquidityBuyFee).add(marketingBuyFee);
    }

    function setMarketingSellFee(uint256 value) external onlyOwner {
        require(value<=maxMarketingFee, "SweetShiba: The new setMarketingSellFee amount should be lesser than or equal to maxMarketingFee");
        marketingSellFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setBuybackSellFee(uint256 value) external onlyOwner {
        require(value<=maxBuybackFee, "SweetShiba: The new setBuybackSellFee amount should be lesser than or equal to maxBuybackFee");
        buybackSellFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "SweetShiba: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "SweetShiba: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "SweetShiba: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "SweetShiba: Cannot update gasForProcessing to same value");
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
        return _isExcludedFromFees[account];
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
		dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        //Check for maxSellTransactionAmount
        if( 
        	!swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            //if sell
            if(automatedMarketMakerPairs[to]) {
                //marketing
                uint256 marketingTokens = contractTokenBalance.mul(marketingSellFee).div(totalSellFees);
                swapAndSendToFeeMarketing(marketingTokens);
                
                //buyback
                uint256 buybackTokens = contractTokenBalance.mul(buybackSellFee).div(totalSellFees);
                swapAndSendToFeeBuyback(buybackTokens);

                //liquidity
                uint256 swapTokens = contractTokenBalance.mul(liquiditySellFee).div(totalSellFees);
                swapAndLiquify(swapTokens);
            }

            //else buy
            else {
                //marketing
                uint256 marketingTokens = contractTokenBalance.mul(marketingBuyFee).div(totalBuyFees);
                swapAndSendToFeeMarketing(marketingTokens);

                //liquidity
                uint256 swapTokens = contractTokenBalance.mul(liquidityBuyFee).div(totalBuyFees);
                swapAndLiquify(swapTokens); 
            }
            
            //dividends
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees;
            //if sell
            if(automatedMarketMakerPairs[to]) {
                fees = amount.mul(totalSellFees).div(100);

                // if sell, multiply by sellFeeIncreaseFactor/100
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }
            //else buy
            else {
                fees = amount.mul(totalBuyFees).div(100);
            }

        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
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

    function swapAndSendToFeeMarketing(uint256 tokens) private  {
        uint256 initialBUSDBalance = IERC20(BUSD).balanceOf(address(this));

        swapTokensForBUSD(tokens);
        uint256 newBalance = (IERC20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
        IERC20(BUSD).transfer(marketingWalletAddress, newBalance);
    }

    function swapAndSendToFeeBuyback(uint256 tokens) private  {
        uint256 initialBUSDBalance = IERC20(BUSD).balanceOf(address(this));

        swapTokensForBUSD(tokens);
        uint256 newBalance = (IERC20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
        IERC20(BUSD).transfer(buybackWalletAddress, newBalance);
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
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

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
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function swapTokensForBUSD(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BUSD;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }
}

contract SWEETSHIBADividendTracker is DividendPayingToken, Ownable {
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

    constructor() public DividendPayingToken("SWEETSHIBA_Dividend_Tracker", "SWEETSHIBA_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 1000000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "SweetShiba_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "SweetShiba_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main SweetShiba contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "SweetShiba_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "SweetShiba_Dividend_Tracker: Cannot update claimWait to same value");
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