// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IJoePair.sol";
import "./IJoeRouter.sol";
import "./ITracker.sol";
import "./KitsuneInuDividendTracker.sol";

contract KitsuneInu is ERC20, Ownable {
    using SafeMath for uint256;

    IJoeRouter02 public JoeRouter;
    address public JoePair;

    bool private liquidating;

    ITracker public dividendTracker;

    address public liquidityWallet;

    uint256 public constant MAX_SELL_TRANSACTION_AMOUNT = 2_500_000_000 * (10**18);
    uint256 public constant MAX_BUY_TRANSACTION_AMOUNT = 625_000_000 * (10**18);

    uint256 public constant AVAX_REWARDS_FEE = 11;
    uint256 public constant LIQUIDITY_FEE = 3;
    uint256 public constant TOTAL_FEES = AVAX_REWARDS_FEE + LIQUIDITY_FEE;

    // to be added
    address public devAddress = 0x61B3e99AfA0925EaF18bDeb8810b01b4ed1C895B;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    bool _maxBuyEnabled = true;
    bool _maxSellEnabled = true;


    // use by default 150,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 150_000;

    // liquidate tokens for AVAX when the contract reaches 25000k tokens by default
    uint256 public liquidateTokensAtAmount = 25_000_000 * (10**18);

    // whether the token can already be traded
    bool public tradingEnabled;

    // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) public canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdatedDividendTracker(address indexed newAddress, address indexed oldAddress);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event DevWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event LiquidationThresholdUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event ExcludeFromFees(address indexed account, bool exclude);

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event Liquified(
        uint256 tokensSwapped,
        uint256 avaxReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapAndSendToDev(
        uint256 tokensSwapped,
        uint256 avaxReceived
    );
    event SentDividends(
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

    constructor() ERC20("Inu", "INU") {
        liquidityWallet = owner();
        IJoeRouter02 _JoeRouter = IJoeRouter02(0x5db0735cf88F85E78ed742215090c465979B5006);
        JoeRouter = _JoeRouter;
        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);

        // enable owner wallet to send tokens before presales are over.
        canTransferBeforeTradingIsEnabled[owner()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 250_000_000_000 * (10**18));
    }

    receive() external payable {}

    // view functions
    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getDividendToken() public view returns(address){
        return dividendTracker.dividendToken();
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

    function isExcludedFromDividends(address account) public view returns(bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function withdrawableDividendOf(address account) external view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) external view returns (uint256) {
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

    function activate() public onlyOwner {
        require(!tradingEnabled, "KitsuneInu: Trading is already enabled");
        tradingEnabled = true;
    }

    // state functions
    function swapAndSendToDev(uint256 tokens) private {
        uint256 tokenBalance = tokens;

        // capture the contract's current AVAX balance.
        // this is so that we can capture exactly the amount of AVAX that the
        // swap creates, and not make the liquidity event include any AVAX that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for AVAX
        swapTokensForAvax(tokenBalance);

        // how much AVAX did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        address payable _devAndMarketingAddress = payable(devAddress);
        _devAndMarketingAddress.transfer(newBalance);
        
        emit SwapAndSendToDev(tokens, newBalance);
    }

    function swapTokensForDividendToken(uint256 tokenAmount, address recipient) private {
        // generate the JoeTrader pair path of wavax -> AKITA
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = JoeRouter.WAVAX();
        path[2] = getDividendToken();

        _approve(address(this), address(JoeRouter), tokenAmount);

        // make the swap
        JoeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of dividend token
            path,
            recipient,
            block.timestamp
        );
        
    }
    
     function swapAndSendDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this));
        uint256 dividends = IERC20(getDividendToken()).balanceOf(address(this));
        bool success = IERC20(getDividendToken()).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SentDividends(tokens, dividends);
        }
    }

    function swapTokensForAvax(uint256 tokenAmount) private {
        // generate the JoeTrader pair path of token -> wavax
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = JoeRouter.WAVAX();

        _approve(address(this), address(JoeRouter), tokenAmount);

        // make the swap
        JoeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of avax
            path,
            address(this),
            block.timestamp
        );
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != JoePair, "KitsuneInu: The JoeTrader pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setJoePairOnce(address pair) public onlyOwner {
        require(JoePair == address(0) && pair != address(0), "KitsuneInu: The JoeTrader pair has been set!");
        _setAutomatedMarketMakerPair(pair, true);
        JoePair = pair;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "KitsuneInu: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        dividendTracker.excludeFromDividends(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(address account, bool exclude) public onlyOwner {
        require(_isExcludedFromFees[account] != exclude, "already the value has been set!");
        _isExcludedFromFees[account] = exclude;
        emit ExcludeFromFees(account, exclude);
    }

    function excludeFromDividends(address account, bool exclude) public onlyOwner {
        dividendTracker.excludeFromDividends(account, exclude);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "KitsuneInu: The dividend tracker already has that address");
        ITracker newDividendTracker = ITracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "KitsuneInu: The new dividend tracker must be owned by the token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker),true);
        newDividendTracker.excludeFromDividends(address(this),true);
        newDividendTracker.excludeFromDividends(owner(),true);
        newDividendTracker.excludeFromDividends(DEAD_ADDRESS,true);
        newDividendTracker.excludeFromDividends(address(JoeRouter),true);
        newDividendTracker.excludeFromDividends(address(devAddress),true);
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = ITracker(newDividendTracker);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "KitsuneInu: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "KitsuneInu: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateDevWallet(address newDevWallet) public onlyOwner {
        require(newDevWallet != devAddress, "KitsuneInu: The development wallet is already this address");
        excludeFromFees(newDevWallet, true);
        emit DevWalletUpdated(newDevWallet, devAddress);
        devAddress = newDevWallet;
    }

    function addTransferBeforeTrading(address account) external onlyOwner {
        require(account != address(0),"KitsuneInu: shouldn't be the 0 address");
        canTransferBeforeTradingIsEnabled[account] = true;
    }

    function switchMaxBuy(bool enabled) external onlyOwner {
        require(enabled != _maxBuyEnabled,"KitsuneInu: buy limit has already been set");
        _maxBuyEnabled = enabled;
    }

    function switchMaxSell(bool enabled) external onlyOwner {
        require(enabled != _maxSellEnabled,"KitsuneInu: sell limit has already been set");
        _maxSellEnabled = enabled;
    }

    function setDividendTokenAddress(address token) external onlyOwner {
        dividendTracker.setDividendTokenAddress(token);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        bool tradingIsEnabled = tradingEnabled;
        bool areMeet = !liquidating && tradingIsEnabled;
        // only whitelisted addresses can make transfers before the public presale is over.
        if (!tradingIsEnabled) {
            //turn transfer on to allow for whitelist form/mutlisend presale
                require(canTransferBeforeTradingIsEnabled[from], "KitsuneInu: This account cannot send tokens until trading is enabled");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        //to prevent bots both buys and sells will have a max on launch after only sells will
        if(areMeet){
            if (_maxBuyEnabled &&
            automatedMarketMakerPairs[from] && // buys only by detecting transfer from automated market maker pair
            to != address(JoeRouter) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees)
            ) require(amount <= MAX_BUY_TRANSACTION_AMOUNT, "Buy transfer amount exceeds the MAX_BUY_TRANSACTION_AMOUNT.");
            
            if (_maxSellEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
            from != address(JoeRouter) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[from] //no max for those excluded from fees
            ) require(amount <= MAX_SELL_TRANSACTION_AMOUNT, "Sell transfer amount exceeds the MAX_SELL_TRANSACTION_AMOUNT.");
        
            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= liquidateTokensAtAmount;

            if (canSwap &&
                !automatedMarketMakerPairs[from]
                // from != liquidityWallet &&
                // to != liquidityWallet
            ) {
                liquidating = true;

                uint256 swapTokens = contractTokenBalance.mul(LIQUIDITY_FEE).div(TOTAL_FEES);
                swapAndSendToDev(swapTokens);

                uint256 sellTokens = balanceOf(address(this));
                swapAndSendDividends(sellTokens);

                liquidating = false;
            }
        }

        bool takeFee = tradingIsEnabled && !liquidating;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = amount.mul(TOTAL_FEES).div(100);
            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {
            
        }

        if (!liquidating) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } catch {}
        }
    }

}