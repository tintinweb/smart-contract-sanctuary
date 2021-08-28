// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0;

import "./IDividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IPancakeSwapV2Pair.sol";
import "./IPancakeSwapV2Factory.sol";
import "./IPancakeSwapV2Router01.sol";
import "./IPancakeSwapV2Router02.sol";
import "./SIMPSONSDividendPayingToken.sol";

/**
🍩🍺The Simpsons Token Story 🍺🍩
🍩 FAIRLAUNCH TODAY🍩
🍩  Token Information  🍩

🔸 Token Name : The Simpsons Token Story
🔸 Token Symbol: $SIMPSONS
🔸 Max Supply : 10,000,000,000,000,000 SIMPSONS
🔸 Reflective
    🔸 11% tax in each transaction
    🔸 3% put in liquidity and locked (will be used to buyback and burn)
    🔸 4% marketing
    🔸 1% burn


🍩Website: http://www.thesimpsonscoin.com/
🍩Telegram: https://t.me/thesimpsonstoken
*/
contract SIMPSONS is ERC20, Ownable {
    using SafeMath for uint256;

    IPancakeSwapV2Router02 public PancakeSwapV2Router;
    address public immutable PancakeSwapV2Pair;

    address public immutable BANANA = address(0x2CCb7c8C51E55C2364B555fF6E6e3F7246499e16); // WBTC
	address payable public MarketingWallet = payable(0x2a44948F3580a7353c0E6ADe44d31dE2B8160716); // Marketing Address

    bool private swapping;

    MiniMMADividendTracker public dividendTracker;

    address public liquidityWallet;

    uint256 private _FeeFactor = 10000000000000000 * (10**18); 
	uint256 public _maxTxAmount = 10000000 * (10**18);
	uint256 public _maxWalletAmount = 20000000 * (10**18);
    uint256 private _swapTokensAtAmount = 1000000000 * (10**18);
	
    uint256 public immutable BANANARewardsFee;	
    uint256 public immutable LiquidityFee;
    uint256 private immutable totalFees;
	uint256 public MarketingFee = 5;
	uint256 public BurnFee = 1;
	
	bool public autoBurn = false;

	
    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 private immutable sellFeeIncreaseFactor = 0;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 private gasForProcessing = 300000;
    
    address public presaleAddress = address(0);

	bool public tradingOpen = false;
	
	mapping (address => bool) private _isblacklisted;

    // exlcude from fees and max transaction amount
    mapping (address => bool) public _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforetradingOpen;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event updatePancakeSwapV2Router(address indexed newAddress, address indexed oldAddress);

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
 
    constructor() ERC20("The Simpsons Token Story", "SIMPSONS") {
        uint256 _BANANARewardsFee = 8;
        uint256 _LiquidityFee = 4;

        BANANARewardsFee = _BANANARewardsFee;
        LiquidityFee = _LiquidityFee;
        totalFees = _BANANARewardsFee.add(_LiquidityFee);


        dividendTracker = new MiniMMADividendTracker();

        liquidityWallet = owner();

        
        IPancakeSwapV2Router02 _PancakeSwapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
        //IPancakeSwapV2Router02 _PancakeSwapV2Router = IPancakeSwapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet
         // Create a PancakeSwap pair for this new token
        address _PancakeSwapV2Pair = IPancakeSwapV2Factory(_PancakeSwapV2Router.factory())
            .createPair(address(this), _PancakeSwapV2Router.WETH());

        PancakeSwapV2Router = _PancakeSwapV2Router;
        PancakeSwapV2Pair = _PancakeSwapV2Pair;

        _setAutomatedMarketMakerPair(_PancakeSwapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_PancakeSwapV2Router));
        

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforetradingOpen[owner()] = true;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 10000000000000000 * (10**18));
    }

    receive() external payable {

    }
    

    function WhitelistDxSale(address _presaleAddress, address _routerAddress) public onlyOwner {
        presaleAddress = _presaleAddress;
        canTransferBeforetradingOpen[presaleAddress] = true;
        dividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

        canTransferBeforetradingOpen[_routerAddress] = true;
        dividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "MiniMMA: The dividend tracker already has that address");

        MiniMMADividendTracker newDividendTracker = MiniMMADividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "MiniMMA: The new dividend tracker must be owned by the MiniMMA token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(PancakeSwapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "MiniMMA: Account is already the value of 'excluded'");
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
        require(pair != PancakeSwapV2Pair, "MiniMMA: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "MiniMMA: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "MiniMMA: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "MiniMMA: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "MiniMMA: Cannot update gasForProcessing to same value");
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
    
	function SetFeeFactor(uint256 FeeFactor) external onlyOwner() {
        _FeeFactor= FeeFactor;
    }
    
	function SetmaxTxAmount(uint256 maxTxAmount) external view onlyOwner() {
        maxTxAmount = maxTxAmount;
	}
	
	function SetmaxWalletAmount(uint256 maxWalletAmount) external view onlyOwner() {
        maxWalletAmount = maxWalletAmount;
	}
	
	function setautoBurn(bool _enabled) public onlyOwner {
        autoBurn = _enabled;
	}
    function setswapTokensAtAmount(uint256 swapTokensAtAmount) external onlyOwner() {
        _swapTokensAtAmount = swapTokensAtAmount;
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

	function enableTrading(bool enabled) public onlyOwner{
        tradingOpen = enabled;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
			        require(!_isblacklisted[from], "You are blacklisted");
        require(!_isblacklisted[to], "The recipient is blacklisted");
       
       if(from != owner()){
            require (tradingOpen);
        }

        // only Blacklisted addresses can make transfers after the fixed-sale has started
        // and before the public presale is over
        if(!tradingOpen) {
            require(canTransferBeforetradingOpen[from], "MiniMMA: This account cannot send tokens until trading is enabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if( 
            !swapping &&
            tradingOpen &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
            from != address(PancakeSwapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= _FeeFactor, "Sell transfer amount exceeds the FeeFactor.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        if(
            tradingOpen && 
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance.mul(LiquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = tradingOpen && !swapping;

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

        // add liquidity to PancakeSwap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        
        // generate the PancakeSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeSwapV2Router.WETH();

        _approve(address(this), address(PancakeSwapV2Router), tokenAmount);

        // make the swap
        PancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
	  
		function BlacklistSniperWallet(address addresses) public onlyOwner(){
        if(_isblacklisted[addresses] == true) return;
        _isblacklisted[addresses] = true;
    }
    
    function BlacklistMultipleSniperWallet(address[] calldata addresses) public onlyOwner(){
        require(addresses.length <= 800, "Can only Blacklist 800 addresses per transaction");
        for (uint256 i; i < addresses.length; ++i) {
            _isblacklisted[addresses[i]] = true;
        }
    }
    
    function isblacklisted(address addresses) public view returns (bool){
        return _isblacklisted[addresses];
    }
    
    function unBlacklistSniperWallet(address addresses) external onlyOwner(){
         if(_isblacklisted[addresses] == false) return;
        _isblacklisted[addresses] = false;
    }
    
    function unBlacklistMultipleSniperWallet(address[] calldata addresses) public onlyOwner(){
        require(addresses.length <= 800, "Can only unBlacklist 800 addresses per transaction");
        for (uint256 i; i < addresses.length; ++i) {
            _isblacklisted[addresses[i]] = false;
        }
    }

    function swapTokensForBANANA(uint256 tokenAmount, address recipient) private {
       
        // generate the PancakeSwap pair path of weth -> BANANA
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = PancakeSwapV2Router.WETH();
        path[2] = BANANA;

        _approve(address(this), address(PancakeSwapV2Router), tokenAmount);

        // make the swap
        PancakeSwapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BANANA
            path,
            recipient,
            block.timestamp
        );
        
    }    
    
 


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(PancakeSwapV2Router), tokenAmount);

        // add the liquidity
       PancakeSwapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForBANANA(tokens, address(this));
        uint256 dividends = IERC20(BANANA).balanceOf(address(this));
        bool success = IERC20(BANANA).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeBANANADividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}


contract MiniMMADividendTracker is DividendPayingToken, Ownable {
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

    constructor() DividendPayingToken("MiniMMA_Dividend_Tracker", "MiniMMA_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) internal pure override {
        require(true, "MiniMMA_Dividend_Tracker: No transfers allowed");
    }

    
    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1 && newClaimWait <= 86400, "MiniMMA_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "MiniMMA_Dividend_Tracker: Cannot update claimWait to same value");
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