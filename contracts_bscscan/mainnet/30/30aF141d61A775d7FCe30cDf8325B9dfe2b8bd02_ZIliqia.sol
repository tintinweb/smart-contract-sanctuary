// SPDX-License-Identifier: MIT

/*

Telegram : https://t.me/ZIliqiaofficial

*/
pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract ZIliqia is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    SHIBDividendTracker public SHIBdividendTracker;
    DOGEDividendTracker public DOGEdividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public immutable SHIB = address(0x2859e4544C4bB03966803b044A93563Bd2D0DD4D); //SHIB

    address public immutable DOGE = address(0xbA2aE424d960c26247Dd6c32edC70B295c744C43); //DOGE

    uint256 public swapTokensAtAmount = 2000000 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    uint256 public DOGERewardsFee = 3;
    uint256 public SHIBRewardsFee = 3;
    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 3;
    uint256 public totalFees = 17;
    uint256 public _maxWalletToken = 30000000000000 * (10**18); // 3% of total supply line

    address public _marketingWalletAddress = 0x29DEc5A856A55Bc323fc510FBC9aC58483018Fd2;


    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateSHIBDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateDOGEDividendTracker(address indexed newAddress, address indexed oldAddress);

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

    event ProcessedSHIBDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
     event ProcessedDOGEDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() public ERC20("ZIliqia", "ZIliqia") {
        

    	SHIBdividendTracker = new SHIBDividendTracker();
        DOGEdividendTracker = new DOGEDividendTracker();

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        SHIBdividendTracker.excludeFromDividends(address(SHIBdividendTracker));
        SHIBdividendTracker.excludeFromDividends(address(this));
        SHIBdividendTracker.excludeFromDividends(owner());
        SHIBdividendTracker.excludeFromDividends(deadWallet);
        SHIBdividendTracker.excludeFromDividends(address(_uniswapV2Router));
        DOGEdividendTracker.excludeFromDividends(address(DOGEdividendTracker));
        DOGEdividendTracker.excludeFromDividends(address(this));
        DOGEdividendTracker.excludeFromDividends(owner());
        DOGEdividendTracker.excludeFromDividends(deadWallet);
        DOGEdividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateSHIBDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(SHIBdividendTracker), "ZIliqia: The dividend tracker already has that address");

        SHIBDividendTracker newSHIBDividendTracker = SHIBDividendTracker(payable(newAddress));

        require(newSHIBDividendTracker.owner() == address(this), "ZIliqia: The new dividend tracker must be owned by the ZIliqia token contract");

        newSHIBDividendTracker.excludeFromDividends(address(newSHIBDividendTracker));
        newSHIBDividendTracker.excludeFromDividends(address(this));
        newSHIBDividendTracker.excludeFromDividends(owner());
        newSHIBDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateSHIBDividendTracker(newAddress, address(SHIBdividendTracker));

        SHIBdividendTracker = newSHIBDividendTracker;
    }

    function updateDOGEDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(DOGEdividendTracker), "ZIliqia: The dividend tracker already has that address");

        DOGEDividendTracker newDOGEDividendTracker = DOGEDividendTracker(payable(newAddress));

        require(newDOGEDividendTracker.owner() == address(this), "ZIliqia: The new dividend tracker must be owned by the ZIliqia token contract");

        newDOGEDividendTracker.excludeFromDividends(address(newDOGEDividendTracker));
        newDOGEDividendTracker.excludeFromDividends(address(this));
        newDOGEDividendTracker.excludeFromDividends(owner());
        newDOGEDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDOGEDividendTracker(newAddress, address(DOGEdividendTracker));

        DOGEdividendTracker = newDOGEDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "ZIliqia: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }
    
    function updateMaxWallet(uint256 maxWallet) public onlyOwner {
        _maxWalletToken = maxWallet * (10**18);
    } 

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "ZIliqia: Account is already the value of 'excluded'");
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

    function setSHIBRewardsFee(uint256 value) external onlyOwner{
        SHIBRewardsFee = value;
        totalFees = SHIBRewardsFee.add(DOGERewardsFee).add(liquidityFee).add(marketingFee);
    }

    function setDOGERewardsFee(uint256 value) external onlyOwner{
        SHIBRewardsFee = value;
        totalFees = DOGERewardsFee.add(SHIBRewardsFee).add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = SHIBRewardsFee.add(DOGERewardsFee).add(liquidityFee).add(marketingFee);
    }
   
    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = SHIBRewardsFee.add(DOGERewardsFee).add(liquidityFee).add(marketingFee);

    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "ZIliqia: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "BabyUshi: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            SHIBdividendTracker.excludeFromDividends(pair);
            DOGEdividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "ZIliqia: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "ZIliqia: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        SHIBdividendTracker.updateClaimWait(claimWait);
        DOGEdividendTracker.updateClaimWait(claimWait);
    }

    function getSHIBClaimWait() external view returns(uint256) {
        return SHIBdividendTracker.claimWait();
    }

    function getDOGEClaimWait() external view returns(uint256) {
        return DOGEdividendTracker.claimWait();
    }

    function getTotalSHIBDividendsDistributed() external view returns (uint256) {
        return SHIBdividendTracker.totalDividendsDistributed();
    }

    function getTotalDOGEDividendsDistributed() external view returns (uint256) {
        return DOGEdividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableSHIBDividendOf(address account) public view returns(uint256) {
    	return SHIBdividendTracker.withdrawableDividendOf(account);
  	}

    function withdrawableDOGEDividendOf(address account) public view returns(uint256) {
    	return DOGEdividendTracker.withdrawableDividendOf(account);
  	}

	function SHIBdividendTokenBalanceOf(address account) public view returns (uint256) {
		return SHIBdividendTracker.balanceOf(account);
	}

    function DOGEdividendTokenBalanceOf(address account) public view returns (uint256) {
		return DOGEdividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    SHIBdividendTracker.excludeFromDividends(account);
	    DOGEdividendTracker.excludeFromDividends(account);
	}

    function getAccountSHIBDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return SHIBdividendTracker.getAccount(account);
    }

    function getAccountDOGEDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return DOGEdividendTracker.getAccount(account);
    }

	function getAccountSHIBDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return SHIBdividendTracker.getAccountAtIndex(index);
    }

    function getAccountDOGEDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return DOGEdividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 SHIBiterations, uint256 SHIBclaims, uint256 SHIBlastProcessedIndex) = SHIBdividendTracker.process(gas);
		emit ProcessedSHIBDividendTracker(SHIBiterations, SHIBclaims, SHIBlastProcessedIndex, false, gas, tx.origin);

        (uint256 DOGEiterations, uint256 DOGEclaims, uint256 DOGElastProcessedIndex) = DOGEdividendTracker.process(gas);
		emit ProcessedDOGEDividendTracker(DOGEiterations, DOGEclaims, DOGElastProcessedIndex, false, gas, tx.origin);     
    }
    
    function claim() external {
		SHIBdividendTracker.processAccount(msg.sender, false);
        DOGEdividendTracker.processAccount(msg.sender, false);
    }

    function getLastSHIBProcessedIndex() external view returns(uint256) {
    	return SHIBdividendTracker.getLastProcessedIndex();
    }
    
    function getLastDOGEProcessedIndex() external view returns(uint256) {
    	return DOGEdividendTracker.getLastProcessedIndex();
    }  
     
    function getNumberOfSHIBDividendTokenHolders() external view returns(uint256) {
        return SHIBdividendTracker.getNumberOfTokenHolders();
    }

    function getNumberOfDOGEDividendTokenHolders() external view returns(uint256) {
        return DOGEdividendTracker.getNumberOfTokenHolders();
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


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	if(automatedMarketMakerPairs[to]){
        	    fees += amount.mul(1).div(100);
        	}
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try SHIBdividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try DOGEdividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try SHIBdividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try DOGEdividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try SHIBdividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedSHIBDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
	    	try DOGEdividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDOGEDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndSendToFee(uint256 tokens) private  {

        uint256 initialSHIBBalance = IERC20(SHIB).balanceOf(address(this));

        swapTokensForSHIB(tokens);
        uint256 newBalance = (IERC20(SHIB).balanceOf(address(this))).sub(initialSHIBBalance);
        IERC20(SHIB).transfer(_marketingWalletAddress, newBalance);
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
        swapTokensForDOGE(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }


    function swapTokensForDOGE(uint256 tokenAmount) private {


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

    function swapTokensForSHIB(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = SHIB;

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

    function swapAndSendSHIBDividends(uint256 tokens) private{
        swapTokensForSHIB(tokens);
        uint256 SHIBdividends = IERC20(SHIB).balanceOf(address(this));
        bool success = IERC20(SHIB).transfer(address(SHIBdividendTracker), SHIBdividends);

        if (success) {
            SHIBdividendTracker.distributeSHIBDividends(SHIBdividends);
            emit SendDividends(tokens, SHIBdividends);
        }
    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForDOGE(tokens);
        uint256 DOGEdividends = IERC20(DOGE).balanceOf(address(this));
        bool success = IERC20(DOGE).transfer(address(DOGEdividendTracker), DOGEdividends);

        if (success) {
            DOGEdividendTracker.distributeDOGEDividends(DOGEdividends);
            emit SendDividends(tokens, DOGEdividends);
        }

    }
}

contract SHIBDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;
    uint256 public _maxWalletToken = 10000000000000 * (10**18); // 1.0% of total supply

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("ZIliqia_SHIB_Dividen_Tracker", "ZIliqia_SHIB_Dividend_Tracker") {
    	claimWait = 1200;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "ZIliqia_SHIB_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "ZIliqia_SHIB_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ZIliqia contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "ZIliqia_SHIB_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "ZIliqia_SHIB_Dividend_Tracker: Cannot update claimWait to same value");
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
        uint256 amountSHIB = _withdrawDividendOfUserSHIB(account);

    	if(amountSHIB > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amountSHIB, automatic);
    		return true;
    	}

    	return false;
    }
}


contract DOGEDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;
    uint256 public _maxWalletToken = 10000000000000 * (10**18); // 1.0% of total supply

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("ZIliqia_DOGE_Dividen_Tracker", "ZIliqia_DOGE_Dividend_Tracker") {
    	claimWait = 1200;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "ZIliqia_DOGE_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "ZIliqia_DOGE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ZIliqia contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "ZIliqia_DOGE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "ZIliqia_DOGE_Dividend_Tracker: Cannot update claimWait to same value");
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
         uint256 amountDOGE = _withdrawDividendOfUserDOGE(account);

    	if(amountDOGE > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amountDOGE, automatic);
    		return true;
    	}

    	return false;
    }
}