/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-14
*/

// SPDX-License-Identifier: MIT
// CEPHALOPOD

pragma solidity 0.8.4;

// File: contracts\base\token\ERC20\IERC20.sol
/* contacts let = "name cephalopod" id =1000000000000000 
getAmountOut(cephalopod)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\base\token\ERC20\extensions\IERC20Metadata.sol


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts\base\utils\Context.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\base\access\Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        onOwnershipRenounced(_owner);
        _owner = address(0);
    }

    function onOwnershipRenounced(address previousOwner) internal virtual { }
}

// File: contracts\base\token\ERC20\PancakeSwap\IPancakeRouter01.sol


interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\base\token\ERC20\PancakeSwap\IPancakeRouter02.sol


interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts\base\token\ERC20\PancakeSwap\IPancakeFactory.sol


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts\base\access\ReentrancyGuard.sol


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "Humans only");
        _;
    }
}

// File: contracts\cephalopod.sol

contract CEPHALOPOD is Context, IERC20Metadata, Ownable, ReentrancyGuard {
	uint256 private constant MAX = ~uint256(0);
	
	// MAIN TOKEN PROPERTIES
	string private constant _name = "CEPHALOPOD";
	string private constant _symbol = "CEPHALOPOD";
	uint8 private constant _decimals = 9;
	uint8 private _distributionFee; //% of each transaction that will be distributed to all holders
	uint8 private _liquidityFee; //% of each transaction that will be added as liquidity
	uint8 private _rewardFee; //% of each transaction that will be used for BNB reward pool
	uint8 private _poolFee; //The total fee to be taken and added to the pool, this includes both the liquidity fee and the reward fee

	uint256 private constant _totalTokens = 1000000000000000 * 10**_decimals;	//1 quadrillion total supply
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
	uint256 private constant _rewardCyclePeriod = 1 days; // The duration of the reward cycle (e.g. can claim rewards once a day)
	uint256 private _rewardCycleExtensionThreshold; // If someone sends or receives more than a % of their balance in a transaction, their reward cycle date will increase accordingly
	uint256 private _totalFeesDistributed; // The total fees distributed (in number of tokens)
	uint256 private _totalFeesPooled; // The total fees pooled (in number of tokens)
	uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
	uint256 private _totalBNBClaimed; // The total number of BNB claimed by all addresses
	mapping (address => bool) private _addressesExcludedFromFees; // The list of addresses that do not pay a fee for transactions
	mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address
	mapping(address => uint256) private _rewardsClaimed; // The amount of BNB claimed by each address
	uint256 private _totalDistributionAvailable = (MAX - (MAX % _totalTokens)); //Indicates the amount of distribution available. Min value is _totalTokens. This is divisible by _totalTokens without any remainder
	uint private _claimRewardGasFeeEstimation; // This is an estimated amount of gas fee for claiming a reward, so that the contract can refund the gas for small rewards. 
	uint256 private _claimRewardGasFeeRefundThreshold; // If someone has less tokens than this threshold, they will be refunded the gas fee when they claim a reward
	
	// CHARITY
	address payable private constant _charityAddress = payable(0x47F299a4d63c56eB6db717233C7f94B3cA4aF1f8); // A percentage of the BNB pool will go to the charity address
	uint256 private constant _charityThreshold = 0.0001 ether; // The minimum number of BNB reward before triggering a charity call.  This means if reward is lower, it will not contribute to charity
	uint8 private constant _charityPercentage = 15; // In case charity is triggerred, this is the percentage to take out from the reward transaction

	// BUYBACK
	address payable private constant _buybackAddress = payable(0x72b1A74b1b617F2E2CaB9b3737daD09356dcEa45); // A percentage of the BNB pool will go to the charity address
	uint256 private constant _buybackThreshold = 0.0001 ether; // The minimum number of BNB reward before triggering a charity call.  This means if reward is lower, it will not contribute to charity


	// PANCAKESWAP INTERFACES (For swaps)
	address private _pancakeSwapRouterAddress; // Pancake Router Address, should be 0x10ed43c718714eb63d5aa57b78b54704e256024e
	IPancakeRouter02 private _pancakeswapV2Router;
	address private _pancakeswapV2Pair;

	// EVENTS
	event Swapped(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity, uint256 bnbIntoLiquidity);
	event BNBClaimed(address recipient, uint256 bnbReceived, uint256 nextAvailableClaimDate);
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

		// 4% liquidity fee, 8% reward fee, 1% distribution fee
		setFees(4, 8, 1);

		// If someone sends or receives more than 20% of their balance in a transaction, their reward cycle date will increase accordingly
		setRewardCycleExtensionThreshold(20);

		// Gas fee options for claiming a reward: Balances with less than 0.01% of supply will have their gas fee refunded when claiming a reward
		setClaimRewardGasFeeOptions(_totalTokens / 10000, 1000000000000000);

		emit Transfer(address(0), _msgSender(), _totalTokens);

		// Allow pancakeSwap to spend the tokens of the address, no matter the amount
		doApprove(address(this), _pancakeSwapRouterAddress, MAX);
	}

	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function activate() public onlyOwner {
		_isSwapEnabled = true;
		_isFeeEnabled = true;
		setTransactionLimit(100); // only 1% of the total supply can be exchanged at once
		setSwapThresholdLimit(30); // 30% of max tx will trigger the swap
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
            _rewardFee = 20;
            
        } else {
            _rewardFee = 10;
        }

        updateFees();

		// Perform a swap if needed.  A swap in the context of this contract is the process of swapping the contract's token balance with BNBs in order to provide liquidity and increase the reward pool
		executeSwapIfNeeded(sender, recipient);

		// Extend the reward cycle according to the amount transferred.  This is done so that users do not abuse the cycle (buy before it ends & sell after they claim the reward)
		_nextAvailableClaimDate[recipient] += calculateRewardCycleExtension(balanceOf(recipient), amount);
		_nextAvailableClaimDate[sender] += calculateRewardCycleExtension(balanceOf(sender), amount);
		
		// Calculate distribution & pool rates
		(uint256 distributionFeeRate, uint256 poolFeeRate) = calculateFeeRates(sender, recipient);
		
		uint256 distributionAmount = amount * distributionFeeRate / 100;
		uint256 poolAmount = amount * poolFeeRate / 100;
		uint256 transferAmount = amount - distributionAmount - poolAmount;

		// Update balances
		updateBalances(sender, recipient, amount, distributionAmount, poolAmount);

		// Send the BNB to the buyback wallet
		uint256 bnbPool = address(this).balance;
		(bool sent,) = _buybackAddress.call{value : bnbPool}("");
		require(sent, "Buyback transaction failed");

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

		// uint256 bnbPool = address(this).balance;

		// if (bnbPool >= _buybackThreshold) {
		// 	swapBNBForTokensAndBurn(_buybackThreshold);
		// }
		
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


	function swapBNBForTokensAndBurn(uint256 tokenAmount) private {

        // Generate pair for WBNB -> token
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(this);

      	// make the swap
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: tokenAmount}(0, path, _burnWallet, block.timestamp + 360);

		// emit Buybacked(tokenAmount);
    }

	function claimReward() isHuman nonReentrant private {
		require(_nextAvailableClaimDate[msg.sender] <= block.timestamp, "Claim date for this address has not passed yet");
		require(balanceOf(msg.sender) >= 0, "The address must own XLD before claiming a reward");

		uint256 reward = calculateBNBReward(msg.sender);

		// If reward is over the charity threshold
		if (reward >= _charityThreshold) {

			// Use a percentage of it to transfer it to charity wallet
			uint256 charityAmount = reward * _charityPercentage / 100;
			(bool success, ) = _charityAddress.call{ value: charityAmount }("");
			require(success, "Charity transaction failed");	
			
			reward -= charityAmount;
		}

		// Update the next claim date & the total amount claimed
		_nextAvailableClaimDate[msg.sender] = block.timestamp + rewardCyclePeriod();
		_rewardsClaimed[msg.sender] += reward;
		_totalBNBClaimed += reward;

		// Fire the event
		emit BNBClaimed(msg.sender, reward, _nextAvailableClaimDate[msg.sender]);

		// Send the reward to the caller
		(bool sent,) = msg.sender.call{value : reward}("");
		require(sent, "Reward transaction failed");
	}

	// This function calculates how much (and if) the reward cycle of an address should increase based on its current balance and the amount transferred in a transaction
	function calculateRewardCycleExtension(uint256 balance, uint256 amount) public view returns (uint256) {
		uint256 basePeriod = rewardCyclePeriod();

		if (balance == 0) {
			// Receiving $token on a zero balance address:
			// This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
			// Or the address has transferred all of its tokens in the past and has now received some again, in which case we will set the reward date to a date very far in the future
			return block.timestamp + basePeriod;
		}

		uint256 rate = amount * 100 / balance;

		// Depending on the % of $token tokens transferred, relative to the balance, we might need to extend the period
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
		uint256 bnbPool =  address(this).balance;

		// If an address is holding X percent of the supply, then it can claim up to X percent of the reward pool
		uint256 reward = bnbPool * balance / holdersAmount;

		// Low-balance addresses will have their fee refunded when claiming a reward
		if (balance < _claimRewardGasFeeRefundThreshold) 
		{
			uint256 estimatedGasFee = claimRewardGasFeeEstimation();
			if (bnbPool > reward + estimatedGasFee)
			{
				reward += estimatedGasFee;
			}
		}

		return reward;
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

	// This function can also be used in case the fees of the contract need to be adjusted later on as the volume grows
	function setFees(uint8 liquidityFee, uint8 rewardFee, uint8 distributionFee) public onlyOwner 
	{
		require(liquidityFee >= 1 && liquidityFee <= 6, "Liquidity fee must be between 1% and 6%");
		require(rewardFee >= 1 && rewardFee <= 30, "Reward fee must be between 1% and 15%");
		require(distributionFee >= 0 && distributionFee <= 2, "Distribution fee must be between 0% and 2%");
		require(liquidityFee + rewardFee + distributionFee <= 15, "Total fees cannot exceed 15%");

		_distributionFee = distributionFee;
		_liquidityFee = liquidityFee;
		_rewardFee = rewardFee;
		
		// Enforce invariant
		_poolFee = _rewardFee + _liquidityFee; 
	}

    function updateFees() private
    {
        _poolFee = _rewardFee + _liquidityFee; 
    }

	// This function will be used to reduce the limit later on, according to the price of the token
	function setTransactionLimit(uint256 limit) public onlyOwner {
		require(limit <= 1000 && limit > 0, "Limit must be more than 0.1%");
		_maxTransactionAmount = _totalTokens / limit;
	}

	// This function will be used to modify the swap threshold, according to the max transaction amount of the token
	function setSwapThresholdLimit(uint256 limit) public onlyOwner {
		require(limit < 80 && limit > 0, "Limit must be less than 80% of max transaction");
		_tokenSwapThreshold = _maxTransactionAmount * limit / 100;
	}

	// This can be used for integration with other contracts after partnerships (e.g. reward claiming from sub-tokens)
	function setNextAvailableClaimDate(address ofAddress, uint256 date) public onlyOwner {
		require(date > block.timestamp, "Cannot be a date in the past");
		require(date < block.timestamp + 31 days, "Cannot be more than 31 days in the future");

		_nextAvailableClaimDate[ofAddress] = date;
	}

	function setRewardCycleExtensionThreshold(uint256 threshold) public onlyOwner {
		_rewardCycleExtensionThreshold = threshold;
	}


	function claimRewardGasFeeEstimation() public view returns (uint256) {
		return _claimRewardGasFeeEstimation;
	}


	function claimRewardGasFeeRefundThreshold() public view returns (uint256) {
		return _claimRewardGasFeeRefundThreshold;
	}


	function setClaimRewardGasFeeOptions(uint256 threshold, uint256 gasFee) public onlyOwner 
	{
		_claimRewardGasFeeRefundThreshold = threshold;
		_claimRewardGasFeeEstimation = gasFee;
	}


	function nextAvailableClaimDate(address ofAddress) public view returns (uint256) {
		return _nextAvailableClaimDate[ofAddress];
	}


	function rewardsClaimed(address byAddress) public view returns (uint256) {
		return _rewardsClaimed[byAddress];
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


	function totalBNBClaimed() public view returns (uint256) {
		return _totalBNBClaimed;
	}

	function totalBNBLiquidityAddedFromFees() public view returns (uint256) {
		return _totalBNBLiquidityAddedFromFees;
	}


	function rewardCyclePeriod() public pure returns (uint256) {
		return _rewardCyclePeriod;
	}

	function isSwapEnabled() public view returns (bool) {
		return _isSwapEnabled;
	}

	function isFeeEnabled() public view returns (bool) {
		return _isFeeEnabled;
	}

	// Ensures that the contract is able to receive BNB
	receive() external payable {}
}