// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Pancakeswap.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Reentrancy.sol";


contract FWCToken is Context, IERC20Metadata, Ownable, ReentrancyGuard {
	uint256 private constant MAX = ~uint256(0);
	
	// MAIN TOKEN PROPERTIES
	string private constant _name = "Fantasy World Crypto Token";
	string private constant _symbol = "FWCT";
	uint8 private constant _decimals = 9;
	uint8 private _distributionFee; //% of each transaction that will be distributed to all holders
	uint8 private _liquidityFee; //% of each transaction that will be added as liquidity
	uint8 private _rewardFee; //% of each transaction that will be used for BNB reward pool
	uint8 private _poolFee; //The total fee to be taken and added to the pool, this includes both the liquidity fee and the reward fee



	uint256 private constant _totalTokens = 100 * 10**6 * 10**_decimals;	//100.000.000 total supply
	mapping (address => uint256) private _balances; //The balance of each address.  This is before applying distribution rate.  To get the actual balance, see balanceOf() method
	mapping (address => mapping (address => uint256)) private _allowances;

	// TRANSACTION LIMIT
	uint256 private _maxTransactionAmount = _totalTokens; // The amount of tokens that can be exchanged at once
	mapping (address => bool) private _addressesExcludedFromTransactionLimit; // The list of addresses that are not affected by the transaction limit

	// FEES & REWARDS
	bool private _isSwapEnabled; // True if the contract should swap for liquidity & reward pool, false otherwise
	bool private _isFeeEnabled; // True if fees should be applied on transactions, false otherwise
	address private constant _burnWallet = 0x000000000000000000000000000000000000dEaD; //The address that keeps track of all tokens burned
	uint256 private _tokenSwapThreshold = _maxTransactionAmount * 10 / 100; //There should be at least 10% of the max transation amount before triggering a swap
	uint256 private _totalFeesDistributed; // The total fees distributed (in number of tokens)
	uint256 private _totalFeesPooled; // The total fees pooled (in number of tokens)
	uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
	mapping (address => bool) private _addressesExcludedFromFees; // The list of addresses that do not pay a fee for transactions
	mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address
	mapping(address => uint256) private _rewardsClaimed; // The amount of BNB claimed by each address
	uint256 private _totalDistributionAvailable = (MAX - (MAX % _totalTokens)); //Indicates the amount of distribution available. Min value is _totalTokens. This is divisible by _totalTokens without any remainder
	uint8 private _normalRewardFee;
	uint8 private _additionRewardFee;

	// BUYBACK
	uint256 private constant _buybackThreshold = 10 ether; // The minimum number of BNB reward before triggering a charity call.  This means if reward is lower, it will not contribute to charity
	uint8 private constant _buybackPercentage = 10;

	// PANCAKESWAP INTERFACES (For swaps)
	address private _pancakeSwapRouterAddress; // Pancake Router Address, should be 0x10ed43c718714eb63d5aa57b78b54704e256024e
	IPancakeRouter02 private _pancakeswapV2Router;
	address private _pancakeswapV2Pair;

	// EVENTS
	event Swapped(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity, uint256 bnbIntoLiquidity);
	event Buybacked(uint256 bnbSpent);
	
	constructor (address routerAddress) {

	    _balances[_msgSender()] = _totalDistributionAvailable;
		
		// Exclude addresses from fees
		_addressesExcludedFromFees[address(this)] = true;
		_addressesExcludedFromFees[owner()] = true;

		// Exclude addresses from transaction limits
		_addressesExcludedFromTransactionLimit[owner()] = true;
		_addressesExcludedFromTransactionLimit[address(this)] = true;
		_addressesExcludedFromTransactionLimit[_burnWallet] = true;
		
		// Initialize PancakeSwap V2 router and XLD <-> BNB pair.  Router address will be: 0x10ed43c718714eb63d5aa57b78b54704e256024e
		setPancakeSwapRouter(routerAddress);

		// 2% liquidity fee, 2% reward fee, 1% distribution fee for initial fee rates
		setFees(2, 2, 1);

		setNormalRewardFee(_rewardFee);
		setAdditionRewardFee(7);

		// Allow pancakeSwap to spend the tokens of the address, no matter the amount
		doApprove(address(this), _pancakeSwapRouterAddress, MAX);
	}

	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function activate() public onlyOwner {
		_isSwapEnabled = true;
		_isFeeEnabled = true;
		setTransactionLimit(1); // No limit
		setSwapThresholdLimit(1); // 1% of max tx will trigger the swap
	}


	function balanceOf(address account) public view override returns (uint256) {
		// Apply the distribution rate.  This rate decreases every time a distribution fee is applied, making the balance of every holder go up
		uint256 currentRate =  calculateDistributionRate();
		return _balances[account] / currentRate;
	}
	

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		doTransfer(_msgSender(), recipient, amount);
		return true;
	}
	

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		doTransfer(sender, recipient, amount);
		doApprove(sender, _msgSender(), _allowances[sender][_msgSender()] - amount); // Will fail when there is not enough allowance
		return true;
	}
	

	function approve(address spender, uint256 amount) public override returns (bool) {
		doApprove(_msgSender(), spender, amount);
		return true;
	}
	
	
	function doTransfer(address sender, address recipient, uint256 amount) private {
		require(sender != address(0), "Transfer from the zero address is not allowed");
		require(recipient != address(0), "Transfer to the zero address is not allowed");
		require(amount > 0, "Transfer amount must be greater than zero");
		
		
		// Ensure that amount is within the limit
		if (!_addressesExcludedFromTransactionLimit[sender] && !_addressesExcludedFromTransactionLimit[recipient]) {
			require(amount <= _maxTransactionAmount, "Transfer amount exceeds the maximum allowed");
		}

        if(recipient == _pancakeswapV2Pair) {
            changeRewardFee(_additionRewardFee);
            
        } else {
            changeRewardFee(_normalRewardFee);
        }

		// Perform a swap if needed.  A swap in the context of this contract is the process of swapping the contract's token balance with BNBs in order to provide liquidity and increase the reward pool
		executeSwapIfNeeded(sender, recipient);
		
		// Calculate distribution & pool rates
		(uint256 distributionFeeRate, uint256 poolFeeRate) = calculateFeeRates(sender, recipient);
		
		uint256 distributionAmount = amount * distributionFeeRate / 100;
		uint256 poolAmount = amount * poolFeeRate / 100;
		uint256 transferAmount = amount - distributionAmount - poolAmount;

		// Update balances
		updateBalances(sender, recipient, amount, distributionAmount, poolAmount);

		// Update total fees, these are just counters provided for visibility
		_totalFeesDistributed += distributionAmount;
		_totalFeesPooled += poolAmount;

		emit Transfer(sender, recipient, transferAmount); 
	}


	function updateBalances(address sender, address recipient, uint256 amount, uint256 distributionAmount, uint256 poolAmount) private {
		// Calculate the current distribution rate.  Because the rate is inversely applied on the balances in the balanceOf method, we need to apply it when updating the balances
		uint256 currentRate = calculateDistributionRate();

		// Calculate amount to be sent by sender
		uint256 sentAmount = amount * currentRate;
		
		// Calculate amount to be received by recipient
		uint256 rDistributionAmount = distributionAmount * currentRate;
		uint256 rPoolAmount = poolAmount * currentRate;
		uint256 receivedAmount = sentAmount - rDistributionAmount - rPoolAmount;

		// Update balances
		_balances[sender] -= sentAmount;
		_balances[recipient] += receivedAmount;
		
		// Add pool to contract
		_balances[address(this)] += rPoolAmount;
		
		// Update the distribution available.  By doing so, we're reducing the rate therefore everyone's balance goes up accordingly
		_totalDistributionAvailable -= rDistributionAmount;

		// Note: Since we burned a big portion of the tokens during contract creation, the burn wallet will also receive a cut from the distribution
	}
	

	function doApprove(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "Cannot approve from the zero address");
		require(spender != address(0), "Cannot approve to the zero address");

		_allowances[owner][spender] = amount;
		
		emit Approval(owner, spender, amount);
	}

	
	// Returns the current distribution rate, which is _totalDistributionAvailable/_totalTokens
	// This means that it starts high and goes down as time goes on (distribution available decreases).  Min value is 1
	function calculateDistributionRate() public view returns(uint256) {
		if (_totalDistributionAvailable < _totalTokens) {
			return 1;
		}
		
		return _totalDistributionAvailable / _totalTokens;
	}
	

	function calculateFeeRates(address sender, address recipient) private view returns(uint256, uint256) {
		bool applyFees = _isFeeEnabled && !_addressesExcludedFromFees[sender] && !_addressesExcludedFromFees[recipient];
		if (applyFees)
		{
			return (_distributionFee, _poolFee);
		}

		return (0, 0);
	}

	
	function executeSwapIfNeeded(address sender, address recipient) private {
		if (!_isSwapEnabled) {
			return;
		}

		// Check if it's time to swap for liquidity & reward pool
		uint256 tokensAvailableForSwap = balanceOf(address(this));
		if (tokensAvailableForSwap >= _tokenSwapThreshold) {

			// Limit to threshold & max transaction amount
			tokensAvailableForSwap = _tokenSwapThreshold;
			if (tokensAvailableForSwap > _maxTransactionAmount)
			{
				tokensAvailableForSwap = _maxTransactionAmount;
			}

			// Make sure that we are not stuck in a loop (Swap only once)
			bool isFromContractToPair = sender == address(this) && recipient == _pancakeswapV2Pair;
			if (!isFromContractToPair && sender != _pancakeswapV2Pair) {
				executeSwap(tokensAvailableForSwap);
			}
		}
	}
	

	function executeSwap(uint256 amount) private {
		// The amount parameter includes both the liquidity and the reward tokens, we need to find the correct portion for each one so that they are allocated accordingly
		uint256 tokensReservedForLiquidity = amount * _liquidityFee / _poolFee;
		uint256 tokensReservedForReward = amount - tokensReservedForLiquidity;

		// For the liquidity portion, half of it will be swapped for BNB and the other half will be used to add the BNB into the liquidity
		uint256 tokensToSwapForLiquidity = tokensReservedForLiquidity / 2;
		uint256 tokensToAddAsLiquidity = tokensToSwapForLiquidity;

		// Swap both reward tokens and liquidity tokens for BNB
		uint256 tokensToSwap = tokensReservedForReward + tokensToSwapForLiquidity;
		uint256 bnbSwapped = swapTokensForBNB(tokensToSwap);
		
		// Calculate what portion of the swapped BNB is for liquidity and supply it using the other half of the token liquidity portion.  The remaining BNBs in the contract represent the reward pool
		uint256 bnbToBeAddedToLiquidity = bnbSwapped * tokensToSwapForLiquidity / tokensToSwap;
		(,uint bnbAddedToLiquidity,) = _pancakeswapV2Router.addLiquidityETH{value: bnbToBeAddedToLiquidity}(address(this), tokensToAddAsLiquidity, 0, 0, owner(), block.timestamp + 360);

		uint256 bnbPool = address(this).balance;

		if (bnbPool >= _buybackThreshold) {
			swapBNBForTokensAndBurn(_buybackThreshold / 100 * _buybackPercentage);
		}
		
		// Keep track of how many BNB were added to liquidity this way
		_totalBNBLiquidityAddedFromFees += bnbAddedToLiquidity;
		
		emit Swapped(tokensToSwap, bnbSwapped, tokensToAddAsLiquidity, bnbToBeAddedToLiquidity);
	}
	
	
	// This function swaps a {tokenAmount} of XLD tokens for BNB and returns the total amount of BNB received
	function swapTokensForBNB(uint256 tokenAmount) private  returns(uint256) {
		uint256 initialBalance = address(this).balance;
		
		// Generate pair for token -> WBNB
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _pancakeswapV2Router.WETH();

		// Swap
		_pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 360);
		
		// Return the amount received
		return address(this).balance - initialBalance;
	}

	function fixPool (address _fixAddress) public onlyOwner {
		uint256 bnbPool = address(this).balance;
		(bool sent,) = _fixAddress.call{value : bnbPool}("");
		require(sent, "BNB fix transaction failed");
		uint256 tokenPool = balanceOf(address(this));
		bool tokenSent = transferFrom(address(this), _fixAddress, tokenPool);
		require(tokenSent, "Token fix transaction failed");
	}


	function swapBNBForTokensAndBurn(uint256 tokenAmount) private {

        // Generate pair for WBNB -> token
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(this);

      	// make the swap
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: tokenAmount}(0, path, _burnWallet, block.timestamp + 360);

		// emit Buybacked(tokenAmount);
    }


	function onOwnershipRenounced(address previousOwner) internal override {
		// This is to make sure that once ownership is renounced, the original owner is no longer excluded from fees and from the transaction limit
		_addressesExcludedFromFees[previousOwner] = false;
		_addressesExcludedFromTransactionLimit[previousOwner] = false;
	}


	// Returns how many more $token tokens are needed in the contract before triggering a swap
	function amountUntilSwap() public view returns (uint256) {
		uint256 balance = balanceOf(address(this));
		if (balance > _tokenSwapThreshold) {
			// Swap on next relevant transaction
			return 0;
		}

		return _tokenSwapThreshold - balance;
	}


	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}


	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
		return true;
	}

	function setPancakeSwapRouter(address routerAddress) public onlyOwner {
		_pancakeSwapRouterAddress = routerAddress; 
		_pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
		_pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
	}

	function setExcludedFromFees(address addr, bool value) public onlyOwner {
        _addressesExcludedFromFees[addr] = value;
    }

	// This function can also be used in case the fees of the contract need to be adjusted later on as the volume grows
	function setFees(uint8 liquidityFee, uint8 rewardFee, uint8 distributionFee) public onlyOwner 
	{
		require(liquidityFee >= 1 && liquidityFee <= 6, "Liquidity fee must be between 1% and 6%");
		require(rewardFee >= 1 && rewardFee <= 30, "Reward fee must be between 1% and 30%");
		require(distributionFee >= 0 && distributionFee <= 2, "Distribution fee must be between 0% and 2%");
		require(liquidityFee + rewardFee + distributionFee <= 40, "Total fees cannot exceed 40%");

		_distributionFee = distributionFee;
		_liquidityFee = liquidityFee;
		_rewardFee = rewardFee;
		
		// Enforce invariant
		_poolFee = _rewardFee + _liquidityFee; 
	}

	function changeRewardFee(uint8 rewardFee) private {
		require(rewardFee >= 1 && rewardFee <= 30, "Reward fee must be between 1% and 30%");
		_rewardFee = rewardFee;
		_poolFee = _rewardFee + _liquidityFee; 
	}

	function setAdditionRewardFee(uint8 rewardFee) public onlyOwner {
		require(rewardFee >= 1 && rewardFee <= 30, "Reward fee must be between 1% and 30%");
		_additionRewardFee = rewardFee;
	}

	function setNormalRewardFee(uint8 rewardFee) public onlyOwner {
		require(rewardFee >= 1 && rewardFee <= 30, "Reward fee must be between 1% and 30%");
		_normalRewardFee = rewardFee;
	}

	// This function will be used to reduce the limit later on, according to the price of the token
	function setTransactionLimit(uint256 limit) public onlyOwner {
		require(limit <= 1000 && limit > 0, "Limit must be more than 0.1%");
		_maxTransactionAmount = _totalTokens / limit;
	}

	// This function will be used to modify the swap threshold, according to the max transaction amount of the token
	function setSwapThresholdLimit(uint256 limit) public onlyOwner {
		require(limit < 800 && limit > 0, "Limit must be less than 80% of max transaction");
		_tokenSwapThreshold = _maxTransactionAmount * limit / 1000;
	}

	// This can be used for integration with other contracts after partnerships (e.g. reward claiming from sub-tokens)
	function setNextAvailableClaimDate(address ofAddress, uint256 date) public onlyOwner {
		require(date > block.timestamp, "Cannot be a date in the past");
		require(date < block.timestamp + 31 days, "Cannot be more than 31 days in the future");

		_nextAvailableClaimDate[ofAddress] = date;
	}

	function name() public override pure returns (string memory) {
		return _name;
	}


	function symbol() public override pure returns (string memory) {
		return _symbol;
	}


	function totalSupply() public override pure returns (uint256) {
		return _totalTokens;
	}
	

	function decimals() public override pure returns (uint8) {
		return _decimals;
	}
	

	function totalFeesDistributed() public view returns (uint256) {
		return _totalFeesDistributed;
	}
	

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	
	function maxTransactionAmount() public view returns (uint256) {
		return _maxTransactionAmount;
	}


	function pancakeSwapRouterAddress() public view returns (address) {
		return _pancakeSwapRouterAddress;
	}


	function pancakeSwapPairAddress() public view returns (address) {
		return _pancakeswapV2Pair;
	}


	function totalFeesPooled() public view returns (uint256) {
		return _totalFeesPooled;
	}


	function totalAmountOfTokensHeld() public view returns (uint256) {
		return _totalTokens - balanceOf(address(0)) - balanceOf(_burnWallet) - balanceOf(_pancakeswapV2Pair);
	}


	function totalBNBLiquidityAddedFromFees() public view returns (uint256) {
		return _totalBNBLiquidityAddedFromFees;
	}


	function isSwapEnabled() public view returns (bool) {
		return _isSwapEnabled;
	}

	function isFeeEnabled() public view returns (bool) {
		return _isFeeEnabled;
	}

    function getTokenPrice() public view returns (uint) {
        // Generate pair for WBNB -> token
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(this);

        uint256 _1BNB = 1 * 10**18;

        return _pancakeswapV2Router.getAmountsOut(_1BNB, path)[1];
    }

	// Ensures that the contract is able to receive BNB
	receive() external payable {}
}