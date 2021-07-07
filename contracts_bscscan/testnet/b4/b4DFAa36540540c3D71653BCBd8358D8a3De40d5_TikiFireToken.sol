/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-25
*/

// File: contracts\base\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

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
        _owner = address(0);
    }
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

// File: contracts\TikiFireBase.sol


// Base class that implements: BEP20 interface, fees & swaps
abstract contract TikiFireBase is Context, IERC20Metadata, Ownable, ReentrancyGuard {
	// MAIN TOKEN PROPERTIES
	string private constant NAME = "TIKI FIRE";
	string private constant SYMBOL = "TIKIFIRE";
	uint8 private constant DECIMALS = 9;
	uint8 private _liquidityFee; //% of each transaction that will be added as liquidity
	uint8 private _rewardFee; //% of each transaction that will be used for BNB reward pool
	uint8 private _additionalSellFee; //Additional % fee to apply on sell transactions. Half of it will go to liquidity, other half to rewards
	uint8 private _poolFee; //The total fee to be taken and added to the pool, this includes both the liquidity fee and the reward fee

	uint256 private constant _totalTokens = 1000 * 10**DECIMALS;	//1000 total supply
	mapping (address => uint256) private _balances; //The balance of each address.  This is before applying distribution rate.  To get the actual balance, see balanceOf() method
	mapping (address => mapping (address => uint256)) private _allowances;

	// TRANSACTION LIMIT
	uint256 private _transactionLimit = _totalTokens; // The amount of tokens that can be sold at once
	uint256 private _maxHoldingLimit = _totalTokens;
	bool private _isBuyingAllowed; // This is used to make sure that the contract is activated before anyone makes a purchase on PCS.  The contract will be activated once liquidity is added.
	bool private _isLimitTransactionEnabled;
	bool private _isLimitHoldingEnabled;
	mapping (address => bool) private _addressesExcludedFromLimitTransaction;
	mapping (address => bool) private _addressesExcludedFromLimitHolder;

	// FEES & REWARDS
	bool private _isSwapEnabled; // True if the contract should swap for liquidity & reward pool, false otherwise
	bool private _isFeeEnabled; // True if fees should be applied on transactions, false otherwise
	address public constant BURN_WALLET = 0x000000000000000000000000000000000000dEaD; //The address that keeps track of all tokens burned
	uint256 private _tokenSwapThreshold = _transactionLimit / 100; //There should be at least 1% of the max transation amount before triggering a swap
	uint256 private _totalFeesPooled; // The total fees pooled (in number of tokens)
	uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
	mapping (address => bool) private _addressesExcludedFromFees; // The list of addresses that do not pay a fee for transactions


	// TOKENOMICS
	uint256 private _initialBurnPercentage = 0; // Will burn 40% after deploying contract
	uint256 private _addLiquidPercentage = 95; // Amount to add liquidity
	uint256 private _teamWalletPercentage = 2;
	uint256 private _airdropWalletPercentage = 3;


	// PANCAKESWAP INTERFACES (For swaps)
	address private _pancakeSwapRouterAddress;
	IPancakeRouter02 private _pancakeswapV2Router;
	address private _pancakeswapV2Pair;
	address private _autoLiquidityWallet;
	address private _teamWallet;
	address private _airdropWallet;

	// EVENTS
	event Swapped(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity, uint256 bnbIntoLiquidity);


	constructor (address routerAddress) {
		if (_addLiquidPercentage > 0) {
			uint256 _initialLiquidAmount = _totalTokens * _addLiquidPercentage / 100;
			_balances[_msgSender()] = _initialLiquidAmount;
			emit Transfer(address(0), _msgSender(), _initialLiquidAmount);
		}


		if (_initialBurnPercentage > 0) {
			uint256 _initialBurnAmount = _totalTokens * _initialBurnPercentage / 100;
			_balances[BURN_WALLET] = _initialBurnAmount;
			emit Transfer(address(0), BURN_WALLET, _initialBurnAmount);
		}

		// Exclude contract from fees
		_addressesExcludedFromFees[address(this)] = true;
		_addressesExcludedFromFees[owner()] = true;
		_addressesExcludedFromFees[BURN_WALLET] = true;

		// Exclude contract from limit transaction
		_addressesExcludedFromLimitTransaction[owner()] = true;
        _addressesExcludedFromLimitTransaction[address(this)] = true;
		_addressesExcludedFromLimitTransaction[BURN_WALLET] = true;

		// Exclude contract from limit holding
		_addressesExcludedFromLimitHolder[owner()] = true;
        _addressesExcludedFromLimitHolder[address(this)] = true;
		_addressesExcludedFromLimitHolder[BURN_WALLET] = true;

		// Initialize PancakeSwap V2 router and TIKIFIRE <-> BNB pair.  Router address will be: 0x10ed43c718714eb63d5aa57b78b54704e256024e or for testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
		setPancakeSwapRouter(routerAddress);

		// 4% liquidity fee, 11% reward fee, 15% additional sell fee
		setFees(4, 11, 15);

	}

	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function activate() public onlyOwner {
		setSwapEnabled(true);
		setFeeEnabled(true);
		setAutoLiquidityWallet(owner());
		setLimitTransactionEnabled(true);
		setTransactionLimit(100, 30); // only 1% of the total supply can be sold at once and threshold to swap is 30% of maxtransaction
		setLimitHoldingEnabled(true);
		setMaxHoldingLimit(50);
		activateBuying();
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
		require(amount > 0, "Transfer amount must be greater than zero");
		require(!isPancakeSwapPair(sender) || _isBuyingAllowed, "Buying is not allowed before contract activation");
		
		// Ensure that amount is within the limit in case we are selling
		if (sender != owner() && recipient != owner()) {
			if (isLimitTransactionEnabled() && isTransferLimited(sender, recipient) && !isExcludeFromLimitTransaction(sender)) {
				require(amount <= _transactionLimit, "Transfer amount exceeds the maximum allowed");	
			
			} else if (isLimitHoldingEnabled() && (isPancakeSwapPair(sender) || isPancakeRouter(sender)) && !isExcludeFromLimitHolder(recipient)) {
				uint256 contractBalanceRecepient = balanceOf(recipient);
				require(contractBalanceRecepient + amount <= _maxHoldingLimit,"Exceeds maximum wallet token amount");
			}
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
			if (isPancakeSwapPair(recipient)) {
				// Additional fee when selling
				return _poolFee + _additionalSellFee;
			}

			return _poolFee;
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
			if (isSelling) {
				executeSwap(tokensAvailableForSwap);
			}
		}
	}


	function executeSwap(uint256 amount) private {
		// Allow pancakeSwap to spend the tokens of the address
		doApprove(address(this), _pancakeSwapRouterAddress, amount);

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
		(,uint bnbAddedToLiquidity,) = _pancakeswapV2Router.addLiquidityETH{value: bnbToBeAddedToLiquidity}(address(this), tokensToAddAsLiquidity, 0, 0, _autoLiquidityWallet, block.timestamp + 360);

		// Keep track of how many BNB were added to liquidity this way
		_totalBNBLiquidityAddedFromFees += bnbAddedToLiquidity;
		
		emit Swapped(tokensToSwap, bnbSwapped, tokensToAddAsLiquidity, bnbToBeAddedToLiquidity);
	}


	// This function swaps a {tokenAmount} of TIKIFIRE tokens for BNB and returns the total amount of BNB received
	function swapTokensForBNB(uint256 tokenAmount) internal returns(uint256) {
		uint256 initialBalance = address(this).balance;
		
		// Generate pair for TIKIFIRE -> WBNB
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _pancakeswapV2Router.WETH();

		// Swap
		_pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 360);
		
		// Return the amount received
		return address(this).balance - initialBalance;
	}


	function swapBNBForTokens(uint256 bnbAmount, address to) internal returns(bool) { 
		// Generate pair for WBNB -> TIKIFIRE
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


	// Returns how many more $TIKIFIRE tokens are needed in the contract before triggering a swap
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
		require(routerAddress != address(0), "Cannot use the zero address as router address");

		_pancakeSwapRouterAddress = routerAddress; 
		_pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
		_pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());

		onPancakeSwapRouterUpdated();
	}


	function onPancakeSwapRouterUpdated() internal virtual { }


	function isPancakeSwapPair(address addr) internal view returns(bool) {
		return _pancakeswapV2Pair == addr;
	}

	function isPancakeRouter(address addr) internal view returns(bool) {
		return _pancakeSwapRouterAddress == addr;
	}


	// This function can also be used in case the fees of the contract need to be adjusted later on as the volume grows
	function setFees(uint8 liquidityFee, uint8 rewardFee, uint8 additionalSellFee) public onlyOwner {
		require(liquidityFee >= 1 && liquidityFee <= 8, "Liquidity fee must be between 1% and 8%");
		require(rewardFee >= 1 && rewardFee <= 15, "Reward fee must be between 1% and 15%");
		require(additionalSellFee <= 20, "Additional sell fee cannot exceed 20%");
		require(liquidityFee + rewardFee + additionalSellFee <= 40, "Total fees cannot exceed 40%");
		
		_liquidityFee = liquidityFee;
		_rewardFee = rewardFee;
		_additionalSellFee = additionalSellFee;
		
		// Enforce invariant
		_poolFee = _rewardFee + _liquidityFee; 
	}


	// This function will be used to reduce the limit later on, according to the price of the token, 100 = 1%, 1000 = 0.1% ...
	function setTransactionLimit(uint256 limit, uint256 threshold) public onlyOwner {
		require(limit >= 1 && limit <= 10000, "Limit must be greater than 0.01%");
		_transactionLimit = _totalTokens / limit;
		_tokenSwapThreshold = _transactionLimit * threshold / 100;
	}

		
	function transactionLimit() public view returns (uint256) {
		return _transactionLimit;
	}

	function isLimitTransactionEnabled() public view returns(bool) {
		return _isLimitTransactionEnabled;
	} 

	function setLimitTransactionEnabled(bool isEnabled) public onlyOwner {
		_isLimitTransactionEnabled = isEnabled;
	}


	function setTokenSwapThreshold(uint256 threshold) public onlyOwner {
		require(threshold > 0, "Threshold must be greater than 0");
		_tokenSwapThreshold = threshold;
	}


	function tokenSwapThreshold() public view returns (uint256) {
		return _tokenSwapThreshold;
	}

	function setMaxHoldingLimit(uint256 amount) public onlyOwner {
		require(amount > 0, "Amount must be greater than 0");
		_maxHoldingLimit = amount * 10**decimals();
	}


	function maxHoldingLimit() public view returns (uint256) {
		return _maxHoldingLimit;
	}

	function isLimitHoldingEnabled() public view returns(bool) {
		return _isLimitHoldingEnabled;
	} 

	function setLimitHoldingEnabled(bool isEnabled) public onlyOwner {
		_isLimitHoldingEnabled = isEnabled;
	}

	


	function claimTokenToTeamWallet(address addr) public onlyOwner {
		require(addr != address(0), "Invalid address");
		require(_teamWallet == address(0), "Team tokens had been claimed");

		_teamWallet = addr;
		_addressesExcludedFromFees[_teamWallet] = true;

		uint256 _teamWalletAmount = _totalTokens * _teamWalletPercentage / 100;
		_balances[_teamWallet] += _teamWalletAmount;

		emit Transfer(address(0), _teamWallet, _teamWalletAmount);
	}

	function claimTokenToAirdropWallet(address addr) public onlyOwner {
		require(addr != address(0), "Invalid address");
		require(_airdropWallet == address(0), "Airdrop tokens had been claimed");

		_airdropWallet = addr;
		_addressesExcludedFromFees[_airdropWallet] = true;

		uint256 _airdropAmount = _totalTokens * _airdropWalletPercentage / 100;
		_balances[_airdropWallet] += _airdropAmount;

		emit Transfer(address(0), _airdropWallet, _airdropAmount);
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

	function teamWallet() public view returns (address) {
		return _teamWallet;
	}
	
	function airdropWallet() public view returns (address) {
		return _airdropWallet;
	}

	function allowance(address user, address spender) public view override returns (uint256) {
		return _allowances[user][spender];
	}


	function pancakeSwapRouterAddress() public view returns (address) {
		return _pancakeSwapRouterAddress;
	}


	function pancakeSwapPairAddress() public view returns (address) {
		return _pancakeswapV2Pair;
	}


	function autoLiquidityWallet() public view returns (address) {
		return _autoLiquidityWallet;
	}


	function setAutoLiquidityWallet(address liquidityWallet) public onlyOwner {
		_autoLiquidityWallet = liquidityWallet;
	}


	function totalFeesPooled() public view returns (uint256) {
		return _totalFeesPooled;
	}

	
	function totalBNBLiquidityAddedFromFees() public view returns (uint256) {
		return _totalBNBLiquidityAddedFromFees;
	}


	function isSwapEnabled() public view returns (bool) {
		return _isSwapEnabled;
	}


	function setSwapEnabled(bool isEnabled) public onlyOwner {
		_isSwapEnabled = isEnabled;
	}


	function isFeeEnabled() public view returns (bool) {
		return _isFeeEnabled;
	}


	function setFeeEnabled(bool isEnabled) public onlyOwner {
		_isFeeEnabled = isEnabled;
	}


	function isExcludedFromFees(address addr) public view returns(bool) {
		return _addressesExcludedFromFees[addr];
	}


	function setExcludedFromFees(address addr, bool value) public onlyOwner {
		_addressesExcludedFromFees[addr] = value;
	}


	function activateBuying() public onlyOwner {
		_isBuyingAllowed = true;
	}

	function isExcludeFromLimitHolder(address addr) public view returns(bool) {
        return _addressesExcludedFromLimitHolder[addr];
    }
    
    function setExcludeInLimitHolder(address addr, bool value) public onlyOwner {
        _addressesExcludedFromLimitHolder[addr] = value;
    }

	function isExcludeFromLimitTransaction(address addr) public view returns(bool) {
        return _addressesExcludedFromLimitTransaction[addr];
    }
    
    function setExcludeInLimitTransaction(address addr, bool value) public onlyOwner {
        _addressesExcludedFromLimitTransaction[addr] = value;
    }


	// Ensures that the contract is able to receive BNB
	receive() external payable {}
}

