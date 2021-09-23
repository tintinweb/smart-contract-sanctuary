pragma solidity 0.8.7;

import "./AggregatorV3Interface.sol";
import "./BEP20.sol";
import "./BNBFlokiDividendTracker.sol";
import "./IPancakeSwapV2Factory.sol";
import "./IPancakeSwapV2Pair.sol";
import "./IPancakeSwapV2Router02.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

// SPDX-License-Identifier: MIT
contract BNBFloki is BEP20, Ownable {

    using SafeMath for uint256;
    receive() external payable {}

    /**
     * Configuration
     *  Stores the initial configuration of the contract.
     */

    uint256 public maxAccountBalance = 10**13 * (10**9);
    uint256 public _minimumCollectedTaxesForSwap = 1 * 10**11 * (10**9); // Threshold for sending tokens to liquidity automatically
    uint256 public gasForProcessing = 3 * 10**5; // auto-claim gas usage

    bool private priceOracleEnabled = true;
    int private manualBNBValue = 3000 * 10**8;
    bool private pairSwapped = false;

    uint256 public normalBuyTax = 100;
    uint256 public normalSellTax = 200;
    uint256 public windowBuyTax = 0;
    uint256 public windowSellTax = 300;

    /**
     * State
     *  Fields keeping track of the current state of the contract.
     */

    IPancakeSwapV2Router02 public pancakeswapV2Router;
    address public immutable pancakeswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // Toggle swap & liquify on and off
    bool public tradingEnabled = false; // To avoid snipers

    BNBFlokiDividendTracker public dividendTracker;

    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public liquidityWallet;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    AggregatorV3Interface internal priceFeed;
    // Testnet 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    // Mainnet 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address public _oraclePriceFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    uint256 public allTimeHigh = 0;

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
    constructor() BEP20("BNBFloki", "BNBFloki", 9) {
    	dividendTracker = new BNBFlokiDividendTracker();
    	liquidityWallet = owner();
        // PancakeSwap initialization
        // Testnet (kiemtienonline) : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // V1 : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
        // V2 : 0x10ED43C718714eb63d5aA57B78B54704E256024E
    	IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pancakeswapV2Pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
        pancakeswapV2Pair = _pancakeswapV2Pair;
        _setAutomatedMarketMakerPair(_pancakeswapV2Pair, true);
        priceFeed = AggregatorV3Interface(_oraclePriceFeed);
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
        require(newAddress != address(dividendTracker), "BNBFloki: The dividend tracker already has that address");
        BNBFlokiDividendTracker newDividendTracker = BNBFlokiDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "BNBFloki: The new dividend tracker must be owned by the BNBFloki token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(pancakeswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updatePancakeswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeswapV2Router), "BNBFloki: The router already has that address");
        emit UpdatePancakeswapV2Router(newAddress, address(pancakeswapV2Router));
        pancakeswapV2Router = IPancakeSwapV2Router02(newAddress);
        dividendTracker.excludeFromDividends(address(pancakeswapV2Router));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BNBFloki: Account is already the value of 'excluded'");
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

    function setMinimumCollectedTaxesForSwap(uint256 minimumCollectedTaxesForSwap) external onlyOwner() {
        _minimumCollectedTaxesForSwap = minimumCollectedTaxesForSwap;
    }

    function setTradingEnabled(bool _enabled) public onlyOwner {
        tradingEnabled = _enabled;
        emit UpdateTradingEnabledTimestamp(block.timestamp);
    }

    function setFees(uint256 newNormalBuyTax, uint256 newNormalSellTax, uint256 newWindowBuyTax, uint256 newWindowSellTax) public onlyOwner {
        normalBuyTax = newNormalBuyTax;
        normalSellTax = newNormalSellTax;
        windowBuyTax = newWindowBuyTax;
        windowSellTax = newWindowSellTax;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakeswapV2Pair, "BNBFloki: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BNBFloki: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if (value)
            dividendTracker.excludeFromDividends(pair);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "BNBFloki: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BNBFloki: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BNBFloki: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function setMaxAccountBalance(uint256 newMaxAccountBalance) external onlyOwner {
        maxAccountBalance = newMaxAccountBalance;
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

    function validateTransfer(address from, address to, uint256 amount) private view {
        require(from != address(0) && to != address(0), "BEP20: transfer from / to the zero address");
        if (from != owner() && to != owner()) {
            require(tradingEnabled, "Trading is not enabled");
            if (to != burnAddress && from != address(this) && to != address(this)) {
                if (!automatedMarketMakerPairs[to])
                    require(balanceOf(to) + amount <= maxAccountBalance, "Exceeds maximum wallet token amount");
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount == 0)
            return super._transfer(from, to, 0);
        validateTransfer(from, to, amount);
        if (!inSwapAndLiquify && from != pancakeswapV2Pair && from != address(pancakeswapV2Router) && to != address(pancakeswapV2Router))
            initiateSwap();
        bool takeFee = (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to])
            takeFee = false;
        transferInternal(from, to, amount, takeFee);
        payDividends(from, to);
    }

    function transferInternal(address from, address to, uint256 amount, bool takeFee) private {
        if (takeFee) { // one of the addresses (from/to) should be an AMM
            uint256 currentPrice = this.getTokenPrice();
            uint256 tax = (automatedMarketMakerPairs[to] ? normalSellTax : normalBuyTax);
            if (currentPrice < allTimeHigh.mul(75).div(100))
                tax = (automatedMarketMakerPairs[to] ? windowSellTax : windowBuyTax);
        	uint256 fees = amount.mul(tax).div(1000);
        	amount = amount.sub(fees);
            allTimeHigh = currentPrice > allTimeHigh ? currentPrice : allTimeHigh;
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
    }

    function payDividends(address from, address to) private {
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
        uint256 totalBalance = balanceOf(address(this));
        if (totalBalance > _minimumCollectedTaxesForSwap)
            swapAndSendDividends(_minimumCollectedTaxesForSwap);
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForBNB(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        if (success)
   	 		emit SendDividends(tokens, dividends);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
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

    function setPriceFeed(address newPriceFeed) external onlyOwner {
        _oraclePriceFeed = newPriceFeed;
        priceFeed = AggregatorV3Interface(_oraclePriceFeed);
    }

    function getLatestPrice() external view returns (uint80, int, uint, uint,  uint80) {
        (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        return (roundID, price, startedAt, timeStamp,  answeredInRound);
    }

    function getTokenPrice() external view returns(uint256) {
        BEP20 token0 = BEP20(IPancakeSwapV2Pair(pancakeswapV2Pair).token0());
        BEP20 token1 = BEP20(IPancakeSwapV2Pair(pancakeswapV2Pair).token1());
        (uint112 Res0, uint112 Res1,) = IPancakeSwapV2Pair(pancakeswapV2Pair).getReserves();
        if (pairSwapped) {
            token0 = BEP20(IPancakeSwapV2Pair(pancakeswapV2Pair).token1()); // this token
            token1 = BEP20(IPancakeSwapV2Pair(pancakeswapV2Pair).token0()); // bnb
            (Res1, Res0,) = IPancakeSwapV2Pair(pancakeswapV2Pair).getReserves();
        }
        int latestBNBprice = manualBNBValue; // manually configure BNB value if oracle crashes
        if (priceOracleEnabled)
            (,latestBNBprice,,,) = this.getLatestPrice();
        uint256 res1 = (uint256(Res1)*uint256(latestBNBprice)*(10**uint256(token0.decimals())))/uint256(token1.decimals());
        return(res1/uint256(Res0)); // amount of bnb needed to buy this token
    }

    function setManualBNBValue(uint256 val) external onlyOwner() {
        manualBNBValue = int(val.mul(10**8));//18));
    }

    function enablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == false, "price oracle already enabled");
        priceOracleEnabled = true;
    }

    function disablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == true, "price oracle already disabled");
        priceOracleEnabled = false;
    }

    function setPairSwapped(bool swapped) external onlyOwner() {
        pairSwapped = swapped;
    }

}