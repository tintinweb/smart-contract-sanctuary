// SPDX-License-Identifier: MIT

//
// DIVIDEND YIELD PAID IN Matic and MST! With the auto-claim feature,
// simply hold $MST and you'll receive Matic and MST automatically in your wallet.
// 
// Hold MST and get rewarded in Matic and MST on every transaction!
//

pragma solidity ^0.6.2;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./DividendPayingToken.sol";
import "./IWeth.sol";
import "./Pausable.sol";

contract MST is ERC20, Ownable, Pausable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    MSTDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public swapTokensAtAmount = 4 * (10**6) * (10**18);
    uint256 public maxTokensToSwap = 25000 * (10**6) * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    bool public waivePurchaseFees = false;

    mapping(bool => uint256) public burnFee;
    mapping(bool => uint256) public dividendsFeeToken;
    mapping(bool => uint256) public dividendsFeeEth;
    mapping(bool => uint256) public marketingFee;
    mapping(bool => uint256) public liquidityFee;

    uint256 private dividendStoredTokensTotal;
    uint256 private marketingStoredTokensTotal;
    uint256 private liquidityStoredTokensTotal;

    //parameter 
    address payable public marketingWalletAddress;
    address public airdropAddress = address(0);

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    bool public automaticRedistributionEnabled = false;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    //parameter max tx amount
    uint256 public maxTxAmount = 50000 * (10**6) * (10**18);

    mapping (address => bool) public excludedFromPaused;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event AutomaticRedistributionUpdated(bool indexed newValue, bool indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        address token,
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

    //parameters name/symbol
    constructor(address _router) public ERC20("Marstack", "MST") {
        marketingWalletAddress = payable(owner());

        //parameter buy fees
        burnFee[false] = 0;
        dividendsFeeToken[false] = 3;
        dividendsFeeEth[false] = 3;
        marketingFee[false] = 4;
        liquidityFee[false] = 3;

        //parameter sell fees
        burnFee[true] = 0;
        dividendsFeeToken[true] = 3;
        dividendsFeeEth[true] = 3;
        marketingFee[true] = 5;
        liquidityFee[true] = 4;

        if(_router == address(0))
            _router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        dividendTracker = new MSTDividendTracker(_uniswapV2Router.WETH());

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
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        if (marketingWalletAddress != owner()) excludeFromFees(marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadWallet, true);
        excludeFromFees(address(dividendTracker), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        //parameters totalsupply
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "MST: The dividend tracker already has that address");

        MSTDividendTracker newDividendTracker = MSTDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "MST: The new dividend tracker must be owned by the MST token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(deadWallet);
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "MST: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        dividendTracker.setWeth(uniswapV2Router.WETH());
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "MST: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] memory accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount;
    }

    function setMaxTokensToSwap(uint256 amount) external onlyOwner{
        maxTokensToSwap = amount;
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        marketingWalletAddress = wallet;
        if(!_isExcludedFromFees[marketingWalletAddress])
            excludeFromFees(marketingWalletAddress, true);
    }

    function setAirdropAddress(address wallet) external onlyOwner{
        airdropAddress = wallet;
    }

    function setWaivePurchaseFees(bool value) external onlyOwner {
        waivePurchaseFees = value;
    }

    function setBurnFee(bool sell, uint256 value) external onlyOwner{
        burnFee[sell] = value;
    }

    function setDividendsFeeToken(bool sell, uint256 value) external onlyOwner{
        dividendsFeeToken[sell] = value;
    }

    function setDividendsFeeEth(bool sell, uint256 value) external onlyOwner{
        dividendsFeeEth[sell] = value;
    }

    function setMarketingFee(bool sell, uint256 value) external onlyOwner{
        marketingFee[sell] = value;
    }

    function setLiquiditFee(bool sell, uint256 value) external onlyOwner{
        liquidityFee[sell] = value;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function excludeFromPause(address address_) public onlyOwner {
        excludedFromPaused[address_] = true;
    }

    function includeInPause(address address_) public onlyOwner {
        excludedFromPaused[address_] = false;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "MST: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "MST: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setMaxTxAmount(uint256 value) external onlyOwner() {
        maxTxAmount = value;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 600000, "MST: gasForProcessing must be between 200,000 and 600,000");
        require(newValue != gasForProcessing, "MST: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function setAutomaticRedistributionEnabled(bool newValue) public onlyOwner {
        emit AutomaticRedistributionUpdated(newValue, automaticRedistributionEnabled);
        automaticRedistributionEnabled = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function setMinimumTokenBalanceForDividends(uint256 minimumTokenBalanceForDividends_) external onlyOwner {
        dividendTracker.setMinimumTokenBalanceForDividends(minimumTokenBalanceForDividends_);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed(address tokenAddress) external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed(tokenAddress);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address tokenAddress, address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(tokenAddress, account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
	}

    function getAccountDividendsInfo(address token, address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(token, account);
    }

	function getAccountDividendsInfoAtIndex(address token, uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(token, index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(msg.sender, false);
    }

    function claimAddress(address claimee) external onlyOwner {
		dividendTracker.processAccount(payable(claimee), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function setLastProcessedIndex(uint256 index) external onlyOwner {
    	dividendTracker.setLastProcessedIndex(index);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        //super._beforeTokenTransfer(from, to, amount);

        require(!paused() || (excludedFromPaused[from] && excludedFromPaused[to]), "ERC20Pausable: token transfer while paused");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        if(from != owner() && from != address(this))
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        bool isAirdrop = from == airdropAddress || to == airdropAddress;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !isAirdrop &&
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            to != address(this) &&
            from != address(dividendTracker) &&
            to != address(dividendTracker) &&
            from != address(deadWallet) &&
            to != address(deadWallet)
        ) {
            if(contractTokenBalance > maxTokensToSwap) {
                contractTokenBalance = maxTokensToSwap;
            }

            swapTokens(contractTokenBalance);
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] ||
            (waivePurchaseFees && automatedMarketMakerPairs[from])) {
            takeFee = false;
        }

        if(takeFee) {
            bool sell = automatedMarketMakerPairs[to];
        	
            uint256 burnTokens = amount.mul(burnFee[sell]).div(100);
            uint256 divedendsTokens = amount.mul(dividendsFeeToken[sell]).div(100);

            super._transfer(from, deadWallet, burnTokens);
            super._transfer(from, address(dividendTracker), divedendsTokens);
            
            if(dividendTracker.distributeDividends(address(this), balanceOf(address(dividendTracker))))
                emit SendDividends(address(this), balanceOf(address(dividendTracker)));

            uint256 dividendsEthTokens = amount.mul(dividendsFeeEth[sell]).div(100);
            uint256 marketingTokens = amount.mul(marketingFee[sell]).div(100);
            uint256 liquidityTokens = amount.mul(liquidityFee[sell]).div(100);

            super._transfer(from, address(this), dividendsEthTokens + marketingTokens + liquidityTokens);

            amount = amount.sub(burnTokens);
            amount = amount.sub(divedendsTokens);
            amount = amount.sub(dividendsEthTokens);
            amount = amount.sub(marketingTokens);
            amount = amount.sub(liquidityTokens);

            dividendStoredTokensTotal += dividendsEthTokens;
            marketingStoredTokensTotal += marketingTokens;
            liquidityStoredTokensTotal += liquidityTokens;
        }

        super._transfer(from, to, amount);

        dividendTracker.setBalance(payable(from), balanceOf(from));
        dividendTracker.setBalance(payable(to), balanceOf(to));

        if(!swapping && !isAirdrop && !dividendTracker.processing() && automaticRedistributionEnabled) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
	    	}
        }
    }

    function dynamicFees() private view returns (uint256, uint256, uint256, uint256) {
        uint256 balance = balanceOf(address(this));
        
        uint256 dynamicDividendsFee = dividendStoredTokensTotal.mul(100).div(balance);
        uint256 dynamicLiquidityFee = liquidityStoredTokensTotal.mul(100).div(balance);
        uint256 dynamicMarketingFee = uint256(100).sub(dynamicDividendsFee).sub(dynamicLiquidityFee);

        return (balance, dynamicDividendsFee, dynamicLiquidityFee, dynamicMarketingFee);
    }

    function updateTokens(uint256 tokens, uint256 dynamicDividendsFee,
            uint256 dynamicLiquidityFee, uint256 dynamicMarketingFee) private {
        uint256 balance = balanceOf(address(this));
        
        dividendStoredTokensTotal = balance.mul(dynamicDividendsFee).div(100);
        liquidityStoredTokensTotal = balance.mul(dynamicLiquidityFee).div(100);
        
        marketingStoredTokensTotal = balance.sub(dividendStoredTokensTotal);
        marketingStoredTokensTotal = marketingStoredTokensTotal.sub(liquidityStoredTokensTotal);
    }

    function swapTokens(uint256 tokens) private {
        swapping = true;

        (, uint256 dynamicDividendsFee, uint256 dynamicLiquidityFee, uint256 dynamicMarketingFee) = dynamicFees();

        uint256 tokensForLiquidity = tokens.mul(dynamicLiquidityFee).div(100);
        uint256 tokensForLiquidityHalf = tokensForLiquidity.div(2);
        uint256 tokensForBnb = tokens.sub(tokensForLiquidityHalf);

        // Swap tokens for BNB
        uint256 bnbReceived = swapTokensForBnb(tokensForBnb);

        // Add liquidity to PancakeSwap
        uint256 bnbForLiquidity = bnbReceived.mul(tokensForLiquidityHalf).div(tokensForBnb);
        addLiquidity(tokensForLiquidityHalf, bnbForLiquidity);

        // Fees
        uint256 totalFeesWithoutLiq = dynamicDividendsFee.add(dynamicMarketingFee);
        uint256 bnbBalance = address(this).balance;
        uint256 bnbForFees = bnbBalance.mul(dynamicMarketingFee).div(totalFeesWithoutLiq);
        (bool sent, ) = marketingWalletAddress.call{value: bnbForFees}("");
        require(sent, "MST:swapTokens Failed to send Ether");

        // Dividends
        uint256 dividends = address(this).balance;
        swapAndSendDividends(dividends);
        

        updateTokens(tokens, dynamicDividendsFee, dynamicLiquidityFee, dynamicMarketingFee);

        swapping = false;
    }

    function swapTokensOnDemand(bool liquify, bool sendToFee, bool sendDividends) external onlyOwner {
        swapping = true;

        (uint256 contractTokenBalance, uint256 dynamicDividendsFee, uint256 dynamicLiquidityFee, uint256 dynamicMarketingFee) = dynamicFees();
        if(contractTokenBalance > maxTokensToSwap) {
            contractTokenBalance = maxTokensToSwap;
        }

        // Determine the amount of tokens to swap
        uint256 tokensToSwap = 0;
        uint256 liquidityTokens = 0;
        uint256 feeTokens = 0;
        uint256 dividendTokens = 0;
        if (liquify) {
            liquidityTokens = contractTokenBalance.mul(dynamicLiquidityFee).div(100);
            tokensToSwap += liquidityTokens.div(2);

            if(liquidityStoredTokensTotal > liquidityTokens)
                liquidityStoredTokensTotal = liquidityStoredTokensTotal.sub(liquidityTokens);
            else
                liquidityStoredTokensTotal = 0;
        }

        if (sendToFee) {
            feeTokens = contractTokenBalance.mul(dynamicMarketingFee).div(100);
            tokensToSwap += feeTokens;

            if(marketingStoredTokensTotal > feeTokens)
                marketingStoredTokensTotal = marketingStoredTokensTotal.sub(feeTokens);
            else
                marketingStoredTokensTotal = 0;
        }

        if (sendDividends) {
            dividendTokens = contractTokenBalance.mul(dynamicDividendsFee).div(100);
            tokensToSwap += dividendTokens;

            if(dividendStoredTokensTotal > dividendTokens)
                dividendStoredTokensTotal = dividendStoredTokensTotal.sub(dividendTokens);
            else
                dividendStoredTokensTotal = 0;
        }

        // Swap and magic
        if (tokensToSwap > 0) {
            uint256 bnbReceived = swapTokensForBnb(tokensToSwap);

            if (liquify) {
                uint256 half = liquidityTokens.div(2);
                uint256 bnbAmount = bnbReceived.mul(half).div(tokensToSwap);
                addLiquidity(liquidityTokens.sub(half), bnbAmount);
            }

            if (sendToFee) {
                uint256 bnbAmount = bnbReceived.mul(feeTokens).div(tokensToSwap);
                (bool sent, bytes memory data) = marketingWalletAddress.call{value: bnbAmount}("");
                require(sent, "MST:swapTokensOnDemand Failed to send Ether");
            }

            if (sendDividends) {
                uint256 bnbAmount = bnbReceived.mul(dividendTokens).div(tokensToSwap);
                swapAndSendDividends(bnbAmount);
            }
        }

        swapping = false;
    }

    function swapTokensForBnb(uint256 tokenAmount) private returns(uint256) {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );

        return address(this).balance.sub(initialBalance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {

        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(),
            block.timestamp
        );

        emit SwapAndLiquify(tokenAmount, bnbAmount, tokenAmount);
    }

    function swapAndSendDividends(uint256 bnbForDividends) private {
        swapEthForWETH(bnbForDividends);
        IERC20 weth = IERC20(uniswapV2Router.WETH());
        uint256 dividends = weth.balanceOf(address(this));
        bool success = weth.transfer(address(dividendTracker), dividends);

        if (success) {
            if(dividendTracker.distributeDividends(uniswapV2Router.WETH(), weth.balanceOf(address(dividendTracker))))
                emit SendDividends(uniswapV2Router.WETH(), weth.balanceOf(address(dividendTracker)));
        }
    }

    function swapEthForWETH(uint256 bnbAmount) private {
        IWeth weth = IWeth(uniswapV2Router.WETH());
        weth.deposit{value: bnbAmount}();
    }
}

contract MSTDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    bool public processing;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event SetMinimumTokenBalanceForDividends(uint256 minimumTokenBalanceForDividends_);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(address weth_) public DividendPayingToken("MST_Dividen_Tracker", "MST_Dividend_Tracker", weth_) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "MST_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend(address token) public override {
        require(false, "MST_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main MST contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account], "MST_Dividend_Tracker: already excluded");
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function setMinimumTokenBalanceForDividends(uint256 minimumTokenBalanceForDividends_) external onlyOwner {
    	minimumTokenBalanceForDividends = minimumTokenBalanceForDividends_;

    	emit SetMinimumTokenBalanceForDividends(minimumTokenBalanceForDividends);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "MST_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "MST_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function setLastProcessedIndex(uint256 index) external onlyOwner {
    	lastProcessedIndex = index;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _token, address _account)
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


        withdrawableDividends = withdrawableDividendOf(_token, account);
        totalDividends = accumulativeDividendOf(_token, account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(address token, uint256 index)
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

        return getAccount(token, account);
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
        if(!processing)
    	    processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        processing = true;
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
        processing = false;
    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        bool claimed = false;
        for(uint i = 0; i < redistributionTokens.length; i++) {
            address token = redistributionTokens[i];
            uint256 amount = _withdrawDividendOfUser(token, account);
            if(amount > 0) {
                claimed = true;
                lastClaimTimes[account] = block.timestamp;
                emit Claim(account, amount, automatic);
            }
        }

    	return claimed;
    }
}