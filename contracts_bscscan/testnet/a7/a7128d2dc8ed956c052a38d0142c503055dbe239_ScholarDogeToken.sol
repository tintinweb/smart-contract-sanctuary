// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ScholarDogeTeamTimelock.sol";
import "./ScholarDogeDividendTracker.sol";
import "./IPancakePair.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter02.sol";

contract ScholarDogeToken is BEP20, Ownable {
    struct FeeStruct {
        uint8 rewardFee;
        uint8 lpFee;
        uint8 treasuryFee;
        uint8 burnFee;
        uint8 totalFee;
    }
    
    struct RewardStruct {
        bool swapAndLiquifyOn;
        bool rewardsOn;
        bool burnOn;
        uint128 minToSwap;
        address rewardToken;
    }

    struct DexStruct {
        IPancakeRouter02 router;
        address pair;
    }
    
    uint256 internal constant SUPPLY = 1000000000 * (10**9);
    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint8 internal constant SELL_FACTOR = 120;
    bool public punishBots = true;

    // Stores the contracts updates
    // index = function number (arbitrary)
    // value = block timestamp of the first call + delay
    mapping (uint8 => uint256) public contractUpdates;

    uint256 public maxHold = SUPPLY;

    // Set a multi-sign wallet here
    address public treasury;

    bool private swapping;
    bool public initialized;

    uint256 public maxSellTx = SUPPLY;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 internal requiredGas = 300000;

    FeeStruct public feeStruct;
    RewardStruct public rewardStruct;
    DexStruct public dexStruct;

    ScholarDogeTeamTimelock public teamTimelock;
    ScholarDogeDividendTracker public dividendTracker;

    mapping (address => bool) public _excludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed _dividendTracker);

    event FeeStructUpdated(
        uint8 _rewardFee,
        uint8 _lpFee,
        uint8 _treasuryFee,
        uint8 _burnFee
    );

    event RewardStructUpdated(
        bool _swapAndLiquifyOn,
        bool _rewardsOn,
        bool _burnOn,
        uint256 indexed _minToSwap,
        address indexed _rewardToken
    );

    event DexStructUpdated(address indexed _router, address indexed _pair);

    event MaxSellTxUpdated(uint256 indexed _maxSellTx);

    event MaxHoldUpdated(uint256 indexed _maxHold);

    event TreasuryUpdated(address indexed _treasury);

    event ExcludeFromFees(address indexed _account, bool _excluded);

    event SetAutomatedMarketMakerPair(
        address indexed _pair,
        bool indexed _value
    );

    event RequiredGasUpdated(uint256 indexed newValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 addedLp
    );

    event SendDividends(
    	uint256 tokens,
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

    event MigrateLiquidity(
        uint256 indexed tokenAmount,
        uint256 indexed bnbAmount,
        address indexed newAddress
    );
    
    event PunishBotsDisabled();
    
    event BotPunished(address indexed bot, uint256 indexed amount);
    
    event ContractUpdateCall(uint8 indexed fnNb, uint256 indexed delay);

    event ContractUpdateCancelled(uint8 indexed fnNb);

    // Adds a security on sensible contract updates
    modifier safeContractUpdate(uint8 fnNb, uint256 delay) {
        if (contractUpdates[fnNb] == 0) {
            contractUpdates[fnNb] = block.timestamp + delay;

            emit ContractUpdateCall(fnNb, delay);
            
            return;
        } else {
            require(
                block.timestamp >= contractUpdates[fnNb], 
                "$SDOGE: Too early"
            );
            
            contractUpdates[fnNb] = 0;
            
            _;
        }
    }
    
    modifier onlyInit() {
        require(
            !initialized,
            "$SDOGE: Already init");

        _;
        
        initialized = true;
    }

    constructor() BEP20("ScholarDoge", "$SDOGE") {
        // Main net: 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // Test net: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        dexStruct.router
            = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        dexStruct.pair = IPancakeFactory(dexStruct.router.factory())
            .createPair(address(this), dexStruct.router.WETH());
        
        dividendTracker = new ScholarDogeDividendTracker();
        
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x0));
        dividendTracker.excludeFromDividends(address(dexStruct.router));
        // TODO See if needed
        dividendTracker.excludeFromDividends(address(dexStruct.pair));
        
        // Init supply alloc
        // 5%
        uint256 teamAlloc = SUPPLY * 5 / 100;
        // 5.2%
        uint256 marketingAlloc = SUPPLY * 52 / 1000;
        // 10%
	    uint256 foundationAlloc = SUPPLY * 10 / 100;
	    // 8.4% Private sale - 42% Presale - 29.4% Liquidity
        uint256 alloc = SUPPLY - teamAlloc - marketingAlloc
	        - foundationAlloc;
        
        teamTimelock = new ScholarDogeTeamTimelock(this, _msgSender());
        
        // TODO Exclude marketing / foundation as well
        _excludedFromFees[dexStruct.pair] = true;
        _excludedFromFees[address(this)] = true;
        _excludedFromFees[address(teamTimelock)] = true;
        
        _mint(owner(), alloc);
        _mint(address(teamTimelock), teamAlloc);
        // Hardcode marketing multisig here only used here
        _mint(address(0x1), marketingAlloc);
        _mint(address(0x2), foundationAlloc);
    }

    receive() external payable {

  	}

  	function initializeContract(address _treasury)
  	    external
  	    onlyOwner
  	    onlyInit
  	{
  	    feeStruct.rewardFee = 4;
        feeStruct.lpFee = 4;
        feeStruct.treasuryFee = 3;
        feeStruct.burnFee = 1;
        feeStruct.totalFee = 12;

        // Initialized at 0.5% totalSupply
        maxSellTx = SUPPLY * 5 / 10 ** 3;
        // Initialized to 2.5% totalSupply
        maxHold = SUPPLY * 25 / 10 ** 3;

        rewardStruct.swapAndLiquifyOn = true;
        rewardStruct.rewardsOn = true;
        rewardStruct.burnOn = true;
        rewardStruct.minToSwap
            = uint128(SUPPLY / 10 ** 4);
        // Default to 0x0 => BNB
        rewardStruct.rewardToken = address(0x0);
        
        treasury = _treasury;
        // Treasury will not be taxed as used for charities
        _excludedFromFees[treasury] = true;
  	}

  	// Testing purposes only
    function initLiquidity() external payable onlyOwner {
        _transfer(_msgSender(), address(this),
            balanceOf(_msgSender()) / 2);
        
        _addLiquidity(balanceOf(address(this)), msg.value);
    }

  	function withdrawTeamTokens()
  	    external
  	    virtual
  	    onlyOwner
  	{
        teamTimelock.release();
    }

    function cancelContractUpdate(uint8 fnNb) external onlyOwner {
        contractUpdates[fnNb] = 0;
        
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
        uint16 totalFees = _rewardFee + _lpFee + _treasuryFee + _burnFee;
        // Max fees up to 20% max
        require(
            totalFees <= 20,
            "$SDOGE: > 20"
        );
        
        feeStruct.rewardFee = _rewardFee;
        feeStruct.lpFee = _lpFee;
        feeStruct.treasuryFee = _treasuryFee;
        feeStruct.burnFee = _burnFee;
        feeStruct.totalFee = uint8(totalFees);
        
        emit FeeStructUpdated(_rewardFee, _lpFee, _treasuryFee, _burnFee);
    }

    function setTreasury(address _treasury)
        external
        onlyOwner
        safeContractUpdate(1, 3 days)
    {
        treasury = _treasury;
        
        emit TreasuryUpdated(_treasury);
    }

    function setDividendTracker(address newAddress)
        external
        onlyOwner
        safeContractUpdate(2, 3 days)
    {
        ScholarDogeDividendTracker newDividendTracker
            = ScholarDogeDividendTracker(payable(newAddress));

        require(
            newDividendTracker.owner() == address(this),
            "$SDOGE: Tracker owner must be $SDOGE"
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(dexStruct.router));
        newDividendTracker.excludeFromDividends(address(dexStruct.pair));

        emit UpdateDividendTracker(newAddress);
    }

    function updateDexStruct(address _router)
        external
        onlyOwner
        safeContractUpdate(3, 15 days)
    {
        _setDexStruct(_router);
        
        emit DexStructUpdated(_router, dexStruct.pair);
    }
    
    function migrateLiquidity(address _router)
        external
        onlyOwner
        safeContractUpdate(4, 15 days)
    {
        (uint256 tokenReceived, uint256 bnbReceived) = _removeLiquidity();
        
        _setDexStruct(_router);
        _addLiquidity(tokenReceived, bnbReceived);
        
        emit MigrateLiquidity(tokenReceived, bnbReceived, _router);
    }
    
    function excludeFromFees(
        address account,
        bool excluded
    )
        external
        onlyOwner
        safeContractUpdate(5, 3 days)
    {
        _excludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function setMaxSellTx(uint256 _amount)
        external
        onlyOwner
        safeContractUpdate(6, 3 days)
    {
        // Protect users from being unable to sell their tokens
        // Min to 0.01% and max to 1% total supply
        require(
            _amount >= SUPPLY / 10 ** 4 &&
            _amount <= SUPPLY / 10 ** 2,
            "$SDOGE: 0.01% < maxSellTx < 1% (supply)"
        );
        
        maxSellTx = _amount;
        
        emit MaxSellTxUpdated(_amount);
    }
    
    function setMaxHold(uint256 _amount)
        external
        onlyOwner
        safeContractUpdate(7, 3 days)
    {
        // Protect users from being unable to sell their tokens
        // Min to 1% and max to 5% total supply
        require(
            _amount >= SUPPLY / 10 ** 2 &&
            _amount <= SUPPLY * 5 / 10 ** 2,
            "$SDOGE: 1% < maxHold < 5% (supply)"
        );
        
        maxHold = _amount;
        
        emit MaxHoldUpdated(_amount);
    }
    
    function updateRewardStruct(
        bool _swapAndLiquifyOn,
        bool _rewardsOn,
        bool _burnOn,
        uint128 _minToSwap,
        address _rewardToken
    )
        external
        onlyOwner
    {
        rewardStruct.swapAndLiquifyOn = _swapAndLiquifyOn;
        rewardStruct.rewardsOn = _rewardsOn;
        rewardStruct.burnOn = _burnOn;
        rewardStruct.minToSwap = _minToSwap;
        rewardStruct.rewardToken = _rewardToken;

        emit RewardStructUpdated(
            _swapAndLiquifyOn,
            _rewardsOn,
            _burnOn,
            _minToSwap,
            _rewardToken
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

        _setAutomatedMarketMakerPair(_pair, value);
        
        emit SetAutomatedMarketMakerPair(_pair, value);
    }
    
    function disablePunishBots() external onlyOwner {
        punishBots = false;
        
        emit PunishBotsDisabled();
    }

    function updateRequiredGas(uint256 newValue) external onlyOwner {
        requiredGas = newValue;
        
        emit RequiredGasUpdated(newValue);
    }
    
    function updateWithdrawGas(uint256 gas) external onlyOwner {
        dividendTracker.updateWithdrawGas(gas);
    }
    
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        dividendTracker.updateClaimWait(newClaimWait);
    }
    
    function isExcludedFromFees(address account) public view returns (bool) {
        return _excludedFromFees[account];
    }

	function processDividendTracker(uint256 gas) external {
	    (
		    uint256 iterations,
		    uint256 claims,
		    uint256 lastProcessedIndex
		 ) = dividendTracker.process(gas);
		
		emit ProcessedDividendTracker(
		    iterations,
		    claims,
		    lastProcessedIndex,
		    false,
		    gas,
		    tx.origin
		);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
    {
        if (amount == 0) {
            super._transfer(from, to, 0);
            
            return;
        }

        _processMaxSellTxAmountCheck(from, to, amount);
        
        if (punishBots) {
            amount = _processPunishBots(from, amount);
        }

        _processTokenConversions(from, to);
        _processTransfer(from, to, amount);
        _processDividendTracker(from, to);
    }
    
    function _processPunishBots(address from, uint256 amount)
        private
        returns (uint256)
    {
        // Hardcoded values as will only be used for project launch,
        // avoiding a maximum of bots to pump and dump by taxing them.
        // All investors will be warned several time about this
        // If gas price >= 15 gwei => taking fees
        // If gas price >= 7.5 gwei => reverts
        // If gas price < 7.5 gwei => accepted
        if (tx.gasprice >= 15000000000) {
            uint256 left = amount / 100;
            uint256 tax = amount - left;
            
            super._transfer(from, treasury, tax);
            
            emit BotPunished(from, tax);
            
            return left;
        } else if (tx.gasprice >= 7500000000) {
            revert();
        }
        
        return amount;
    }
    
    function _processMaxSellTxAmountCheck(
        address from,
        address to,
        uint256 amount
    ) 
        private
        view
    {
        if (
            !swapping &&
            automatedMarketMakerPairs[to] &&
        	from != address(dexStruct.router) &&
            !_excludedFromFees[to]
        ) {
            require(
                amount <= maxSellTx,
                "$SDOGE: > maxSellTx amount."
            );
        }
    }
    
    function _processTokenConversions(
        address from,
        address to
    )
        private
    {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinSwap = contractTokenBalance >= rewardStruct.minToSwap;

        if (
            overMinSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != address(this) &&
            to != address(this)
        ) {
            swapping = true;

            if (rewardStruct.swapAndLiquifyOn) {
                uint256 swapTokens = contractTokenBalance
                    * feeStruct.lpFee / feeStruct.totalFee;

                _swapAndLiquify(swapTokens);
            }

            if (rewardStruct.rewardsOn) {
                uint256 rewardTokens = contractTokenBalance
                    * feeStruct.rewardFee / feeStruct.totalFee;
                    
                _swapAndSendDividends(rewardTokens);
            }

            swapping = false;
        }
    }
    
    function _processTransfer(
        address from,
        address to,
        uint256 amount
    )
        private
    {
        bool takeFee = !swapping;

        // if any account belongs to _excludedFromFee then remove the fee
        // will be used later for the lottery
        if (_excludedFromFees[from] || _excludedFromFees[to]) {
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
        	
        	// Restricting the max token users can hold
        	require(
        	    balanceOf(to) + amount <= maxHold,
        	    "$SDOGE: > maxHold amount"
        	);
        	
            super._transfer(from, address(this), conversionFees);
            super._transfer(from, treasury, treasuryFee);
            
            if (rewardStruct.burnOn) {
                super._burn(
                    from,
                    burnFee
                );
            }
        }

        super._transfer(from, to, amount);
    }
    
    function _processDividendTracker(
        address from,
        address to
    )
        private
    {
        if (rewardStruct.rewardsOn || !initialized) {
            try dividendTracker.setBalance(
                payable(from),
                balanceOf(from)
            ) {} catch {}
            
            try dividendTracker.setBalance(
                payable(to),
                balanceOf(to)
            ) {} catch {}
    
            if (!swapping) {
    	    	uint256 gas = requiredGas;
    
    	    	try dividendTracker.process(gas) returns (
    	    	    uint256 iterations,
    	    	    uint256 claims,
    	    	    uint256 lastProcessedIndex
    	    	) {
    	    		emit ProcessedDividendTracker(
    	    		    iterations,
    	    		    claims,
    	    		    lastProcessedIndex,
    	    		    true,
    	    		    gas,
    	    		    tx.origin
    	    		);
    	    	} catch {}
            }
        }
    }
    
    function _setAutomatedMarketMakerPair(
        address pair,
        bool value
    )
        private
    {
        automatedMarketMakerPairs[pair] = value;

        if (value) 
            dividendTracker.excludeFromDividends(pair);
    }
    
    function _setDexStruct(address _router) private {
        dexStruct.router = IPancakeRouter02(_router);
        dexStruct.pair = IPancakeFactory(dexStruct.router.factory())
            .createPair(address(this), dexStruct.router.WETH());
            
        dividendTracker.excludeFromDividends(_router);
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
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            block.timestamp
        );
    }

    function _removeLiquidity()
        private
        returns (uint256 amountToken, uint256 amountBnb)
    {
        bool result = IBEP20(dexStruct.pair).approve(address(dexStruct.router),
                IBEP20(dexStruct.pair).balanceOf(address(this)));
                
        require(result, "$SDOGE: Approve pair failed");
            
        return dexStruct.router.removeLiquidityETH(
            address(this),
            IBEP20(dexStruct.pair).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
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
            block.timestamp
        );
    }

    function _swapAndSendDividends(uint256 tokens) private {
        _swapTokensForBnb(tokens);

        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }
}