//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IPancakeFactory.sol";
import "./IPancakeRouter02.sol";
import "./IPinkAntiBot.sol";

abstract contract RuffyCoinBase is IERC20Metadata, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    string private constant NAME = "Meta Baby Ruffy";
    string private constant SYMBOL = "MBR";
    uint8 private constant DECIMALS = 18;

    uint8 private _marketingBuyFee; //% of each transaction that will be used for marketing
    uint8 private _developerBuyFee; //% of each transaction that will be used for developer
    uint8 private _rewardBuyFee; //% of each transaction that will be used for BNB reward pool
    uint8 private _buybackBuyFee; //% of each transaction that will be used for buy back and burn
    uint8 private _liquidityBuyFee; //% of each transaction that will be added as liquidity
    uint8 private _totalBuyFee;

    uint8 private _marketingSellFee; //% of each transaction that will be used for marketing
    uint8 private _developerSellFee; //% of each transaction that will be used for developer
    uint8 private _rewardSellFee; //% of each transaction that will be used for BNB reward pool
    uint8 private _buybackSellFee; //% of each transaction that will be used for buy back and burn
    uint8 private _liquiditySellFee; //% of each transaction that will be added as liquidity
    uint8 private _totalSellFee;

	uint256 private constant _totalTokens = 100000000000 * 10 ** DECIMALS;	//100 billion total supply

    bool private _isSwapEnabled; // True if the contract should swap for liquidity & reward pool, false otherwise
	bool private _isFeeEnabled; // True if fees should be applied on transactions, false otherwise
    bool private _isBuyingAllowed; // This is used to make sure that the contract is activated before anyone makes a purchase on PCS.  The contract will be activated once liquidity is added.

    uint256 private _tokenSwapThreshold = _totalTokens / 10000; //There should be at least 0.0001% of the total supply in the contract before triggering a swap
	uint256 private _totalFeesPooled; // The total fees pooled (in number of tokens)
	uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
    uint256 private _transactionLimit = _totalTokens; // The amount of tokens that can be sold at once

	mapping (address => uint256) private _balances; //The balance of each address.  This is before applying distribution rate.  To get the actual balance, see balanceOf() method
	mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _addressesExcludedFromFees;
    // PANCAKESWAP INTERFACES (For swaps)
	address private _pancakeswapRouterAddress;
	IPancakeRouter02 private _pancakeswapV2Router;
	address private _pancakeswapV2Pair;
	address private _autoLiquidityWallet;
	
	IPinkAntiBot public pinkAntiBot;
	bool public antiBotEnabled;

    //ADDRESSES
    address public constant BURN_WALLET = 0x000000000000000000000000000000000000dEaD;
    address private _marketingWallet = 0x383C800fAD2FcBD18a31dE878826F03b3f92a31c;
	address private _developerWallet = 0x0Dc5D532ACE71741f87F897c3Ccf11E1755ac6fF;

    // EVENTS
	event Swapped(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity, uint256 bnbIntoLiquidity);
	event AutoBurned(uint256 bnbAmount);

    constructor (address routerAddress, address pinkAntiBot_) {
		_balances[_msgSender()] = totalSupply();
		
		// Exclude contract from fees
		_addressesExcludedFromFees[address(this)] = true;

		// Initialize PancakeSwap V2 router and RUFFY <-> BNB pair.  Router address will be: 0x10ed43c718714eb63d5aa57b78b54704e256024e or for testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
		setPancakeSwapRouter(routerAddress);

		// 3% liquidity fee, 3% reward fee, 1% buyback fee, 3% marketing fee, 3% developer fee, 0% additional sell fee
		setBuyFees(0, 10, 0, 0, 0);
		setSellFees(0, 10, 0, 0, 0);

		emit Transfer(address(0), _msgSender(), totalSupply());
		
		// Create an instance of the PinkAntiBot variable from the provided address. PinkAntiBot will be: 0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002 or for testnet: 0xbb06F5C7689eA93d9DeACCf4aF8546C4Fe0Bf1E5
        pinkAntiBot = IPinkAntiBot(pinkAntiBot_);
        // Register the deployer to be the token owner with PinkAntiBot. You can
        // later change the token owner in the PinkAntiBot contract
        pinkAntiBot.setTokenOwner(msg.sender);
        antiBotEnabled = true;
	}





	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function activate() public onlyOwner {
		setSwapEnabled(true);
		setFeeEnabled(true);
		setAutoLiquidityWallet(owner());
		setTransactionLimit(1000); // only 0.1% of the total supply can be sold at once
		setActivateBuying();
		onActivated();
	}

    function onActivated() internal virtual { }

    function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
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
	
	
	function doTransfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "Transfer from the zero address is not allowed");
		require(recipient != address(0), "Transfer to the zero address is not allowed");
		if(antiBotEnabled) {
		    pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
		}
		require(amount > 0, "Transfer amount must be greater than zero");
		require(!isPancakeSwapPair(sender) || _isBuyingAllowed, "Buying is not allowed before contract activation");
		
		// Ensure that amount is within the limit in case we are selling
		if (isTransferLimited(sender, recipient)) {
			require(amount <= _transactionLimit, "Transfer amount exceeds the maximum allowed");
		}

		// Perform a swap if needed.  A swap in the context of this contract is the process of swapping the contract's token balance with BNBs in order to provide liquidity and increase the reward pool
		executeSwapIfNeeded(sender, recipient);

		onBeforeTransfer(sender, recipient, amount);

		// Calculate fee rate
		uint256 feeRate = calculateFeeRate(sender, recipient);
		
		uint256 feeAmount = amount * feeRate / 100;
		uint256 transferAmount = amount - feeAmount;

		// Update balances
		updateBalances(sender, recipient, amount, feeAmount);

		// Update total fees, this is just a counter provided for visibility
		_totalFeesPooled += feeAmount;

		emit Transfer(sender, recipient, transferAmount); 

		onTransfer(sender, recipient, amount);
	}

	function onBeforeTransfer(address sender, address recipient, uint256 amount) internal virtual { }

	function onTransfer(address sender, address recipient, uint256 amount) internal virtual { }


	function updateBalances(address sender, address recipient, uint256 sentAmount, uint256 feeAmount) private {
		// Calculate amount to be received by recipient
		uint256 receivedAmount = sentAmount - feeAmount;

		// Update balances
		_balances[sender] -= sentAmount;
		_balances[recipient] += receivedAmount;
		
		// Add fees to contract
		_balances[address(this)] += feeAmount;
	}


	function doApprove(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "Cannot approve from the zero address");
		require(spender != address(0), "Cannot approve to the zero address");

		_allowances[owner][spender] = amount;
		
		emit Approval(owner, spender, amount);
	}


	function calculateFeeRate(address sender, address recipient) private view returns(uint256) {
		bool applyFees = _isFeeEnabled && !_addressesExcludedFromFees[sender] && !_addressesExcludedFromFees[recipient];
		if (applyFees) {
            // if sell transaction, return sell fee
			if (isPancakeSwapPair(recipient)) {
				return _totalSellFee;
			}

			return _totalBuyFee;
		}

		return 0;
	}

	
	function executeSwapIfNeeded(address sender, address recipient) private {
		if (!isMarketTransfer(sender, recipient)) {
			return;
		}

		// Check if it's time to swap for liquidity & reward pool
		uint256 tokensAvailableForSwap = balanceOf(address(this));
		if (tokensAvailableForSwap >= _tokenSwapThreshold) {

			// Limit to threshold
			tokensAvailableForSwap = _tokenSwapThreshold;

			// Make sure that we are not stuck in a loop (Swap only once)
			bool isSelling = isPancakeSwapPair(recipient);
		
			executeSwap(tokensAvailableForSwap, isSelling);
		
		}
	}


	function executeSwap(uint256 amount, bool isSell) private {
		// Allow pancakeSwap to spend the tokens of the address
		doApprove(address(this), _pancakeswapRouterAddress, amount);

		uint256 tokensReservedForLiquidity;
		uint256 tokensReservedForBuyback;
		uint256 tokensReservedForMarketing;
		uint256 tokensReservedForDeveloper;

        if (isSell) {
            tokensReservedForLiquidity = amount * _liquiditySellFee / _totalSellFee;
		    tokensReservedForBuyback = amount * _buybackSellFee / _totalSellFee;
		    tokensReservedForMarketing = amount * _marketingSellFee / _totalSellFee;
		    tokensReservedForDeveloper = amount * _developerSellFee / _totalSellFee;
        } 
        else {
            tokensReservedForLiquidity = amount * _liquidityBuyFee / _totalBuyFee;
		    tokensReservedForBuyback = amount * _buybackBuyFee / _totalBuyFee;
		    tokensReservedForMarketing = amount * _marketingBuyFee / _totalBuyFee;
		    tokensReservedForDeveloper = amount * _developerBuyFee / _totalBuyFee;
        }
		uint256 tokensReservedForReward = amount - tokensReservedForLiquidity - tokensReservedForBuyback - tokensReservedForMarketing - tokensReservedForDeveloper;

		// For the liquidity portion, half of it will be swapped for BNB and the other half will be used to add the BNB into the liquidity
		uint256 tokensToSwapForLiquidity = tokensReservedForLiquidity / 2;
		uint256 tokensToAddAsLiquidity = tokensToSwapForLiquidity;

		uint256 tokensToSwap = tokensReservedForReward + tokensToSwapForLiquidity + tokensReservedForBuyback + tokensReservedForMarketing + tokensReservedForDeveloper;
		uint256 bnbSwapped = swapTokensForBNB(tokensToSwap);
		
		// Calculate what portion of the swapped BNB is for liquidity and supply it using the other half of the token liquidity portion.  The remaining BNBs in the contract represent the reward pool
		uint256 bnbToBeAddedToLiquidity = bnbSwapped * tokensToSwapForLiquidity / tokensToSwap;
		(,uint bnbAddedToLiquidity,) = _pancakeswapV2Router.addLiquidityETH{value: bnbToBeAddedToLiquidity}(address(this), tokensToAddAsLiquidity, 0, 0, _autoLiquidityWallet, block.timestamp + 360);

		// Keep track of how many BNB were added to liquidity this way
		_totalBNBLiquidityAddedFromFees += bnbAddedToLiquidity;
		
		//send bnb to marketing wallet
		uint256 bnbToBeSendToMarketing = bnbSwapped * tokensReservedForMarketing / tokensToSwap;
		(bool sent, ) = _marketingWallet.call{value: bnbToBeSendToMarketing}("");
		require(sent, "Failed to send BNB to marketing wallet");
		
		//send bnb to developer wallet
		uint256 bnbToBeSendToDeveloper = bnbSwapped * tokensReservedForDeveloper / tokensToSwap;
		(sent, ) = _developerWallet.call{value: bnbToBeSendToDeveloper}("");
		require(sent, "Failed to send BNB to Developer Wallet");
		
		//buyback and burn
		uint256 bnbToBeBuybackAndBurn = bnbSwapped * tokensReservedForBuyback / tokensToSwap;
		
		if (swapBNBForTokens(bnbToBeBuybackAndBurn, BURN_WALLET)) {
			emit AutoBurned(bnbToBeBuybackAndBurn);
		}
		
		emit Swapped(tokensToSwap, bnbSwapped, tokensToAddAsLiquidity, bnbToBeAddedToLiquidity);
	}


	// This function swaps a {tokenAmount} of RUFFY tokens for BNB and returns the total amount of BNB received
	function swapTokensForBNB(uint256 tokenAmount) internal returns(uint256) {
		uint256 initialBalance = address(this).balance;
		
		// Generate pair for RUFFY -> WBNB
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _pancakeswapV2Router.WETH();

		// Swap
		_pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 360);
		
		// Return the amount received
		return address(this).balance - initialBalance;
	}


	function swapBNBForTokens(uint256 bnbAmount, address to) internal returns(bool) { 
		// Generate pair for WBNB -> RUFFY
		address[] memory path = new address[](2);
		path[0] = _pancakeswapV2Router.WETH();
		path[1] = address(this);


		// Swap and send the tokens to the 'to' address
		try _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(0, path, to, block.timestamp + 360) { 
			return true;
		} 
		catch { 
			return false;
		}
	}

	function swapBNBForCustomeTokens(address rewardToken, uint256 bnbAmount, address to) internal returns(bool) {
		// Generate pair for WBNB -> SSHLD
		address[] memory path = new address[](2);
		path[0] = _pancakeswapV2Router.WETH();
		path[1] = rewardToken;


		// Swap and send the tokens to the 'to' address
		try _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(0, path, to, block.timestamp + 360) { 
			return true;
		} 
		catch { 
			return false;
		}
	}
	
	// Returns true if the transfer between the two given addresses should be limited by the transaction limit and false otherwise
	function isTransferLimited(address sender, address recipient) private view returns(bool) {
		bool isSelling = isPancakeSwapPair(recipient);
		return isSelling && isMarketTransfer(sender, recipient);
	}


	function isSwapTransfer(address sender, address recipient) private view returns(bool) {
		bool isContractSelling = sender == address(this) && isPancakeSwapPair(recipient);
		return isContractSelling;
	}


	// Function that is used to determine whether a transfer occurred due to a user buying/selling/transfering and not due to the contract swapping tokens
	function isMarketTransfer(address sender, address recipient) internal virtual view returns(bool) {
		return !isSwapTransfer(sender, recipient);
	}


	// Returns how many more $RUFFY tokens are needed in the contract before triggering a swap
	function amountUntilSwap() public view returns (uint256) {
		uint256 balance = balanceOf(address(this));
		if (balance > _tokenSwapThreshold) {
			// Swap on next relevant transaction
			return 0;
		}

		return _tokenSwapThreshold - balance;
	}


	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}


	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
		return true;
	}


    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
		require(routerAddress != address(0), "Cannot use the zero address as router address");

		_pancakeswapRouterAddress = routerAddress; 
		_pancakeswapV2Router = IPancakeRouter02(_pancakeswapRouterAddress);
		_pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());

		onPancakeSwapRouterUpdated();
	}


	function onPancakeSwapRouterUpdated() internal virtual { }

	function isPancakeSwapPair(address addr) internal view returns(bool) {
		return _pancakeswapV2Pair == addr;
	}

    // This function can also be used in case the fees of the contract need to be adjusted later on as the volume grows
	function setBuyFees(uint8 developerFee, uint8 marketingFee, uint8 rewardFee, uint8 buybackFee, uint8 liquidityFee) public onlyOwner {
        require(developerFee >= 0 && developerFee <= 10, "Developer fee must be between 0% and 10%");
        require(marketingFee >= 0 && marketingFee <= 10, "Marketing fee must be between 0% and 10%");
		require(rewardFee >= 0 && rewardFee <= 10, "Reward fee must be between 0% and 10%");
        require(buybackFee >= 0 && buybackFee <= 10, "Buyback fee must be between 0% and 10%");
        require(liquidityFee >= 0 && liquidityFee <= 10, "Liquidity fee must be between 0% and 10%");
		require(developerFee + marketingFee + rewardFee + buybackFee + liquidityFee <= 30, "Total fees cannot exceed 30%");
		
		_liquidityBuyFee = liquidityFee;
		_rewardBuyFee = rewardFee;
        _buybackBuyFee = buybackFee;
        _marketingBuyFee = marketingFee;
        _developerBuyFee = developerFee;
		
		// Enforce invariant
		_totalBuyFee = _rewardBuyFee + _liquidityBuyFee + _buybackBuyFee + _marketingBuyFee + _developerBuyFee;
	}

    // This function can also be used in case the fees of the contract need to be adjusted later on as the volume grows
	function setSellFees(uint8 developerFee, uint8 marketingFee, uint8 rewardFee, uint8 buybackFee, uint8 liquidityFee) public onlyOwner {
        require(developerFee >= 0 && developerFee <= 10, "Developer fee must be between 0% and 10%");
        require(marketingFee >= 0 && marketingFee <= 10, "Marketing fee must be between 0% and 10%");
		require(rewardFee >= 0 && rewardFee <= 10, "Reward fee must be between 0% and 10%");
        require(buybackFee >= 0 && buybackFee <= 10, "Buyback fee must be between 0% and 10%");
        require(liquidityFee >= 0 && liquidityFee <= 10, "Liquidity fee must be between 0% and 10%");
		require(developerFee + marketingFee + rewardFee + buybackFee + liquidityFee <= 30, "Total fees cannot exceed 30%");
		
		_liquiditySellFee = liquidityFee;
		_rewardSellFee = rewardFee;
        _buybackSellFee = buybackFee;
        _marketingSellFee = marketingFee;
        _developerSellFee = developerFee;
		
		// Enforce invariant
		_totalSellFee = _rewardSellFee + _liquiditySellFee + _buybackSellFee + _marketingSellFee + _developerSellFee;
	}


    //---------Setter Functions-----------

    // Use this function to control whether to use PinkAntiBot or not instead
    // of managing this in the PinkAntiBot contract
    function setEnableAntiBot(bool _enable) external onlyOwner {
        antiBotEnabled = _enable;
    }

    // This function will be used to reduce the limit later on, according to the price of the token, 100 = 1%, 1000 = 0.1% ...
	function setTransactionLimit(uint256 limit) public onlyOwner {
		require(limit >= 1 && limit <= 10000, "Limit must be greater than 0.01%");
		_transactionLimit = _totalTokens / limit;
	}

	function setTokenSwapThreshold(uint256 threshold) public onlyOwner {
		require(threshold > 0, "Threshold must be greater than 0");
		_tokenSwapThreshold = threshold;
	}
    
	function setAutoLiquidityWallet(address liquidityWallet) public onlyOwner {
		_autoLiquidityWallet = liquidityWallet;
	}
    
	function setMarketingWallet(address marketWallet) public onlyOwner {
		_marketingWallet = marketWallet;
	}

	function setDeveloperWallet(address devWallet) public onlyOwner {
		_developerWallet = devWallet;
	}

	function setSwapEnabled(bool isEnabled) public onlyOwner {
		_isSwapEnabled = isEnabled;
	}

	function setFeeEnabled(bool isEnabled) public onlyOwner {
		_isFeeEnabled = isEnabled;
	}

	function setExcludedFromFees(address addr, bool value) public onlyOwner {
		_addressesExcludedFromFees[addr] = value;
	}

	function setActivateBuying() public onlyOwner {
		_isBuyingAllowed = true;
	}




    //---------------Getter Functions---------------

	function transactionLimit() public view returns (uint256) {
		return _transactionLimit;
	}

	function tokenSwapThreshold() public view returns (uint256) {
		return _tokenSwapThreshold;
	}

	function name() public override pure returns (string memory) {
		return NAME;
	}

	function symbol() public override pure returns (string memory) {
		return SYMBOL;
	}

	function totalSupply() public override pure returns (uint256) {
		return _totalTokens;
	}
	

	function decimals() public override pure returns (uint8) {
		return DECIMALS;
	}
	

	function allowance(address user, address spender) public view override returns (uint256) {
		return _allowances[user][spender];
	}


	function pancakeSwapRouterAddress() public view returns (address) {
		return _pancakeswapRouterAddress;
	}


	function pancakeSwapPairAddress() public view returns (address) {
		return _pancakeswapV2Pair;
	}


	function autoLiquidityWallet() public view returns (address) {
		return _autoLiquidityWallet;
	}
	
	function marketingWallet() public view returns (address) {
		return _marketingWallet;
	}

	function developerWallet() public view returns (address) {
		return _developerWallet;
	}



	function totalFeesPooled() public view returns (uint256) {
		return _totalFeesPooled;
	}

    function buyFees() public view returns (uint8, uint8, uint8, uint8, uint8, uint8) {
        return (_developerBuyFee, _marketingBuyFee, _rewardBuyFee, _buybackBuyFee, _liquidityBuyFee, _totalBuyFee);
    }

    function sellFees() public view returns (uint8, uint8, uint8, uint8, uint8, uint8) {
        return (_developerSellFee, _marketingSellFee, _rewardSellFee, _buybackSellFee, _liquiditySellFee, _totalSellFee);
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

	function isExcludedFromFees(address addr) public view returns(bool) {
		return _addressesExcludedFromFees[addr];
	}
    

	// Ensures that the contract is able to receive BNB
	receive() external payable {}

}

