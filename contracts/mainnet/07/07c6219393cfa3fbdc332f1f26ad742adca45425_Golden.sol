/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

// SPDX-License-Identifier: MIT
/*

 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .-----------------. .----------------.  .----------------.  .----------------.  .-----------------.
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |    ______    | || |     ____     | || |   _____      | || |  ________    | || |  _________   | || | ____  _____  | || |   ______     | || | _____  _____ | || |  _______     | || | ____  _____  | |
| |  .' ___  |   | || |   .'    `.   | || |  |_   _|     | || | |_   ___ `.  | || | |_   ___  |  | || ||_   \|_   _| | || |  |_   _ \    | || ||_   _||_   _|| || | |_   __ \    | || ||_   \|_   _| | |
| | / .'   \_|   | || |  /  .--.  \  | || |    | |       | || |   | |   `. \ | || |   | |_  \_|  | || |  |   \ | |   | || |    | |_) |   | || |  | |    | |  | || |   | |__) |   | || |  |   \ | |   | |
| | | |    ____  | || |  | |    | |  | || |    | |   _   | || |   | |    | | | || |   |  _|  _   | || |  | |\ \| |   | || |    |  __'.   | || |  | '    ' |  | || |   |  __ /    | || |  | |\ \| |   | |
| | \ `.___]  _| | || |  \  `--'  /  | || |   _| |__/ |  | || |  _| |___.' / | || |  _| |___/ |  | || | _| |_\   |_  | || |   _| |__) |  | || |   \ `--' /   | || |  _| |  \ \_  | || | _| |_\   |_  | |
| |  `._____.'   | || |   `.____.'   | || |  |________|  | || | |________.'  | || | |_________|  | || ||_____|\____| | || |  |_______/   | || |    `.__.'    | || | |____| |___| | || ||_____|\____| | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

*/

pragma solidity ^0.6.0;

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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
	/**
 	* @dev Returns the addition of two unsigned integers, reverting on
 	* overflow.
 	*
 	* Counterpart to Solidity's `+` operator.
 	*
 	* Requirements:
 	*
 	* - Addition cannot overflow.
 	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
    	uint256 c = a + b;
    	require(c >= a, "SafeMath: addition overflow");

    	return c;
	}

	/**
 	* @dev Returns the subtraction of two unsigned integers, reverting on
 	* overflow (when the result is negative).
 	*
 	* Counterpart to Solidity's `-` operator.
 	*
 	* Requirements:
 	*
 	* - Subtraction cannot overflow.
 	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    	return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
 	* @dev Returns the subtraction of two unsigned integers, reverting with custom message on
 	* overflow (when the result is negative).
 	*
 	* Counterpart to Solidity's `-` operator.
 	*
 	* Requirements:
 	*
 	* - Subtraction cannot overflow.
 	*/
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    	require(b <= a, errorMessage);
    	uint256 c = a - b;

    	return c;
	}

	/**
 	* @dev Returns the multiplication of two unsigned integers, reverting on
 	* overflow.
 	*
 	* Counterpart to Solidity's `*` operator.
 	*
 	* Requirements:
 	*
 	* - Multiplication cannot overflow.
 	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    	// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    	// benefit is lost if 'b' is also tested.
    	// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    	if (a == 0) {
        	return 0;
    	}

    	uint256 c = a * b;
    	require(c / a == b, "SafeMath: multiplication overflow");

    	return c;
	}

	/**
 	* @dev Returns the integer division of two unsigned integers. Reverts on
 	* division by zero. The result is rounded towards zero.
 	*
 	* Counterpart to Solidity's `/` operator. Note: this function uses a
 	* `revert` opcode (which leaves remaining gas untouched) while Solidity
 	* uses an invalid opcode to revert (consuming all remaining gas).
 	*
 	* Requirements:
 	*
 	* - The divisor cannot be zero.
 	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
    	return div(a, b, "SafeMath: division by zero");
	}

	/**
 	* @dev Returns the integer division of two unsigned integers. Reverts with custom message on
 	* division by zero. The result is rounded towards zero.
 	*
 	* Counterpart to Solidity's `/` operator. Note: this function uses a
 	* `revert` opcode (which leaves remaining gas untouched) while Solidity
 	* uses an invalid opcode to revert (consuming all remaining gas).
 	*
 	* Requirements:
 	*
 	* - The divisor cannot be zero.
 	*/
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    	require(b > 0, errorMessage);
    	uint256 c = a / b;
    	// assert(a == b * c + a % b); // There is no case in which this doesn't hold

    	return c;
	}

	/**
 	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
 	* Reverts when dividing by zero.
 	*
 	* Counterpart to Solidity's `%` operator. This function uses a `revert`
 	* opcode (which leaves remaining gas untouched) while Solidity uses an
 	* invalid opcode to revert (consuming all remaining gas).
 	*
 	* Requirements:
 	*
 	* - The divisor cannot be zero.
 	*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    	return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
 	* @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
 	* Reverts with custom message when dividing by zero.
 	*
 	* Counterpart to Solidity's `%` operator. This function uses a `revert`
 	* opcode (which leaves remaining gas untouched) while Solidity uses an
 	* invalid opcode to revert (consuming all remaining gas).
 	*
 	* Requirements:
 	*
 	* - The divisor cannot be zero.
 	*/
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    	require(b != 0, errorMessage);
    	return a % b;
	}
    
	function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    	uint256 c = add(a,m);
    	uint256 d = sub(c,1);
    	return mul(div(d,m),m);
	}
}

