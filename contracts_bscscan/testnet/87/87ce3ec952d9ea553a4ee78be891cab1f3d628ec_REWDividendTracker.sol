// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./RewManagerInterface.sol";


contract BABY09 is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    CAKEDividendTracker public cakeDividendTracker;
    REWDividendTracker public rewDividendTracker;
    
    RewManagerInterface public MDIV = RewManagerInterface(0xe9c8a83066945701fb9153A864752a4BDd737BdB); // TODO

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public immutable CAKE = address(0x9BAC35cccb8A7de5fDa6425B6B05e13604a378c2); //CAKE
 
    uint256 public swapTokensAtAmount = 1000000 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    uint256 public _cakeBuyFee = 6;
    uint256 public _devBuyFee = 1;
    uint256 public _marketingBuyFee = 3;
    
    uint256 public _minRewSellFee = 6;
    uint256 public _maxRewSellFee = 22;
    uint256 public _devSellFee = 3;
    uint256 public _marketingSellFee = 5;
    uint256 public _dailySellFeeDiscount = 2;

    uint256 public _cakeRewardsBalance = 0;
    uint256 public _rewRewardsBalance = 0;
    uint256 public _marketingFeeBalance = 0;
    uint256 public _devFeeBalance = 0;

    address payable public _marketingWalletAddress = 0x4b24df2fbC81C437E4F6732edD9558DA8ED816a2;
    address payable public _devWalletAddress = 0xD0CEA25E0573130f90B045261580F17b1C9c7984;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    
    // Record the time of the last buy for each address, for sell tax cooldown.
    mapping (address => uint256) public lastBuy;
    event SellFeeDebug(uint256 rewSellFee, uint256 daysSinceLastBuy, uint256 feeReduction);

    event UpdateCakeDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateRewDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SendCakeDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );
    
    event SendRewDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedCakeDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    event ProcessedRewDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );


    constructor() public ERC20("BABY09", "BABY09") {

    	cakeDividendTracker = new CAKEDividendTracker();
    	rewDividendTracker = new REWDividendTracker(MDIV);


    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        cakeDividendTracker.excludeFromDividends(address(cakeDividendTracker));
        cakeDividendTracker.excludeFromDividends(address(rewDividendTracker));
        cakeDividendTracker.excludeFromDividends(address(this));
        cakeDividendTracker.excludeFromDividends(owner());
        cakeDividendTracker.excludeFromDividends(deadWallet);
        cakeDividendTracker.excludeFromDividends(address(_uniswapV2Router));
        
        rewDividendTracker.excludeFromDividends(address(cakeDividendTracker));
        rewDividendTracker.excludeFromDividends(address(rewDividendTracker));
        rewDividendTracker.excludeFromDividends(address(this));
        rewDividendTracker.excludeFromDividends(owner());
        rewDividendTracker.excludeFromDividends(deadWallet);
        rewDividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateCakeDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(cakeDividendTracker), "BABYCAKE: The Cake dividend tracker already has that address");

        CAKEDividendTracker newDividendTracker = CAKEDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BABYCAKE: The new Cake dividend tracker must be owned by the BABYCAKE token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(rewDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateCakeDividendTracker(newAddress, address(cakeDividendTracker));

        cakeDividendTracker = newDividendTracker;
    }
    
    function updateRewDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(cakeDividendTracker), "BABYCAKE: The REW dividend tracker already has that address");

        REWDividendTracker newDividendTracker = REWDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BABYCAKE: The new REW dividend tracker must be owned by the BABYCAKE token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(cakeDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateRewDividendTracker(newAddress, address(rewDividendTracker));

        rewDividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BABYCAKE: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BABYCAKE: Account is already the value of 'excluded'");
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

    function setDevWallet(address payable wallet) external onlyOwner{
        _devWalletAddress = wallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BABYCAKE: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BABYCAKE: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            rewDividendTracker.excludeFromDividends(pair);
            cakeDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BABYCAKE: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BABYCAKE: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        cakeDividendTracker.updateClaimWait(claimWait);
        rewDividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return cakeDividendTracker.claimWait();
    }

    function getTotalCakeDividendsDistributed() external view returns (uint256) {
        return cakeDividendTracker.totalDividendsDistributed();
    }
    
    function getTotalRewDividendsDistributed() external view returns (uint256) {
        return MDIV.dividendsDistributed(rewDividendTracker);
    }
    

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableCakeDividendOf(address account) public view returns(uint256) {
    	return cakeDividendTracker.withdrawableDividendOf(account);
  	}

    function withdrawableRewDividendOf(address account) public view returns(uint256) {
    	return MDIV.withdrawableDividendOf(rewDividendTracker,account);
  	}

	function cakeDividendTokenBalanceOf(address account) public view returns (uint256) {
		return cakeDividendTracker.balanceOf(account);
	}
	
	function rewDividendTokenBalanceOf(address account) public view returns (uint256) {
		return rewDividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    cakeDividendTracker.excludeFromDividends(account);
	    rewDividendTracker.excludeFromDividends(account);
	}

    function getAccountCakeDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return cakeDividendTracker.getAccount(account);
    }
    
    function getAccountRewDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return rewDividendTracker.getAccount(account);
    }

	function getAccountCakeDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return cakeDividendTracker.getAccountAtIndex(index);
    }
    
    function getAccountRewDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return rewDividendTracker.getAccountAtIndex(index);
    }

	function processCakeDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = cakeDividendTracker.process(gas);
		emit ProcessedCakeDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

	function processRewDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = rewDividendTracker.process(gas);
		emit ProcessedRewDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claimCake() external {
		cakeDividendTracker.processAccount(msg.sender, false);
    }
    
    function claimRew() external {
		rewDividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedCakeIndex() external view returns(uint256) {
    	return cakeDividendTracker.getLastProcessedIndex();
    }

    function getLastProcessedRewIndex() external view returns(uint256) {
    	return rewDividendTracker.getLastProcessedIndex();
    }

    function getNumberOfCakeDividendTokenHolders() external view returns(uint256) {
        return cakeDividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfRewDividendTokenHolders() external view returns(uint256) {
        return rewDividendTracker.getNumberOfTokenHolders();
    }

    function _takeFee(address from, uint256 amount, uint256 cakeFee, uint256 rewFee, uint256 marketingFee, uint256 devFee) internal returns (uint256) {
        uint256 cakeTokens = amount.mul(cakeFee).div(100);
        uint256 rewTokens = amount.mul(rewFee).div(100);
        uint256 marketingTokens = amount.mul(marketingFee).div(100);
        uint256 devTokens = amount.mul(devFee).div(100);
        
        uint256 totalFeeTokens = cakeTokens.add(rewTokens).add(marketingTokens).add(devTokens);
        
        _cakeRewardsBalance = _cakeRewardsBalance.add(cakeTokens);
        _rewRewardsBalance = _rewRewardsBalance.add(rewTokens);
        _marketingFeeBalance = _marketingFeeBalance.add(marketingTokens);
        _devFeeBalance = _devFeeBalance.add(devTokens);
        
        super._transfer(from, address(this), totalFeeTokens);
        
        return totalFeeTokens;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if( !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            if(_rewRewardsBalance >= swapTokensAtAmount) {
                swapAndSendRewDividends(_rewRewardsBalance);
                _rewRewardsBalance = 0;
            }
            
            if(_cakeRewardsBalance >= swapTokensAtAmount) {
                swapAndSendCakeDividends(_cakeRewardsBalance);
                _cakeRewardsBalance = 0;
            }
            
            if(_marketingFeeBalance >= swapTokensAtAmount) {
                swapAndSendToFee(_marketingFeeBalance,_devFeeBalance);
                _marketingFeeBalance = 0;
                _devFeeBalance = 0;
            }

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 totalFeeTokens = 0;
            if(automatedMarketMakerPairs[to]) {
                // Sell fees
                uint256 rewSellFee = _minRewSellFee;

                uint256 secondsSinceLastBuy = block.timestamp.sub(lastBuy[from]);
                uint256 daysSinceLastBuy = secondsSinceLastBuy.div(5 minutes);  // XXX TODO 
                uint256 feeReduction = daysSinceLastBuy.mul(_dailySellFeeDiscount);
                
                // This math avoids unsigned underflow and provides a floor of _minRewSellFee
                if(feeReduction < _maxRewSellFee.sub(_minRewSellFee)) {
                    rewSellFee = _maxRewSellFee.sub(feeReduction);
                }
                
                emit SellFeeDebug(rewSellFee,daysSinceLastBuy,feeReduction);
                
                totalFeeTokens = _takeFee(from, amount, 0, rewSellFee, _marketingSellFee, _devSellFee);
            } else {
                // Buy fees
                totalFeeTokens = _takeFee(from, amount, _cakeBuyFee, 0, _marketingBuyFee, _devBuyFee);
            }
        	amount = amount.sub(totalFeeTokens);
        }

        super._transfer(from, to, amount);
        lastBuy[to] = block.timestamp;

        try cakeDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try cakeDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try rewDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try rewDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try cakeDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedCakeDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
	    	
	        try rewDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedRewDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndSendToFee(uint256 marketingTokens, uint256 devTokens) private  {
        uint256 totalTokens = marketingTokens.add(devTokens);
        
        swapTokensForEth(totalTokens);
        
        // compute marketing share of ETH
        uint256 marketingETH = address(this).balance.mul(marketingTokens).div(marketingTokens.add(devTokens));
        
        // We are careful not to leave any ETH in the contract between transactions, so we can
        // just send all ETH.
        _marketingWalletAddress.transfer(marketingETH);
        _devWalletAddress.transfer(address(this).balance);
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
    
    function swapAndSendCakeDividends(uint256 tokens) private{
        swapTokensForCake(tokens);
        uint256 dividends = IERC20(CAKE).balanceOf(address(this));
        bool success = IERC20(CAKE).transfer(address(cakeDividendTracker), dividends);

        if (success) {
            cakeDividendTracker.distributeCAKEDividends(dividends);
            emit SendCakeDividends(tokens, dividends);
        }
    }
    
    function swapAndSendRewDividends(uint256 tokens) private{
        swapTokensForEth(tokens);
        uint256 totalEth = address(this).balance;
        rewDividendTracker.distributeDividends{value:totalEth}();
        emit SendRewDividends(tokens, totalEth);
    }
    
}

contract REWDividendTracker is Ownable, ERC20 {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    
    RewManagerInterface MDIV;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(RewManagerInterface rm) public ERC20("REW_Dividend_Tracker", "REW_Dividend_Tracker") {
        MDIV = rm;
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "REW_Dividend_Tracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

        uint256 amount = super.balanceOf(account);
        if(amount > 0) {
            super._burn(account,amount);
            MDIV.clientBurn(account,amount);
        }
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "BABYCAKE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BABYCAKE_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    
    function distributeDividends() external payable {
        uint256 amount = msg.value;
        MDIV.distributeDividends{value : amount}();
    }

    // We use this rather than a "transfer" operation to capture all balance changes.
    // This is necessary because balances in this contract aren't always the same as
    // balances in the main contract (for accounts that are excluded from dividends).
    // When a transfer occurs from one of those accounts, it doesn't really make 
    // sense here.
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
    		return;
    	}

        uint256 oldBalance = super.balanceOf(account);
        
        if(newBalance >= minimumTokenBalanceForDividends) {
            if(newBalance > oldBalance) {
                uint256 mintAmount = newBalance.sub(oldBalance);
                super._mint(account,mintAmount);
                MDIV.clientMint(account,mintAmount);
            } else if (newBalance < oldBalance) {
                uint256 burnAmount = oldBalance.sub(newBalance);
                super._burn(account,burnAmount);
                MDIV.clientBurn(account,burnAmount);
            }
            tokenHoldersMap.set(account,newBalance);
        } else {
            super._burn(account, oldBalance);
            tokenHoldersMap.remove(account);
            MDIV.clientBurn(account, oldBalance);
        }

    	processAccount(account, true);
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


        withdrawableDividends = MDIV.withdrawableDividendOf(this,account);
        totalDividends = MDIV.accumulativeDividendOf(this,account);

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
        uint256 amount = MDIV.withdrawDividend(this,account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

contract CAKEDividendTracker is Ownable, DividendPayingToken {
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

    constructor() public DividendPayingToken("CAKE_Dividen_Tracker", "CAKE_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BABYCAKE_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BABYCAKE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BABYCAKE contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "BABYCAKE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BABYCAKE_Dividend_Tracker: Cannot update claimWait to same value");
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