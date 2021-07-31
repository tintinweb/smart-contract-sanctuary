// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./BNBQDividendTracker.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract BNBQ is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public  deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;

    BNBQDividendTracker public dividendTracker;

    address  payable public rewardsPool;

    bool public tradingEnabled = false;

    address public liquidityWallet;

    uint256 public maxSellTransactionAmount = 1000000000 * (10**18); //
    uint256 public swapTokensAtAmount = 20000000 * (10**18); //

    uint256 public  BNBRewardsFee;
    uint256 public  liquidityFee;
    uint256 public  buyBackFee;
    uint256 public  rewardsPoolFee;

    uint256 public  totalFees = BNBRewardsFee.add(liquidityFee).add(buyBackFee).add(rewardsPoolFee);

    uint256 public buyBackUpperLimit = 1 * 10**18;
    bool public buyBackEnabled = true;
    bool public swapEnabled = false;

    uint256 public lastTransferTokenRewardsInterval = 3600; // Sending 50% of the BNB Balance to the Rewards Pool every hour so that there is no wastage of BNB.
    uint256 public lastTransferTokenRewardsTimestamp; // Checking for the last time this event has occurred.

    uint public tradingEnabledTimestamp; // Keep track of time.
    uint public buy2rewthreshold; // Adjust threshold of sending BNB

    // By default, use 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    // Exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // Stores addresses of automatic Market Maker pairs.
    // Any transfer TO these addresses could be subject to a maximum transfer amount.
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);


    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
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

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() public ERC20("BNB Qname", "BNBQ") {
        uint256 _BNBRewardsFee = 10;
        uint256 _liquidityFee = 3;
        uint256 _buyBackFee = 2;
        // Rewards Pool is to store BNB in case of low volume. This can be adjusted at a later date.
        uint256 _rewardsPoolFee = 6;

        BNBRewardsFee = _BNBRewardsFee;
        liquidityFee = _liquidityFee;
        buyBackFee = _buyBackFee;
        rewardsPoolFee = _rewardsPoolFee;

        totalFees = BNBRewardsFee.add(liquidityFee).add(buyBackFee).add(rewardsPoolFee);

    	dividendTracker = new BNBQDividendTracker();

    	liquidityWallet = owner();


    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //0x10ED43C718714eb63d5aA57B78B54704E256024E
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // Exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadAddress);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // Exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));//1000000000
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BNBQ: The dividend tracker already has that address");

        BNBQDividendTracker newDividendTracker = BNBQDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BNBQ: The new dividend tracker must be owned by the BNBQ token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BNBQ: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BNBQ: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BNBQ: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BNBQ: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    function isExcludedFromDividends(address account) external view returns(bool){
        return dividendTracker.isExcludedFromDividends(account);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "BNBQ: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BNBQ: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BNBQ: Cannot update gasForProcessing to same value");
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

    // Funciton is only used once. Can never be used again.
    function setTradingEnabled(bool value) external onlyOwner{
        require(tradingEnabled == false);
        tradingEnabled = value;
        tradingEnabledTimestamp = block.timestamp;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setBuyBackFee(uint256 value) external onlyOwner{
        buyBackFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(buyBackFee).add(rewardsPoolFee);
    }

    function setBNBRewardsFee(uint256 value) external onlyOwner{
        BNBRewardsFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(buyBackFee).add(rewardsPoolFee);
    }

    function setRewardsPool(address payable rewardsPoolAddress) external onlyOwner{
        rewardsPool = rewardsPoolAddress;
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(buyBackFee).add(rewardsPoolFee);
    }

    function setBuy2RewThreshold(uint256 newThreshold) external onlyOwner{
        buy2rewthreshold = newThreshold;
    }

    function setRewardsPoolFee(uint256 value) external onlyOwner{
        rewardsPoolFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(buyBackFee).add(rewardsPoolFee);
    }

    function setMaxSellTxAmount(uint256 amount) external onlyOwner{
        maxSellTransactionAmount = amount * 10**18;
    }

    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**18;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(!_isExcludedFromFees[from]) { require(tradingEnabled == true, 'Trading not enabled yet'); }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(
        	!swapping  &&
        	tradingEnabled &&
            automatedMarketMakerPairs[to] && // Sells only when detected Automated Market Maker Pair.
        	from != uniswapV2Pair && // Router -> Pair removes liquidity that does not have Max Amount.
            !_isExcludedFromFees[from]
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

            uint256 timeSinceLaunch = block.timestamp.sub(tradingEnabledTimestamp);
            if(timeSinceLaunch <= 1 hours && from == uniswapV2Pair && !_isExcludedFromFees[to]){
                if(timeSinceLaunch <= 10 * 1 minutes) { require(amount <= (100000000 * (10**18)), 'Amount in first 10 minutes must be less than 100k'); }
                    else if(timeSinceLaunch > 10 * 1 minutes && timeSinceLaunch <= 15 * 1 minutes) { require(amount <= (200000000 * (10**18)), 'Amount in first 15 minutes must be less than 200k'); }
                    else if(timeSinceLaunch > 15 * 1 minutes && timeSinceLaunch <= 30 * 1 minutes) { require(amount <= (400000000 * (10**18)), 'Amount in first 30 minutes must be less than 400k'); }
                    else if(timeSinceLaunch > 30 * 1 minutes && timeSinceLaunch <= 60 * 1 minutes) { require(amount <= (800000000 * (10**18)), 'Amount in first 60 minutes must be less than 800k'); }
        }


        if(block.timestamp>lastTransferTokenRewardsTimestamp.add(lastTransferTokenRewardsInterval) && address(this).balance> buy2rewthreshold) // Every hour check for funds available in BuyBack and send 50% to RewardsPool.
        {
            lastTransferTokenRewardsTimestamp=block.timestamp;
            rewardsPool.transfer(address(this).balance.div(2));
        }

	    uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= swapTokensAtAmount;
        if(swapEnabled && !swapping && from != uniswapV2Pair) {
            uint256 balance = address(this).balance;
            if(to == uniswapV2Pair){
                if (buyBackEnabled && balance > uint256(1 * 10**18)) {

                    if (balance > buyBackUpperLimit)
                        balance = buyBackUpperLimit;

                    buyBackTokens(balance.div(100));
                }
            }

           if (overMinimumTokenBalance) {
                contractTokenBalance = swapTokensAtAmount;
                swapAndLiquify(contractTokenBalance);
           }

        }


        bool takeFee = true;

        // If an account belongs to _isExcludedFromFee, this ensures that is removes the fee.
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	uint256 rawFee = 0;
            if(automatedMarketMakerPairs[to]) {
                uint256 timePasses = block.timestamp.sub(tradingEnabledTimestamp);
                // Increase fees to 10% for all sales during firsts 3 hours.
                if(timePasses <= 3 * 1 hours) { rawFee = rawFee.add(amount.mul(10).div(100)); }
               else { rawFee = rawFee.add(amount.mul(5).div(100)); }
            }
        	amount = amount.sub(fees).sub(rawFee);
        	if(rawFee > 0 && swapEnabled){
        	    swapAndSendToReward(rawFee);
        	}

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

    function swapBuyBackTokens(uint256 tokens) private lockTheSwap{
        swapTokensForEth(tokens);
    }

    function buyBackTokens(uint256 amount) private lockTheSwap{
    	if (amount > 0) {
    	    swapETHForTokens(amount);
	    }
    }

    function swapETHForTokens(uint256 amount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // Create the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of Tokens
            path,
            deadAddress,
            block.timestamp.add(300)
        );
        emit SwapETHForTokens(amount, path);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // Split the contract balance into halves
        uint256 denominator=totalFees.mul(2);
        uint256 tokensToAddLiquidityWith = contractTokenBalance.mul(liquidityFee).div(denominator);
        uint256 toSwap = contractTokenBalance.sub(tokensToAddLiquidityWith);

        // Capture the contract's current BNB balance.
        // This is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // Swap tokens for BNB
        swapTokensForEth(toSwap);

        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(denominator.sub(liquidityFee));
        uint256 bnbToAddLiquidityWith = unitBalance.mul(liquidityFee);

        // Add liquidity to PancakeSwap Router
        addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);

        // Send BNB to rewardsPool
        uint256 rewardBNB = unitBalance.mul(2).mul(rewardsPoolFee);
        rewardsPool.transfer(rewardBNB);

        // Send BNB to dividendTracker
        uint256 dividends = unitBalance.mul(2).mul(BNBRewardsFee);
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		emit SendDividends(toSwap.sub(tokensToAddLiquidityWith), dividends);
        }

        // Remaining BNB IS stored in the contract balance to execute BuyBack

    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );

    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function swapAndSendToReward(uint256 tokensAmt) private lockTheSwap{
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensAmt);
        uint256 rewardBNB = address(this).balance.sub(initialBalance);
        rewardsPool.transfer(rewardBNB);
    }

    function manualSendFromBuybackToRewardsPool(uint256 weiAmount) external onlyOwner{
        require(address(this).balance>=weiAmount);
        rewardsPool.transfer(weiAmount);
    }

}