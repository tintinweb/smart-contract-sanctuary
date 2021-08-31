pragma solidity 0.8.7;

import "./BEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IPancakeSwapV2Factory.sol";
import "./IPancakeSwapV2Router02.sol";
import "./BNBMaxDividendTracker.sol";

/**
 * @dev The main BNBMax contract.
 *
 * The website : https://bnb-max.finance
 * The telegram : https://t.me/bnbmax_official
 */
// SPDX-License-Identifier: MIT
contract BNBMax is BEP20, Ownable {

    using SafeMath for uint256;
    receive() external payable {}

    /**
     * Configuration
     *  Stores the initial configuration of the contract.
     */

    uint256 public maxAccountBalance = 10**13 * (10**9);
    uint256 public _numTokensSellToInitiateSwap = 1 * 10**11 * (10**9); // Threshold for sending tokens to liquidity automatically
    uint256 public maxSellTransactionAmount = 5 * 10**11 * (10**9);
    uint256 public maxCumulativeSellTransactionAmount = 10**12 * (10**9); // Max cumulative sell (over a period of time)
    uint256 public sellRightsMultiplier = 10**9 * (10**9);
    uint256 public swapTokensAtAmount = 10**9 * (10**9);
    uint256 public sellRewardsFeeIncrease = 10; // 15% more tax on sells
    uint256 public gasForProcessing = 3 * 10**5; // auto-claim gas usage

    /**
     * State
     *  Fields keeping track of the current state of the contract.
     */

    mapping(address => uint256) private lastSellByAccount;
    mapping(address => uint256) private soldCumulativelyByAccount;

    IPancakeSwapV2Router02 public pancakeswapV2Router;
    address public immutable pancakeswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // Toggle swap & liquify on and off
    bool public tradingEnabled = false; // To avoid snipers

    BNBMaxDividendTracker public dividendTracker;

    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public liquidityWallet;

    uint256 public immutable BNBRewardsFee;
    uint256 public immutable liquidityFee;
    uint256 public immutable totalFees;
    uint256 private liquidityTokens = 0; // collected fees to send to liquidity pools

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /**
     * Events
     *  Definition of various events that are triggered at various occasions.
     */

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdatePancakeswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event UpdatedCanTransferBeforeTrading(address  account, bool state);
    event UpdateTradingEnabledTimestamp(uint256 timestamp);
    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    /**
     * The constructor (entry point) of the contract.
     */
    constructor() BEP20("BNBMax", "BNBMax", 9) {
        uint256 _BNBRewardsFee = 11;
        uint256 _liquidityFee = 4;
        BNBRewardsFee = _BNBRewardsFee;
        liquidityFee = _liquidityFee;
        totalFees = _BNBRewardsFee.add(_liquidityFee);
    	dividendTracker = new BNBMaxDividendTracker();
    	liquidityWallet = owner();
        // PancakeSwap initialization
        // Testnet (kiemtienonline) : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // V1 : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
        // V2 : 0x10ED43C718714eb63d5aA57B78B54704E256024E
    	IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pancakeswapV2Pair = IPancakeSwapV2Factory(
            _pancakeswapV2Router.factory()
        ).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
        pancakeswapV2Pair = _pancakeswapV2Pair;
        _setAutomatedMarketMakerPair(_pancakeswapV2Pair, true);
        // Exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(burnAddress));
        dividendTracker.excludeFromDividends(address(_pancakeswapV2Router));
        // Exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        // Internal function that can only be called once
        _mint(owner(), 10**15 * (10**9));
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BNBMax: The dividend tracker already has that address");
        BNBMaxDividendTracker newDividendTracker = BNBMaxDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "BNBMax: The new dividend tracker must be owned by the BNBMax token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(pancakeswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updatePancakeswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeswapV2Router), "BNBMax: The router already has that address");
        emit UpdatePancakeswapV2Router(newAddress, address(pancakeswapV2Router));
        pancakeswapV2Router = IPancakeSwapV2Router02(newAddress);
        dividendTracker.excludeFromDividends(address(pancakeswapV2Router));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BNBMax: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++)
            _isExcludedFromFees[accounts[i]] = excluded;
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function excludeFromTrading(address account) public onlyOwner {
        super._transfer(account, burnAddress, balanceOf(account));
        try dividendTracker.setBalance(payable(account), balanceOf(account)) {} catch {}
        try dividendTracker.setBalance(payable(burnAddress), balanceOf(burnAddress)) {} catch {}
    }

    function setNumTokensSellToInitiateSwap(uint256 numTokensSellToAddToLiquidity) external onlyOwner() {
        _numTokensSellToInitiateSwap = numTokensSellToAddToLiquidity;
    }

    function setSellRightsMultiplier(uint256 multiplier) external onlyOwner() {
        sellRightsMultiplier = multiplier;
    }

    function setTradingEnabled(bool _enabled) public onlyOwner {
        tradingEnabled = _enabled;
        emit UpdateTradingEnabledTimestamp(block.timestamp);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakeswapV2Pair, "BNBMax: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BNBMax: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if (value)
            dividendTracker.excludeFromDividends(pair);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "BNBMax: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BNBMax: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BNBMax: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    
    function setMaxSellTransaction(uint256 txnAmount) external onlyOwner {
        maxSellTransactionAmount= txnAmount;
    }

    function setMaxCumulativeSellTransaction(uint256 txnAmount) external onlyOwner {
        maxCumulativeSellTransactionAmount= txnAmount;
    }

    function setSwapAt(uint256 swapAmount) external onlyOwner {
        swapTokensAtAmount = swapAmount;
    }
    
    function setSellRewardsFeeIncrease(uint256 factor) external onlyOwner {
        sellRewardsFeeIncrease = factor;
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

    function getAccountDividendsInfo(address account) external view 
        returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index) external view 
        returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
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

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function checkTransferValidity(address from, address to, uint256 amount) private {
        require(from != address(0) && to != address(0), "BEP20: transfer from / to the zero address");
        if (from != owner() && to != owner()) {
            require(tradingEnabled, "Trading is not enabled");
            if (to != burnAddress && from != address(this) && to != address(this)) {
                if (!automatedMarketMakerPairs[to])
                    require(balanceOf(to) + amount <= maxAccountBalance, "Exceeds maximum wallet token amount");
                else {
                    if (from != address(pancakeswapV2Router) && !_isExcludedFromFees[to])
                        require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
                    require(lastSellByAccount[from] != block.number, "Can't sell twice in the same block.");
                    if (lastSellByAccount[from] != 0) {
                        uint256 sellRights = block.number.sub(lastSellByAccount[from]).mul(sellRightsMultiplier);
                        if (sellRights > soldCumulativelyByAccount[from])
                            soldCumulativelyByAccount[from] = 0;
                        else
                            soldCumulativelyByAccount[from] = soldCumulativelyByAccount[from].sub(sellRights);
                    }
                    soldCumulativelyByAccount[from] = soldCumulativelyByAccount[from].add(amount);
                    lastSellByAccount[from] = block.number;
                    require(soldCumulativelyByAccount[from] <= maxCumulativeSellTransactionAmount, "Excessive cumulative sell");
                    soldCumulativelyByAccount[from] = soldCumulativelyByAccount[from].add(1);
                }
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount == 0)
            return super._transfer(from, to, 0);
        checkTransferValidity(from, to, amount);
        if (!inSwapAndLiquify && from != pancakeswapV2Pair && from != address(pancakeswapV2Router) && to != address(pancakeswapV2Router))
            initiateSwap();
        // Transfer with tax
        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to])
            takeFee = false;
        if (takeFee) {
            uint256 updatedTotalFees = totalFees;
            if (automatedMarketMakerPairs[to])
                updatedTotalFees = updatedTotalFees.add(sellRewardsFeeIncrease);
        	uint256 fees = amount.mul(updatedTotalFees).div(100);
            liquidityTokens = liquidityTokens.add(fees.mul(liquidityFee).div(updatedTotalFees));
        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
        // Pay dividends
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        if (!inSwapAndLiquify) {
	    	uint256 gas = gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {}
        }
    }

    function initiateSwap() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            uint256 liquidityShare = contractTokenBalance.mul(liquidityTokens).div(contractTokenBalance);
            if (contractTokenBalance >= maxSellTransactionAmount)
                contractTokenBalance = maxSellTransactionAmount;
            bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToInitiateSwap;
            if (overMinTokenBalance) {
                if (liquidityShare < contractTokenBalance) {
                    liquidityTokens = liquidityTokens.sub(liquidityShare);
                    swapAndLiquify(liquidityShare);
                    uint256 tokensForRewards = contractTokenBalance.sub(liquidityShare);
                    swapAndSendDividends(tokensForRewards);
                }
            }
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // infinite slippage
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
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
        if (success)
   	 		emit SendDividends(tokens, dividends);
    }

}