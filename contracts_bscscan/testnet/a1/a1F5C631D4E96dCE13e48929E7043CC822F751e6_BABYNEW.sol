// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract BABYNEW is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    IUniswapV2Factory private uniswapFactory;

    bool private swapping;

    BABYNEWDividendTracker public dividendTracker;

    address private immutable WBNB = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // main net 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd testnet 

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    // address public zeroWallet = 0x0000000000000000000000000000000000000000;

    uint256 public swapTokensAtAmount = 200 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    uint256 public RewardsFee = 7;
    uint256 public liquidityFee = 2;
    uint256 public totalFees = RewardsFee.add(liquidityFee);

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

    constructor() public ERC20("BABY WHOLE TOKEN TEST", "BABYWHOLETOKEN TEST") {

    	dividendTracker = new BABYNEWDividendTracker();


    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1Ed675D5e63314B760162A3D1Cae1803DCFC87C7); // main net 0x10ED43C718714eb63d5aA57B78B54704E256024E // test net 0x1Ed675D5e63314B760162A3D1Cae1803DCFC87C7
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        IUniswapV2Factory _uniswapFactory = IUniswapV2Factory(uniswapV2Router.factory());
        uniswapFactory = _uniswapFactory;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // set token address
        dividendTracker.setTokenAddress(address(this));

        dividendTracker.setAutomatedMarketMakerRouter(address(_uniswapV2Router));

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BABYWHOLETOKEN: The dividend tracker already has that address");

        BABYNEWDividendTracker newDividendTracker = BABYNEWDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BABYWHOLETOKEN: The new dividend tracker must be owned by the BABYWHOLETOKEN token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BABYWHOLETOKEN: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BABYWHOLETOKEN: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setRewardsFee(uint256 value) external onlyOwner{
        RewardsFee = value;
        totalFees = RewardsFee.add(liquidityFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = RewardsFee.add(liquidityFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BABYWHOLETOKEN: The TotemSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BABYWHOLETOKEN: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BABYWHOLETOKEN: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BABYWHOLETOKEN: Cannot update gasForProcessing to same value");
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
        	if (!automatedMarketMakerPairs[to]){
                uint256 fees = amount.mul(totalFees).div(100);
                if(automatedMarketMakerPairs[to]){
                    fees += amount.mul(1).div(100);
                }
                amount = amount.sub(fees);

                super._transfer(from, address(this), fees);
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

    function swapTokensForToken(uint256 tokenAmount) private {

        // address[] memory path = new address[](3);
        // path[0] = address(this);
        // path[1] = uniswapV2Router.WETH();
        // path[2] = TOTEM;

        // _approve(address(this), address(uniswapV2Router), tokenAmount);

        // // make the swap
        // uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     tokenAmount,
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp
        // );
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
        // swapTokensForToken(tokens);
        uint256 dividends = IERC20(address(this)).balanceOf(address(this));
        bool success = IERC20(address(this)).transfer(address(dividendTracker), dividends);

        if (success) {
            _approve(address(dividendTracker), address(uniswapV2Router), dividends);
            dividendTracker.distributeTOKENSDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function setRewardTokenA(address tokenAddress, uint256 percent) external{
        require(address(this) != tokenAddress, "BABYNEW can't be set as a reward token.");
        require(uniswapFactory.getPair(tokenAddress, WBNB) != address(0), "Please input the address of token that has listed on PancakeSwap");
        require(percent <= 100, "Please set percent as the value between 1 to 100.");
        dividendTracker.setRewardTokenA(msg.sender, tokenAddress, percent);
    }

    function setRewardTokenB(address tokenAddress, uint256 percent) external{
        require(address(this) != tokenAddress, "BABYNEW can't be set as a reward token.");
        require(uniswapFactory.getPair(tokenAddress, WBNB) != address(0), "Please input the address of token that has listed on PancakeSwap");
        require(percent <= 100, "Please set percent as the value between 1 to 100.");
        dividendTracker.setRewardTokenB(msg.sender, tokenAddress, percent);
    }
}

contract BABYNEWDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;

    
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    IUniswapV2Router02 private uniswapV2Router;

    address private TOKEN;

    address private immutable DEFAULTREWARDTOKEN = address(0x36d468D6055ac88d2D08793B4816B67AB49a0339); // Default reward token - BUSD // main net 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 //testnet 0x36d468D6055ac88d2D08793B4816B67AB49a0339


    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("BABYWHOLETOKENS_Dividen_Tracker", "BABYWHOLETOKENS_Dividen_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 20 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BABYWHOLETOKENS_Dividen_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BABYWHOLETOKENS_Dividen_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BABYWHOLETOKEN contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "BABYWHOLETOKENS_Dividen_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BABYWHOLETOKENS_Dividen_Tracker: Cannot update claimWait to same value");
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
    	    bool tokenASeted = tokenHoldersMap.tokenASeted[account];
    	    bool tokenBSeted = tokenHoldersMap.tokenBSeted[account];
    	    
            
    	    if (tokenASeted && tokenBSeted){
    	        address[] memory path = new address[](3);
                path[0] = TOKEN;
                path[1] = uniswapV2Router.WETH();
                path[2] = tokenHoldersMap.tokenA[account];

                uint256 swapAmount = amount.mul(tokenHoldersMap.tokenAPercent[account]).div(10000);
                // make the swap
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    account,
                    block.timestamp
                );
                
                swapAmount = amount.sub(swapAmount);
                path[2] = tokenHoldersMap.tokenB[account];
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    account,
                    block.timestamp
                );
                
    	    }
    	    else if (!tokenASeted && !tokenBSeted){
    	        address[] memory path = new address[](3);
                path[0] = TOKEN;
                path[1] = uniswapV2Router.WETH();
                path[2] = DEFAULTREWARDTOKEN;
        
                // make the swap
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amount,
                    0,
                    path,
                    account,
                    block.timestamp
                );
    	    }
    	    else if (tokenASeted && !tokenBSeted){
    	        address[] memory path = new address[](3);
                path[0] = TOKEN;
                path[1] = uniswapV2Router.WETH();
                path[2] = tokenHoldersMap.tokenA[account];
        
                // make the swap
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amount,
                    0,
                    path,
                    account,
                    block.timestamp
                );
    	    }
    	    else if (!tokenASeted && tokenBSeted){
    	        address[] memory path = new address[](3);
                path[0] = TOKEN;
                path[1] = uniswapV2Router.WETH();
                path[2] = tokenHoldersMap.tokenB[account];
        
                // make the swap
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amount,
                    0,
                    path,
                    account,
                    block.timestamp
                );
    	    }
    	    
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }

    function setRewardTokenA(address account, address token, uint256 percent) public onlyOwner{
        require(tokenHoldersMap.getIndexOfKey(account) >= 0, "You must hold BABYNEW tokens to set up reward tokens.");
        if (tokenHoldersMap.tokenBSeted[account]) {
            require(tokenHoldersMap.tokenB[account] != token, "The token has already been set as another reward token.");
        }
        tokenHoldersMap.tokenASeted[account] = true;
        tokenHoldersMap.tokenA[account] = token;
        tokenHoldersMap.tokenAPercent[account] = percent;
    }

    function setRewardTokenB(address account, address token, uint256 percent) public onlyOwner{
        require(tokenHoldersMap.getIndexOfKey(account) >= 0, "You must hold BABYNEW tokens to set up reward tokens.");
        if (tokenHoldersMap.tokenASeted[account]) {
            require(tokenHoldersMap.tokenA[account] != token, "The token has already been set as another reward token.");
        }
        tokenHoldersMap.tokenBSeted[account] = true;
        tokenHoldersMap.tokenB[account] = token;
        tokenHoldersMap.tokenBPercent[account] = percent;
    }

    function setAutomatedMarketMakerRouter(address router) public onlyOwner{
        uniswapV2Router = IUniswapV2Router02(router);
    }

    function setTokenAddress(address token) public onlyOwner {
        TOKEN = token;
    }
}