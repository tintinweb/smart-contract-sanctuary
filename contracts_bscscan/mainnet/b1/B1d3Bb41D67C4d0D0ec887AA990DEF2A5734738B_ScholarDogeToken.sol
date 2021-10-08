// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ScholarDogeTeamTimelock.sol";
import "./ScholarDogeDividendTracker.sol";
import "./IPancakePair.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter02.sol";
import "./BEP20.sol";

contract ScholarDogeToken is BEP20, Ownable {
    struct FeeStruct {
        uint8 rewardFee;
        uint8 lpFee;
        uint8 treasuryFee;
        uint8 burnFee;
        uint256 totalFee;
    }

    struct RewardStruct {
        uint256 minToSwap;
        address rewardToken;
        uint8 swapSlippage;
        uint8 rewardSlippage;
    }
    
    struct DexStruct {
        IPancakeRouter02 router;
        address pair;
    }
    
    uint256 private constant MAX_SUPPLY = 1000000000 * (10**9);
    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint8 private constant SELL_FACTOR = 120;
    
    // Securize the launch by allowing 1 sell tx / block
    // also reverting / taxing if gas price set too high
    bool public safeLaunch = true;
    
    bool public init;

    bool private swapping;
    bool private shouldAddLp;
    bool private shouldReward;
    
    uint256 public rewardTokenCount;

    // Stores the contracts updates
    // index = function number (arbitrary)
    // value = block timestamp of the first call + delay
    mapping(uint256 => uint256) public pendingContractUpdates;
    
    // Stores the last sells times / address
    mapping(address => uint256) private safeLaunchSells;
    
    mapping(address => bool) private addedTokens;
    
    address[] public rewardTokens;

    uint256 public maxHold = MAX_SUPPLY;
    
    uint256 public treasuryFeeCollected;
    
    // use by default 800,000 gas to process transfer
    // avoids out of gas exception, extra gas will be refunded
    uint256 private minTxGas = 800000;

    // Multi-sign wallets here
    address public treasury;
    address public marketing;
    address public foundation;

    uint256 public maxSellTx = MAX_SUPPLY;
    
    FeeStruct public feeStruct;
    RewardStruct public rewardStruct;
    DexStruct public dexStruct;

    ScholarDogeTeamTimelock public teamTimelock;
    ScholarDogeDividendTracker public dividendTracker;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed _dividendTracker);

    event FeeStructUpdated(
        uint256 _rewardFee,
        uint256 _lpFee,
        uint256 _treasuryFee,
        uint256 _burnFee
    );

    event RewardStructUpdated(
        uint256 _minToSwap,
        address indexed _rewardToken,
        uint256 _swapSlippage,
        uint256 _rewardSlippage
    );

    event DexStructUpdated(address indexed _router, address indexed _pair);

    event MaxSellTxUpdated(uint256 _maxSellTx);

    event MaxHoldUpdated(uint256 _maxHold);

    event TreasuryUpdated(address _treasury);
    
    event MarketingUpdated(address _marketing);
    
    event FoundationUpdated(address _foundation);
    
    event MinTxGasUpdated(uint256 newValue);
    
    event RewardTokenAdded(address rewardToken);

    event ExcludeFromFees(address indexed _account, bool _excluded);

    event SetAutomatedMarketMakerPair(
        address indexed _pair,
        bool _value
    );

    event MigrateLiquidity(
        address indexed newAddress
    );

    event SwapAndLiquify(
        uint256 addedTokens,
        uint256 addedBnb
    );

    event SendDividends(
        uint256 amount
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 lastProcessedIndex,
        uint256 gas
    );
    
    event DividendWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    
    event SafeLaunchDisabled();
    
    event ContractUpdateCall(uint256 indexed fnNb, uint256 indexed delay);

    event ContractUpdateCancelled(uint256 indexed fnNb);

    // Adds a security on sensible contract updates
    modifier safeContractUpdate(uint256 fnNb, uint256 delay) {
        if (init) {
            if (pendingContractUpdates[fnNb] == 0) {
                pendingContractUpdates[fnNb] = block.timestamp + delay;
    
                emit ContractUpdateCall(fnNb, delay);
    
                return;
            } else {
                require(
                    block.timestamp >= pendingContractUpdates[fnNb],
                    "Update still pending"
                );
    
                pendingContractUpdates[fnNb] = 0;
    
                _;
            }
        } else {
            _;
        }
    }
    
    modifier uninitialized() {
        require(
            !init,
            "Already init");

        _;

        init = true;
    }

    constructor() BEP20("ScholarDoge", "$SDOGE") {
        dexStruct.router
            = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        dexStruct.pair = IPancakeFactory(dexStruct.router.factory())
            .createPair(address(this), dexStruct.router.WETH());
        
        teamTimelock = new ScholarDogeTeamTimelock(this, _msgSender());
        dividendTracker = new ScholarDogeDividendTracker(address(this));
        
        rewardStruct.rewardToken = dexStruct.router.WETH();
        
        _addRewardToken(dexStruct.router.WETH());
        
        excludedFromFees[address(this)] = true;
        excludedFromFees[address(teamTimelock)] = true;
        excludedFromFees[address(dividendTracker)] = true;
        excludedFromFees[owner()] = true;
    }
    
    receive() external payable {
  	}
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    
    function initSupply() external {
        require(
		    totalSupply() == 0,
		    "Supply already initialized"
	    );
	    
	    require(
	        treasury != address(0x0) &&
	        marketing != address(0x0) &&
	        foundation != address(0x0),
	        "Project wallets uninitialized"
	    );

        // Supply alloc
        // 8.4% Private sale - 42% Presale - 29.4% Liquidity
        // 5%
        uint256 teamAlloc = MAX_SUPPLY * 5 / 100;
        // 5.2%
        uint256 marketingAlloc = MAX_SUPPLY * 52 / 1000;
        // 3% Lottery / 3% Devlopment - Partneships / 4% Donations
        uint256 foundationAlloc = MAX_SUPPLY * 10 / 100;
        
        _mint(owner(), MAX_SUPPLY);
        _updateShareAndTransfer(owner(), address(teamTimelock), teamAlloc);
        _updateShareAndTransfer(owner(), marketing, marketingAlloc);
        _updateShareAndTransfer(owner(), foundation, foundationAlloc);
        
        // TODO Exclude marketing / foundation as well
        excludedFromFees[treasury] = true;
        excludedFromFees[marketing] = true;
        excludedFromFees[foundation] = true;
    }

  	function initializeContract(
  	    
  	)
  	    external
  	    onlyOwner
  	    uninitialized
  	{
  	    feeStruct.rewardFee = 10;
        feeStruct.lpFee = 3;
        feeStruct.treasuryFee = 3;
        feeStruct.burnFee = 0;
        feeStruct.totalFee = 16;

        // Arbitrary setting max slipplage
        // ensure better security than common 100%
        // will be updated depending on reward tokens
        rewardStruct.swapSlippage = 15;
        rewardStruct.rewardSlippage = 5;
        // Initialized at 0.1% totalSupply
        maxSellTx = MAX_SUPPLY * 1 / 10 ** 3;
        // Initialized to 2.5% totalSupply
        maxHold = MAX_SUPPLY * 25 / 10 ** 3;

        rewardStruct.minToSwap = MAX_SUPPLY * 5 / 10 ** 5;
        
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x0));
        dividendTracker.excludeFromDividends(address(dexStruct.router));
        
        _addAMMPair(dexStruct.pair, true);

        // Fairness - No bypass for the dev
        excludedFromFees[owner()] = false;
  	}
    
    function wbnb() public view returns (address) {
        return dexStruct.router.WETH();
    }
    
    function rewardToken() public view returns (address) {
        return rewardStruct.rewardToken;
    }

  	function withdrawTeamTokens()
  	    external
  	    virtual
  	    onlyOwner
  	{
        teamTimelock.release();
    }

    function cancelUpdate(uint256 fnNb) external onlyOwner {
        pendingContractUpdates[fnNb] = 0;
        
        emit ContractUpdateCancelled(fnNb);
    }

    function updateFeeStruct(
        uint8 _rewardFee,
        uint8 _lpFee,
        uint8 _treasuryFee,
        uint8 _burnFee
    )
        external
        onlyOwner
        safeContractUpdate(0, 3 days)
    {
        uint8 totalFees = _rewardFee + _lpFee + _treasuryFee + _burnFee;
        // Max fees up to 25% max
        require(
            totalFees <= 25,
            "total fees > 25"
        );
        
        feeStruct.rewardFee = _rewardFee;
        feeStruct.lpFee = _lpFee;
        feeStruct.treasuryFee = _treasuryFee;
        feeStruct.burnFee = _burnFee;
        feeStruct.totalFee = totalFees;
        
        emit FeeStructUpdated(_rewardFee, _lpFee, _treasuryFee, _burnFee);
    }

    function setTreasury(address _treasury)
        external
        onlyOwner
        safeContractUpdate(1, 7 days)
    {
        treasury = _treasury;
        
        emit TreasuryUpdated(_treasury);
    }
    
    function setMarketing(address _marketing)
        external
        onlyOwner
        safeContractUpdate(2, 3 days)
    {
        marketing = _marketing;
        
        emit MarketingUpdated(_marketing);
    }
    
    function setFoundation(address _foundation)
        external
        onlyOwner
        safeContractUpdate(3, 3 days)
    {
        foundation = _foundation;
        
        emit FoundationUpdated(_foundation);
    }

    function setDividendTracker(address newAddress)
        external
        onlyOwner
        safeContractUpdate(4, 3 days)
    {
        ScholarDogeDividendTracker newDividendTracker
            = ScholarDogeDividendTracker(payable(newAddress));

        require(
            newDividendTracker.owner() == address(this),
            "Tracker owner must be $SDOGE"
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(dexStruct.router));
        newDividendTracker.excludeFromDividends(address(dexStruct.pair));

        emit UpdateDividendTracker(newAddress);
    }

    function updateDEXStruct(address _router)
        external
        onlyOwner
        safeContractUpdate(5, 15 days)
    {
        _setDexStruct(_router);
        
        emit DexStructUpdated(_router, dexStruct.pair);
    }
    
    function executeLiquidityMigration(address _router)
        external
        onlyOwner
        safeContractUpdate(6, 15 days)
    {
        (uint256 tokenReceived, uint256 bnbReceived) = _removeLiquidity();
        
        _setDexStruct(_router);
        _addLiquidity(tokenReceived, bnbReceived);
        
        emit MigrateLiquidity(_router);
    }
    
    function excludeFromFees(
        address account,
        bool excluded
    )
        external
        onlyOwner
        safeContractUpdate(7, 3 days)
    {
        excludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeFromDividends(
        address account
    )
        external
        onlyOwner
        safeContractUpdate(8, 3 days)
    {
        dividendTracker.excludeFromDividends(account);
    }
    
    function setMaxSellTx(uint256 _amount)
        external
        onlyOwner
    {
        // Protect users from being unable to sell their tokens
        // Min to 0.01% and max to 1% total supply
        require(
            _amount >= MAX_SUPPLY / 10 ** 4 &&
            _amount <= MAX_SUPPLY / 10 ** 2,
            "0.01% < maxSellTx < 1% (supply)"
        );
        
        maxSellTx = _amount;
        
        emit MaxSellTxUpdated(_amount);
    }
    
    function setMaxHoldAmount(uint256 _amount)
        external
        onlyOwner
    {
        // Protect users from being unable to sell their tokens
        // Min to 1% and max to 5% total supply
        require(
            _amount >= MAX_SUPPLY / 10 ** 2 &&
            _amount <= MAX_SUPPLY * 5 / 10 ** 2,
            "1% < maxHold < 5% (supply)"
        );
        
        maxHold = _amount;
        
        emit MaxHoldUpdated(_amount);
    }
    
    function setMinTokensForDividends(uint64 _min)
        external
        onlyOwner
    {
        dividendTracker.setMinTokensForDividends(_min);
    }
    
    function updateClaimWait(uint32 newClaimWait)
        external
        onlyOwner
    {
        dividendTracker.updateClaimWait(newClaimWait);
    }
    
    function withdrawLockedTokens(address token)
        external
        onlyOwner
    {
        require(token != address(this), "Can't withdraw $SDOGE");
        
        uint256 amount;
        bool success;
        
        if (token == wbnb()) {
            amount = address(this).balance;
            (success,) = msg.sender.call{value: amount}("");
        } else {
            amount = IBEP20(token).balanceOf(address(this));
            success = IBEP20(token).transfer(msg.sender, amount);
        }
        
        require(success, "Widthdrawal failed");
    }
    
    function updateRewardStruct(
        uint256 _minToSwap,
        address _rewardToken,
        uint8 _swapSlippage,
        uint8 _rewardSlippage
    )
        external
        onlyOwner
    {
        rewardStruct.minToSwap = _minToSwap;
        rewardStruct.rewardToken = _rewardToken;
        rewardStruct.swapSlippage = _swapSlippage;
        rewardStruct.rewardSlippage = _rewardSlippage;
        
        _addRewardToken(_rewardToken);

        emit RewardStructUpdated(
            _minToSwap,
            _rewardToken,
            _swapSlippage,
            _rewardSlippage
        );
    }

    function setAutomatedMarketMakerPair(
        address _pair,
        bool value
    )
        external
        onlyOwner
    {
        require(
            _pair != dexStruct.pair,
            "$SDOGE: Can't remove current"
        );

        _addAMMPair(_pair, value);
        
        emit SetAutomatedMarketMakerPair(_pair, value);
    }
    
    function switchSafeLaunchOff() external onlyOwner {
        safeLaunch = false;

        emit SafeLaunchDisabled();
    }

    function updateMinTxGas(uint32 newValue) external onlyOwner {
        minTxGas = newValue;

        emit MinTxGasUpdated(newValue);
    }
    
    function updateWithdrawGas(uint32 gas) external onlyOwner {
        dividendTracker.updateWithdrawGas(gas);
    }

	function processDividendTracker(uint256 gas) external {
	    (
		    uint256 iterations,
		    uint256 lastProcessedIndex
		 ) = dividendTracker.process(gas);
		
		emit ProcessedDividendTracker(
		    iterations,
		    lastProcessedIndex,
		    gas
		);
    }

    function claim(address token) external {
		dividendTracker.processAccount(payable(msg.sender), token);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
    {
        // Trick to avoid out of gas
        require(swapping || gasleft() > minTxGas);
        
        if (amount == 0) {
            _updateShareAndTransfer(from, to, 0);

            return;
        }
        
        if (
            safeLaunch &&
            automatedMarketMakerPairs[to] &&
            !excludedFromFees[from]
        ) {
            // Punish bots
            // >= 10 gwei => take fees on tokens
            // > 6 gwei => reverts
            // <= 6 => pass
            if (tx.gasprice >= 10000000000) {
                // 60 % fees to discourage using bots for launch
                uint256 left = amount * 40 / 100;
                uint256 tax = amount - left;
                amount = left;

                _updateShareAndTransfer(from, treasury, tax);
            } else if (tx.gasprice > 6000000000) {
                revert("[SafeLaunch] Gas price should be <= 6");
            } else {
                // Checks if already sold during this block
                uint256 previous = safeLaunchSells[msg.sender];
                
                safeLaunchSells[msg.sender] = block.timestamp + 3 minutes;
                
                
                if (!swapping && previous > block.timestamp) {
                    revert("[SafeLaunch] Already sold during last 3 min");
                }
            }
        }

        if (
            automatedMarketMakerPairs[to] &&
            from != address(dexStruct.router)
        ) {
            require(amount <= maxSellTx,"amount > maxSellTx");
        }

        _processTokensTransfer(from, to, amount);
        
        bool processed = _processTokenConversion(from);

        if (!swapping && !processed && feeStruct.rewardFee > 0)
            _processDividendTracker();
    }

    function _processTokenConversion(address from)
        private
        returns (bool)
    {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinSwap = contractTokenBalance >= rewardStruct.minToSwap;
        bool processed = false;
        
        if (overMinSwap && !shouldAddLp && !shouldReward) {
            shouldAddLp = feeStruct.lpFee > 0;
            shouldReward = feeStruct.rewardFee > 0;
        }
        
        if (
            !automatedMarketMakerPairs[from] &&
            !swapping
        ) {
            swapping = true;
            
            // Slipts in order to avoid too much gas on transfer
            if (shouldAddLp) {
                shouldAddLp = false;
                
                uint256 swapTokens = rewardStruct.minToSwap
                    * feeStruct.lpFee / (feeStruct.lpFee + feeStruct.rewardFee);
    
                _swapAndLiquify(swapTokens);
                
                processed = true;
            } else if (shouldReward) {
                shouldReward = false;
                
                uint256 rewards = rewardStruct.minToSwap
                    * feeStruct.rewardFee / (feeStruct.lpFee + feeStruct.rewardFee);
    
                _swapAndSendDividends(rewards);
                
                processed = true;
            }
            
            swapping = false;
        }
        
        return processed;
    }
    
    function _updateShareAndTransfer(
        address from,
        address to,
        uint256 amount
    )
        private
    {
        super._transfer(from, to, amount);
        
        dividendTracker.updateShare(from, to, amount);
    }
    
    function _processTokensTransfer(
        address from,
        address to,
        uint256 amount
    )
        private
    {
        bool takeFee = !swapping;

        // if any account belongs to _excludedFromFee then remove the fee
        // will be used later for the lottery
        if (excludedFromFees[from] || excludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 treasuryFee = amount * feeStruct.treasuryFee / 100;
            uint256 burnFee = amount * feeStruct.burnFee / 100;
        	uint256 conversionFees = amount * (feeStruct.lpFee
        	    + feeStruct.rewardFee) / 100;

            // if sell, multiply by 1.2
            if (automatedMarketMakerPairs[to]) {
                treasuryFee = treasuryFee * SELL_FACTOR / 100;
                burnFee = burnFee * SELL_FACTOR / 100;
                conversionFees = conversionFees * SELL_FACTOR / 100;
            }

        	amount = amount - treasuryFee - burnFee - conversionFees;
        	treasuryFeeCollected += treasuryFee;
        	
        	// Restricting the max token users can hold
        	require(
                automatedMarketMakerPairs[to] ||
                balanceOf(to) + amount <= maxHold,
                "balance > maxHold"
            );
        	
            _updateShareAndTransfer(from, address(this), conversionFees);
            _updateShareAndTransfer(from, treasury, treasuryFee);

            if (feeStruct.burnFee > 0)
                super._burn(from, burnFee);
        }

        _updateShareAndTransfer(from, to, amount);
    }
    
    function _processDividendTracker()
        private
    {
        try dividendTracker.process(0) returns (
            uint256 iterations,
            uint256 lastProcessedIndex
    	) {
    	    emit ProcessedDividendTracker(
			    iterations,
    	    	lastProcessedIndex,
    	    	0
    	    );
    	} catch {}
    }
    
    function _addRewardToken(address _token) private {
        if (!addedTokens[_token]) {
            addedTokens[_token] = true;
            
            rewardTokens.push(_token);
            
            rewardTokenCount++;
        
            emit RewardTokenAdded(_token);
        }
    }
    
    function _setDexStruct(address _router) private {
        dexStruct.router = IPancakeRouter02(_router);
        dexStruct.pair = IPancakeFactory(dexStruct.router.factory())
            .createPair(address(this), dexStruct.router.WETH());
            
        dividendTracker.excludeFromDividends(_router);
        _addAMMPair(dexStruct.pair, true);
    }

    function _swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        _swapTokensForBnb(half);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to dex
        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance);
    }
    
    function _addAMMPair(
        address pair,
        bool value
    )
        private
    {
        automatedMarketMakerPairs[pair] = value;

        if (value)
            dividendTracker.excludeFromDividends(pair);
    }

    function _swapTokensForBnb(
        uint256 tokenAmount
    )
        private
    {
        // generate the dex pair path of token -> wbnb
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = dexStruct.router.WETH();

        _approve(address(this), address(dexStruct.router), tokenAmount);

        // make the swap
        dexStruct.router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp + 5 minutes
        );
    }
    
    function _swapTokensForTokens(
        uint256 tokenAmount
    )
        private
    {
        uint256 previousBalance = address(this).balance;

        _swapTokensForBnb(tokenAmount);

        uint256 toTransfer = address(this).balance - previousBalance;

        // generate the dex pair path of token -> wbnb
        address[] memory path = new address[](2);

        path[0] = dexStruct.router.WETH();
        path[1] = rewardStruct.rewardToken;

        // make the swap
        dexStruct.router
            .swapExactETHForTokensSupportingFeeOnTransferTokens
            {value: toTransfer}(
                _getExpectedMinSwap(
                    path[0],
                    path[1],
                    toTransfer,
                    rewardStruct.rewardSlippage
                ),
                path,
                address(this),
                block.timestamp + 5 minutes
            );
    }
    
    function _getExpectedMinSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 slippage
    )
        private
        view
        returns (uint256)
    {
        IPancakePair pair = IPancakePair(
            IPancakeFactory(dexStruct.router.factory())
                .getPair(tokenIn, tokenOut)
        );
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 amountOut = pair.token0() == tokenIn ?
        amountIn * reserve1 / reserve0 : amountIn * reserve0 / reserve1;

        return amountOut - amountOut * slippage / 100;
    }

    function _removeLiquidity()
        private
        returns (uint256, uint256)
    {
        bool result = IBEP20(dexStruct.pair).approve(address(dexStruct.router),
                IBEP20(dexStruct.pair).balanceOf(address(this)));
                
        require(result, "Approve pair failed");
            
        return dexStruct.router.removeLiquidityETH(
            address(this),
            IBEP20(dexStruct.pair).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(dexStruct.router), tokenAmount);

        dexStruct.router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function _swapAndSendDividends(uint256 tokens) private {
        uint256 dividends;
        bool success;
        
        if (rewardStruct.rewardToken == wbnb()) {
            _swapTokensForBnb(tokens);

            dividends = address(this).balance;
            (success,) = address(dividendTracker).call{value: dividends}("");
        } else {
            if (rewardStruct.rewardToken != address(this))
                _swapTokensForTokens(tokens);

            IBEP20 token = IBEP20(rewardStruct.rewardToken);
            dividends = token.balanceOf(address(this));
            success = token.transfer(address(dividendTracker), dividends);
            
            if (success)
                dividendTracker.receiveTokens(rewardStruct.rewardToken, dividends);
        }

        if (success)
   	 		emit SendDividends(dividends);
    }
}