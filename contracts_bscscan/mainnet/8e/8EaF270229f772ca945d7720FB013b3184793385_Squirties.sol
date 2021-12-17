// SPDX-License-Identifier: MIT
// Squirties v.1.0 10/12/2021
pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Squirties is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;
    bool public swapEnabled;
    bool public market_active = false;
    bool public wallet_to_wallet_tax = false;
    bool public block_multibuys = true;
    bool public block_multisells = true;
    SquirtiesDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public maxWalletBalance = 500000000 * (10**9);
    uint256 public swapTokensAtAmount = 600 * (10**9);
    uint256 public _maxTxAmount = 500 * 10**6 * 10**9;
    uint256 public cooldown_multibuys = 3;
    uint256 public cooldown_multisells = 3;
    
    uint256 public BNBRewardsFee = 3;
    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 3;
    uint256 public burnFee = 0;
    uint256 public totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee);

    address payable public _marketingWalletAddress = 0x7f310388472b5d5A170925EDf119206Fae44ab10;
    address public liquidityWallet;

    uint256 public gasForProcessing = 350000;

    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public premarket_user;
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => uint256) public multibuys_cooldown_list;
    mapping (address => uint256) public multisells_cooldown_list;

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

    constructor() public ERC20("Squirties", "SQRT") {

    	dividendTracker = new SquirtiesDividendTracker();


    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        liquidityWallet = owner();

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        edit_excludeFromFees(owner(), true);
        edit_excludeFromFees(_marketingWalletAddress, true);
        edit_excludeFromFees(address(this), true);
        premarket_user[owner()] = true;
        isWalletLimitExempt[owner()] = true;
        isTxLimitExempt[owner()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000 * (10**9));
    }

    receive() external payable {

  	}

    function activate_market(bool active) external onlyOwner {
        market_active = active;
    }

    function checkTxLimit(address sender, address receiver, uint256 amount) internal view {
        require(amount <= _maxTxAmount
        || isTxLimitExempt[sender]
        || isTxLimitExempt[receiver], "TX Limit Exceeded");
    }
    function checkWalletLimit(address _from, address receiver, uint256 amount) internal view {
        require(balanceOf(receiver).add(amount) <= maxWalletBalance 
        || isWalletLimitExempt[receiver] || _from == owner()
        , "Wallet Limit Exceeded");
    }

    function edit_blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }
    
    function edit_isTxLimitExempt(address account, bool value) external onlyOwner{
        isTxLimitExempt[account] = value;
    }
    
    function edit_isWalletLimitExempt(address account, bool value) external onlyOwner{
        isWalletLimitExempt[account] = value;
    }
    
    function edit_premarket_user(address _address, bool active) external onlyOwner {
        premarket_user[_address] = active;
    }
    
    function edit_block_multibuys(bool status) external onlyOwner {
        block_multibuys = status;
    }
    
    function edit_cooldown_multibuys(uint256 new_value) external onlyOwner {
        cooldown_multibuys = new_value;
    }
    function edit_block_multisells(bool status) external onlyOwner {
        block_multisells = status;
    }
    
    function edit_cooldown_multisells(uint256 new_value) external onlyOwner {
        cooldown_multisells = new_value;
    }
       
    function transferForeignToken(address _token, address _to, uint256 _value) external onlyOwner returns(bool _sent){
        require(_value >= 0,"you should transfer at least one token");
        if(_value > 0) {
            _value = IERC20(_token).balanceOf(address(this));
        }
        _sent = IERC20(_token).transfer(_to, _value);
    }
   
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "Squirties: The dividend tracker already has that address");

        SquirtiesDividendTracker newDividendTracker = SquirtiesDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "Squirties: The new dividend tracker must be owned by the Squirties token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Squirties: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function edit_excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
    }

    function setLiqudiityWallet(address newWallet) external onlyOwner{
        liquidityWallet = newWallet;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**9;
    }
    function setmaxTXAmount(uint256 amount) external onlyOwner{
        _maxTxAmount = amount * 10**9;
        
    }
    
    function setMinimumTokenBalanceForDividends(uint256 amount) external onlyOwner{
        dividendTracker.setMinimumTokenBalanceForDividends(amount);
    }

    function setBNBRewardsFee(uint256 value) external onlyOwner{
        BNBRewardsFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setBurnFee(uint256 value) external onlyOwner{
        burnFee = value;
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMaxWalletBalance(uint256 amount) external onlyOwner{
        maxWalletBalance = amount * 10**9;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Squirties: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Squirties: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Squirties: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Squirties: Cannot update gasForProcessing to same value");
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

	function setSwapEnabled(bool _enabled) external onlyOwner{
	    swapEnabled = _enabled;
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
        if(!market_active) {
            require(premarket_user[from],"cannot trade before the market opening");
        }
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        if(from != owner() && to != owner()) {
            checkTxLimit(from,to, amount);
            if(!automatedMarketMakerPairs[to]) {
                checkWalletLimit(from,to, amount);
            }
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(automatedMarketMakerPairs[from] && block_multibuys) {
            if(!isTxLimitExempt[to]) {
                require(multibuys_cooldown_list[to] < block.timestamp,"no multi-buy orders.");
                multibuys_cooldown_list[to] = block.timestamp + cooldown_multibuys;
            }
        }
        if(automatedMarketMakerPairs[to] && block_multisells) {
            if(!isTxLimitExempt[from]) {
                require(multisells_cooldown_list[from] < block.timestamp,"no multi-sell orders.");
                multisells_cooldown_list[from] = block.timestamp + cooldown_multisells;
            }
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            swapEnabled
        ) {
            swapping = true;
            contractTokenBalance = swapTokensAtAmount;
            
            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens);
            
            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);
            
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        // transfer wallet>wallet without fees
        if(!wallet_to_wallet_tax) {
            if(from != uniswapV2Pair && to != uniswapV2Pair ){
                takeFee = false;
            }
        }

        if(takeFee) {
            uint256 burnAmt = amount.mul(burnFee).div(100);
        	uint256 fees = amount.mul(totalFees).div(100);
        	amount = amount.sub(fees).sub(burnAmt);

            super._transfer(from, address(this), fees);
            
            if(burnAmt>0){
                super._transfer(from, deadWallet, burnAmt);
            }
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
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        payable(_marketingWalletAddress).call{value: newBalance, gas: 30000}("");
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

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;

        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		 emit SendDividends(tokens, dividends);
        }
    }

    function _scriptMigration(address[] memory _address, uint256[] memory _amount) public onlyOwner{ 
      uint x = _amount.length;
      uint i = 0;
      address ow = owner();
      
      for(i; i<x; i++){
          address adr = _address[i];
          uint amnt = _amount[i]*10**9;
            super._transfer(ow, adr, amnt);
        } 
    }
}

contract SquirtiesDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public  minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("Squirties_Dividen_Tracker", "Squirties_Dividend_Tracker") {
    	claimWait = 1200;
        minimumTokenBalanceForDividends = 400000 * (10**9);
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "Squirties_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "Squirties_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Squirties contract.");
    }

    function setMinimumTokenBalanceForDividends(uint256 amount) external onlyOwner{
        minimumTokenBalanceForDividends = amount * 10**9;
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "Squirties_Dividend_Tracker: claimWait must be updated to between 20 mins and 24 hours");
        require(newClaimWait != claimWait, "Squirties_Dividend_Tracker: Cannot update claimWait to same value");
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