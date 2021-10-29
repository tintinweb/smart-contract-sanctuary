// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

pragma solidity ^0.8.4;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./SafeERC20.sol";
import "./Address.sol";

abstract contract Reentrancy {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


contract Test is ERC20, Ownable, Reentrancy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    TestDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public  defaultToken = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); 

    uint256 public swapTokensAtAmount = 100 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    uint256 public rewardsFee = 3;
    uint256 public liquidityFee = 1;
    uint256 public marketingFee = 1;
    uint256 public HolderAmountCap=100;


    uint256 public capFees = 15;

    uint256 public totalFees = rewardsFee.add(liquidityFee).add(marketingFee);

    address public _marketingWalletAddress = 0x344dDc19c655de0dE7ED4201C684721B9D366f8F; 


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
    event MarketingWalletUpdated(address indexed newMarketingyWallet, address indexed oldMarketingyWallet);


    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
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

    constructor()  ERC20("Test", "$Tx") {

    	dividendTracker = new TestDividendTracker();


    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
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
        dividendTracker.approveToken(defaultToken,true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {

  	}
    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount < swapTokensAtAmount/(10**18));
  	    swapTokensAtAmount = newAmount * (10**18);
  	    return true;
  	}
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "Test: The dividend tracker already has that address");

        TestDividendTracker newDividendTracker = TestDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "Test: The new dividend tracker must be owned by the Test token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }
    
    // If there are problems with BUSD
    function updateDefaultToken(address token) public onlyOwner{
        dividendTracker.setDefaultToken(token);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Test: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }
    // updates the default router for buying tokens from dividend tracker
    function updateDividendUniswapV2Router(address newAddress) external onlyOwner {
        dividendTracker.updateDividendUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Test: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }


    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(wallet != _marketingWalletAddress,"Test: this is already the marketing wallet");
        excludeFromFees(wallet, true);
        emit MarketingWalletUpdated(wallet, _marketingWalletAddress);
        _marketingWalletAddress = wallet;

    }

    function setRewardsFee(uint256 value) external onlyOwner{
        require((value.add(liquidityFee).add(marketingFee) <= capFees),"Fees cap exceeded");
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        require((value.add(rewardsFee).add(marketingFee) <= capFees),"Fees cap exceeded");
        liquidityFee = value;
        totalFees = rewardsFee.add(liquidityFee).add(marketingFee);
    }
    
     function setMarketingFee(uint256 value) external onlyOwner{
        require((value.add(liquidityFee).add(rewardsFee) <= capFees),"Fees cap exceeded");
        marketingFee = value;
        totalFees = rewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setHolderAmountCap(uint256 value) external onlyOwner{
        require(value >= 100, "The value can only be increased from the initial 50M limit");
        HolderAmountCap = value;

    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Test: The Swap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Test: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Test: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Test: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    
    function approveToken(address tokenAddress, bool isApproved) external onlyOwner returns (bool){
        dividendTracker.approveToken(tokenAddress, isApproved);
        return true;
    }

    function approveAMM(address ammAddress, bool isWhiteListed) external onlyOwner {
      dividendTracker.approveAMM(ammAddress, isWhiteListed);
    }
    
    
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }
  	function getUserCurrentRewardToken(address holder) external view returns (address){
  	    return dividendTracker.userCurrentRewardToken(holder);
  	}
  	
  	function getUserHasCustomRewardToken(address holder) external view returns (bool){
  	    return dividendTracker.userHasCustomRewardToken(holder);
  	}
  	
  	function getRewardTokenSelectionCount(address token) external view returns (uint256){
  	    return dividendTracker.rewardTokenSelectionCount(token);
  	}
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    
    function getDividendTokensMinimum() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
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
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
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

	function processDividendTracker(uint256 gas) external nonReentrant {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external nonReentrant {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    // determines if a token can be used for rewards
    function isTokenApproved(address tokenAddress) public view returns (bool){
        return dividendTracker.isTokenApproved(tokenAddress);
    }
    // determines if an AMM can be used for rewards
    function isAMMApproved(address ammAddress) public view returns (bool){
        return dividendTracker.isAMMApproved(ammAddress);
    }
  	
    
    // set the reward token for the user.  Call from here.
  	function setRewardToken(address rewardTokenAddress) external  nonReentrant returns (bool) {
  	    require(rewardTokenAddress != address(this), "Test: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
        require(dividendTracker.isTokenApproved(rewardTokenAddress),"Test: setRewardToken:: Token not approved");
  	    dividendTracker.setRewardToken(msg.sender, rewardTokenAddress);
  	    return true;
  	}

  	
  	// set the reward token for the user with a custom AMM (AMM must be whitelisted).  Call from here.
  	function setRewardTokenWithCustomAMM(address rewardTokenAddress, address ammContractAddress) external nonReentrant returns (bool) {
  	    require(ammContractAddress != address(uniswapV2Router), "Test: setRewardToken:: Use setRewardToken to use default Router");
  	    require(rewardTokenAddress != address(this), "Test: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
  	    require(dividendTracker.isTokenApproved(rewardTokenAddress) , "Test: setRewardToken:: Token not approved.");
  	    require(dividendTracker.isAMMApproved(ammContractAddress) , "Test: setRewardToken:: AMM is not whitelisted!");
  	    dividendTracker.setRewardTokenWithCustomAMM(msg.sender, rewardTokenAddress, ammContractAddress);
  	    return true;
  	}
  	
    // Unset the reward token back to defaultToken.  Call from here.
  	function unsetRewardToken() external nonReentrant returns (bool){
  	    dividendTracker.unsetRewardToken(msg.sender);
  	    return true;
  	}
      
    function _transfer(
        address  from,
        address  to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');


        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(totalFees > 0){		
            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if( canSwap &&
                !swapping &&
                !automatedMarketMakerPairs[from] &&
                from != owner() &&
                to != owner()                
                ) {
                swapping = true;

                uint256 sellTokens = contractTokenBalance >= swapTokensAtAmount * 5 ? swapTokensAtAmount * 5 : contractTokenBalance;  // only sell up to 5x the swap token amount per sell to prevent massive dumps.
                swapBack(sellTokens);

                swapping = false;
            }


            bool takeFee = !swapping;

            // if any account belongs to _isExcludedFromFee account then remove the fee
            if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                takeFee = false;
            }
            if(takeFee) {
        	    uint256 fees = amount.mul(totalFees).div(100);
        	    amount = amount.sub(fees);
                if (!automatedMarketMakerPairs[to]){
                    require((IERC20(address(this)).balanceOf(to).add(amount) <= (HolderAmountCap * (10**3) * (10**18))), "Test: transfer amount exceeds address limit");
                }
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping && rewardsFee > 0) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapBack(uint256 contractTokenBalance) internal {
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFees).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 balanceBefore = address(this).balance;

        swapTokensForEth(amountToSwap);

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFees.sub(liquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(rewardsFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        
        
        (bool success,) = address(dividendTracker).call{value: amountBNBReflection}("");
        
        if (success) {
            emit SendDividends(amountBNBReflection);
        }
        
        (success,) = address(_marketingWalletAddress).call{value: amountBNBMarketing}("");
        

        if(amountToLiquify > 0){
            addLiquidity(amountToLiquify, amountBNBLiquidity);
        }
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
            address(0),
            block.timestamp
        );
        
    }
    //Withdraws trapped tokens and send them to a multi-sig marketing wallet
    function withdrawBep20(address token) public onlyOwner nonReentrant{
        require(token != address(this));
        require((IERC20(address(token)).balanceOf(address(this)))>0);
        IERC20(token).safeTransfer(payable(_marketingWalletAddress),IERC20(token).balanceOf(address(this)));
}
    //Withdraws trapped BNBs and send them to a multi-sig marketing wallet
    function withdrawBNB(uint256 amount) public onlyOwner nonReentrant {
	    amount = amount * (10**17);//starting from 1st decimal
	    require(balanceOf(address(this)) > amount);
        (bool success, ) = payable(_marketingWalletAddress).call{value: amount}("");
        require(success, "transfer failed");
    }

}

contract TestDividendTracker is Ownable, DividendPayingToken {
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
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor()  DividendPayingToken("Dividend_Tracker", "Dividend_Tracker") {
    	claimWait = 21600;
        minimumTokenBalanceForDividends = 100 * (10**18); //must hold 100+ tokens
    }

    function _transfer(address, address, uint256) internal override pure {
        require(false, "TestDividendTracker: No transfers allowed");
    }

    function withdrawDividend() public override pure {
        require(false, "TestDividendTracker: withdrawDividend disabled. Use the 'claim' function on the main Test contract.");
    }
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }
    function includeInDividends(address account) external onlyOwner {
    	require(excludedFromDividends[account]);
    	excludedFromDividends[account] = false;

    	emit IncludeInDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "TestDividendTracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "TestDividendTracker: Cannot update claimWait to same value");
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