contract RuffyCoin is RuffyCoinBase {

    uint256 private _rewardCyclePeriod = 43200; // The duration of the reward cycle (e.g. can claim rewards once 12 hours)
	uint256 private _rewardCycleExtensionThreshold; // If someone sends or receives more than a % of their balance in a transaction, their reward cycle date will increase accordingly
    
    uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
	uint256 private _totalBNBAsRewardTokenClaimed; // The total number of BNB that was converted to RUFFY and claimed by all addresses

    mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address
    mapping(address => uint256) private _bnbAsRewardTokenClaimed; // The amount of BNB converted to RUFFY and claimed by each address
	mapping(address => bool) private _addressesExcludedFromRewards; // The list of addresses excluded from rewards
	mapping(address => mapping(address => bool)) private _rewardClaimApprovals; //Used to allow an address to claim rewards on behalf of someone else

    // AUTO-CLAIM
	bool private _autoClaimEnabled;
    bool private _rewardAsTokensEnabled; //If enabled, the contract will give out tokens instead of BNB according to the preference of each user
    bool private _processingQueue; //Flag that indicates whether the queue is currently being processed and sending out rewards
    bool private _excludeNonHumansFromRewards = true;
    bool private isTradingEnabled;

    mapping(address => uint) _rewardClaimQueueIndices;
    mapping(address => bool) _addressesInRewardClaimQueue; // Mapping between addresses and false/true depending on whether they are queued up for auto-claim or not
    mapping(address => bool) private _whitelistedExternalProcessors; //Contains a list of addresses that are whitelisted for low-gas queue processing 
    mapping (address => bool) private _isBlacklisted;

    uint256 private _maxGasForAutoClaim = 600000; // The maximum gas to consume for processing the auto-claim queue
	address[] _rewardClaimQueue;
    uint256 private _rewardClaimQueueIndex;
    uint256 private _minRewardBalance; //The minimum balance required to be eligible for rewards
	uint256 private _maxClaimAllowed = 100 ether; // Can only claim up to 100 bnb at a time.
	uint256 private _globalRewardDampeningPercentage = 3; // Rewards are reduced by 3% at the start to fill the main BNB pool faster and ensure consistency in rewards
	uint256 private _mainBnbPoolSize = 5000 ether; // Any excess BNB after the main pool will be used as reserves to ensure consistency in rewards
    uint256 private _gradualBurnMagnitude; // The contract can optionally burn tokens (By buying them from reward pool).  This is the magnitude of the burn (1 = 0.01%).
	uint256 private _gradualBurnTimespan = 1 days; //Burn every 1 day by default
    uint256 private _lastBurnDate; //The last burn date
    uint256 private _sendWeiGasLimit;

    address private _rewardTokenAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    struct MinimumTokenBalance {
		uint256 balanceAmount;
		uint256 taxFeePercent;
	}

    MinimumTokenBalance private T1 = MinimumTokenBalance(1 * 10**decimals(), 100);
	MinimumTokenBalance private T2 = MinimumTokenBalance(1000000000 * 10**decimals(), 0);
	MinimumTokenBalance private T3 = MinimumTokenBalance(10000000000 * 10**decimals(), 0);

    event RewardClaimed(address recipient, uint256 amountBnb, uint256 nextAvailableClaimDate); 
	event Burned(uint256 bnbAmount);
	event BlacklistChange(address indexed holder, bool indexed status);

    constructor (address routerAddress, address pinkAntiBot_) RuffyCoinBase(routerAddress, pinkAntiBot_) {
		// Exclude addresses from rewards
        _addressesExcludedFromRewards[BURN_WALLET] = true;
		_addressesExcludedFromRewards[owner()] = true;
		_addressesExcludedFromRewards[address(this)] = true;
		_addressesExcludedFromRewards[address(0)] = true;

        // If someone sends or receives more than 15% of their balance in a transaction, their reward cycle date will increase accordingly
		setRewardCycleExtensionThreshold(15);
	}

    // This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function onActivated() internal override {
		super.onActivated();

		setRewardAsTokensEnabled(true);
		setAutoClaimEnabled(true);
		setMinRewardBalance(1 * 10**decimals());  //At least 1 tokens are required to be eligible for rewards
		setGradualBurnMagnitude(1); //Buy tokens using 0.01% of reward pool and burn them
		activateTrading();
		_lastBurnDate = block.timestamp;
	}


    	function processGradualBurn() private returns(bool) {
		if (!shouldBurn()) {
			return false;
		}

		uint256 burnAmount = address(this).balance * _gradualBurnMagnitude / 10000;
		doBuyAndBurn(burnAmount);
		return true;
	}

    modifier isHuman() {
        require(tx.origin == msg.sender, "Humans only");
        _;
    }


    function claimReward() isHuman nonReentrant external {
		claimReward(msg.sender);
	}


	function claimReward(address user) public {
		require(msg.sender == user || isClaimApproved(user, msg.sender), "You are not allowed to claim rewards on behalf of this user");
		require(isRewardReady(user), "Claim date for this address has not passed yet");
		require(isIncludedInRewards(user), "Address is excluded from rewards, make sure there is enough RUFFY balance");

		bool success = doClaimReward(user);
		require(success, "Reward claim failed");
	}


	function doClaimReward(address user) private returns (bool) {
		// Update the next claim date & the total amount claimed
		_nextAvailableClaimDate[user] = block.timestamp + rewardCyclePeriod();

		(uint256 claimBnb, uint256 taxFee) = calculateClaimRewards(user);

    uint256 claimBnbAsTokens = claimBnb - claimBnb * taxFee / 100;
		bool tokenClaimSuccess = true;
    // Claim Reward tokens
		if (!claimRewardToken(user, claimBnbAsTokens)) {
			tokenClaimSuccess = false;
			claimBnbAsTokens = 0;
		}

		// Fire the event in case something was claimed
		if (tokenClaimSuccess) {
			emit RewardClaimed(user, claimBnbAsTokens, _nextAvailableClaimDate[user]);
		}

		return tokenClaimSuccess;
	}

	function claimRewardToken(address user, uint256 bnbAmount) private returns (bool) {
		if (bnbAmount == 0) {
			return true;
		}

		bool success = swapBNBForCustomeTokens(rewardTokenAddress(), bnbAmount, user);
		if (!success) {
			return false;
		}

		_bnbAsRewardTokenClaimed[user] += bnbAmount;
		_totalBNBAsRewardTokenClaimed += bnbAmount;
		return true;
	}

	// Processes users in the claim queue and sends out rewards when applicable. The amount of users processed depends on the gas provided, up to 1 cycle through the whole queue. 
	// Note: Any external processor can process the claim queue (e.g. even if auto claim is disabled from the contract, an external contract/user/service can process the queue for it 
	// and pay the gas cost). "gas" parameter is the maximum amount of gas allowed to be consumed
	function processRewardClaimQueue(uint256 gas) public {
		require(gas > 0, "Gas limit is required");

		uint256 queueLength = _rewardClaimQueue.length;

		if (queueLength == 0) {
			return;
		}

		uint256 gasUsed = 0;
		uint256 gasLeft = gasleft();
		uint256 iteration = 0;
		_processingQueue = true;

		// Keep claiming rewards from the list until we either consume all available gas or we finish one cycle
		while (gasUsed < gas && iteration < queueLength) {
			if (_rewardClaimQueueIndex >= queueLength) {
				_rewardClaimQueueIndex = 0;
			}

			address user = _rewardClaimQueue[_rewardClaimQueueIndex];
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
			_rewardClaimQueueIndex++;
		}

		_processingQueue = false;
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

		if (swapBNBForTokens(bnbAmount, BURN_WALLET)) {
			emit Burned(bnbAmount);
		}

		_lastBurnDate = block.timestamp;
	}


	


    //------------------Override Functions----------------------
	function onBeforeTransfer(address sender, address recipient, uint256 amount) internal override {
		super.onBeforeTransfer(sender, recipient, amount);
		require(!_isBlacklisted[sender], "RUFFY: Account is blacklisted");
		require(!_isBlacklisted[recipient], "RUFFY: Account is blacklisted");

		if(!isTradingEnabled) {
			require(!isPancakeSwapPair(recipient), "RUFFY: Trading is currently disabled.");
			require(!isPancakeSwapPair(sender), "RUFFY: Trading is currently disabled.");
		}

		if (!isMarketTransfer(sender, recipient)) {
			return;
		}

        // Extend the reward cycle according to the amount transferred.  This is done so that users do not abuse the cycle (buy before it ends & sell after they claim the reward)
		_nextAvailableClaimDate[recipient] += calculateRewardCycleExtension(balanceOf(recipient), amount);
		_nextAvailableClaimDate[sender] += calculateRewardCycleExtension(balanceOf(sender), amount);
		
		bool isSelling = isPancakeSwapPair(recipient);
		if (!isSelling) {
			// Wait for a dip, stellar diamond hands
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

    function onPancakeSwapRouterUpdated() internal override { 
		_addressesExcludedFromRewards[pancakeSwapRouterAddress()] = true;
		_addressesExcludedFromRewards[pancakeSwapPairAddress()] = true;
	}

    function isMarketTransfer(address sender, address recipient) internal override view returns(bool) {
		// Not a market transfer when we are burning or sending out rewards
		return super.isMarketTransfer(sender, recipient) && !isBurnTransfer(sender, recipient) && !_processingQueue;
	}

    function isBurnTransfer(address sender, address recipient) private view returns (bool) {
		return isPancakeSwapPair(sender) && recipient == BURN_WALLET;
	}


	function shouldBurn() public view returns(bool) {
		return _gradualBurnMagnitude > 0 && block.timestamp - _lastBurnDate > _gradualBurnTimespan;
	}



    // This function calculates how much (and if) the reward cycle of an address should increase based on its current balance and the amount transferred in a transaction
	function calculateRewardCycleExtension(uint256 balance, uint256 amount) public view returns (uint256) {
		uint256 basePeriod = rewardCyclePeriod();

		if (balance == 0) {
			// Receiving $RUFFY on a zero balance address:
			// This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
			// Or the address has transferred all of its tokens in the past and has now received some again, in which case we will set the reward date to a date very far in the future
			return block.timestamp + basePeriod;
		}

		uint256 rate = amount * 100 / balance;

		// Depending on the % of $RUFFY tokens transferred, relative to the balance, we might need to extend the period
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

    function calculateClaimRewards(address ofAddress) public view returns (uint256, uint256) {
		uint256 reward = calculateBNBReward(ofAddress);
		uint256 taxFee = 0;
		if (balanceOf(ofAddress) >= T3.balanceAmount) {
				taxFee = T3.taxFeePercent;
		} else if(balanceOf(ofAddress) >= T2.balanceAmount) {
				taxFee = T2.taxFeePercent;
		} else if(balanceOf(ofAddress) >= T1.balanceAmount) {
				taxFee = T1.taxFeePercent;
		}

		return (reward, taxFee);
	}


	function calculateBNBReward(address ofAddress) public view returns (uint256) {
		uint256 holdersAmount = totalAmountOfTokensHeld();

		uint256 balance = balanceOf(ofAddress);
		uint256 bnbPool =  address(this).balance * (100 - _globalRewardDampeningPercentage) / 100;

		// Limit to main pool size.  The rest of the pool is used as a reserve to improve consistency
		if (bnbPool > _mainBnbPoolSize) {
			bnbPool = _mainBnbPoolSize;
		}

		// If an address is holding X percent of the supply, then it can claim up to X percent of the reward pool
		uint256 reward = bnbPool * balance / holdersAmount;

		if (reward > _maxClaimAllowed) {
			reward = _maxClaimAllowed;
		}

		return reward;
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

		return balanceOf(user) >= T1.balanceAmount && !_addressesExcludedFromRewards[user];
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

    //---------------------Setter Functions----------------------
    function setRewardCyclePeriod(uint256 period) public onlyOwner {
		require(period >= 3600 && period <= 86400, "RewardCycle must be updated to between 1 and 24 hours");
		_rewardCyclePeriod = period;
	}

    function setRewardCycleExtensionThreshold(uint256 threshold) public onlyOwner {
		_rewardCycleExtensionThreshold = threshold;
	}

    function setMaxClaimAllowed(uint256 value) public onlyOwner {
		require(value > 0, "Value must be greater than zero");
		_maxClaimAllowed = value;
	}

    function setMinRewardBalance(uint256 balance) public onlyOwner {
		_minRewardBalance = balance;
	}

	function setMaxGasForAutoClaim(uint256 gas) public onlyOwner {
		_maxGasForAutoClaim = gas;
	}
	
	function setAutoClaimEnabled(bool isEnabled) public onlyOwner {
		_autoClaimEnabled = isEnabled;
	}

    // Will be used to exclude unicrypt fees/token vesting addresses from rewards
	function setExcludedFromRewards(address addr, bool isExcluded) public onlyOwner {
		_addressesExcludedFromRewards[addr] = isExcluded;
		updateAutoClaimQueue(addr);
	}

    function approveClaim(address byAddress, bool isApproved) public {
		require(byAddress != address(0), "Invalid address");
		_rewardClaimApprovals[msg.sender][byAddress] = isApproved;
	}

    function setGlobalRewardDampeningPercentage(uint256 value) public onlyOwner {
		require(value <= 90, "Cannot be greater than 90%");
		_globalRewardDampeningPercentage = value;
	}

    function setRewardAsTokensEnabled(bool isEnabled) public onlyOwner {
		_rewardAsTokensEnabled = isEnabled;
	}

    function setGradualBurnMagnitude(uint256 magnitude) public onlyOwner {
		require(magnitude <= 100, "Must be equal or less to 100");
		_gradualBurnMagnitude = magnitude;
	}

    function setGradualBurnTimespan(uint256 timespan) public onlyOwner {
		require(timespan >= 5 minutes, "Cannot be less than 5 minutes");
		_gradualBurnTimespan = timespan;
	}

	function setMainBnbPoolSize(uint256 size) public onlyOwner {
		require(size >= 10 ether, "Size is too small");
		_mainBnbPoolSize = size;
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

	function blacklistAccount(address account) public onlyOwner {
		require(!_isBlacklisted[account], "RUFFY: Account is already blacklisted");
		_isBlacklisted[account] = true;
		emit BlacklistChange(account, true);
	}

	function unBlacklistAccount(address account) public onlyOwner {
		require(_isBlacklisted[account], "RUFFY: Account is not blacklisted");
		_isBlacklisted[account] = false;
        emit BlacklistChange(account, false);
	}

    function setRewardTokenAddress(address tokenAddr) public onlyOwner {
		address oldTokenAddr = rewardTokenAddress();
		require(oldTokenAddr != tokenAddr, "RUFFY: Token is already set reward token");
		require(oldTokenAddr != address(0), "RUFFY: New Token is the zero address");
        require(isContract(tokenAddr), "RUFFY: New Token is non-contract");
		_rewardTokenAddress = tokenAddr;
	}

	function activateTrading() public onlyOwner {
		isTradingEnabled = true;
	}

	function deactivateTrading() public onlyOwner {
		isTradingEnabled = false;
	}

    function setTiers(uint256 balanceAmount1, uint256 taxFeePercent1, uint256 balanceAmount2, uint256 taxFeePercent2, uint256 balanceAmount3, uint256 taxFeePercent3) public onlyOwner {
		require(taxFeePercent1 >= 0 && taxFeePercent1 <= 100, "RUFFY: Percentage must be updated to between 0 and 100");
		require(taxFeePercent2 >= 0 && taxFeePercent2 <= 100, "RUFFY: Percentage must be updated to between 0 and 100");
		require(taxFeePercent3 >= 0 && taxFeePercent3 <= 100, "RUFFY: Percentage must be updated to between 0 and 100");
		T1.balanceAmount = balanceAmount1;
		T1.taxFeePercent = taxFeePercent1;
		T2.balanceAmount = balanceAmount2;
		T2.taxFeePercent = taxFeePercent2;
		T3.balanceAmount = balanceAmount3;
		T3.taxFeePercent = taxFeePercent3;
	}




    //----------------Getter Functions----------------
    function totalAmountOfTokensHeld() public view returns (uint256) {
		return totalSupply() - balanceOf(address(0)) - balanceOf(BURN_WALLET) - balanceOf(pancakeSwapPairAddress());
	}

    function bnbRewardClaimedAsRewardToken(address byAddress) public view returns (uint256) {
		return _bnbAsRewardTokenClaimed[byAddress];
	}

    function totalBNBClaimedAsRewardToken() public view returns (uint256) {
		return _totalBNBAsRewardTokenClaimed;
	}

    function rewardCyclePeriod() public view returns (uint256) {
		return _rewardCyclePeriod;
	}

    function nextAvailableClaimDate(address ofAddress) public view returns (uint256) {
		return _nextAvailableClaimDate[ofAddress];
	}

	function maxClaimAllowed() public view returns (uint256) {
		return _maxClaimAllowed;
	}

	function minRewardBalance() public view returns (uint256) {
		return _minRewardBalance;
	}

    function maxGasForAutoClaim() public view returns (uint256) {
		return _maxGasForAutoClaim;
	}

    function isAutoClaimEnabled() public view returns (bool) {
		return _autoClaimEnabled;
	}

    function isExcludedFromRewards(address addr) public view returns (bool) {
		return _addressesExcludedFromRewards[addr];
	}

    function isClaimApproved(address ofAddress, address byAddress) public view returns(bool) {
		return _rewardClaimApprovals[ofAddress][byAddress];
	}

	function isRewardAsTokensEnabled() public view returns(bool) {
		return _rewardAsTokensEnabled;
	}

    function gradualBurnMagnitude() public view returns (uint256) {
		return _gradualBurnMagnitude;
	}

    function gradualBurnTimespan() public view returns (uint256) {
		return _gradualBurnTimespan;
	}

    function mainBnbPoolSize() public view returns (uint256) {
		return _mainBnbPoolSize;
	}

    function isInRewardClaimQueue(address addr) public view returns(bool) {
		return _addressesInRewardClaimQueue[addr];
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

    function rewardTokenAddress() public view returns(address) {
		return _rewardTokenAddress;
	}

    function getTradingStatus() public view onlyOwner returns(bool){
		return isTradingEnabled;
	}

    function globalRewardDampeningPercentage() public view returns(uint256) {
		return _globalRewardDampeningPercentage;
	}

    function isContract(address account) public view returns (bool) {
		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly { size := extcodesize(account) }
		return size > 0;
	}

    function getTiers() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		return (T1.balanceAmount, T1.taxFeePercent, T2.balanceAmount, T2.taxFeePercent, T3.balanceAmount, T3.taxFeePercent);
	}
}