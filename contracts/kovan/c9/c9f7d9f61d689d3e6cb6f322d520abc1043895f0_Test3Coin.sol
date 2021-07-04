// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./lib/Context.sol";
import "./lib/Ownable.sol";
import "./lib/Address.sol";
import "./TestMetaData.sol";

contract Test3Coin is Ownable, TestMetaData {
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);
	event SwapAndLiquifyStateUpdate(bool state);

	/**
	 *@dev Adds the Address library utility methods to the type {address}.
	 */
	using Address for address;

	/**
	 *@dev the maximum uint256 value in solidity, which is used to convert the total supply of tokens to reflections for the reward mechanism.
	 */
	uint256 private constant MAX_INT_VALUE = type(uint256).max;

	uint256 private _tokenSupply = 10**9 * 10**18;
	/**
	 *@dev Convert the total supply to reflections with perfect rouding using the maximum uint256 as the numerator.
	 */
	uint256 private _reflectionSupply = (MAX_INT_VALUE -
		(MAX_INT_VALUE % _tokenSupply));

	/**
	 *@dev The total amount of fees paid by the users.
	 */
	uint256 private _totalTokenFees;

	/**
	 *@dev The transaction fee users will incur upon selling the token. 2 percent of the principal.
	 */
	uint8 public taxFee = 2;
	/**
	 *@dev The wallet which holds the account balance in reflections.
	 */
	mapping(address => uint256) private _reflectionBalance;

	/**
	 *@dev Accounts which are excluded from paying txs fees.
	 */
	mapping(address => bool) private _isExcludedFromFees;

	/**
	 *@dev Contains the allowances a parent account has provided to children accounts in reflections;
	 */
	mapping(address => mapping(address => uint256)) private _allowances;

	/**
	 *@dev A maximum amount that can be transfered at once. Which is equivalent to 0.5% of the total supply.
	 */
	uint256 public maxTxAmount = 5 * 10**6 * 10**18;

	/**
	 *@dev Number of tokens needed to provide liquidity to the pool
	 */
	uint256 private _numberTokensSellToAddToLiquidity = 5 * 10**6 * 10**18;

	/**
	 *@dev State indicating that we are in a liquefaction process to prevent stacking liquefaction events.
	 */
	bool swapAndLiquifyingInProgress;

	/**
	 *@dev Variable to allow the owner to enable or disable liquefaction  events
	 */
	bool public isSwapAndLiquifyingEnabled = false;

	bool public startTrading = false;

		bool public catchWhales = true;

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2WETHPair;

	address public immutable fireFund;

	  constructor(address routerAddress, address fireFundAddress) {
		/**
		 *@dev Gives all the reflection to the deplyer (the first owner) of the contract upon creation.
		 */
		_reflectionBalance[_msgSender()] = _reflectionSupply;

		// Tells solidity this address follows the IUniswapV2Router interface
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);

		// Creates a pair between our token and WETH and saves the address in a state variable
		uniswapV2WETHPair = IUniswapV2Factory(_uniswapV2Router.factory())
			.createPair(address(this), _uniswapV2Router.WETH());

		// Saves the UniswapV2Router in a state variable
		uniswapV2Router = _uniswapV2Router;

		fireFund = fireFundAddress;

		_isExcludedFromFees[owner()] = true;
		_isExcludedFromFees[address(this)] = true;
		_isExcludedFromFees[fireFundAddress] = true;

		emit Transfer(address(0), _msgSender(), _tokenSupply);
	}

	/**
	 *@dev Tell the contract we are swapping
	 */
	modifier lockTheSwap {
		swapAndLiquifyingInProgress = true;
		_;
		swapAndLiquifyingInProgress = false;
	}

	/**
	 *@dev returns the total supply of tokens.
	 */
	function totalSupply() external view override returns (uint256) {
		return _tokenSupply;
	}

	/**
	 *@dev Returns the rate betweenthe total reflections and the total tokens.
	 */
	function _getRate() private view returns (uint256) {
		return _reflectionSupply / _tokenSupply;
	}

	/**
	 *@dev Converts an amount of tokens to reflections using the current rate.
	 */
	function _reflectionFromToken(uint256 amount)
		private
		view
		returns (uint256)
	{
		require(
			_tokenSupply >= amount,
			"You cannot own more tokens than the total token supply"
		);
		return amount * _getRate();
	}

	/**
	 *@dev Converts an amount of reflections to tokens using the current rate.
	 */
	function _tokenFromReflection(uint256 reflectionAmount)
		private
		view
		returns (uint256)
	{
		require(
			_reflectionSupply >= reflectionAmount,
			"Cannot have a personal reflection amount larger than total reflection"
		);
		return reflectionAmount / _getRate();
	}

	/**
	 *@dev returns the total tokens a user holds. It first finds the reflections and converts to tokens to reflect the rewards the user has accrued over time.
	 * if the account does not receive rewards. It returns the balance from the token balance.
	 */
	function balanceOf(address account) public view override returns (uint256) {
		return _tokenFromReflection(_reflectionBalance[account]);
	}

	function totalFees() external view returns (uint256) {
		return _totalTokenFees;
	}

	/**
	 *@dev It allows a non excluded account to airdrop to other users.
	 */
	function deliver(uint256 amount) public {
		address sender = _msgSender();
		uint256 reflectionAmount = _reflectionFromToken(amount);
		_reflectionBalance[sender] =
			_reflectionBalance[sender] -
			reflectionAmount;
		_reflectionSupply -= reflectionAmount;
		_totalTokenFees += amount;
	}

	/**
	 *@dev Removes all fees and saves them to be reinstated at a later date.
	 */
	function removeAllFees() private {
		if (taxFee == 0) return;

		taxFee = 0;
	}

	/**
	 *@dev Restores the fees to their previous values.
	 */
	function restoreAllFees() private {
		taxFee = 2;
	}

	/**
	 *@dev Gives the owner of the contract control if the logic to add liquidity to the pool is enabled or not.
	 */
	function enableSwapAndLiquifyingState() external onlyOwner() {
		isSwapAndLiquifyingEnabled = true;
		emit SwapAndLiquifyStateUpdate(true);
	}

	/**
	 *@dev Calculates a fee final amount based on a ratio.
	 *important This funciton only works with values based on token supply and NOT reflection supply.
	 */
	function _calculateFee(uint256 amount, uint8 fee)
		private
		pure
		returns (uint256)
	{
		return (amount * fee) / 100;
	}

	/**
	 *@dev Returns the final amount for the tax.
	 *important This function only works with values based on token supply and NOT reflection supply.
	 */
	function _calculateTax(uint256 amount) private view returns (uint256) {
		return _calculateFee(amount, taxFee);
	}

	/**
	 *@dev Updates the value of the total fees paid and reduces the reflection supply to reward all holders.
	 */
	function _reflectFee(uint256 rfee, uint256 fee) private {
		_reflectionSupply -= rfee;
		_totalTokenFees += fee + fee + fee;
	}

	/**
	 *@dev Stores the liquidity fee in the contract's address
	 */
	function _takeLiquidity(uint256 amount) private {
		_reflectionBalance[address(this)] =
			_reflectionBalance[address(this)] +
			amount;
	}

	/**
	 *@dev This is used to recieve ETH from uniswapv2router when swaping.
	 */
	receive() external payable {}

	/**
	 *@dev Allows a user to transfer his reflections to another user. It taxes the sender by the tax fee while inflating the all tokens value.
	 */
	function _transferToken(
		address sender,
		address recipient,
		uint256 amount,
		bool removeFees
	) private {
		// If this is a feeless transaction. Remove all fees and store them.
		if (removeFees) removeAllFees();

		uint256 rAmount = _reflectionFromToken(amount);

		if (
			sender != owner() &&
			recipient != owner() &&
			catchWhales &&
			recipient != uniswapV2WETHPair
		) {
			require(
				_tokenFromReflection(_reflectionBalance[recipient] + rAmount) <=
					maxTxAmount,
				"No whales allowed right now :)"
			);
		}

		// Because this account comes from a excluded account to an excluded. We only to reduce it's reflections and tokens.
		_reflectionBalance[sender] = _reflectionBalance[sender] - rAmount;

		// Calculates transaction fee
		uint256 tax = _calculateTax(amount);
		uint256 rTax = _reflectionFromToken(tax);

		// Since the recipient is also  excluded. We need to update his reflections and tokens.
		_reflectionBalance[recipient] =
			_reflectionBalance[recipient] +
			rAmount -
			rTax -
			rTax -
			rTax;

		_reflectionBalance[fireFund] = _reflectionBalance[fireFund] + rTax;

		_takeLiquidity(rTax);
		_reflectFee(rTax, tax);

		emit Transfer(sender, recipient, amount - tax * 3);

		// Restores all fees if they were disabled.
		if (removeFees) restoreAllFees();
	}

	/**
	 *@dev buys ETH with tokens stored in this contract
	 */
	function _swapTokensForEth(uint256 tokenAmount) private {
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

	/**
	 *@dev Adds equal amount of eth and tokens to the ETH liquidity pool
	 */
	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		// approve token transfer to cover all possible scenarios
		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// add the liquidity
		uniswapV2Router.addLiquidityETH{ value: ethAmount }(
			address(this),
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			address(0),
			block.timestamp
		);
	}

	function _swapAndLiquefy() private lockTheSwap {
		// split the contract token balance into halves
		uint256 half = _numberTokensSellToAddToLiquidity / 2;
		uint256 otherHalf = _numberTokensSellToAddToLiquidity - half;

		uint256 initialETHContractBalance = address(this).balance;

		// Buys ETH at current token price
		_swapTokensForEth(half);

		// This is to make sure we are only using ETH derived from the liquidity fee
		uint256 ethBought = address(this).balance - initialETHContractBalance;

		// Add liquidity to the pool
		_addLiquidity(otherHalf, ethBought);

		emit SwapAndLiquify(half, ethBought, otherHalf);
	}

	/**
    @dev Function to enable trading
   */
	function enableTrading() external onlyOwner() {
		startTrading = true;
	}

		/**
	@dev Function to allow holders to have more than 0.5% of tokens
	 */
	function freeWhales() external onlyOwner() {
		catchWhales = false;
	}

	/**
	 *@dev This function first adds liquidity to the pool, then transfers tokens between accounts
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) private {
		require(
			sender != address(0),
			"ERC20: Sender cannot be the zero address"
		);
		require(
			recipient != address(0),
			"ERC20: Recipient cannot be the zero address"
		);
		require(amount > 0, "Transfer amount must be greater than zero");
		if (sender != owner() && recipient != owner()) {
			require(
				amount <= maxTxAmount,
				"Transfer amount exceeds the maxTxAmount."
			);

			require(startTrading, "Nice try :)");
		}

		// Condition 1: Make sure the contract has the enough tokens to liquefy
		// Condition 2: We are not in a liquefication event
		// Condition 3: Liquification is enabled
		// Condition 4: It is not the uniswapPair that is sending tokens

		if (
			balanceOf(address(this)) >= _numberTokensSellToAddToLiquidity &&
			!swapAndLiquifyingInProgress &&
			isSwapAndLiquifyingEnabled &&
			sender != uniswapV2WETHPair
		) _swapAndLiquefy();

		_transferToken(
			sender,
			recipient,
			amount,
			_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]
		);
	}

	/**
	 *@dev Gives allowance to an account
	 */
	function _approve(
		address owner,
		address beneficiary,
		uint256 amount
	) private {
		require(
			beneficiary != address(0),
			"The burn address is not allowed to receive approval for allowances."
		);
		require(
			owner != address(0),
			"The burn address is not allowed to approve allowances."
		);

		_allowances[owner][beneficiary] = amount;
		emit Approval(owner, beneficiary, amount);
	}

	function transfer(address recipient, uint256 amount)
		public
		override
		returns (bool)
	{
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function approve(address beneficiary, uint256 amount)
		public
		override
		returns (bool)
	{
		_approve(_msgSender(), beneficiary, amount);
		return true;
	}

	/**
	 *@dev It allows an account to transfer it's allowance to any other account;
	 */
	function transferFrom(
		address provider,
		address beneficiary,
		uint256 amount
	) public override returns (bool) {
		_transfer(provider, beneficiary, amount);
		_approve(
			provider,
			_msgSender(),
			_allowances[provider][_msgSender()] - amount
		);
		return true;
	}

	/**
	 *@dev Shows the allowance of a beneficiary in tokens.
	 */
	function allowance(address owner, address beneficiary)
		public
		view
		override
		returns (uint256)
	{
		return _allowances[owner][beneficiary];
	}

	/**
	 *@dev Increases the allowance of a beneficiary
	 */
	function increaseAllowance(address beneficiary, uint256 amount)
		external
		returns (bool)
	{
		_approve(
			_msgSender(),
			beneficiary,
			_allowances[_msgSender()][beneficiary] + amount
		);
		return true;
	}

	/**
	 *@dev Decreases the allowance of a beneficiary
	 */
	function decreaseAllowance(address beneficiary, uint256 amount)
		external
		returns (bool)
	{
		_approve(
			_msgSender(),
			beneficiary,
			_allowances[_msgSender()][beneficiary] - amount
		);
		return true;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

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
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IUniswapV2Factory {
	event PairCreated(
		address indexed token0,
		address indexed token1,
		address pair,
		uint256
	);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB)
		external
		view
		returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(address tokenA, address tokenB)
		external
		returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Context.sol";

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

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
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

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
	/**
	 * @dev Returns true if `account` is a contract.
	 *
	 * [IMPORTANT]
	 * ====
	 * It is unsafe to assume that an address for which this function returns
	 * false is an externally-owned account (EOA) and not a contract.
	 *
	 * Among others, `isContract` will return false for the following
	 * types of addresses:
	 *
	 *  - an externally-owned account
	 *  - a contract in construction
	 *  - an address where a contract will be created
	 *  - an address where a contract lived, but was destroyed
	 * ====
	 */
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	/**
	 * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
	 * `recipient`, forwarding all available gas and reverting on errors.
	 *
	 * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
	 * of certain opcodes, possibly making contracts go over the 2300 gas limit
	 * imposed by `transfer`, making them unable to receive funds via
	 * `transfer`. {sendValue} removes this limitation.
	 *
	 * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
	 *
	 * IMPORTANT: because control is transferred to `recipient`, care must be
	 * taken to not create reentrancy vulnerabilities. Consider using
	 * {ReentrancyGuard} or the
	 * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
	 */
	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	/**
	 * @dev Performs a Solidity function call using a low level `call`. A
	 * plain`call` is an unsafe replacement for a function call: use this
	 * function instead.
	 *
	 * If `target` reverts with a revert reason, it is bubbled up by this
	 * function (like regular Solidity function calls).
	 *
	 * Returns the raw returned data. To convert to the expected return value,
	 * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
	 *
	 * Requirements:
	 *
	 * - `target` must be a contract.
	 * - calling `target` with `data` must not revert.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	 * `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but also transferring `value` wei to `target`.
	 *
	 * Requirements:
	 *
	 * - the calling contract must have an ETH balance of at least `value`.
	 * - the called Solidity function must be `payable`.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
			functionCallWithValue(
				target,
				data,
				value,
				"Address: low-level call with value failed"
			);
	}

	/**
	 * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	 * with `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) =
			target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(address target, bytes memory data)
		internal
		view
		returns (bytes memory)
	{
		return
			functionStaticCall(
				target,
				data,
				"Address: low-level static call failed"
			);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function functionDelegateCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return
			functionDelegateCall(
				target,
				data,
				"Address: low-level delegate call failed"
			);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				// solhint-disable-next-line no-inline-assembly
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IERC20MetaData.sol";

abstract contract TestMetaData is IERC20Metadata {
	/**
	 *@dev The name of the token managed by the this smart contract.
	 */
	string private _name = "Test3Coin";

	/**
	 *@dev The symbol of the token managed by the this smart contract.
	 */
	string private _symbol = "TESTCOIN";

	/**
	 *@dev The decimals of the token managed by the this smart contract.
	 */
	uint8 private _decimals = 18;

	/**
	 *@dev It returns the name of the token.
	 */
	function name() public view override returns (string memory) {
		return _name;
	}

	/**
	 *@dev It returns the symbol of the token.
	 */
	function symbol() public view override returns (string memory) {
		return _symbol;
	}

	/**
	 *@dev It returns the decimal of the token.
	 */
	function decimals() public view override returns (uint8) {
		return _decimals;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}