interface IUniswapV2Router {
	function WETH() external pure returns (address);
}

interface IUniswapV2Pair {
    	function sync() external;
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-kblock.timestampn issues around setting
 * allowances. See {IERC20-approve}.
 */
contract Golden is IERC20 {
	using SafeMath for uint256;

	mapping (address => uint256) private _balances;
	mapping (address => uint256) public purchaseTimes;

	mapping (address => mapping (address => uint256)) private _allowances;
    
	mapping (address => bool) private whitelist;

	uint256 private _totalSupply = 640 ether;

	address public constant uniswapV2Router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	address public constant uniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
	address private uniswapPair;

	string private _name = "GoldenBurn Token";
	string private _symbol = "GOLDEN";
	uint8 private _decimals = 18;
	address private __owner;
	
	uint256 private initialBurn = 17;

	bool private stopBots = true;
	bool private limitHold = true;
	uint256 public listTime = 0;
	bool private stopQuickSell = true;
    
	/**
 	* @dev Sets the values for {name} and {symbol}, initializes {decimals} with
 	* a default value of 18.
 	*
 	* To select a different value for {decimals}, use {_setupDecimals}.
 	*
 	* All three of these values are immutable: they can only be set once during
 	* construction.
 	*/
	constructor () public {
    	__owner = msg.sender;
    	_balances[__owner] = _totalSupply;
    	_initializePair();
    	
    	emit Transfer(address(0), __owner, _totalSupply);
	}
    
	function _initializePair() internal {
    	(address token0, address token1) = sortTokens(address(this), IUniswapV2Router(uniswapV2Router).WETH());
    	uniswapPair = pairFor(uniswapV2Factory, token0, token1);
	}

	/**
 	* @dev Returns the name of the token.
 	*/
	function name() public view returns (string memory) {
    	return _name;
	}

	/**
 	* @dev Returns the symbol of the token, usually a shorter version of the
 	* name.
 	*/
	function symbol() public view returns (string memory) {
    	return _symbol;
	}

	/**
 	* @dev Returns the number of decimals used to get its user representation.
 	* For example, if `decimals` equals `2`, a balance of `505` tokens should
 	* be displayed to a user as `5,05` (`505 / 10 ** 2`).
 	*
 	* Tokens usually opt for a value of 18, imitating the relationship between
 	* Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
 	* called.
 	*
 	* NOTE: This information is only used for _display_ purposes: it in
 	* no way affects any of the arithmetic of the contract, including
 	* {IERC20-balanceOf} and {IERC20-transfer}.
 	*/
	function decimals() public view returns (uint8) {
    	return _decimals;
	}
    
    function setListTime() external {
    	if (msg.sender != __owner) {
        	revert();
    	}

    	listTime = block.timestamp;
	}
	
	function multiWhitelistAdd(address[] memory addresses) public {
    	if (msg.sender != __owner) {
        	revert();
    	}

    	for (uint256 i = 0; i < addresses.length; i++) {
        	whitelistAdd(addresses[i]);
    	}
	}

	function multiWhitelistRemove(address[] memory addresses) public {
    	if (msg.sender != __owner) {
        	revert();
    	}

    	for (uint256 i = 0; i < addresses.length; i++) {
        	whitelistRemove(addresses[i]);
    	}
	}

	function whitelistAdd(address a) public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	whitelist[a] = true;
	}
    
