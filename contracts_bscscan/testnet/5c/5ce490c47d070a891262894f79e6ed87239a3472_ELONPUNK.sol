// SPDX-License-Identifier: MIT

// $ELONPUNK proposes an innovative feature in its contract.
//
// DIVIDEND YIELD PAID IN BNB! With the auto-claim feature,
// simply hold $ELONPUNK and you'll receive BNB automatically in your wallet.
// 
// Hold ELONPUNK and get rewarded in BNB on every transaction!
//
// 📱 Telegram: https://t.me/ElonPunk/
// 🌎 Website: https://elonpunk.xyz/

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./Marketable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract ELONPUNK is ERC20, Ownable, Marketable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public immutable bounceFixedSaleWallet;

    bool private swapping;

    ELONPUNKDividendTracker public dividendTracker;

    address public liquidityWallet;

    uint256 public maxSellTransactionAmount = 1000000000 * (10**9);
    uint256 public swapTokensAtAmount = 20000000 * (10**9);
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public immutable BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD

    address public immutable buybackWalletAddress = address(0xFb87692f896eb34C28925848371BDd18cfeE3a61);

    mapping(address => bool) public _isBlacklisted;

    uint256 public BNBBuyRewardsFee;
    uint256 public liquidityBuyFee;
    uint256 public marketingBuyFee;
    uint256 public buybackBuyFee;

    uint256 public BNBSellRewardsFee;
    uint256 public liquiditySellFee;
    uint256 public marketingSellFee;
    uint256 public buybackSellFee;
    
    uint256 public totalBuyFees;
    uint256 public totalSellFees;
    

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

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

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


    constructor() public ERC20("ElonPunk", "ElonPunk") {

        // Buy Tokenomics
        uint256 _BNBBuyRewardsFee = 2;
        uint256 _liquidityBuyFee = 3;
        uint256 _marketingBuyFee = 2;
        uint256 _buybackBuyFee = 2;

        BNBBuyRewardsFee = _BNBBuyRewardsFee;
        liquidityBuyFee = _liquidityBuyFee;
        marketingBuyFee = _marketingBuyFee;
        buybackBuyFee = _buybackBuyFee;
        totalBuyFees = _BNBBuyRewardsFee.add(_liquidityBuyFee).add(_marketingBuyFee).add(_buybackBuyFee);

        // Sell Tokenomics
        uint256 _BNBSellRewardsFee = 5;
        uint256 _liquiditySellFee = 2;
        uint256 _marketingSellFee = 4;
        uint256 _buybackSellFee = 4;
        
        BNBSellRewardsFee = _BNBSellRewardsFee;
        liquiditySellFee = _liquiditySellFee;
        marketingSellFee = _marketingSellFee;
        buybackSellFee = _buybackSellFee;
        totalSellFees = _BNBSellRewardsFee.add(_liquiditySellFee).add(_marketingSellFee).add(_buybackSellFee);
        
    	dividendTracker = new ELONPUNKDividendTracker();

    	liquidityWallet = owner();
        
        //Address for PancakeSwap
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        address _bounceFixedSaleWallet = 0xDABB51D119552166aa8a87C54a16C1C049c231Cf;
        bounceFixedSaleWallet = _bounceFixedSaleWallet;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(_bounceFixedSaleWallet);
        dividendTracker.excludeFromDividends(deadWallet);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        //100 Billion
        _mint(owner(), 100000000000 * (10**9));
    }

    receive() external payable {

  	}

    function updateMaxSellTransactionAmount(uint newValue) public onlyOwner {
        require(newValue>=0, "ELONPUNK: The new maxSellTransaction amount should be greater than or equal to zero");
        emit UpdateMaxSellTransactionAmount(newValue, maxSellTransactionAmount);
        maxSellTransactionAmount = newValue;
    }

    function updateSellFeesIncreaseFactor(uint256 newSellingFees) public onlyOwner {
        require(newSellingFees>=0, "ELONPUNK: New Selling fees should be greater than 0");
        emit UpdateSellFeesIncreaseFactor(newSellingFees, sellFeeIncreaseFactor);
        sellFeeIncreaseFactor = newSellingFees;
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "ELONPUNK: The dividend tracker already has that address");

        ELONPUNKDividendTracker newDividendTracker = ELONPUNKDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "ELONPUNK: The new dividend tracker must be owned by the ELONPUNK token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(deadWallet);

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "ELONPUNK: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "ELONPUNK: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setBNBBuyRewardsFee(uint256 value) external onlyOwner{
        BNBBuyRewardsFee = value;
        totalBuyFees = BNBBuyRewardsFee.add(liquidityBuyFee).add(marketingBuyFee).add(buybackBuyFee);
    }

    function setBNBSellRewardsFee(uint256 value) external onlyOwner{
        BNBSellRewardsFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setLiquidityBuyFee(uint256 value) external onlyOwner{
        liquidityBuyFee = value;
        totalBuyFees = BNBBuyRewardsFee.add(liquidityBuyFee).add(marketingBuyFee).add(buybackBuyFee);
    }

    function setLiquiditySellFee(uint256 value) external onlyOwner{
        liquiditySellFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setMarketingBuyFee(uint256 value) external onlyOwner{
        marketingBuyFee = value;
        totalBuyFees = BNBBuyRewardsFee.add(liquidityBuyFee).add(marketingBuyFee).add(buybackBuyFee);
    }

    function setMarketingSellFee(uint256 value) external onlyOwner{
        marketingSellFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setBuybackBuyFee(uint256 value) external onlyOwner{
        buybackBuyFee = value;
        totalBuyFees = BNBBuyRewardsFee.add(liquidityBuyFee).add(marketingBuyFee).add(buybackBuyFee);
    }

    function setBuybackSellFee(uint256 value) external onlyOwner{
        buybackSellFee = value;
        totalSellFees = BNBSellRewardsFee.add(liquiditySellFee).add(marketingSellFee).add(buybackSellFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "ELONPUNK: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "ELONPUNK: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "ELONPUNK: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "ELONPUNK: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "ELONPUNK: Cannot update gasForProcessing to same value");
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
            from != liquidityWallet &&
            to != liquidityWallet
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
                
                //buyback
                uint256 buybackTokens = contractTokenBalance.mul(buybackBuyFee).div(totalBuyFees);
                swapAndSendToFeeBuyback(buybackTokens);

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
        IERC20(BUSD).transfer(marketingWalletAddress(), newBalance);
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
            liquidityWallet,
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

contract ELONPUNKDividendTracker is DividendPayingToken, Ownable {
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

    constructor() public DividendPayingToken("ELONPUNK_Dividend_Tracker", "ELONPUNK_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 1000000 * (10**9); //must hold 1000000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "ELONPUNK_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "ELONPUNK_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ELONPUNK contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "ELONPUNK_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "ELONPUNK_Dividend_Tracker: Cannot update claimWait to same value");
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