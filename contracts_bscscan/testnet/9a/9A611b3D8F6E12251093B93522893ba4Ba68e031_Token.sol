/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
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


abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return payable(address(msg.sender));
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	}
}


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
	address private _previousOwner;
	uint256 private _lockTime;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
		* @dev Initializes the contract setting the deployer as the initial owner.
		*/
	constructor ()  {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	/**
		* @dev Returns the address of the current owner.
		*/
	function owner() public view returns (address) {
		return _owner;
	}

	/**
		* @dev Throws if called by any account other than the owner.
		*/
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}

	function getUnlockTime() public view returns (uint256) {
		return _lockTime;
	}

	//Locks the contract for owner for the amount of time provided
	function lock(uint256 time) public virtual onlyOwner {
		_previousOwner = _owner;
		_owner = address(0);
		_lockTime = block.timestamp + time;
		emit OwnershipTransferred(_owner, address(0));
	}

	//Unlocks the contract for owner when _lockTime is exceeds
	function unlock() public virtual {
		require(_previousOwner == msg.sender, "You don't have permission to unlock the token contract");
		require(block.timestamp > _lockTime , "Contract is locked until 7 days");
		emit OwnershipTransferred(_owner, _previousOwner);
		_owner = _previousOwner;
	}
}


interface IUniswapV2Factory {
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


interface IUniswapV2Router01 {
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


interface IUniswapV2Router02 is IUniswapV2Router01 {
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


contract Token is Context, IERC20, Ownable {

	address dead = 0x000000000000000000000000000000000000dEaD;

	uint8 public maxLiqFee = 10;
	uint8 public maxTaxFee = 10;
	uint8 public maxBurnFee = 10;
	uint8 public maxWalletFee = 10;
	uint8 public maxBuybackFee = 10;
	uint8 public minMxTxPercentage = 1;
	uint8 public minMxWalletPercentage = 1;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	mapping (address => bool) private _isExcludedFromFee;

	mapping (address => bool) private _isExcluded;
	address[] private _excluded;

	//address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;


	uint256 private constant MAX = ~uint256(0);
	uint256 public _tTotal;
	uint256 private _rTotal;
	uint256 private _tFeeTotal;

	string public _name;
	string public _symbol;
	uint8 private _decimals;

	uint8 public _taxFee;
	uint8 private _previousTaxFee;

	uint8 public _liquidityFee;
	uint8 private _previousLiquidityFee;

	uint8 public _burnFee;
	uint8 private _previousBurnFee;

	uint8 public _walletFee;
	uint8 private _previousWalletFee;

	uint8 public _buybackFee;
	uint8 private _previousBuybackFee;

	IUniswapV2Router02 public immutable pcsV2Router;
	address public immutable pcsV2Pair;
	address payable public feeWallet;

	bool inSwapAndLiquify;
	bool public swapAndLiquifyEnabled = true;

	uint256 public _maxTxAmount;
	uint256 public _maxWalletAmount;
	uint256 public numTokensSellToAddToLiquidity;
	uint256 private buyBackUpperLimit = 1 * 10**18;

	event SwapAndLiquifyEnabledUpdated(bool enabled);
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);

	event SetFee(uint256 oldValue, uint256 newValue, string valueName);

	modifier lockTheSwap {
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}

	constructor (
		address tokenOwner,
		string memory tokenName,
		string memory tokenSymbol,
		uint8 decimal,
		uint256 amountOfTokenWei,
		uint8 setMxTxPer,
		uint8 setMxWalletPer,
		address payable _feeWallet
	) payable
	{
		_name = tokenName;
		_symbol = tokenSymbol;
		_decimals = decimal;
		_tTotal = amountOfTokenWei;
		_rTotal = (MAX - (MAX % _tTotal));
		_rOwned[tokenOwner] = _rTotal;
		feeWallet = _feeWallet;

		_maxTxAmount = _tTotal*(setMxTxPer)/(10**2);
		_maxWalletAmount = _tTotal*(setMxWalletPer)/(10**2);
		numTokensSellToAddToLiquidity = amountOfTokenWei/1000;

		IUniswapV2Router02 _pcsV2Router = IUniswapV2Router02(router);

		// Create a uniswap pair for this new token
		pcsV2Pair = IUniswapV2Factory(_pcsV2Router.factory()).createPair(address(this), _pcsV2Router.WETH());

		// set the rest of the contract variables
		pcsV2Router = _pcsV2Router;

		_isExcludedFromFee[tokenOwner] = true;
		_isExcludedFromFee[address(this)] = true;

		emit Transfer(address(0), tokenOwner, _tTotal);
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcluded[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + (addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
		return true;
	}

	function isExcludedFromReward(address account) public view returns (bool) {
		return _isExcluded[account];
	}

	function totalFees() public view returns (uint256) {
		return _tFeeTotal;
	}

	function deliver(uint256 tAmount) public {
		address sender = _msgSender();
		require(!_isExcluded[sender], "Excluded addresses cannot call this function");
		(uint256 rAmount,,,,,) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender] - (rAmount);
		_rTotal = _rTotal - (rAmount);
		_tFeeTotal = _tFeeTotal + (tAmount);
	}

	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
		require(tAmount <= _tTotal, "Amt must be less than supply");
		if (!deductTransferFee) {
			(uint256 rAmount,,,,,) = _getValues(tAmount);
			return rAmount;
		} else {
			(,uint256 rTransferAmount,,,,) = _getValues(tAmount);
			return rTransferAmount;
		}
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "Amt must be less than tot refl");
		uint256 currentRate =  _getRate();
		return rAmount / currentRate;
	}

