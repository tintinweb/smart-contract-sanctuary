/*
    SPDX-License-Identifier: MIT
    
*/

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract DrivenX is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    // TODO: Change this
    address public marketingWallet = 0x59e41a5b86D673d8c7Ed721b7EC20DA3d7572433;
    address public minterAddress = 0x59e41a5b86D673d8c7Ed721b7EC20DA3d7572433;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;

    bool private swapping;

    DrivenDividendTracker public dividendTracker;

    address public liquidityWallet;
    
    // TODO: Change this
    uint256 public swapTokensAtAmount = 100000 * (10**18);
                                                            
    uint256 public BUSDRewardsFee;
    uint256 public burnFee;
    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public totalFees;
    
    // sells have a higher total fee
    uint256 public sellFeeIncreaseFactor = 200; 

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // BUSD ERC20 Address
    // TODO: Change this
    address BUSD_address = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);

    // BUSD ERC-20 Object
    ERC20 BUSD = ERC20(BUSD_address);

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs.
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event sellFeeIncreaseFactorUpdated(uint256 indexed newSellFeeIncreaseFactor, uint256 indexed sellFeeIncreaseFactor);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event marketingTeamFeeUpdated(uint256 indexed newmarketingTeamFee, uint256 indexed marketingTeamFee);
    event LiquidityFeeUpdated(uint256 indexed newLiquidityFee, uint256 indexed liquidityFee);
    event RewardsFeeUpdated(uint256 indexed newRewardsFee, uint256 indexed rewardsFee);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event DividendsSent(
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

    constructor() public ERC20("TEST0", "TEST0") {
        uint256 _BUSDRewardsFee = 4;
        uint256 _liquidityFee = 2;
        uint256 _marketingFee = 2;
        uint256 _burnFee = 4;

        BUSDRewardsFee = _BUSDRewardsFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        burnFee = _burnFee;
        totalFees = _BUSDRewardsFee.add(_liquidityFee).add(_marketingFee).add(burnFee);

        dividendTracker = new DrivenDividendTracker();

        liquidityWallet = msg.sender;

        // TODO: Change this:
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
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludeFromDividends(ZERO);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 200000000 * (10**18));
    }

    receive() external payable {

    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "DrivenX: The dividend tracker already has that address");

        DrivenDividendTracker newDividendTracker = DrivenDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "DrivenX: The new dividend tracker must be owned by the UR token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "DrivenX: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "DrivenX: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "DrivenX: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // This mint function is needed to reward the liquidity providers
    // Total mint is limited to 50M tokens and is controlled by a masterchef
    function mint(address to, uint256 amount) external {
        require(msg.sender == minterAddress);
        uint256 maxSupply = 250000000 * (10**18);
        if(totalSupply().add(amount) < maxSupply) {
            _mint(to, amount);
        }
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, ": The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    
    function updateMarketingWallet(address newMarketingWallet) public onlyOwner {
        require(newMarketingWallet != marketingWallet, "The marketing wallet is already this address");
        excludeFromFees(newMarketingWallet, true);
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function updateMinterAddress(address newMinterAddress) public onlyOwner {
    require(newMinterAddress != minterAddress, "The team wallet is already this address");
    excludeFromFees(newMinterAddress, true);
    minterAddress = newMinterAddress;
    }
    
    function updateLiquidityFee(uint256 newLiquidityFee) public onlyOwner {
        require(newLiquidityFee <= 4, "Liquidity fee can't be more than 4%");
        liquidityFee = newLiquidityFee;
        totalFees = BUSDRewardsFee.add(liquidityFee).add(marketingFee);
    }
    
    function updateRewardsFee(uint256 newRewardsFee) public onlyOwner {
        require(newRewardsFee <= 4, "Rewards fee can't be more than 4%");
        BUSDRewardsFee = newRewardsFee;
        totalFees = BUSDRewardsFee.add(liquidityFee).add(marketingFee);
    }
   
    function updateSellFeeIncreaseFactor(uint256 newSellFeeIncreaseFactor) public onlyOwner {
        require(newSellFeeIncreaseFactor <= 350, "Sell Increase factor can't be more than 350%");
        emit sellFeeIncreaseFactorUpdated(newSellFeeIncreaseFactor, sellFeeIncreaseFactor);
        sellFeeIncreaseFactor = newSellFeeIncreaseFactor;
    } 

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "DrivenX: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "DrivenX: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    
    function updateSwapTokensAmount(uint256 _swapTokensAtAmount) external onlyOwner {
        swapTokensAtAmount = _swapTokensAtAmount;
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

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != minterAddress &&
            to != minterAddress &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 tokensForLiquidity = swapTokensAtAmount.mul(liquidityFee).div(totalFees).div(2);
            uint256 tokensForBurning = swapTokensAtAmount.mul(burnFee).div(totalFees);
            uint256 tokensForRewards = swapTokensAtAmount.mul(BUSDRewardsFee).div(totalFees);
            uint256 tokensForMarketing = swapTokensAtAmount.mul(marketingFee).div(totalFees);

            super._transfer(address(this), DEAD, tokensForBurning); // Burn tokens

            swapAndSendDividends(tokensForRewards); // Send tokens to Dividend contract

            swapTokensForBUSD(tokensForMarketing); // Get tokens in BUSD
            BUSD.transfer(marketingWallet, BUSD.balanceOf(address(this))); // Send BUSD to marketing

            uint256 BNBBefore = address(this).balance;
            swapTokensForEth(tokensForLiquidity); // Get BNB for liquidity
            uint256 BNBForLiquidity = address(this).balance.sub(BNBBefore); // How much did we get?
            swapAndLiquifyNew(tokensForLiquidity, BNBForLiquidity); // We add liquidity

            swapping = false;
        }

        // We take fees if...
        if(!swapping && // We are not swapping inside the tx (for liquidity for instance)
            !_isExcludedFromFees[from] && // We are not sending from an excluded address
            !_isExcludedFromFees[to] && // We are not receiving from an excluded address
            (automatedMarketMakerPairs[to] || // We are sending it to an AMM Pair or
            automatedMarketMakerPairs[from]) // we are receiving from an AMM pair
            ) {
            uint256 fees = amount.mul(totalFees).div(100);

            // if sell, multiply by fee increase Factor
            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
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

    function swapTokensForBUSD(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = address(BUSD);

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

    function swapAndLiquifyNew(uint256 tokens, uint256 liquidityBNB) private {

        addLiquidity(tokens, liquidityBNB);
        emit SwapAndLiquify(tokens, liquidityBNB, tokens);
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
        swapTokensForBUSD(tokens);
        uint256 dividends = BUSD.balanceOf(address(this));
        bool success = BUSD.transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeBUSDDividends(dividends);
            emit DividendsSent(dividends);
        }
    }
}

contract DrivenDividendTracker is Ownable, DividendPayingToken {
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

    constructor() public DividendPayingToken("Driven_Dividend_Tracker", "Driven_Dividend_Tracker") {
        // TODO: Change this
    	claimWait = 120;
        minimumTokenBalanceForDividends = 1 * (10**10); //must hold 200 tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "Driven_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "Driven_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Driven contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1 && newClaimWait <= 86400, "Driven_Dividend_Tracker: claimWait must be updated to between 0 and 24 hours");
        require(newClaimWait != claimWait, "Driven_Dividend_Tracker: Cannot update claimWait to same value");
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