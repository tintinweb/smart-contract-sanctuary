// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.5;

import "./FinanceBase.sol";

// Implements rewards & burns
contract BINERO is FinanceBase {
	// REWARD CYCLE
	uint256 private _rewardCyclePeriod = 12 hours; // The duration of the reward cycle (e.g. can claim rewards once a day)
	uint256 private _rewardCycleExtensionThreshold; // If someone sends or receives more than a % of their balance in a transaction, their reward cycle date will increase accordingly
	mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address

	uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
	uint256 private _totalBNBClaimed; // The total number of BNB claimed by all addresses
	mapping(address => uint256) private _totalTokenClaimed; // The amount of token T claimed by each address
	mapping(address => uint256) private _bnbRewardClaimed; // The amount of BNB claimed by each address
	
	mapping(address => uint8) private _claimDivision; //Allows users to optionally use a % of the reward pool to receive the second token option automatically
	mapping(address => mapping(address => uint256)) private _tokenRewardClaimed; // The amount of BNB claimed by each holder as tokens (holder -> token address)
	
	mapping (address => address) private _firstRewardToken; //stores users first token option
	mapping (address => address) private _secondRewardToken; //stores users second token option
	mapping (string => address) private _tokensList; //hold the token addresses
	mapping (address => bool) private _tokensAllowance; //check if a token distribution is allowed or not
	
	mapping(address => bool) private _addressesExcludedFromRewards; // The list of addresses excluded from rewards
	mapping(address => mapping(address => bool)) private _rewardClaimApprovals; //Used to allow an address to claim rewards on behalf of someone else
	
	uint256 private _minRewardBalance; //The minimum balance required to be eligible for rewards
	uint256 private _maxClaimAllowed = 50 ether; // Can only claim up to 50 bnb at a time.
	uint256 private _globalRewardDampeningPercentage = 3; // Rewards are reduced by 3% at the start to fill the main BNB pool faster and ensure consistency in rewards
	uint256 private _mainBnbPoolSize = 500 ether; // Any excess BNB after the main pool will be used as reserves to ensure consistency in rewards
	uint256 private _gradualBurnMagnitude; // The contract can optionally burn tokens (By buying them from reward pool).  This is the magnitude of the burn (1 = 0.01%).
	uint256 private _gradualBurnTimespan = 1 days; //Burn every 1 day by default
	uint256 private _lastBurnDate; //The last burn date
	uint256 private _minBnbPoolSizeBeforeBurn = 20 ether; //The minimum amount of BNB that need to be in the pool before initiating gradual burns

	// AUTO-CLAIM
	bool private _autoClaimEnabled = true;
	uint256 private _maxGasForAutoClaim = 800000; // The maximum gas to consume for processing the auto-claim queue
	address[] _rewardClaimQueue;
	mapping(address => uint) _rewardClaimQueueIndices;
	uint256 private _rewardClaimQueueIndex;
	mapping(address => bool) _addressesInRewardClaimQueue; // Mapping between addresses and false/true depending on whether they are queued up for auto-claim or not
	bool private _reimburseAfterTokenClaimFailure; // If true, and BNO reward claim portion fails, the portion will be given as BNB instead
	bool private _processingQueue; //Flag that indicates whether the queue is currently being processed and sending out rewards
	mapping(address => bool) private _whitelistedExternalProcessors; //Contains a list of addresses that are whitelisted for low-gas queue processing 
	uint256 private _sendWeiGasLimit;
	bool private _excludeNonHumansFromRewards = true;

	event RewardClaimed(address recipient, uint256 amountFirst, uint256 amountSecond, uint256 amountBnb, uint256 nextAvailableClaimDate); 
	event Burned(uint256 bnbAmount);

    //Router MAINNET: 0x10ED43C718714eb63d5aA57B78B54704E256024E TESTNET: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 KIENTI360 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
	constructor (address routerAddress) FinanceBase(routerAddress) {
		// Exclude addresses from rewards
		_addressesExcludedFromRewards[BURN_WALLET] = true;
		_addressesExcludedFromRewards[owner()] = true;
		_addressesExcludedFromRewards[address(this)] = true;
		_addressesExcludedFromRewards[address(0)] = true;
		
		_tokensList["BNO"] = address(this);
		_tokensList["BNB"] = _pancakeswapV2Router.WETH();
		
		_tokensList["ADA"] = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47; //mainnet 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47 | 0xaC2A889dEfE2205AA18BD46c0A24e8cAE7084DBB testnet
		_tokensList["BUSD"] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //mainnet 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 | 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47 testnet 
		_tokensList["CAKE"] = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //mainnet 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82 | 0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e testnet
		_tokensList["DOT"] = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402; //mainnet 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402 | 0xE2EEEaa527f78eE845EB46355210FbeD77e92C47 testnet
		_tokensList["ETH"] = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8; //mainnet 0x2170Ed0880ac9A755fd29B2688956BD959F933F8 | 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca testnet
		
		enableToken("ADA");
		enableToken("BNB");
		enableToken("BUSD");
		enableToken("CAKE");
		enableToken("DOT");
		enableToken("ETH");
		enableToken("BNO");
        
		// If someone sends or receives more than 75% of their balance in a transaction, their reward cycle date will increase accordingly
		setRewardCycleExtensionThreshold(75);
	}


	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function onActivated() internal override {
		super.onActivated();
		setAutoClaimEnabled(true);
		setReimburseAfterTokenClaimFailure(true);
		setMinRewardBalance(1000000 * 10**decimals());  //At least 10,000,000 tokens are required to be eligible for rewards
		setGradualBurnMagnitude(1); //Buy tokens using 0.01% of reward pool and burn them
		_lastBurnDate = block.timestamp;
		setBotFeeMode();
	}

	function onBeforeTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onBeforeTransfer(sender, recipient, amount);

		if (!isMarketTransfer(sender, recipient)) {
			return;
		}

        // Extend the reward cycle according to the amount transferred.  This is done so that users do not abuse the cycle (buy before it ends & sell after they claim the reward)
        uint256 recipientExtension = _nextAvailableClaimDate[recipient] + calculateRewardCycleExtension(balanceOf(recipient), amount);
        uint256 senderExtension = _nextAvailableClaimDate[sender] + calculateRewardCycleExtension(balanceOf(sender), amount);
        
		_nextAvailableClaimDate[recipient] = recipientExtension;
		_nextAvailableClaimDate[sender] = senderExtension;
		
		bool isSelling = isPancakeswapPair(recipient);
		if (!isSelling) {
			// Wait for a dip xd
			return;
		}

		// Process gradual burns
		bool burnTriggered = processGradualBurn();

		// Do not burn & process queue in the same transaction
		if (!burnTriggered && isAutoClaimEnabled()) {
			// Trigger auto-claim
			try this.processRewardClaimQueue(_maxGasForAutoClaim) { } catch { }
		}
    }


	function onTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onTransfer(sender, recipient, amount);

		if (!isMarketTransfer(sender, recipient)) {
			return;
		}

		// Update auto-claim queue after balances have been updated
		updateAutoClaimQueue(sender);
		updateAutoClaimQueue(recipient);
    }
	
	
	function processGradualBurn() private returns(bool) {
		if (!shouldBurn()) {
			return false;
		}

		uint256 burnAmount = address(this).balance * _gradualBurnMagnitude / 10000;
		doBuyAndBurn(burnAmount);
		return true;
	}


	function updateAutoClaimQueue(address user) private {
		bool isQueued = _addressesInRewardClaimQueue[user];

		if (!isIncludedInRewards(user)) {
			if (isQueued) {
				// Need to dequeue
				uint index = _rewardClaimQueueIndices[user];
				address lastUser = _rewardClaimQueue[_rewardClaimQueue.length - 1];

				// Move the last one to this index, and pop it
				_rewardClaimQueueIndices[lastUser] = index;
				_rewardClaimQueue[index] = lastUser;
				_rewardClaimQueue.pop();

				// Clean-up
				delete _rewardClaimQueueIndices[user];
				delete _addressesInRewardClaimQueue[user];
			}
		} else {
			if (!isQueued) {
				// Need to enqueue
				_rewardClaimQueue.push(user);
				_rewardClaimQueueIndices[user] = _rewardClaimQueue.length - 1;
				_addressesInRewardClaimQueue[user] = true;
			}
		}
	}


    function claimReward() isHuman nonReentrant external {
		claimReward(msg.sender);
	}
        
	function claimReward(address user) private {
		require(msg.sender == user || isClaimApproved(user, msg.sender), "You are not allowed to claim rewards on behalf of this user");
		require(isRewardReady(user), "Claim date for this address has not passed yet");
		require(isIncludedInRewards(user), "Address is excluded from rewards, make sure there is enough BNO balance");
        
		bool success = doClaimReward(user);
		require(success, "Reward claim failed");
	}
    

	function doClaimReward(address user) private returns (bool) {
		// Update the next claim date & the total amount claimed
		_nextAvailableClaimDate[user] = block.timestamp + rewardCyclePeriod();
        
		address firstTokenAddress = _firstRewardToken[user];
		address secondTokenAddress = _secondRewardToken[user];
		address bnbAddress = _pancakeswapV2Router.WETH();
        uint8 divisionPercentage;
		
        //user didn't set any token
		if (firstTokenAddress == address(0) && secondTokenAddress == address(0) 
		|| (!_tokensAllowance[firstTokenAddress] && !_tokensAllowance[secondTokenAddress])) { 
		    firstTokenAddress = bnbAddress;
		    secondTokenAddress = address(this);
		    divisionPercentage = 50;
		} else {
		    divisionPercentage = _claimDivision[user];
		}
		
		uint256 reward = calculateBNBReward(user);
        uint256 firstTokenRewards = (reward * divisionPercentage) / 100;
		uint256 secondTokenRewards = reward - firstTokenRewards;
		uint256 optionalBnbRewards = 0;
		
		bool firstTokenClaimSuccess = true;
		bool secondTokenClaimSuccess = true;
		bool optionalBnbClaim = true;
		
        // Claim BNO tokens
        if (firstTokenAddress != address(0) && firstTokenRewards > 0 || !_tokensAllowance[firstTokenAddress]) {
            if (firstTokenAddress == bnbAddress) {
                optionalBnbRewards += firstTokenRewards;
            } else {
                if (!claimTokens(user, firstTokenAddress, firstTokenRewards)) {
        			// If token claim fails for any reason, award whole portion as BNB
        			if (_reimburseAfterTokenClaimFailure) {
        				optionalBnbRewards += firstTokenRewards;
        			} else {
        				firstTokenClaimSuccess = false;
        			}
        
        			firstTokenRewards = 0;
    		    }
            }
        } else {
            optionalBnbRewards += firstTokenRewards;
        }
		
		if (secondTokenAddress != address(0) && secondTokenRewards > 0 || !_tokensAllowance[secondTokenAddress]) {
    		if (secondTokenAddress == bnbAddress) {
    		    optionalBnbRewards += secondTokenRewards;
            } else {
                if (!claimTokens(user, secondTokenAddress, secondTokenRewards)) {
        			// If token claim fails for any reason, award whole portion as BNB
        			if (_reimburseAfterTokenClaimFailure) {
        				optionalBnbRewards += secondTokenRewards;
        			} else {
        				secondTokenClaimSuccess = false;
        			}
        
        			secondTokenRewards = 0;
    		    }
            }
		} else {
		    optionalBnbRewards += secondTokenRewards;
		}
		
		if (optionalBnbRewards > 0) {
		    optionalBnbClaim = claimBNB(user, optionalBnbRewards);
		}
		
		// Fire the event in case something was claimed
		if (firstTokenClaimSuccess || secondTokenClaimSuccess || optionalBnbClaim) {
            uint256 nextDate = _nextAvailableClaimDate[user];		    
			emit RewardClaimed(user, firstTokenRewards, secondTokenRewards, optionalBnbRewards, nextDate);
		}
		
		return firstTokenClaimSuccess && secondTokenClaimSuccess && optionalBnbClaim;
	}


	function claimBNB(address user, uint256 bnbAmount) private returns (bool) {
		if (bnbAmount == 0) {
			return true;
		}

		// Send the reward to the caller
		if (_sendWeiGasLimit > 0) {
			(bool sent,) = user.call{value : bnbAmount, gas: _sendWeiGasLimit}("");
			if (!sent) {
				return false;
			}
		} else {
			(bool sent,) = user.call{value : bnbAmount}("");
			if (!sent) {
				return false;
			}
		}
        
	    uint256 bnbRewardClaimedByUser = _bnbRewardClaimed[user];
	    uint256 totalBnbClaimedByAll = _totalBNBClaimed;
	    
	    bnbRewardClaimedByUser += bnbAmount;
	    totalBnbClaimedByAll += bnbAmount;
	    
	    _bnbRewardClaimed[user] = bnbRewardClaimedByUser;
		_totalBNBClaimed = totalBnbClaimedByAll;
		return true;
	}


	function claimTokens(address user, address token, uint256 bnbAmount) private returns (bool) {
		if (bnbAmount == 0) {
			return true;
		}

		bool success = swapBNBForTokens(user, token, bnbAmount);
		if (!success) {
			return false;
		}
        
        uint256 bnbRewardClaimedAsTokenT = _tokenRewardClaimed[user][token];
        uint256 bnbRewardClaimedByUser = _bnbRewardClaimed[user];
    	uint256 totalBnbClaimedByAll = _totalBNBClaimed;
        uint256 totalTokenClaimedByAll = _totalTokenClaimed[token];
	    
	    bnbRewardClaimedAsTokenT += bnbAmount;
	    bnbRewardClaimedByUser += bnbAmount;
	    totalBnbClaimedByAll += bnbAmount;
	    totalTokenClaimedByAll += bnbAmount;
	    
		_tokenRewardClaimed[user][token] = bnbRewardClaimedAsTokenT;
	    _bnbRewardClaimed[user] = bnbRewardClaimedByUser;
		_totalBNBClaimed = totalBnbClaimedByAll;
		_totalTokenClaimed[token] = totalBnbClaimedByAll;
		
		return true;
	}


	// Processes users in the claim queue and sends out rewards when applicable. The amount of users processed depends on the gas provided, up to 1 cycle through the whole queue. 
	// Note: Any external processor can process the claim queue (e.g. even if auto claim is disabled from the contract, an external contract/user/service can process the queue for it 
	// and pay the gas cost). "gas" parameter is the maximum amount of gas allowed to be consumed
	function processRewardClaimQueue(uint256 gas) public {
		require(gas > 0, "Gas limit is required");

		uint256 queueLength = _rewardClaimQueue.length;
		uint256 rewardQueueIndex = _rewardClaimQueueIndex;
		
		if (queueLength == 0) {
			return;
		}

		uint256 gasUsed = 0;
		uint256 gasLeft = gasleft();
		uint256 iteration = 0;
		_processingQueue = true;

		// Keep claiming rewards from the list until we either consume all available gas or we finish one cycle
		while (gasUsed < gas && iteration < queueLength) {
			if (rewardQueueIndex >= queueLength) {
				rewardQueueIndex = 0;
			}

			address user = _rewardClaimQueue[rewardQueueIndex];
			if (isRewardReady(user) && isIncludedInRewards(user)) {
				doClaimReward(user);
			}

			uint256 newGasLeft = gasleft();
			
			if (gasLeft > newGasLeft) {
				uint256 consumedGas = gasLeft - newGasLeft;
				gasUsed += consumedGas;
				gasLeft = newGasLeft;
			}

			iteration++;
			rewardQueueIndex++;
		}
        
        _rewardClaimQueueIndex = rewardQueueIndex;
		_processingQueue = false;
	}

	// Allows a whitelisted external contract/user/service to process the queue and have a portion of the gas costs refunded.
	// This can be used to help with transaction fees and payout response time when/if the queue grows too big for the contract.
	// "gas" parameter is the maximum amount of gas allowed to be used.
	function processRewardClaimQueueAndRefundGas(uint256 gas) external {
		require(_whitelistedExternalProcessors[msg.sender], "Not whitelisted - use processRewardClaimQueue instead");

		uint256 startGas = gasleft();
		processRewardClaimQueue(gas);
		uint256 gasUsed = startGas - gasleft();

		payable(msg.sender).transfer(gasUsed);
	}


	function isRewardReady(address user) public view returns(bool) {
		return _nextAvailableClaimDate[user] <= block.timestamp;
	}


	function isIncludedInRewards(address user) public view returns(bool) {
		if (_excludeNonHumansFromRewards) {
			if (isContract(user)) {
				return false;
			}
		}

		return balanceOf(user) >= _minRewardBalance && !_addressesExcludedFromRewards[user];
	}


	// This function calculates how much (and if) the reward cycle of an address should increase based on its current balance and the amount transferred in a transaction
	function calculateRewardCycleExtension(uint256 balance, uint256 amount) public view returns (uint256) {
		uint256 basePeriod = rewardCyclePeriod();

		if (balance == 0) {
			// Receiving $BNO on a zero balance address:
			// This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
			// Or the address has transferred all of its tokens in the past and has now received some again, in which case we will set the reward date to a date very far in the future
			return block.timestamp + basePeriod;
		}

		uint256 rate = amount * 100 / balance;

		// Depending on the % of $BNO tokens transferred, relative to the balance, we might need to extend the period
		if (rate >= _rewardCycleExtensionThreshold) {

			// If new balance is X percent higher, then we will extend the reward date by X percent
			uint256 extension = basePeriod * rate / 100;

			// Cap to the base period
			if (extension >= basePeriod) {
				extension = basePeriod;
			}

			return extension;
		}

		return 0;
	}


	function calculateBNBReward(address ofAddress) public view returns (uint256) {
		uint256 holdersAmount = totalAmountOfTokensHeld();

		uint256 balance = balanceOf(ofAddress);
		uint256 bnbPool =  address(this).balance * (100 - _globalRewardDampeningPercentage) / 100;
		uint256 bnbPoolSize = _mainBnbPoolSize;
		uint256 maxClaim = _maxClaimAllowed;

		// Limit to main pool size.  The rest of the pool is used as a reserve to improve consistency
		if (bnbPool > bnbPoolSize) {
			bnbPool = bnbPoolSize;
		}

		// If an address is holding X percent of the supply, then it can claim up to X percent of the reward pool
		uint256 reward = bnbPool * balance / holdersAmount;

		if (reward > maxClaim) {
			reward = maxClaim;
		}

		return reward;
	}

	function onPancakeswapRouterUpdated() internal override { 
		_addressesExcludedFromRewards[address(_pancakeswapV2Router)] = true;
		_addressesExcludedFromRewards[pancakeswapPairAddress()] = true;
	}
	
    function setFirstToken(string memory token) isHuman nonReentrant external {
        setFirstToken(msg.sender, token);
        
        if (_secondRewardToken[msg.sender] == address(0)) {
            _claimDivision[msg.sender] = 100;
        } else {
            _claimDivision[msg.sender] = 50;
        }
	}
		
	function setFirstToken(address user, string memory token) private {
	    require(msg.sender == user, "You are not allowed first token on this user behalf");
	    address selectedToken = _tokensList[token];
    	require(selectedToken != address(0) && selectedToken != BURN_WALLET, "The selected token does not exist.");
    	require(_tokensAllowance[selectedToken], "The selected token is not allowed");
    	
    	_firstRewardToken[user] = selectedToken;
	}
	
	function setSecondToken(string memory token) isHuman nonReentrant external {
        setSecondToken(msg.sender, token);
        
        if (_firstRewardToken[msg.sender] == address(0)) {
            _claimDivision[msg.sender] = 0;
        } else {
            _claimDivision[msg.sender] = 50;
        }
	}
	
	function setSecondToken(address user, string memory token) private {
	    require(msg.sender == user, "You are not allowed to set second token on this user behalf");
	    address selectedToken = _tokensList[token];
    	require(selectedToken != address(0) && selectedToken != BURN_WALLET, "The selected token does not exist.");
    	require(_tokensAllowance[selectedToken], "The selected token is not allowed");
    	
    	_secondRewardToken[msg.sender] = selectedToken;
	}
	
	function getFirstToken(address user) public view returns (address) {
	    return _firstRewardToken[user];
	}
	
	function getSecondToken(address user) public view returns (address) {
	    return _secondRewardToken[user];
	}
	
	function addNewToken(string memory symbol, address tokenAddress) public onlyOwner {
	    require(tokenAddress != address(0) && tokenAddress != BURN_WALLET, "Token address is invalid.");
	    require(_tokensList[symbol] != tokenAddress, "This token is already added.");
	    
	    _tokensList[symbol] = tokenAddress;
	    _tokensAllowance[tokenAddress] = true;
	}
	
	function enableToken(string memory symbol) public onlyOwner {
	   address tokenAddress = _tokensList[symbol];
	   require(tokenAddress != address(0) && tokenAddress != BURN_WALLET, "Token symbol is not added.");
	    
	   _tokensAllowance[tokenAddress] = true;
	}
	
	function disableToken(string memory symbol) public onlyOwner {
	    address tokenAddress = _tokensList[symbol];
	    require(tokenAddress != address(0) && tokenAddress != BURN_WALLET, "Token symbol is not added.");
	    
	    _tokensAllowance[tokenAddress] = false;
	}
	
	function removeToken(string memory symbol) public onlyOwner {
	    address tokenAddress = _tokensList[symbol];
	    require(tokenAddress != address(0) && tokenAddress != BURN_WALLET, "Token symbol is not added.");
	    
	    _tokensList[symbol] = address(0);
	    _tokensAllowance[tokenAddress] = false;
	}
	
	function getTokenAddress(string memory symbol) public view returns (address) {
	    return _tokensList[symbol];
	}
	
	function isTokenAllowed(string memory symbol) public view returns (bool) {
	    return _tokensAllowance[_tokensList[symbol]];
	}

	function isMarketTransfer(address sender, address recipient) internal override view returns(bool) {
		// Not a market transfer when we are burning or sending out rewards
		return super.isMarketTransfer(sender, recipient) && !isBurnTransfer(sender, recipient) && !_processingQueue;
	}


	function isBurnTransfer(address sender, address recipient) private view returns (bool) {
		return isPancakeswapPair(sender) && recipient == BURN_WALLET;
	}


	function shouldBurn() public view returns(bool) {
		return _gradualBurnMagnitude > 0 && address(this).balance >= _minBnbPoolSizeBeforeBurn && block.timestamp - _lastBurnDate > _gradualBurnTimespan;
	}


	// Up to 1% manual buyback & burn
	function buyAndBurn(uint256 bnbAmount) external onlyOwner {
		require(bnbAmount <= address(this).balance / 100, "Manual burn amount is too high!");
		require(bnbAmount > 0, "Amount must be greater than zero");

		doBuyAndBurn(bnbAmount);
	}


	function doBuyAndBurn(uint256 bnbAmount) private {
		if (bnbAmount > address(this).balance) {
			bnbAmount = address(this).balance;
		}

		if (bnbAmount == 0) {
			return;
		}

		if (swapBNBForTokens(BURN_WALLET, address(this), bnbAmount)) {
			emit Burned(bnbAmount);
		}

		_lastBurnDate = block.timestamp;
	}


	function isContract(address account) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
	}


	function totalAmountOfTokensHeld() public view returns (uint256) {
		return totalSupply() - balanceOf(address(0)) - balanceOf(BURN_WALLET) - balanceOf(pancakeswapPairAddress());
	}


    function bnbRewardClaimed(address byAddress) public view returns (uint256) {
		return _bnbRewardClaimed[byAddress];
	}

    function totalBNBClaimed() public view returns (uint256) {
		return _totalBNBClaimed;
	}


    function totalBNBClaimedAsToken(address tokenAddress) public view returns (uint256) {
		return _totalTokenClaimed[tokenAddress];
	}


    function rewardCyclePeriod() public view returns (uint256) {
		return _rewardCyclePeriod;
	}


	function setRewardCyclePeriod(uint256 period) public onlyOwner {
		require(period > 0 && period <= 7 days, "Value out of range");
		_rewardCyclePeriod = period;
	}


	function setRewardCycleExtensionThreshold(uint256 threshold) public onlyOwner {
		_rewardCycleExtensionThreshold = threshold;
	}


	function nextAvailableClaimDate(address ofAddress) public view returns (uint256) {
		return _nextAvailableClaimDate[ofAddress];
	}


	function maxClaimAllowed() public view returns (uint256) {
		return _maxClaimAllowed;
	}


	function setMaxClaimAllowed(uint256 value) public onlyOwner {
		require(value > 0, "Value must be greater than zero");
		_maxClaimAllowed = value;
	}


	function minRewardBalance() public view returns (uint256) {
		return _minRewardBalance;
	}


	function setMinRewardBalance(uint256 balance) public onlyOwner {
		_minRewardBalance = balance;
	}


	function maxGasForAutoClaim() public view returns (uint256) {
		return _maxGasForAutoClaim;
	}


	function setMaxGasForAutoClaim(uint256 gas) public onlyOwner {
		_maxGasForAutoClaim = gas;
	}


	function isAutoClaimEnabled() public view returns (bool) {
		return _autoClaimEnabled;
	}


	function setAutoClaimEnabled(bool isEnabled) public onlyOwner {
		_autoClaimEnabled = isEnabled;
	}


	function isExcludedFromRewards(address addr) public view returns (bool) {
		return _addressesExcludedFromRewards[addr];
	}


	// Will be used to exclude unicrypt fees/token vesting addresses from rewards
	function setExcludedFromRewards(address addr, bool isExcluded) public onlyOwner {
		_addressesExcludedFromRewards[addr] = isExcluded;
		updateAutoClaimQueue(addr);
	}


	function globalRewardDampeningPercentage() public view returns(uint256) {
		return _globalRewardDampeningPercentage;
	}


	function setGlobalRewardDampeningPercentage(uint256 value) public onlyOwner {
		require(value <= 90, "Cannot be greater than 90%");
		_globalRewardDampeningPercentage = value;
	}


	function approveClaim(address byAddress, bool isApproved) public {
		require(byAddress != address(0), "Invalid address");
		_rewardClaimApprovals[msg.sender][byAddress] = isApproved;
	}


	function isClaimApproved(address ofAddress, address byAddress) public view returns(bool) {
		return _rewardClaimApprovals[ofAddress][byAddress];
	}


	function gradualBurnMagnitude() public view returns (uint256) {
		return _gradualBurnMagnitude;
	}


	function setGradualBurnMagnitude(uint256 magnitude) public onlyOwner {
		require(magnitude <= 100, "Must be equal or less to 100");
		_gradualBurnMagnitude = magnitude;
	}


	function gradualBurnTimespan() public view returns (uint256) {
		return _gradualBurnTimespan;
	}


	function setGradualBurnTimespan(uint256 timespan) public onlyOwner {
		require(timespan >= 5 minutes, "Cannot be less than 5 minutes");
		_gradualBurnTimespan = timespan;
	}


	function minBnbPoolSizeBeforeBurn() public view returns(uint256) {
		return _minBnbPoolSizeBeforeBurn;
	}


	function setMinBnbPoolSizeBeforeBurn(uint256 amount) public onlyOwner {
		require(amount > 0, "Amount must be greater than zero");
		_minBnbPoolSizeBeforeBurn = amount;
	}
	
	function getClaimDivision(address ofAddress) public view returns(uint256) {
		return _claimDivision[ofAddress];
	}


	function setClaimDivision(uint8 claimDivision) public {
		require(claimDivision >= 0 && claimDivision <= 100, "Your claim division needs to be between 0 and 100");
		_claimDivision[msg.sender] = claimDivision;
	}


	function mainBnbPoolSize() public view returns (uint256) {
		return _mainBnbPoolSize;
	}


	function setMainBnbPoolSize(uint256 size) public onlyOwner {
		require(size >= 10 ether, "Size is too small");
		_mainBnbPoolSize = size;
	}


	function isInRewardClaimQueue(address addr) public view returns(bool) {
		return _addressesInRewardClaimQueue[addr];
	}

	
	function reimburseAfterTokenClaimFailure() public view returns(bool) {
		return _reimburseAfterTokenClaimFailure;
	}


	function setReimburseAfterTokenClaimFailure(bool value) public onlyOwner {
		_reimburseAfterTokenClaimFailure = value;
	}


	function lastBurnDate() public view returns(uint256) {
		return _lastBurnDate;
	}


	function rewardClaimQueueLength() public view returns(uint256) {
		return _rewardClaimQueue.length;
	}


	function rewardClaimQueueIndex() public view returns(uint256) {
		return _rewardClaimQueueIndex;
	}


	function isWhitelistedExternalProcessor(address addr) public view returns(bool) {
		return _whitelistedExternalProcessors[addr];
	}


	function setWhitelistedExternalProcessor(address addr, bool isWhitelisted) public onlyOwner {
		 require(addr != address(0), "Invalid address");
		_whitelistedExternalProcessors[addr] = isWhitelisted;
	}

	function setSendWeiGasLimit(uint256 amount) public onlyOwner {
		_sendWeiGasLimit = amount;
	}

	function setExcludeNonHumansFromRewards(bool exclude) public onlyOwner {
		_excludeNonHumansFromRewards = exclude;
	}
}