// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./PallinaQuadrataDividendTracker.sol";
import "./IUniswapV2Factory.sol";



contract PallinaQuadrata is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    bool private swapping;
    bool private stakingEnabled = false;
    bool public tradingEnabled = false;

    PallinaQuadrataDividendTracker public dividendTracker;

    address public liquidityWallet;

    address payable public marketingAddress = payable(0x5C414F73136248E243B96608275b1a3B70F7F90F);

    uint256 public maxSellTransactionAmount = 1000000000 * (10**9);
    uint256 public swapTokensAtAmount = 200000 * (10**9);
    uint256 public swapTokensAtAmountMax = 5000000 * (10**9);

    uint256 public devFees = 3;
    uint256 public liquidityFee = 2;
    uint256 public BNBRewardsBuyFee = 3;
    uint256 public BNBRewardsSellFee = 11;
    
    uint256 private countDevFees = 0;
    uint256 private countLiquidityFees = 0;
    uint256 private countBNBRewardsFee = 0;
    
    mapping (address => mapping (int256 => address)) public referrerTree;
    
    mapping (address => uint256) private unconvertedTokens;
    uint256 public unconvertedTokensIndex;
    uint256 public unconvertedTokensIndexUpper;
    mapping (uint256 => address) private unconvertedTokensKeys;
    

    uint256 private iteration = 0;
    uint256 private iterationDaily = 0;
    uint256 private iterationWeekly = 0;
    uint256 private iterationMonthly = 0;
    uint public dailyTimer = block.timestamp + 86400;
    uint public weeklyTimer = block.timestamp + 604800;
    uint public monthlyTimer = block.timestamp + 2629743;
    bool public swapAndLiquifyEnabled = true;
    
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => uint256) public stakingBonus;
    mapping(address => uint256) public stakingUntilDate;
    mapping(uint256 => uint256) public stakingAmounts;

    mapping(address => bool) private canTransferBeforeTradingIsEnabled;

    event EnableAccountStaking(address indexed account, uint256 duration);
    event UpdateStakingAmounts(uint256 duration, uint256 amount);

    event EnableSwapAndLiquify(bool enabled);
    event EnableStaking(bool enabled);

    event SetPreSaleWallet(address wallet);

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event TradingEnabled();

    event UpdateFees(
        uint256 dev,
        uint256 liquidity,
        uint256 BNBRewardsBuy,
        uint256 BNBRewardsSell
    );
    
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity,
        bool success
    );

    event SendDividends(uint256 dividends, uint256 marketing, bool success);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event UpdatePayoutToken(address account, address token);
    event UpdateAllowTokens(address token, bool allow);
    
    constructor() ERC20("PallinaQuadrata", "PallinaQuadrata") {
        dividendTracker = new PallinaQuadrataDividendTracker(payable(this));

        liquidityWallet = owner();

        uniswapV2Router = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(
            0x000000000000000000000000000000000000dEaD
        );
        dividendTracker.excludedFromDividends(address(0));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(dividendTracker)] = true;

        canTransferBeforeTradingIsEnabled[owner()] = true;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */

        _mint(owner(), 1000000000 * (10**9));
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    receive() external payable {}

    function updateStakingAmounts(uint256 duration, uint256 bonus)
        public
        onlyOwner
    {
        require(stakingAmounts[duration] != bonus);
        require(bonus <= 100, "Staking bonus can't exceed 100");

        stakingAmounts[duration] = bonus;
        emit UpdateStakingAmounts(duration, bonus);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled);

        tradingEnabled = true;
        blockNumEnabled = block.number;
        emit TradingEnabled();
    }

    function setPresaleWallet(address wallet) external onlyOwner {
        canTransferBeforeTradingIsEnabled[wallet] = true;
        _isExcludedFromFees[wallet] = true;
        dividendTracker.excludeFromDividends(wallet);

        emit SetPreSaleWallet(wallet);
    }

    function enableStaking(bool enable) public onlyOwner {
        require(stakingEnabled != enable);
        stakingEnabled = enable;

        emit EnableStaking(enable);
    }

    function stake(uint256 duration) public {
        require(stakingEnabled, "Staking is not enabled");
        require(stakingAmounts[duration] != 0, "Invalid staking duration");
        require(
            stakingUntilDate[_msgSender()] < block.timestamp.add(duration),
            "already staked for a longer duration"
        );

        stakingBonus[_msgSender()] = stakingAmounts[duration];
        stakingUntilDate[_msgSender()] = block.timestamp.add(duration);

        dividendTracker.setBalance(
            _msgSender(),
            getStakingBalance(_msgSender())
        );

        emit EnableAccountStaking(_msgSender(), duration);
    }

    function updateMaxAmount(uint256 newNum) public onlyOwner {
        require(maxSellTransactionAmount != newNum);
        maxSellTransactionAmount = newNum * (10**9);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker));

        PallinaQuadrataDividendTracker newDividendTracker = PallinaQuadrataDividendTracker(
            payable(newAddress)
        );

        require(newDividendTracker.owner() == address(this));

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function setMarketingAddress(address payable newAddress)
        public
        onlyOwner
    {
        marketingAddress = newAddress;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router));
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        dividendTracker.updateUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded);
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function enableSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled);
        swapAndLiquifyEnabled = enabled;

        emit EnableSwapAndLiquify(enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair);

        _setAutomatedMarketMakerPair(pair, value);
    }

    function setAllowCustomTokens(bool allow) public onlyOwner {
        dividendTracker.setAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) public onlyOwner {
        dividendTracker.setAllowAutoReinvest(allow);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet)
        public
        onlyOwner
    {
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000);
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateFees(
        uint256 dev,
        uint256 liquidity,
        uint256 BNBRewardsBuy,
        uint256 BNBRewardsSell
    ) public onlyOwner {
        devFees = dev;
        liquidityFee = liquidity;
        BNBRewardsBuyFee = BNBRewardsBuy;
        BNBRewardsSellFee = BNBRewardsSell;

        emit UpdateFees(dev, liquidity, BNBRewardsBuy, BNBRewardsSell);
    }

    function getStakingInfo(address account)
        external
        view
        returns (uint256, uint256)
    {
        return (stakingUntilDate[account], stakingBonus[account]);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setAutoClaim(bool value) external {
        dividendTracker.setAutoClaim(msg.sender, value);
    }

    function setReinvest(bool value) external {
        dividendTracker.setReinvest(msg.sender, value);
    }

    function setDividendsPaused(bool value) external onlyOwner {
        dividendTracker.setDividendsPaused(value);
    }

    function isExcludedFromAutoClaim(address account)
        external
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromAutoClaim(account);
    }

    function isReinvest(address account) external view returns (bool) {
        return dividendTracker.isReinvest(account);
    }
    
    function getETHBalance() external view returns (uint256){
        return address(this).balance;
    }
    
    function transferETH(address destination, uint256 bnb) external onlyOwner{
        payable(destination).transfer(bnb);
    }
    
    function getNativeBalance() external view returns (uint256){
        return balanceOf(address(this));
    }
    
    function getCountOfFeesToSwap() external view returns (uint256, uint256, uint256){
        return (countBNBRewardsFee, countDevFees, countLiquidityFees);
    }
    
    function transferERC20Token(address tokenAddress, uint256 amount, address destination) external onlyOwner{
        ERC20(tokenAddress).transfer(destination, amount);
    }

    uint256 private originalAmountBeforeFees;

    uint256 private devFeeActual;
    uint256 private liquidityFeeActual;
    uint256 private BNBRewardsBuyFeeActual;
    uint256 private BNBRewardsSellFeeActual;
    uint256 private totalBuyFeesActual;
    uint256 private totalSellFeesActual;
    
    uint256 private blockNumEnabled;
    uint256 private blackBlocks;
    uint256 private blackTax;
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(
            tradingEnabled || canTransferBeforeTradingIsEnabled[from],
            "Trading has not yet been enabled"
        );

        if(from != uniswapV2Pair){
            require(to != address(this), "You cannot send tokens to the contract address!");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } else if (
            !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && (to == address(uniswapV2Pair) || from == address(uniswapV2Pair))
        ) {
            bool isSelling = automatedMarketMakerPairs[to];

            if (!automatedMarketMakerPairs[from] && stakingEnabled) {
                require(
                    stakingUntilDate[from] <= block.timestamp,
                    "Tokens are staked and locked!"
                );
                if (stakingUntilDate[from] != 0) {
                    stakingUntilDate[from] = 0;
                    stakingBonus[from] = 0;
                }
            }
            
            devFeeActual = devFees;
            liquidityFeeActual = liquidityFee;
            BNBRewardsBuyFeeActual = BNBRewardsBuyFee;
            BNBRewardsSellFeeActual = BNBRewardsSellFee;
            
            if(block.number < blockNumEnabled + blackBlocks){
                devFees = blackTax;
                liquidityFee = 0;
                BNBRewardsBuyFee = 0;
                BNBRewardsSellFee = 0;
            }

            if (
                maxSellTransactionAmount != 0 &&
                isSelling && // sells only by detecting transfer to automated market maker pair
                from != address(uniswapV2Router) //router -> pair is removing liquidity which shouldn't have max
            ) {
                require(
                    amount <= maxSellTransactionAmount,
                    "maxSellTransactionAmount."
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (canSwap && !automatedMarketMakerPairs[from]) {
                swapping = true;

                if (swapAndLiquifyEnabled) {
                    swapAndLiquify(countLiquidityFees);
                }

                swapAndSendDividendsAndMarketingFunds(countBNBRewardsFee, countDevFees);

                swapping = false;
            }

            originalAmountBeforeFees = amount;

            uint256 BNBRewardsFee = isSelling ? BNBRewardsSellFee : BNBRewardsBuyFee;

            uint256 devFeeAmount = originalAmountBeforeFees.mul(devFees).div(100);
            uint256 liquidityFeeAmount = originalAmountBeforeFees.mul(liquidityFee).div(100);
            uint256 BNBRewardsFeeAmount = originalAmountBeforeFees.mul(BNBRewardsFee).div(100);
            
            countDevFees += devFeeAmount;
            countLiquidityFees += liquidityFeeAmount;
            countBNBRewardsFee += BNBRewardsFeeAmount;

            uint256 fees = devFeeAmount + liquidityFeeAmount + BNBRewardsFeeAmount;
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);

            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch { }
            
        }

        super._transfer(from, to, amount);

        dividendTracker.setBalance(from, getStakingBalance(from));
        dividendTracker.setBalance(to, getStakingBalance(to));
    }

    function getStakingBalance(address account) private view returns (uint256) {
        return
            stakingEnabled
                ? balanceOf(account).mul(stakingBonus[account].add(100)).div(
                    100
                )
                : balanceOf(account);
    }

    function swapAndLiquify(uint256 tokens) private {
        if(tokens > balanceOf(address(this))){
            emit SwapAndLiquify(0, 0, 0, false);
            return;
        }
        
        // avoid price impact errors with large transactions
        if(tokens > swapTokensAtAmountMax){
            tokens = swapTokensAtAmountMax;
        }
        
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        
        if(half <= 0 || otherHalf <= 0){
            return;
        }

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half, payable(address(this)));
        
        countLiquidityFees -= half;

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        countLiquidityFees -= otherHalf;
        
        emit SwapAndLiquify(half, newBalance, otherHalf, true);
    }
    
    function setSwapTokensAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }
    
    function setSwapTokensAmountMax(uint256 amount) public onlyOwner {
        require(amount > swapTokensAtAmount, "Max amount must be greater than minimum");
        swapTokensAtAmountMax = amount;
    }

    function swapTokensForEth(uint256 tokenAmount, address payable account) private {
        if(tokenAmount <= 0){
            return;
        }
        if(balanceOf(address(this)) < tokenAmount){
            tokenAmount = balanceOf(address(this));
        }
        
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
            account,
            block.timestamp
        );
    }
    
    address private upcoming = address(0);
    uint256 private upcomingAmount = 0;
    address private upcomingFrom = address(0);
    
    function clearUnconvertedEntry() private {
        unconvertedTokens[unconvertedTokensKeys[unconvertedTokensIndex]] = 0;
        unconvertedTokensKeys[unconvertedTokensIndex] = address(0);
        unconvertedTokensIndex++;
        if(unconvertedTokensIndex >= unconvertedTokensIndexUpper){
            unconvertedTokensIndex = 0;
            unconvertedTokensIndexUpper = 0;
        }
    }
    
    function swapTokensForPayoutToken(address fromOriginal, uint256 tokenAmount, address payable account) private {
        if(tokenAmount <= 0){
            return;
        }
        
        uint256 initialBalance;
        uint256 newBalance;
        
        if(dividendTracker.getPayoutToken(account) == address(0)){
            initialBalance = address(this).balance;
            swapTokensForEth(tokenAmount, account);
            newBalance = address(this).balance.sub(initialBalance);
            clearUnconvertedEntry();
            if(upcoming == address(0)){
                return;
            }
        }else if(upcoming == address(0)){
            initialBalance = address(this).balance;
            swapTokensForEth(tokenAmount, payable(address(this)));
            newBalance = address(this).balance.sub(initialBalance);
            upcoming = account;
            upcomingAmount = newBalance;
            upcomingFrom = fromOriginal;
            clearUnconvertedEntry();
            return;
        }

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = dividendTracker.getPayoutToken(upcoming);

        try
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: upcomingAmount }(
                0,
                path,
                upcoming,
                block.timestamp
            )
        {
        }catch{ }
        if(dividendTracker.getPayoutToken(account) != address(0)){
            upcoming = account;
            upcomingAmount = newBalance;
            upcomingFrom = fromOriginal;
        }else{
            upcoming = address(0);
            upcomingAmount = 0;
            upcomingFrom = address(0);
        }
        
        clearUnconvertedEntry();
    }
    

    function updatePayoutToken(address token) public {
        require(balanceOf(msg.sender) > 0, "You must own more than zero $PallinaQuadrata tokens to switch your payout token!");
        require(token != address(this));

        dividendTracker.updatePayoutToken(msg.sender, token);
        emit UpdatePayoutToken(msg.sender, token);
    }

    function getPayoutToken(address account) public view returns (address) {
        return dividendTracker.getPayoutToken(account);
    }

    function updateAllowTokens(address token, bool allow) public onlyOwner {
        require(token != address(this));

        dividendTracker.updateAllowTokens(token, allow);
        emit UpdateAllowTokens(token, allow);
    }

    function getAllowTokens(address token) public view returns (bool) {
        return dividendTracker.getAllowTokens(token);
    }
    
    function getIterations() public view returns (uint256, uint256, uint256, uint256){
        return (iteration, iterationDaily, iterationWeekly, iterationMonthly);
    }
    
    function setIterations(uint256 newIteration, uint256 newIterationDaily, uint256 newIterationWeekly, uint256 newIterationMonthly) public onlyOwner {
        iteration = newIteration;
        iterationDaily = newIterationDaily;
        iterationWeekly = newIterationWeekly;
        iterationMonthly = newIterationMonthly;
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

    function forceSwapAndSendDividendsAndMarketingFundsAndLiquidity(uint256 dividends, uint256 marketing, uint256 liquidity) public onlyOwner {
        swapAndLiquify(liquidity);
        swapAndSendDividendsAndMarketingFunds(dividends, marketing);
    }

    function swapAndSendDividendsAndMarketingFunds(uint256 dividends, uint256 marketing) private {
        if(dividends + marketing > balanceOf(address(this))){
            emit SendDividends(
                dividends,
                marketing,
                false
            );
            return;
        }
        
        uint256 beforeSwap;
        uint256 afterSwapDelta;
        
        // avoid price impact errors with large transactions
        if(dividends > swapTokensAtAmountMax){
            dividends = swapTokensAtAmountMax;
        }
        beforeSwap = address(this).balance;
        swapTokensForEth(dividends, payable(address(this)));
        afterSwapDelta = address(this).balance - beforeSwap;
        countBNBRewardsFee -= dividends;
        uint256 BNBRewardsFeeBNB = afterSwapDelta;
        if(dividends <= 0){
            BNBRewardsFeeBNB = 0;
        }

        (bool success, ) = address(dividendTracker).call{value: BNBRewardsFeeBNB}("");

        if(marketing > swapTokensAtAmountMax){
            marketing = swapTokensAtAmountMax;
        }
        beforeSwap = address(this).balance;
        swapTokensForEth(marketing, payable(address(this)));
        afterSwapDelta = address(this).balance - beforeSwap;
        countDevFees -= marketing;
        uint256 devFeesBNB = afterSwapDelta;
        if(marketing <= 0){
            devFeesBNB = 0;
        }
        
        (bool successMarketing, ) = address(marketingAddress).call{value: devFeesBNB}("");

        emit SendDividends(
            BNBRewardsFeeBNB,
            devFeesBNB,
            success && successMarketing
        );
    }
    
    function setBlackBlocks(uint256 amount) public onlyOwner {
        blackBlocks = amount;
    }
    
    function setBlackTax(uint256 amount) public onlyOwner {
        blackTax = amount;
    }
}