	function excludeFromReward(address account) public onlyOwner() {
		require(!_isExcluded[account], "Account is already excluded from reward");
		if (_rOwned[account] > 0)
			_tOwned[account] = tokenFromReflection(_rOwned[account]);
		_isExcluded[account] = true;
		_excluded.push(account);
	}

	function includeInReward(address account) external onlyOwner() {
		require(_isExcluded[account], "Already excluded");
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_excluded[i] == account) {
				_excluded[i] = _excluded[_excluded.length - 1];
				_tOwned[account] = 0;
				_isExcluded[account] = false;
				_excluded.pop();
				break;
			}
		}
	}


	function excludeFromFee(address account) public onlyOwner {
		require(!_isExcludedFromFee[account], "Already excluded");
		_isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		require(_isExcludedFromFee[account], "Already included");
		_isExcludedFromFee[account] = false;
	}

	function set_taxFee(uint8 taxFee) external onlyOwner() {
		require(taxFee >= 0 && taxFee <= maxTaxFee && taxFee != _taxFee,"TF err");
		emit SetFee(_taxFee, taxFee, "Set taxFee");
		_taxFee = taxFee;
	}

	function set_liquidityFee(uint8 liquidityFee) external onlyOwner() {
		require(liquidityFee >= 0 && liquidityFee <= maxLiqFee && liquidityFee != _liquidityFee,"LF err");
		emit SetFee(_liquidityFee, liquidityFee, "Set liquidityFee");
		_liquidityFee = liquidityFee;
	}

	function set_burnFee(uint8 burnFee) external onlyOwner() {
		require(burnFee >= 0 && burnFee <= maxBurnFee && burnFee != _burnFee,"BF err");
		emit SetFee(_burnFee, burnFee, "Set burnFee");
		_burnFee = burnFee;
	}

	function set_walletFee(uint8 walletFee) external onlyOwner() {
		require(walletFee >= 0 && walletFee <= maxWalletFee && walletFee != _walletFee ,"WF err");
		emit SetFee(_walletFee, walletFee, "Set walletFee");
		_walletFee = walletFee;
	}

	function set_buybackFee(uint8 buybackFee) external onlyOwner() {
		require(buybackFee >= 0 && buybackFee <= maxBuybackFee && buybackFee != _buybackFee,"BBF err");
		emit SetFee(_buybackFee, buybackFee, "Set buybackFee");
		_buybackFee = buybackFee;
	}

	function setAllFeePercent(uint8 taxFee, uint8 liquidityFee, uint8 burnFee, uint8 walletFee, uint8 buybackFee)
	external
	onlyOwner()
	{
		require(taxFee >= 0 && taxFee <= maxTaxFee,"TF err");
		require(liquidityFee >= 0 && liquidityFee <= maxLiqFee,"LF err");
		require(burnFee >= 0 && burnFee <= maxBurnFee,"BF err");
		require(walletFee >= 0 && walletFee <= maxWalletFee,"WF err");
		require(buybackFee >= 0 && buybackFee <= maxBuybackFee,"BBF err");
		_taxFee = taxFee;
		_liquidityFee = liquidityFee;
		_burnFee = burnFee;
		_buybackFee = buybackFee;
		_walletFee = walletFee;
	}

	function buyBackUpperLimitAmount() public view returns (uint256) {
		return buyBackUpperLimit;
	}

	function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
		buyBackUpperLimit = buyBackLimit * 10**18;
	}

	function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
		require(maxTxPercent >= minMxTxPercentage && maxTxPercent <= 100,"err");
		_maxTxAmount = _tTotal * maxTxPercent / (10**2);
	}

	function setMaxWalletPercent(uint256 maxWalletPercent) external onlyOwner() {
		require(maxWalletPercent >= minMxWalletPercentage && maxWalletPercent <= 100,"err");
		_maxWalletAmount = _tTotal * maxWalletPercent / (10**2);
	}

	function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
		require(_enabled != swapAndLiquifyEnabled);
		swapAndLiquifyEnabled = _enabled;
		emit SwapAndLiquifyEnabledUpdated(_enabled);
	}

	function setFeeWallet(address payable newFeeWallet) external onlyOwner {
		require(newFeeWallet != feeWallet);
		require(newFeeWallet != address(0), "ZERO ADDRESS");
		feeWallet = newFeeWallet;
	}

	receive() external payable {}

	function _reflectFee(uint256 rFee, uint256 tFee) private {
		_rTotal = _rTotal - rFee;
		_tFeeTotal = _tFeeTotal + tFee;
	}

	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		(uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
		return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
	}

	function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
		uint256 tFee = calculateTaxFee(tAmount);
		uint256 tLiquidity = calculateLiquidityFee(tAmount);
		uint256 tTransferAmount = tAmount - tFee - tLiquidity;
		return (tTransferAmount, tFee, tLiquidity);
	}

	function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private
	pure
	returns (
		uint256, uint256, uint256
	)
	{
		uint256 rAmount = tAmount * currentRate;
		uint256 rFee = tFee * currentRate;
		uint256 rLiquidity = tLiquidity * currentRate;
		uint256 rTransferAmount = rAmount - rFee - rLiquidity;
		return (rAmount, rTransferAmount, rFee);
	}

	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply / tSupply;
	}

	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;

		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
			rSupply = rSupply - _rOwned[_excluded[i]];
			tSupply = tSupply - _tOwned[_excluded[i]];
		}
		if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}

	function _takeLiquidity(uint256 tLiquidity) private {
		uint256 currentRate =  _getRate();
		uint256 rLiquidity = tLiquidity * (currentRate);
		_rOwned[address(this)] = _rOwned[address(this)] + (rLiquidity);

		if (_isExcluded[address(this)])
			_tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
	}

	function calculateTaxFee(uint256 _amount) private view returns (uint256) {
		return (_amount * _taxFee) / (10**2);
	}

	function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
		return _amount * (_liquidityFee + _burnFee + _walletFee + _buybackFee) / (10**2);
	}

	function removeAllFee() private {
		if (_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0 && _walletFee == 0 && _buybackFee == 0) return;

		_previousTaxFee = _taxFee;
		_previousLiquidityFee = _liquidityFee;
		_previousBurnFee = _burnFee;
		_previousWalletFee = _walletFee;
		_previousBuybackFee = _buybackFee;

		_taxFee = 0;
		_liquidityFee = 0;
		_burnFee = 0;
		_walletFee = 0;
		_buybackFee = 0;
	}

	function restoreAllFee() private {
		_taxFee = _previousTaxFee;
		_liquidityFee = _previousLiquidityFee;
		_burnFee = _previousBurnFee;
		_walletFee = _previousWalletFee;
		_buybackFee = _previousBuybackFee;
	}

	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from zero address");
		require(spender != address(0), "ERC20: approve to zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	)
	private
	{
		require(from != address(0), "ERC20: transfer from zero address");
		require(to != address(0), "ERC20: transfer to zero address");
		require(amount > 0, "Transfer amount must be greater than zero");

		if (from != owner() && to != owner())
			require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

		if (from != owner() && to != owner() && to != address(0) && to != dead && to != pcsV2Pair){
			uint256 contractBalanceRecepient = balanceOf(to);
			require(contractBalanceRecepient + amount <= _maxWalletAmount, "Exceeds maximum wallet amount");
		}
		// is the token balance of this contract address over the min number of
		// tokens that we need to initiate a swap + liquidity lock?
		// also, don't get caught in a circular liquidity event.
		// also, don't swap & liquify if sender is uniswap pair.
		uint256 contractTokenBalance = balanceOf(address(this));

		if (contractTokenBalance >= _maxTxAmount)
			contractTokenBalance = _maxTxAmount;

		bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
		if (
			!inSwapAndLiquify &&
		to == pcsV2Pair &&
		swapAndLiquifyEnabled
		)
		{
			if (overMinTokenBalance){
				contractTokenBalance = numTokensSellToAddToLiquidity;
				//add liquidity
				swapAndLiquify(contractTokenBalance);
			}
			if (_buybackFee !=0) {
				uint256 balance = address(this).balance;

				if (balance > uint256(1 * 10**18)) {
					if (balance > buyBackUpperLimit)
						balance = buyBackUpperLimit;

					buyBackTokens(balance / (100));
				}
			}

		}

		//indicates if fee should be deducted from transfer
		bool takeFee = true;

		//if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}

		//transfer amount, it will take tax, burn, liquidity fee
		_tokenTransfer(from,to,amount,takeFee);
	}

	function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
		//This needs to be distributed among burn, wallet and liquidity
		//burn
		uint8 totFee  = _burnFee + _walletFee + _liquidityFee + _buybackFee;
		uint256 spentAmount = 0;
		uint256 totSpentAmount = 0;

		if (_burnFee != 0) {
			spentAmount  = contractTokenBalance * _burnFee / totFee;
			_tokenTransferNoFee(address(this), dead, spentAmount);
			totSpentAmount = spentAmount;
		}

		if (_walletFee != 0) {
			spentAmount = (contractTokenBalance * _walletFee) / totFee;
			_tokenTransferNoFee(address(this), feeWallet, spentAmount);
			totSpentAmount = totSpentAmount + spentAmount;
		}

		if (_buybackFee != 0) {
			spentAmount = (contractTokenBalance * _buybackFee) / totFee;
			swapTokensForBNB(spentAmount);
			totSpentAmount = totSpentAmount + spentAmount;
		}

		if (_liquidityFee != 0) {
			contractTokenBalance = contractTokenBalance - totSpentAmount;

			// split the contract balance into halves
			uint256 half = contractTokenBalance / 2;
			uint256 otherHalf = contractTokenBalance - half;

			// capture the contract's current ETH balance.
			// this is so that we can capture exactly the amount of ETH that the
			// swap creates, and not make the liquidity event include any ETH that
			// has been manually sent to the contract
			uint256 initialBalance = address(this).balance;

			// swap tokens for ETH
			swapTokensForBNB(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

			// how much ETH did we just swap into?
			uint256 newBalance = address(this).balance - initialBalance;

			// add liquidity to uniswap
			addLiquidity(otherHalf, newBalance);

			emit SwapAndLiquify(half, newBalance, otherHalf);
		}
	}

	function buyBackTokens(uint256 amount) private lockTheSwap {
		if (amount > 0) {
			swapBNBForTokens(amount);
		}
	}

	function swapTokensForBNB(uint256 tokenAmount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = pcsV2Router.WETH();

		_approve(address(this), address(pcsV2Router), tokenAmount);

		// make the swap
		pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function swapBNBForTokens(uint256 amount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = pcsV2Router.WETH();
		path[1] = address(this);

		// make the swap
		pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
			0, // accept any amount of Tokens
			path,
			dead, // Burn address
			block.timestamp + 300
		);
	}

	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		// approve token transfer to cover all possible scenarios
		_approve(address(this), address(pcsV2Router), tokenAmount);

		// add the liquidity
		pcsV2Router.addLiquidityETH{value: ethAmount}(
			address(this),
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			dead,
			block.timestamp
		);
	}

	//this method is responsible for taking all fee, if takeFee is true
	function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
		if (!takeFee)
			removeAllFee();

		if (_isExcluded[sender] && !_isExcluded[recipient]) {
			_transferFromExcluded(sender, recipient, amount);
		} else if (!_isExcluded[sender] && _isExcluded[recipient]) {
			_transferToExcluded(sender, recipient, amount);
		} else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
			_transferStandard(sender, recipient, amount);
		} else if (_isExcluded[sender] && _isExcluded[recipient]) {
			_transferBothExcluded(sender, recipient, amount);
		} else {
			_transferStandard(sender, recipient, amount);
		}

		if(!takeFee)
			restoreAllFee();
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity)
		= _getValues(tAmount);

		_rOwned[sender] = _rOwned[sender] - rAmount;
		_rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);

		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity)
		= _getValues(tAmount);

		_rOwned[sender] = _rOwned[sender] - rAmount;
		_tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
		_rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);

		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity)
		= _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender] - tAmount;
		_rOwned[sender] = _rOwned[sender] - rAmount;
		_rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);

		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity)
		= _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender] - tAmount;
		_rOwned[sender] = _rOwned[sender] - rAmount;
		_tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
		_rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
		_takeLiquidity(tLiquidity);
		_reflectFee(rFee, tFee);

		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
		uint256 currentRate =  _getRate();
		uint256 rAmount = amount * currentRate;

		_rOwned[sender] = _rOwned[sender] - rAmount;
		_rOwned[recipient] = _rOwned[recipient] + rAmount;

		if (_isExcluded[sender])
			_tOwned[sender] = _tOwned[sender] - amount;
		if (_isExcluded[recipient])
			_tOwned[recipient] = _tOwned[recipient] + amount;

		emit Transfer(sender, recipient, amount);
	}

	function recoverBEP20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
		// do not allow recovering self token
		require(tokenAddress != address(this), "Self withdraw");
		IERC20(tokenAddress).transfer(owner(), tokenAmount);
	}
}