// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract MATRIXRETOKEN is ERC20, Ownable {
    using SafeMath for uint256;
	
    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
	
    bool private swapping;
	bool public swapAndLiquifyEnabled = true;
	
    MATRIXRETOKENDividendTracker public dividendTracker;
	
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
	address payable public marketingWalletAddress = 0x881a816C4Df06Db62bF25c13F3449B56103e73c3;

    uint256 public swapTokensAtAmount = 500000 * (10**8);
	uint256 public maxTxAmount = 20000000 * (10**8);
	uint256 public maxWalletAmount = 30000000 * (10**8);
	
	uint256[] public BNBRewardsFee;
	uint256[] public liquidityFee;
	uint256[] public marketingFee;
	
	uint256 private tokenToSwap;
	uint256 private tokenToMarketing;
	uint256 private tokenToLiqudity;
	uint256 private tokenToReward;
	uint256 private tokenToLiqudityHalf;
	
	uint256 public BNBRewardsFeeTotal;
	uint256 public liquidityFeeTotal;
	uint256 public marketingFeeTotal;
    uint256 public gasForProcessing = 300000;

    mapping (address => bool) private _isExcludedFromFees;
	mapping (address => bool) public isExcludedFromMaxWalletToken;
    mapping (address => bool) public automatedMarketMakerPairs;

	event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    constructor() public ERC20("MATRIX RETOKEN", "MATRIX RETOKEN") {

    	dividendTracker = new MATRIXRETOKENDividendTracker();
		
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
		
		isExcludedFromMaxWalletToken[_uniswapV2Pair] = true;
		isExcludedFromMaxWalletToken[address(this)] = true;
		isExcludedFromMaxWalletToken[owner()] = true;

        excludeFromFees(owner(), true);
        excludeFromFees(marketingWalletAddress, true);
        excludeFromFees(address(this), true);
		
		BNBRewardsFee.push(500);
		BNBRewardsFee.push(500);
		BNBRewardsFee.push(500);
		
		liquidityFee.push(300);
		liquidityFee.push(300);
		liquidityFee.push(300);
		
		marketingFee.push(200);
		marketingFee.push(200);
		marketingFee.push(200);
		
        _mint(owner(), 1000000000 * (10**8));
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "MATRIXRETOKEN: The dividend tracker already has that address");
        MATRIXRETOKENDividendTracker newDividendTracker = MATRIXRETOKENDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "MATRIXRETOKEN: The new dividend tracker must be owned by the MATRIXRETOKEN token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "MATRIXRETOKEN: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "MATRIXRETOKEN: Account is already the value of 'excluded'");
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
        marketingWalletAddress = wallet;
    }
	
    function setBNBRewardsFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner{
        BNBRewardsFee[0] = buy;
		BNBRewardsFee[0] = sell;
		BNBRewardsFee[0] = p2p;
    }
	
    function setLiquiditFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner{
        liquidityFee[0] = buy;
		liquidityFee[0] = sell;
		liquidityFee[0] = p2p;
    }
	
    function setMarketingFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner{
        marketingFee[0] = buy;
		marketingFee[0] = sell;
		marketingFee[0] = p2p;
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "MATRIXRETOKEN: The PanCakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "MATRIXRETOKEN: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "MATRIXRETOKEN: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "MATRIXRETOKEN: Cannot update gasForProcessing to same value");
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
	
	function excludeFromMaxWalletToken(address account, bool excluded) public onlyOwner {
        require(isExcludedFromMaxWalletToken[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromMaxWalletToken[account] = excluded;
    }
	
	function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
    }
	
	function setMaxTxAmount(uint256 amount) external onlyOwner() {
		maxTxAmount = amount;
	}
	
	function setMaxWalletAmount(uint256 amount) public onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		maxWalletAmount = amount;
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
	
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		
		if(from != owner() && to != owner()) {
		   require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		}
		
		if(!isExcludedFromMaxWalletToken[to] && !automatedMarketMakerPairs[to]) {
            uint256 balanceRecepient = balanceOf(to);
            require(balanceRecepient + amount <= maxWalletAmount, "Exceeds maximum wallet token amount");
        }
		
		uint256 contractTokenBalance = balanceOf(address(this));
		if(contractTokenBalance >= maxTxAmount) 
		{
			contractTokenBalance = maxTxAmount;
		}
		
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if(canSwap && !swapping && automatedMarketMakerPairs[to] && swapAndLiquifyEnabled){
            swapping = true;
			tokenToSwap;
            tokenToMarketing    = marketingFeeTotal;
			tokenToLiqudity     = liquidityFeeTotal;
			tokenToReward       = BNBRewardsFeeTotal;
			tokenToLiqudityHalf = tokenToLiqudity.div(2);
			
			tokenToSwap = tokenToMarketing.add(tokenToReward).add(tokenToLiqudityHalf);
			
			uint256 initialBalance = address(this).balance;
			swapTokensForBNB(swapTokensAtAmount);
			uint256 newBalance = address(this).balance.sub(initialBalance);
			
			uint256 marketingPart = newBalance.mul(tokenToMarketing).div(tokenToSwap);
			uint256 liqudityPart  = newBalance.mul(tokenToLiqudityHalf).div(tokenToSwap);
			uint256 rewardPart    = newBalance.sub(marketingPart).sub(liqudityPart);

			if(marketingPart > 0) {
			   payable(marketingWalletAddress).transfer(marketingPart);
			}
			if(liqudityPart > 0) {
			    addLiquidity(swapTokensAtAmount.mul(tokenToLiqudityHalf).div(tokenToSwap), liqudityPart);
			}
			if(rewardPart > 0) {
			    sendDividends(rewardPart);
			}
			marketingFeeTotal  = marketingFeeTotal.sub(swapTokensAtAmount.mul(tokenToMarketing).div(tokenToSwap));
		    liquidityFeeTotal  = liquidityFeeTotal.sub((swapTokensAtAmount.mul(tokenToLiqudityHalf).div(tokenToSwap)).mul(2));
		    BNBRewardsFeeTotal = BNBRewardsFeeTotal.sub(swapTokensAtAmount.mul(tokenToReward).div(tokenToSwap));
            swapping = false;
        }
		
        bool takeFee = !swapping;
		
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) 
		{
            takeFee = false;
        }
		
		if(takeFee) 
		{
			uint256 allfee;
			allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]);
			super._transfer(from, address(this), allfee);
			amount = amount.sub(allfee);
		}
		
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
		
        if(!swapping) 
		{
	    	uint256 gas = gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) 
			{
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch 
			{
			   
	    	}
        }
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private returns (uint256) {
        uint256 totalFee;
		
        uint256 rewardFeeNew = amount.mul(p2p ? BNBRewardsFee[2] : sell ? BNBRewardsFee[1] : BNBRewardsFee[0]).div(10000);
		BNBRewardsFeeTotal = BNBRewardsFeeTotal.add(rewardFeeNew);
		
		uint256 liquidityFeeNew = amount.mul(p2p ? liquidityFee[2] : sell ? liquidityFee[1] : liquidityFee[0]).div(10000);
		liquidityFeeTotal = liquidityFeeTotal.add(liquidityFeeNew);
		
		uint256 marketingFeeNew = amount.mul(p2p ? marketingFee[2] : sell ? marketingFee[1] : marketingFee[0]).div(10000);
		marketingFeeTotal = marketingFeeTotal.add(marketingFeeNew);
		
		totalFee = rewardFeeNew.add(liquidityFeeNew).add(marketingFeeNew);
        return totalFee;
    }
	
    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
	
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }
	
	function sendDividends(uint256 dividends) private {
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        if(success) {
   	 		emit SendDividends(dividends);
        }
    }
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		 swapTokensAtAmount = amount;
  	}
	
	function migrateBNB(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }
}

contract MATRIXRETOKENDividendTracker is Ownable, DividendPayingToken {
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

    constructor() public DividendPayingToken("MATRIXRETOKEN_Dividen_Tracker", "MATRIXRETOKEN_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**8); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "MATRIXRETOKEN_Dividend_Tracker: No transfers allowed");
    }
	
    function withdrawDividend() public override {
        require(false, "MATRIXRETOKEN_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main MATRIXRETOKEN contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "MATRIXRETOKEN_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "MATRIXRETOKEN_Dividend_Tracker: Cannot update claimWait to same value");
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
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
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
    	if(excludedFromDividends[account]) 
		{
    		return;
    	}
    	if(newBalance >= minimumTokenBalanceForDividends) 
		{
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else 
		{
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
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
			if(processAccount(payable(account), true)) {
				claims++;
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
	    if(canAutoClaim(lastClaimTimes[account]))
		{
		    uint256 amount = _withdrawDividendOfUser(account);
			if(amount > 0) {
				lastClaimTimes[account] = block.timestamp;
				emit Claim(account, amount, automatic);
				return true;
			}
			return false;
		}
		else
		{
		   return false;
		}
    }
}