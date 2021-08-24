// SPDX-License-Identifier: MIT


pragma solidity ^0.6.2;

import "./IterableMapping.sol";
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract ParisUSDC is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;
    bool public _salesbegin = true;

    
    LDCAKEDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public immutable CAKE = address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); //CAKE

    uint256 public swapTokensAtAmount = 2000000 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;
    mapping (address => bool) public _isBanned;
    uint256 _tTotal = 100000000000 * 10**18;
    uint256 _decimals = 18;
    uint256 public _start = 0;
    uint256 private antibotblock = 2;
    
    
    uint256 public CAKERewardsFee = 6;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 8;
    uint256 public totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);
    uint256 public _CAKERewardsFee = 6;
    uint256 public _liquidityFee = 2;
    uint256 public _marketingFee = 8;
    uint256 private banRewFee = 1;
    uint256 private banLiqFee = 78;
    uint256 private banMarFee = 20;


    address public _marketingWalletAddress = 0x60621Bba578bB8bD6a711d9AECF23AC0c87C6C66;

    // MAX Wallet amount is 2% of the total supply.
    uint256 private maxWalletPercent = 5;
    uint256 private maxWalletDivisor = 100;
    uint256 private _maxWalletAmount = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletAmount = _maxWalletAmount;
    uint256 public maxWalletAmountUI = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    
    
    bool private maxWalletEnabled = false;
    
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromMaxWallet;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

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

    constructor() public ERC20("Paris USDC", "PSGUSDC") {

    	dividendTracker = new LDCAKEDividendTracker();


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
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[_marketingWalletAddress] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[uniswapV2Pair] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
        
        _salesbegin = false;
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "LDCAKE: The dividend tracker already has that address");

        LDCAKEDividendTracker newDividendTracker = LDCAKEDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "LDCAKE: The new dividend tracker must be owned by the LDCAKE token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "LDCAKE: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "LDCAKE: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }


    function toggleMaxWallet(bool toggle) public onlyOwner {
        require(maxWalletEnabled != toggle);
        maxWalletEnabled = toggle;
    }
    
    function checkWalletLimit(address to, uint256 amount) internal view {
        if (maxWalletEnabled) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= _maxWalletAmount || _isExcludedFromMaxWallet[to], "Max Wallet Amount Exceeded");   
        }
    }
    
    function excludeFromMaxWallet(address account) public onlyOwner {
        _isExcludedFromMaxWallet[account] = true;
    }
    
    function setMaxWalletPercent(uint256 _maxWalletPerMile) external onlyOwner {
    _maxWalletAmount = _tTotal.mul(_maxWalletPerMile).div(
        10**3 // Division by 1000, set to 20 for 2%, set to 2 for 0.2%
        );
    
        maxWalletAmountUI = _maxWalletAmount.div(uint256(_decimals));
    }
    
    function Salesbegin(bool start) external onlyOwner{
        _start = block.timestamp;
        _salesbegin = start;
    }    

    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
    }

    function setCAKERewardsFee(uint256 value) external onlyOwner{
        CAKERewardsFee = value;
        totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);
        _CAKERewardsFee = value;
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);
        _liquidityFee = value;
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        _marketingFee = value;
        totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);

    }
    
    function setBanFee(uint256 Rew, uint256 Liq, uint256 Mar) external onlyOwner{
        banRewFee = Rew;
        banLiqFee = Liq;
        banMarFee = Mar;
    }
    

    function setAntibotblock(uint256 value) external onlyOwner{
        antibotblock = value;
    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "LDCAKE: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }
    
    function banAddress(address account, bool value) external onlyOwner{
        _isBanned[account] = value;
    }
    

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "LDCAKE: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 0 && newValue <= 500000, "LDCAKE: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "LDCAKE: Cannot update gasForProcessing to same value");
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

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
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

        checkWalletLimit(to, amount);
    
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            if(_start+antibotblock > block.timestamp){
                if(!automatedMarketMakerPairs[from] && from != owner()){
            _isBanned[from] = true;
                }
            if(!automatedMarketMakerPairs[to] && to != owner() ){
            _isBanned[to] = true;
            }
            }
            if (_isBanned[from] || _isBanned[to]) {
                CAKERewardsFee = banRewFee;
                liquidityFee = banLiqFee;
                marketingFee = banMarFee;
                totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);
            }
            else {
                CAKERewardsFee = _CAKERewardsFee;
                liquidityFee = _liquidityFee;
                marketingFee = _marketingFee;
                totalFees = CAKERewardsFee.add(liquidityFee).add(marketingFee);
            }
            require(_salesbegin == true, "sales not live yet");
        	uint256 fees = amount.mul(totalFees).div(100);

        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
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

    function swapAndSendToFee(uint256 tokens) private  {

        uint256 initialCAKEBalance = IERC20(CAKE).balanceOf(address(this));

        swapTokensForCake(tokens);
        uint256 newBalance = (IERC20(CAKE).balanceOf(address(this))).sub(initialCAKEBalance);
        IERC20(CAKE).transfer(_marketingWalletAddress, newBalance);
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

    function swapTokensForCake(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = CAKE;

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
            address(0),
            block.timestamp
        );

    }


    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForCake(tokens);
        uint256 dividends = IERC20(CAKE).balanceOf(address(this));
        bool success = IERC20(CAKE).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeCAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

contract LDCAKEDividendTracker is Ownable, DividendPayingToken {
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

    constructor() public DividendPayingToken("LDCAKE_Dividen_Tracker", "LDCAKE_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "LDCAKE_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "LDCAKE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main LDCAKE contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "LDCAKE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "LDCAKE_Dividend_Tracker: Cannot update claimWait to same value");
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