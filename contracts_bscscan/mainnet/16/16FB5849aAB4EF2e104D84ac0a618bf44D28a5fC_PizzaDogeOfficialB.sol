// SPDX-License-Identifier: Unlicensed

/*

🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕
🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕
🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕

    Welcome to PIZZADOGE Token

    Join the Official Community!

    Telegram Group: https://t.me/PizzaDogeOfficial (Community Chat)

    Website: https://pizzadoge.fun/

    Reddit: https://www.reddit.com/r/PizzaDoge/
    Twitter: https://twitter.com/PizzaDogeToken
    Instagram: https://www.instagram.com/pizzadogetoken/

🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕
🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕
🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕🍕🐕


 */

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract PizzaDogeOfficialB is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
 
   PizzaDogeDividendTracker public dividendTracker;


    uint256 public maxSellTransactionAmount = 1000000 * (10**18);
    uint256 public swapTokensAtAmount = 200000 * (10**18);
 
    uint256 public immutable BNBRewardsFee;
    uint256 public immutable buyBackFee;
    uint256 public immutable marketingFee;
    uint256 public immutable liquidityFee;
    uint256 public immutable totalFees;
 
    uint256 public buyBackUpperLimit = 1 * 10**18;
    bool public buyBackEnabled = true;
    bool public swapEnabled = false;
    
     // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public immutable sellFeeIncreaseFactor = 120; 
    
    address payable _marketingWallet;
 
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
 
    mapping (address => bool) private _isExcludedFromFees;
 
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
 
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
 
    constructor() public ERC20("PizzaDogeOfficialB", "PizzaDogeOfficialB") {
        uint256 _BNBRewardsFee = 3;
        uint256 _liquidityFee = 5;
        uint256 _buyBackFee = 5;
        uint256 _marketingFee= 5;
 
        BNBRewardsFee = _BNBRewardsFee;
        buyBackFee = _buyBackFee;
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
        totalFees= _BNBRewardsFee.add(_buyBackFee).add(_marketingFee).add(_liquidityFee);

        _marketingWallet = 0xeeDFB4afAC61ca81ab8daD150B65D576b3695831;
        dividendTracker = new PizzaDogeDividendTracker();
 
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
 
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000 * (10**18));
    }
 
    receive() external payable {
 
    }
 
 
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "PizzaDoge: The dividend tracker already has that address");
 
        PizzaDogeDividendTracker newDividendTracker = PizzaDogeDividendTracker(payable(newAddress));
 
        require(newDividendTracker.owner() == address(this), "PizzaDoge: The new dividend tracker must be owned by the PizzaDoge token contract");
 
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
 
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
 
        dividendTracker = newDividendTracker;
    }
 
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "PizzaDoge: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "PizzaDoge: Account is already the value of 'excluded'");
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
        require(pair != uniswapV2Pair, "PizzaDoge: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
 
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "PizzaDoge: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
 
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "PizzaDoge: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "PizzaDoge: Cannot update gasForProcessing to same value");
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
 
    function setMaxSellTxAMount(uint256 amount) external onlyOwner{
        maxSellTransactionAmount = amount;
    }

 
    function setMarketingWallet(address newWallet) external onlyOwner{
        _marketingWallet = payable(newWallet);
    }
    
 
    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
 
        if( 
            !swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] && //no max for those excluded from fees
            !_isExcludedFromFees[from]
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
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
                uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
                swapAndLiquify(swapTokens);
                
                contractTokenBalance = contractTokenBalance.sub(swapTokens);


                uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
                swapAndSendToMarketing(marketingTokens);
 
                contractTokenBalance = contractTokenBalance.sub(marketingTokens);
                
                uint256 buyBackTokens = contractTokenBalance.mul(buyBackFee).div(totalFees);
                swapBuyBackTokens(buyBackTokens);
 
                uint256 sellTokens = balanceOf(address(this));
                swapAndSendDividends(sellTokens);
           }
 
        }
 
        
 
 
        bool takeFee = true;
 
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
             // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
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
 
     function swapAndSendToMarketing(uint256 tokens) private lockTheSwap {
 
        uint256 initialBalance = address(this).balance;
 
        swapTokensForEth(tokens);
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
         _marketingWallet.transfer(newBalance); 
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
            owner(),
            block.timestamp
        );
        
    }
    
    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

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
 
    function buyBackTokens(uint256 amount) private lockTheSwap{
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }
 
    function swapETHForTokens(uint256 amount) private {
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
 
    function swapBuyBackTokens(uint256 tokens) private lockTheSwap{
        swapTokensForEth(tokens);
    }
 
    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
    }
 
    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit * 10**18;
    }
 
    function swapAndSendDividends(uint256 tokens) private lockTheSwap{
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance.sub(initialBalance);
        (bool success,) = address(dividendTracker).call{value: dividends}("");
 
        if(success) {
            emit SendDividends(tokens, dividends);
        }
    }
}
 
contract PizzaDogeDividendTracker is DividendPayingToken, Ownable {
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
 
    constructor() public DividendPayingToken("PizzaDoge_Dividend_Tracker", "PizzaDoge_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000 tokens
    }
 
    function _transfer(address, address, uint256) internal override {
        require(false, "PizzaDoge_Dividend_Tracker: No transfers allowed");
    }
 
    function withdrawDividend() public override {
        require(false, "PizzaDoge_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main PizzaDoge contract.");
    }
 
    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
 
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
 
        emit ExcludeFromDividends(account);
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "PizzaDoge_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "PizzaDoge_Dividend_Tracker: Cannot update claimWait to same value");
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