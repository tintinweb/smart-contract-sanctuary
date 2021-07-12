// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Daisy is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public immutable bounceFixedSaleWallet;
    bool private swapping;
    DaisyDividendTracker public dividendTracker;
    address public liquidityWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public maxSellTransactionAmount = 2000000 * (10**18);

     uint256 public swapTokensAtAmount = 200000 * (10**18);
     uint256 public burnTokensAtEthAmount = 5 * (10**17);
    uint256 public liquidityFee = 25;

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
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;
    mapping (address => bool) public fixedSaleEarlyParticipants;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event FixedSaleEarlyParticipantsAdded(address[] participants);
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

    constructor(address team_, address liquidityWallet_) public ERC20("Daisy", "Daisy") {
    	dividendTracker = new DaisyDividendTracker();
    	liquidityWallet = liquidityWallet_;
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //BSC
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        address _bounceFixedSaleWallet = team_;
        bounceFixedSaleWallet = _bounceFixedSaleWallet;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        // dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        // dividendTracker.excludeFromDividends(_bounceFixedSaleWallet);
        dividendTracker.excludeFromDividends(burnAddress);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(team_, true);

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[_bounceFixedSaleWallet] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(team_, 20 * 1e8 * 1e18);
    }

    receive() external payable {
  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "Daisy: The dividend tracker already has that address");
        DaisyDividendTracker newDividendTracker = DaisyDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "Daisy: The new dividend tracker must be owned by the Daisy token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        // newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(burnAddress);

        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Daisy: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Daisy: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function addFixedSaleEarlyParticipants(address[] calldata accounts) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            fixedSaleEarlyParticipants[accounts[i]] = true;
        }
        emit FixedSaleEarlyParticipantsAdded(accounts);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Daisy: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Daisy: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "Daisy: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Daisy: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Daisy: Cannot update gasForProcessing to same value");
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
        require(dividendTracker.lastClaimTimes(msg.sender)<=block.timestamp, "Daisy: Can't claim");
		dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }
    
    function getPairBalance() public view returns (uint256 pairBalance){
        IERC20 WETH = IERC20(uniswapV2Router.WETH());
        pairBalance = WETH.balanceOf(uniswapV2Pair);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        bool tradingIsEnabled = getTradingIsEnabled();
        // only whitelisted addresses can make transfers after the fixed-sale has started
        // and before the public presale is over
        if(!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "Daisy: This account cannot send tokens until trading is enabled");
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        bool isFixedSaleBuy = from == bounceFixedSaleWallet && to != owner();
        // the fixed-sale can only send tokens to the owner or early participants of the fixed sale in the first 10 minutes,
        // or 600 transactions, whichever is first.
        if(isFixedSaleBuy) {
            require(block.timestamp >= fixedSaleStartTimestamp, "Daisy: The fixed-sale has not started yet.");
            bool openToEveryone = block.timestamp.sub(fixedSaleStartTimestamp) >= fixedSaleEarlyParticipantDuration ||
                                  numberOfFixedSaleBuys >= fixedSaleEarlyParticipantBuysThreshold;
            if(!openToEveryone) {
                require(fixedSaleEarlyParticipants[to], "Daisy: The fixed-sale is only available to certain participants at the start");
            }
            if(!fixedSaleBuyers[to]) {
                fixedSaleBuyers[to] = true;
                numberOfFixedSaleBuys = numberOfFixedSaleBuys.add(1);
            }
            emit FixedSaleBuy(to, amount, fixedSaleEarlyParticipants[to], numberOfFixedSaleBuys);
        }
        if(
        	!swapping &&
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        uint256 totalFees;
        uint256 pairBalance = getPairBalance();
        if(automatedMarketMakerPairs[from]){
            if(pairBalance <= 1000 * 1e18)
                totalFees = 25;
            else if(pairBalance <= 2000 * 1e18)
                totalFees = 20;
            else if(pairBalance <= 4000 * 1e18)
                totalFees = 15;
            else
                totalFees = 10;
        }else{
            if(pairBalance <= 1000 * 1e18)
                totalFees = 15;
            else if(pairBalance <= 2000 * 1e18)
                totalFees = 20;
            else if(pairBalance <= 4000 * 1e18)
                totalFees = 25;
            else
                totalFees = 30;
        }

        if(
            tradingIsEnabled &&
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;
            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(100);
            swapAndLiquify(swapTokens);
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);
            swapping = false;
        }

        bool takeFee = !isFixedSaleBuy && tradingIsEnabled && !swapping;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);

        if(!dividendTracker.excludedFromDividends(from)) {
            try dividendTracker.clearDividend(payable(from)) {} catch {}
        }
        uint256 ethBalance = address(this).balance;
        if(ethBalance >= burnTokensAtEthAmount){
            swapEthForTokensToBurn(ethBalance);
        }

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {}
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

    function swapEthForTokensToBurn(uint256 ethAmount) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        // make the swap
        try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of Tokens
            path,
            burnAddress,
            block.timestamp
        ) {} catch {}
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
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        // how much ETH did we just swap into?
        uint256 dividends = address(this).balance.sub(initialBalance);
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }
}

contract DaisyDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("Daisy_Dividend_Tracker", "Daisy_Dividend_Tracker") {
        minimumTokenBalanceForDividends = 20000 * (10**18); //must hold 20000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "Daisy_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "Daisy_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Daisy contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	if(excludedFromDividends[account]) return;
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "Daisy_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Daisy_Dividend_Tracker: Cannot update claimWait to same value");
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
            } else {
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
    	    if(lastClaimTimes[account] == 0)
    	        lastClaimTimes[account] = block.timestamp.add(firstClaimWait);
    	    else
    		    lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}
    	return false;
    }

    uint256 public claimWait = 3600;
    uint256 public firstClaimWait = 86400;

    event Clear(address indexed account, uint256 amount);
    event DividendClear(address indexed to, uint256 weiAmount);

    function clearDividend(address account) public onlyOwner returns (bool) {
        uint256 amount = _clearDividendOfUser(account);
		lastClaimTimes[account] = block.timestamp.add(firstClaimWait);
    	if(amount > 0) {
            emit Clear(account, amount);
    		return true;
    	}
    	return false;
    }

    function _clearDividendOfUser(address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendClear(user, _withdrawableDividend);
            (bool success,) = payable(owner()).call{value: _withdrawableDividend, gas: 3000}("");
            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }
}