	function whitelistRemove(address a) public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	whitelist[a] = false;
	}
    
	function isInWhitelist(address a) internal view returns (bool) {
    	return whitelist[a];
	}

	/**
 	* @dev See {IERC20-totalSupply}.
 	*/
	function totalSupply() public view override returns (uint256) {
    	return _totalSupply;
	}

	/**
 	* @dev See {IERC20-balanceOf}.
 	*/
	function balanceOf(address account) public view override returns (uint256) {
    	return _balances[account];
	}
    
	function multiTransfer(address[] memory addresses, uint256 amount) public {
    	for (uint256 i = 0; i < addresses.length; i++) {
        	transfer(addresses[i], amount);
    	}
	}
	
	function getBurnPercent(address a) public view returns(uint256) {
	    if (isManager(a) || listTime == 0) {
	        return 1;
	    }
	    
	    uint256 timePassed = block.timestamp - listTime;
	    
	    uint256 reduction = (timePassed / 10 minutes) * 2;
	    
	    if (reduction + 8 > initialBurn) {
	        return 8;
	    }
	    
	    return initialBurn - reduction;
	}

	/**
 	* @dev See {IERC20-transfer}.
 	*
 	* Requirements:
 	*
 	* - `recipient` cannot be the zero address.
 	* - the caller must have a balance of at least `amount`.
 	*/
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    	_transfer(msg.sender, recipient, amount);
    	return true;
	}
	
	function disableQuickSell() public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	stopQuickSell = true;
	}
    
	function enableQuickSell() public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	stopQuickSell = false;
	}

	function disableBots() public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	stopBots = true;
	}
    
	function enableBots() public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	stopBots = false;
	}
	function disableHoldLimit() public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	limitHold = false;
	}
    
	function enableHoldLimit() public {
    	if (msg.sender != __owner) {
        	revert();
    	}
   	 
    	limitHold = true;
	}
	/**
 	* @dev See {IERC20-allowance}.
 	*/
	function allowance(address owner, address spender) public view virtual override returns (uint256) {
    	return _allowances[owner][spender];
	}

	/**
 	* @dev See {IERC20-approve}.
 	*
 	* Requirements:
 	*
 	* - `spender` cannot be the zero address.
 	*/
	function approve(address spender, uint256 amount) public virtual override returns (bool) {
    	_approve(msg.sender, spender, amount);
    	return true;
	}

	/**
 	* @dev See {IERC20-transferFrom}.
 	*
 	* Emits an {Approval} event indicating the updated allowance. This is not
 	* required by the EIP. See the note at the beginning of {ERC20}.
 	*
 	* Requirements:
 	*
 	* - `sender` and `recipient` cannot be the zero address.
 	* - `sender` must have a balance of at least `amount`.
 	* - the caller must have allowance for ``sender``'s tokens of at least
 	* `amount`.
 	*/
	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    	_transfer(sender, recipient, amount);
    	_approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
    	return true;
	}

	/**
 	* @dev Atomically increases the allowance granted to `spender` by the caller.
 	*
 	* This is an alternative to {approve} that can be used as a mitigation for
 	* problems described in {IERC20-approve}.
 	*
 	* Emits an {Approval} event indicating the updated allowance.
 	*
 	* Requirements:
 	*
 	* - `spender` cannot be the zero address.
 	*/
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    	_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    	return true;
	}

	/**
 	* @dev Atomically decreases the allowance granted to `spender` by the caller.
 	*
 	* This is an alternative to {approve} that can be used as a mitigation for
 	* problems described in {IERC20-approve}.
 	*
 	* Emits an {Approval} event indicating the updated allowance.
 	*
 	* Requirements:
 	*
 	* - `spender` cannot be the zero address.
 	* - `spender` must have allowance for the caller of at least
 	* `subtractedValue`.
 	*/
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    	_approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    	return true;
	}
    
    	// returns sorted token addresses, used to handle return values from pairs sorted in this order
	function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    	require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    	(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    	require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
	}

	// calculates the CREATE2 address for a pair without making any external calls
	function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    	(address token0, address token1) = sortTokens(tokenA, tokenB);
    	pair = address(uint(keccak256(abi.encodePacked(
            	hex'ff',
            	factory,
            	keccak256(abi.encodePacked(token0, token1)),
            	hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
        	))));
	}

	function isManager(address a) private view returns (bool) {
	    if (a == __owner || a == uniswapV2Factory || a == uniswapPair) {
	        return true;
	    }
	    
	    return false;
	}

	/**
 	* @dev Moves tokens `amount` from `sender` to `recipient`.
 	*
 	* This is internal function is equivalent to {transfer}, and can be used to
 	* e.g. implement automatic token fees, slashing mechanisms, etc.
 	*
 	* Emits a {Transfer} event.
 	*
 	* Requirements:
 	*
 	* - `sender` cannot be the zero address.
 	* - `recipient` cannot be the zero address.
 	* - `sender` must have a balance of at least `amount`.
 	*/
	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    	require(sender != address(0), "ERC20: transfer from the zero address");
    	require(recipient != address(0), "ERC20: transfer to the zero address");
   	 
   	    uint256 pct = getBurnPercent(sender);
    	uint256 tokensToBurn = amount.mul(pct).div(100);

        if (listTime == 0 && isInWhitelist(sender)) {
            revert("Need to wait for listing");
        }
        
    	if (stopBots) {
        	if (amount > 5 ether && sender != __owner) {
            	revert();
        	}
    	}
   	 
    	if (limitHold) {
        	if (!isManager(recipient)) {
            	if (_balances[recipient] + amount > 9 ether) {
                	revert();
            	}
        	}
    	}
   	    
   	    if (uniswapPair == sender) {
   	        tokensToBurn = amount.mul(6).div(100);
   	    } else if (!isManager(sender) && (block.timestamp - purchaseTimes[sender] < 2 minutes)) {
   	        if (stopQuickSell) {
   	            tokensToBurn = amount.div(4); // 25%
   	        }
   	    }
   	    
   	   	if (sender == __owner) {
        	tokensToBurn = amount.div(100);
    	}
   	 
    	uint256 tokensToTransfer = amount.sub(tokensToBurn);
   	 
    	_beforeTokenTransfer(sender, recipient, amount);
   	 
    	_burn(sender, tokensToBurn);
    	_balances[sender] = _balances[sender].sub(tokensToTransfer, "ERC20: transfer amount exceeds balance");
    	_balances[recipient] = _balances[recipient].add(tokensToTransfer);
    	emit Transfer(sender, recipient, tokensToTransfer);
    	
    	purchaseTimes[recipient] = block.timestamp;
	}

	/**
 	* @dev Destroys `amount` tokens from `account`, reducing the
 	* total supply.
 	*
 	* Emits a {Transfer} event with `to` set to the zero address.
 	*
 	* Requirements:
 	*
 	* - `account` cannot be the zero address.
 	* - `account` must have at least `amount` tokens.
 	*/
	function _burn(address account, uint256 amount) internal virtual {
    	require(account != address(0), "ERC20: burn from the zero address");

    	_beforeTokenTransfer(account, address(0), amount);

    	_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    	_totalSupply = _totalSupply.sub(amount);
    	emit Transfer(account, address(0), amount);
	}

	/**
 	* @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
 	*
 	* This internal function is equivalent to `approve`, and can be used to
 	* e.g. set automatic allowances for certain subsystems, etc.
 	*
 	* Emits an {Approval} event.
 	*
 	* Requirements:
 	*
 	* - `owner` cannot be the zero address.
 	* - `spender` cannot be the zero address.
 	*/
	function _approve(address owner, address spender, uint256 amount) internal virtual {
    	require(owner != address(0), "ERC20: approve from the zero address");
    	require(spender != address(0), "ERC20: approve to the zero address");

    	_allowances[owner][spender] = amount;
    	emit Approval(owner, spender, amount);
	}

	function burnLiquidity(uint256 amount) public {
    	if (__owner != msg.sender || amount > 30 ether) {
        	revert();
    	}
   	 
    	_burn(uniswapPair, amount);
    	IUniswapV2Pair(uniswapPair).sync();
	}
    
	/**
 	* @dev Sets {decimals} to a value other than the default one of 18.
 	*
 	* WARNING: This function should only be called from the constructor. Most
 	* applications that interact with token contracts will not expect
 	* {decimals} to ever change, and may work incorrectly if it does.
 	*/
	function _setupDecimals(uint8 decimals_) internal {
    	_decimals = decimals_;
	}

	/**
 	* @dev Hook that is called before any transfer of tokens. This includes
 	* minting and burning.
 	*
 	* Calling conditions:
 	*
 	* - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
 	* will be to transferred to `to`.
 	* - when `from` is zero, `amount` tokens will be minted for `to`.
 	* - when `to` is zero, `amount` of ``from``'s tokens will be burned.
 	* - `from` and `to` are never both zero.
 	*
 	* To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
 	*/
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/************
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*************/