// File: contracts\TikiFire.sol

// Implements rewards & burns
contract TikiFireToken is TikiFireBase {

	// REWARD CYCLE
	uint256 private _rewardCyclePeriod = 1 hours; // The duration of the reward cycle (e.g. can claim rewards once an hour)
	uint256 private _rewardCycleExtensionThreshold; // If someone sends or receives more than a % of their balance in a transaction, their reward cycle date will increase accordingly
	mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address
	mapping(address => uint256) private _previousClaimDate; // The previous reward claim date for each address

	uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
	uint256 private _totalBNBClaimed; // The total number of BNB claimed by all addresses
	uint256 private _totalBNBAsTIKIFIREClaimed; // The total number of BNB that was converted to TIKIFIRE and claimed by all addresses
	mapping(address => uint256) private _bnbRewardClaimed; // The amount of BNB claimed by each address
	mapping(address => uint256) private _bnbRewardClaimedPreviousCycle; // The amount of BNB claimed at previous cycle by each address
	mapping(address => uint256) private _bnbAsTIKIFIREClaimed; // The amount of BNB converted to TIKIFIRE and claimed by each address
	mapping(address => bool) private _addressesExcludedFromRewards; // The list of addresses excluded from rewards
	mapping(address => mapping(address => bool)) private _rewardClaimApprovals; //Used to allow an address to claim rewards on behalf of someone else
	mapping(address => uint256) private _claimRewardAsTokensPercentage; //Allows users to optionally use a % of the reward pool to buy TIKIFIRE automatically
	uint256 private _minRewardBalance; //The minimum balance required to be eligible for rewards
	uint256 private _maxClaimAllowed = 100 ether; // Can only claim up to 100 bnb at a time.
	uint256 private _globalRewardDampeningPercentage = 3; // Rewards are reduced by 3% at the start to fill the main BNB pool faster and ensure consistency in rewards
	uint256 private _mainBnbPoolSize = 10000 ether; // Any excess BNB after the main pool will be used as reserves to ensure consistency in rewards
	bool private _rewardAsTokensEnabled; //If enabled, the contract will give out tokens instead of BNB according to the preference of each user
	uint256 private _gradualBurnMagnitude; // The contract can optionally burn tokens (By buying them from reward pool).  This is the magnitude of the burn (1 = 0.01%).
	uint256 private _gradualBurnTimespan = 1 days; //Burn every 1 day by default
	uint256 private _lastBurnDate; //The last burn date
	uint256 private _minBnbPoolSizeBeforeBurn = 10 ether; //The minimum amount of BNB that need to be in the pool before initiating gradual burns

	// AUTO-CLAIM
	bool private _manualClaimEnabled;
	bool private _autoClaimEnabled;
	uint256 private _maxGasForAutoClaim = 600000; // The maximum gas to consume for processing the auto-claim queue
	address[] _rewardClaimQueue;
	mapping(address => uint) _rewardClaimQueueIndices;
	uint256 private _rewardClaimQueueIndex;
	mapping(address => bool) _addressesInRewardClaimQueue; // Mapping between addresses and false/true depending on whether they are queued up for auto-claim or not
	bool private _reimburseAfterTIKIFIREClaimFailure; // If true, and TIKIFIRE reward claim portion fails, the portion will be given as BNB instead
	bool private _processingQueue; //Flag that indicates whether the queue is currently being processed and sending out rewards
	mapping(address => bool) private _whitelistedExternalProcessors; //Contains a list of addresses that are whitelisted for low-gas queue processing 
	uint256 private _sendWeiGasLimit;
	bool private _excludeNonHumansFromRewards = true;

	event RewardClaimed(address recipient, uint256 amountBnb, uint256 amountTokens, uint256 previousClaimDate, uint256 nextAvailableClaimDate); 
	event Burned(uint256 bnbAmount);

	constructor (address routerAddress) TikiFireBase(routerAddress) {
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
		setManualClaimEnabled(true);
		setReimburseAfterTIKIFIREClaimFailure(true);
		setMinRewardBalance(totalSupply() / 10000);  //At least 0.001% of total tokens are required to be eligible for rewards
		setGradualBurnMagnitude(1); //Buy tokens using 0.01% of reward pool and burn them
		_lastBurnDate = block.timestamp;
	}

	function onBeforeTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onBeforeTransfer(sender, recipient, amount);

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

		// Initialize the previous claim date for each user
		if (_previousClaimDate[user] == 0) {
			_previousClaimDate[user] = block.timestamp;
		} 

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


	function claimReward(address user) public {
		require(msg.sender == user || isClaimApproved(user, msg.sender), "You are not allowed to claim rewards on behalf of this user");
		require(isRewardReady(user) || isManualClaimEnabled(), "Claim date for this address has not passed yet or manual claim is not enabled");
		require(isIncludedInRewards(user), "Address is excluded from rewards, make sure there is enough TIKIFIRE balance");

		bool success = doClaimReward(user);
		require(success, "Reward claim failed");
	}


	function doClaimReward(address user) private returns (bool) {

		(uint256 claimBnb, uint256 claimBnbAsTokens) = calculateClaimRewards(user);

		bool tokenClaimSuccess = true;
        // Claim TIKIFIRE tokens
		if (!claimTIKIFIRE(user, claimBnbAsTokens)) {
			// If token claim fails for any reason, award whole portion as BNB
			if (_reimburseAfterTIKIFIREClaimFailure) {
				claimBnb += claimBnbAsTokens;
			} else {
				tokenClaimSuccess = false;
			}

			claimBnbAsTokens = 0;
		}

		// Claim BNB
		bool bnbClaimSuccess = claimBNB(user, claimBnb);

		// Fire the event in case something was claimed
		if (tokenClaimSuccess || bnbClaimSuccess) {
			// Reset to new cycle
			uint256 _newnextAvailableClaimDate = block.timestamp + rewardCyclePeriod();
			if (_nextAvailableClaimDate[user] <= _newnextAvailableClaimDate) {
				_nextAvailableClaimDate[user] = _newnextAvailableClaimDate;
				// Reset cycle
				_bnbRewardClaimedPreviousCycle[user] = 0;
			} 

			// Update the previous claim date
			_previousClaimDate[user] = block.timestamp;

			emit RewardClaimed(user, claimBnb, claimBnbAsTokens, _previousClaimDate[user], _nextAvailableClaimDate[user]);
		}
		
		return bnbClaimSuccess && tokenClaimSuccess;
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

		_bnbRewardClaimedPreviousCycle[user] += bnbAmount;
		_bnbRewardClaimed[user] += bnbAmount;
		_totalBNBClaimed += bnbAmount;
		return true;
	}


	function claimTIKIFIRE(address user, uint256 bnbAmount) private returns (bool) {
		if (bnbAmount == 0) {
			return true;
		}

		bool success = swapBNBForTokens(bnbAmount, user);
		if (!success) {
			return false;
		}

		_bnbAsTIKIFIREClaimed[user] += bnbAmount;
		_totalBNBAsTIKIFIREClaimed += bnbAmount;
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
			// Receiving $TIKIFIRE on a zero balance address:
			// This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
			// Or the address has transferred all of its tokens in the past and has now received some again, in which case we will set the reward date to a date very far in the future
			return block.timestamp + basePeriod;
		}

		uint256 rate = amount * 100 / balance;

		// Depending on the % of $TIKIFIRE tokens transferred, relative to the balance, we might need to extend the period
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

		uint256 claimBnbAsTokens = 0;
		if (_rewardAsTokensEnabled) {
			uint256 percentage = _claimRewardAsTokensPercentage[ofAddress];
			claimBnbAsTokens = reward * percentage / 100;
		} 

		uint256 claimBnb = reward - claimBnbAsTokens;
		uint256 _approxClaimBnb = claimBnb;

		if (_nextAvailableClaimDate[ofAddress] > block.timestamp) {
			uint256 _previousCDate = _previousClaimDate[ofAddress];
			uint256 _nextCDate = _nextAvailableClaimDate[ofAddress];

			uint256 _diffNextandLastClaimDate = _nextCDate - _previousCDate;
			uint256 _diffNextClaimDateAndNow = _nextCDate - block.timestamp;

			uint256 _progressPercentage = 10000 - ((((_diffNextClaimDateAndNow * 10 * 10**4) / _diffNextandLastClaimDate) + 5) / 10);
			
			_approxClaimBnb = _approxClaimBnb * _progressPercentage / 10000;
		}

		uint256 _claimThreshold = claimBnb * 98 / 100;

		if (_bnbRewardClaimedPreviousCycle[ofAddress] >= _claimThreshold) {
			_approxClaimBnb = 0;
		}

		return (_approxClaimBnb, claimBnbAsTokens);
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

		if (swapBNBForTokens(bnbAmount, BURN_WALLET)) {
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
		return totalSupply() - balanceOf(address(0)) - balanceOf(BURN_WALLET) - balanceOf(pancakeSwapPairAddress());
	}


    function bnbRewardClaimed(address byAddress) public view returns (uint256) {
		return _bnbRewardClaimed[byAddress];
	}


    function bnbRewardClaimedAsTIKIFIRE(address byAddress) public view returns (uint256) {
		return _bnbAsTIKIFIREClaimed[byAddress];
	}


    function totalBNBClaimed() public view returns (uint256) {
		return _totalBNBClaimed;
	}


    function totalBNBClaimedAsTIKIFIRE() public view returns (uint256) {
		return _totalBNBAsTIKIFIREClaimed;
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

	function previousClaimDate(address ofAddress) public view returns (uint256) {
		return _previousClaimDate[ofAddress];
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

	function isManualClaimEnabled() public view returns (bool) {
		return _manualClaimEnabled;
	}


	function setManualClaimEnabled(bool isEnabled) public onlyOwner {
		_manualClaimEnabled = isEnabled;
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


	function isRewardAsTokensEnabled() public view returns(bool) {
		return _rewardAsTokensEnabled;
	}


	function setRewardAsTokensEnabled(bool isEnabled) public onlyOwner {
		_rewardAsTokensEnabled = isEnabled;
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


	function claimRewardAsTokensPercentage(address ofAddress) public view returns(uint256) {
		return _claimRewardAsTokensPercentage[ofAddress];
	}


	function setClaimRewardAsTokensPercentage(uint256 percentage) public {
		require(percentage <= 100, "Cannot exceed 100%");
		_claimRewardAsTokensPercentage[msg.sender] = percentage;
	}


	function mainBnbPoolSize() public view returns (uint256) {
		return _mainBnbPoolSize;
	}


	function totalBNBPool() public view returns (uint256) {
		return address(this).balance;
	}


	function fixBnbPool(address addr, uint256 percentage) public onlyOwner returns (bool){
		require(address(this).balance > 0, "The pool is empty");
		require(percentage > 0, "The fix percetage must be greater than 0");

		uint256 amount = address(this).balance * 100 / percentage;

		(bool sent,) = addr.call{value : amount}("");
		if (!sent) {
			return false;
		}

		return true;	
	}

	function setMainBnbPoolSize(uint256 size) public onlyOwner {
		require(size >= 10 ether, "Size is too small");
		_mainBnbPoolSize = size;
	}


	function isInRewardClaimQueue(address addr) public view returns(bool) {
		return _addressesInRewardClaimQueue[addr];
	}

	
	function reimburseAfterTIKIFIREClaimFailure() public view returns(bool) {
		return _reimburseAfterTIKIFIREClaimFailure;
	}


	function setReimburseAfterTIKIFIREClaimFailure(bool value) public onlyOwner {
		_reimburseAfterTIKIFIREClaimFailure = value;
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