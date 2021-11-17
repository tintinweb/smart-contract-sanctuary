// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract DummyContract is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    AFLOKIDividendTracker public dividendTracker;

    address public _deadWallet;
	address payable public _marketingAddress;
	address payable public _charityAddress;
	address payable public _buybackAddress;
	
    address public immutable DOGE = address(0xbA2aE424d960c26247Dd6c32edC70B295c744C43); //DOGECOIN 

    uint256 public swapTokensAtAmount = 100000000 * (10**9);
	
	uint256[] public _rewardFee;
	uint256[] public _buybackFee;
	uint256[] public _liquidityFee;
	uint256[] public _charityFee;
	uint256[] public _marketingFee;
	
	uint256 public _rewardFeeTotal;
	uint256 public _buybackFeeTotal;
	uint256 public _liquidityFeeTotal;
	uint256 public _charityFeeTotal;
	uint256 public _marketingFeeTotal;
	
	uint256 private tokenToSwap;
	uint256 private tokenToMarketing;
	uint256 private tokenToCharity;
	uint256 private tokenToBuyback;
	uint256 private tokenToLiqudity;
	uint256 private tokenToReward;
	uint256 private tokenToLiqudityHalf;
	
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


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

    constructor() public ERC20("DummyContract", "$Dummy") {

    	dividendTracker = new AFLOKIDividendTracker();

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(_deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
		
		_rewardFee.push(400);
        _rewardFee.push(600);
        _rewardFee.push(0);
		
		_buybackFee.push(100);
		_buybackFee.push(150);
		_buybackFee.push(0);
		
		_liquidityFee.push(150);
		_liquidityFee.push(150);
		_liquidityFee.push(150);
		
		_charityFee.push(100);
		_charityFee.push(100);
		_charityFee.push(0);
		
		_marketingFee.push(250);
		_marketingFee.push(500);
		_marketingFee.push(0);
		
		_marketingAddress = 0x8A892AE2dfb72aB3d453d370b9DE45693292478b;
		_charityAddress = 0x46b15c1104155113Ae401B762f0F4C3E0168b11e;
		_buybackAddress = 0x0215Bfe021c57473A4a2871A7ca36E84d6A7513E;
		_deadWallet = 0x000000000000000000000000000000000000dEaD;

        _mint(owner(), 1000000000000 * (10**9));
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "AFLOKI: The dividend tracker already has that address");
        AFLOKIDividendTracker newDividendTracker = AFLOKIDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "AFLOKI: The new dividend tracker must be owned by the AFLOKI token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "AFLOKI: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "AFLOKI: Account is already the value of 'excluded'");
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
	    _marketingAddress = wallet;
	}

	function setCharityWallet(address payable wallet) external onlyOwner{
	    _charityAddress = wallet;
	}

	function setBuybackWallet(address payable wallet) external onlyOwner{
	    _buybackAddress = wallet;
	}
	
    function setRewardFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		_rewardFee[0] = buy;
		_rewardFee[1] = sell;
		_rewardFee[2] = p2p;
	}

	function setBuybackFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		_buybackFee[0] = buy;
		_buybackFee[1] = sell;
		_buybackFee[2] = p2p;
	}
	
	function setLiquidityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		_liquidityFee[0] = buy;
		_liquidityFee[1] = sell;
		_liquidityFee[2] = p2p;
	}

	function setCharityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		_charityFee[0] = buy;
		_charityFee[1] = sell;
		_charityFee[2] = p2p;
	}

	function setMarketingFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		_marketingFee[0] = buy;
		_marketingFee[1] = sell;
		_marketingFee[2] = p2p;
	}
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "AFLOKI: The PanCakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "AFLOKI: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "AFLOKI: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "AFLOKI: Cannot update gasForProcessing to same value");
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

    function getAccountDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index) external view returns ( address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
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

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
		
		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap && !swapping && automatedMarketMakerPairs[to]) {
            swapping = true;
			tokenToSwap;
            tokenToMarketing = _marketingFeeTotal;
			tokenToCharity   = _charityFeeTotal;
			tokenToBuyback   = _buybackFeeTotal;
			tokenToLiqudity  = _liquidityFeeTotal;
			tokenToReward    = _rewardFeeTotal;
			tokenToLiqudityHalf = tokenToLiqudity.div(2);
			
			tokenToSwap = tokenToMarketing.add(tokenToCharity).add(tokenToBuyback).add(tokenToReward).add(tokenToLiqudityHalf);
			
			uint256 initialBalance = address(this).balance;
			swapTokensForEth(swapTokensAtAmount);
			uint256 newBalance = address(this).balance.sub(initialBalance);
			
			uint256 marketingPart = newBalance.mul(tokenToMarketing).div(tokenToSwap);
			uint256 charityPart   = newBalance.mul(tokenToCharity).div(tokenToSwap);
			uint256 buybackPart   = newBalance.mul(tokenToBuyback).div(tokenToSwap);
			uint256 liqudityPart  = newBalance.mul(tokenToLiqudityHalf).div(tokenToSwap);
			uint256 rewardPart    = newBalance.sub(marketingPart).sub(charityPart).sub(buybackPart).sub(liqudityPart);
			
			if(marketingPart > 0) {
			   _marketingAddress.transfer(marketingPart);
			}
			
			if(charityPart > 0) {
			   _charityAddress.transfer(charityPart);
			}
			
			if(buybackPart > 0) {
			   _buybackAddress.transfer(buybackPart);
			}
			
			if(liqudityPart > 0) {
			    addLiquidity(swapTokensAtAmount.mul(tokenToLiqudityHalf).div(tokenToSwap), liqudityPart);
			}
			
			if(rewardPart > 0) {
			   swapAndSendDividends(rewardPart);
			}
			
			_marketingFeeTotal = _marketingFeeTotal.sub(swapTokensAtAmount.mul(tokenToMarketing).div(tokenToSwap));
		    _charityFeeTotal   = _charityFeeTotal.sub(swapTokensAtAmount.mul(tokenToCharity).div(tokenToSwap));
		    _buybackFeeTotal   = _buybackFeeTotal.sub(swapTokensAtAmount.mul(tokenToBuyback).div(tokenToSwap));
		    _liquidityFeeTotal = _liquidityFeeTotal.sub((swapTokensAtAmount.mul(tokenToLiqudityHalf).div(tokenToSwap)).mul(2));
		    _rewardFeeTotal    = _rewardFeeTotal.sub(swapTokensAtAmount.mul(tokenToReward).div(tokenToSwap));
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
		
        if(takeFee) {
		    uint256 allfee;
		    allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]);
			super._transfer(from, address(this), allfee);
			amount = amount.sub(allfee);
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
	
	function collectFee(uint256 amount, bool sell, bool p2p) private returns (uint256) {
        uint256 totalFee;
		
        uint256 rewardFee = amount.mul(p2p ? _rewardFee[2] : sell ? _rewardFee[1] : _rewardFee[0]).div(10000);
		_rewardFeeTotal = _rewardFeeTotal.add(rewardFee);
		
		uint256 buybackFee = amount.mul(p2p ? _buybackFee[2] : sell ? _buybackFee[1] : _buybackFee[0]).div(10000);
		_buybackFeeTotal = _buybackFeeTotal.add(buybackFee);
		
		uint256 liquidityFee = amount.mul(p2p ? _liquidityFee[2] : sell ? _liquidityFee[1] : _liquidityFee[0]).div(10000);
		_liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
		
		uint256 charityFee = amount.mul(p2p ? _charityFee[2] : sell ? _charityFee[1] : _charityFee[0]).div(10000);
		_charityFeeTotal = _charityFeeTotal.add(charityFee);
		
		uint256 marketingFee = amount.mul(p2p ? _marketingFee[2] : sell ? _marketingFee[1] : _marketingFee[0]).div(10000);
		_marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
		
		totalFee = rewardFee.add(buybackFee).add(liquidityFee).add(charityFee).add(marketingFee);
        return totalFee;
    }
	
	function swapTokensForEth(uint256 tokenAmount) private {
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
            owner(),
            block.timestamp
        );

    }
	
	function swapETHForDOGE(uint256 amount) private {
		address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = DOGE;
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, address(this), block.timestamp.add(300));
    }

    function swapAndSendDividends(uint256 ethAmount) private{
        swapETHForDOGE(ethAmount);
        uint256 dividends = IERC20(DOGE).balanceOf(address(this));
        bool success = IERC20(DOGE).transfer(address(dividendTracker), dividends);
        if (success) {
            dividendTracker.distributeDOGEDividends(dividends);
            emit SendDividends(ethAmount, dividends);
        }
    }
	
	function migrateBNB(address payable _recipient) public onlyOwner {
		_recipient.transfer(address(this).balance);
	}
	
	function setSwapTokensAtAmount(uint256 swapTokens) external onlyOwner {
  	    swapTokensAtAmount = swapTokens;
  	}
}

contract AFLOKIDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("AFLOKI_Dividen_Tracker", "AFLOKI_Dividend_Tracker") {
    	claimWait = 43200;
        minimumTokenBalanceForDividends = 250000000 * (10**9);
    }
	
	function updateMinimumTokenBalanceForDividends(uint256 newMinimumTokenBalanceForDividends) external onlyOwner {
         minimumTokenBalanceForDividends = newMinimumTokenBalanceForDividends;
    }
	
    function _transfer(address, address, uint256) internal override {
        require(false, "AFLOKI_Dividend_Tracker: No transfers allowed");
    }
	
    function withdrawDividend() public override {
        require(false, "AFLOKI_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main AFLOKI contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "AFLOKI_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "AFLOKI_Dividend_Tracker: Cannot update claimWait to same value");
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
    	if(lastClaimTime > block.timestamp) {
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
	    if(canAutoClaim(lastClaimTimes[account])){
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