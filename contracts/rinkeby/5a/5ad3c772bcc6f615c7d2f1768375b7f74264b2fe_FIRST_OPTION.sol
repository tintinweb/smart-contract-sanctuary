/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

abstract contract Ownable is Context {

	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor (address _paramOwner) {
		require(_paramOwner != address(0), "Ownable: wrong parameter");
		_owner = _paramOwner;
		emit OwnershipTransferred(address(0), _owner);
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}
}

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

contract ERC20 is Context, IERC20 {
	mapping (address => uint256) internal _balances;

	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 internal _totalSupply;

	string private _name;
	string private _symbol;
	uint8 private _decimals;

	/**
	 * @dev Sets the values for {name} and {symbol}.
	 *
	 * The defaut value of {decimals} is 18. To select a different value for
	 * {decimals} you should overload it.
	 *
	 * All three of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;
		_totalSupply = totalSupply_ * 10 ** uint256(decimals());
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() public view virtual returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless this function is
	 * overloaded;
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view virtual returns (uint8) {
		return _decimals;
	}

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
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
		_transfer(_msgSender(), recipient, amount);
		return true;
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
		_approve(_msgSender(), spender, amount);
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

		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		_approve(sender, _msgSender(), currentAllowance - amount);

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
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		_approve(_msgSender(), spender, currentAllowance - subtractedValue);

		return true;
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

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		_balances[sender] = senderBalance - amount;
		_balances[recipient] += amount;

		emit Transfer(sender, recipient, amount);
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

}

contract FIRST_OPTION is ERC20, Ownable {

	uint256 public totalFund            = 1_000_000_000_000_000;
	uint256 public burnedFund           =   400_000_000_000_000;
	uint256 public communityAirdropFund =    20_000_000_000_000;
	uint256 public teamFund             =    50_000_000_000_000;
	uint256 public futureDevFund        =    30_000_000_000_000;

	address public ownerWallet     = 0x403b3fE33bD766C6051B41B9675F8904075A885D;
	address public burnWallet      = 0x000000000000000000000000000000000000dEaD;
	address public airdropWallet   = 0x72dB0c30F9FBbE76EcEc1E83010193857C931705;
	address public teamWallet      = 0xA99fD619Bf98313C03E3B401B58Df06d361E1B8a;
	address public futureDevWallet = 0x065C468d044C38Ae32089458112d7Ec7bED038bd;

	uint256 public allUserFee = 5;
	uint256 public burnFee = 3;
	uint256 public referrerFee = 2;

	uint256 public initialPrice = 1_000_000_000;
	uint256 public increment = 1_000_000_000;

	uint256 public dividendsPerShare;

	uint256  public dividendPerToken;

	mapping (address => address) public referrer;

	mapping(address => uint256) private _dividendCreditedTo;
	mapping(address => bool) private _lockWallet;

	uint256 public endBlockDate;

	event Buy(address member, uint256 etherAmount, uint256 tokens, address referrer);
	event Sell(address member, uint256 etherAmount, uint256 tokens);
	event LockWallet(address member);
	event UnlockWallet(address member);

	constructor () ERC20("TEST20211118", "TEST", 9, totalFund) Ownable(ownerWallet) {
		initWallet(ownerWallet, (totalFund - 100_000_000_000_000)  * 10 ** uint256(decimals()) );
		initWallet(airdropWallet, communityAirdropFund * 10 ** uint256(decimals()) );
		initWallet(teamWallet, teamFund * 10 ** uint256(decimals()) );
		initWallet(futureDevWallet, futureDevFund * 10 ** uint256(decimals()) );
		_transfer(ownerWallet, burnWallet, burnedFund * 10 ** uint256(decimals()));
		endBlockDate = block.timestamp + 365 days;
		lockWallet(airdropWallet);
	}

	receive() payable external {
		purchase(msg.value, address(0));
	}

	function getTokenReward(address account) public {
		uint256 _dividend = calcTokenReward(account);
		if (_dividend > 0) {
			_balances[account] += _dividend;
			_balances[address(this)] -= _dividend;
			emit Transfer(address(this), account, _dividend);
		}
		_dividendCreditedTo[account] = dividendPerToken;
	}

	function calcTokenReward(address account) public view returns (uint256) {
		uint256 _dividendPerToken = dividendPerToken;
		if (_dividendPerToken > _dividendCreditedTo[account]) {
			uint256 _owed = _dividendPerToken - _dividendCreditedTo[account];
			return _balances[account] * _owed / totalSupply();
		}
		return 0;
	}

	function viewDividendPerToken() public view returns (uint256) {
		return dividendPerToken;
	}

	function dividendCreditedTo(address account) external view returns (uint256) {
		return _dividendCreditedTo[account];
	}

	function buy(address _referrer) payable external {
		purchase(msg.value, _referrer);
	}

	function purchase(uint256 _amount, address _referrer) internal {
		require (_msgSender() != _referrer, "OPTN: You can not be your referrer");
		if (referrer[_msgSender()] == address(0) && _referrer != address(0) && balanceOf(_referrer) >= 0) {
			referrer[_msgSender()] = _referrer;
		}

		uint256 _tokens = ethToTokens(_amount);
		uint256 _tokensWithoutFee = makeFeeWithTransfer(owner(), _msgSender(), _tokens, true);

		_transfer(owner(), _msgSender(), _tokensWithoutFee);

		emit Buy(_msgSender(), _amount, _tokensWithoutFee, _referrer);
	}

	function sell(uint256 _tokens) external {
		require (_tokens <= balanceOf(_msgSender()), "OPTN: Not enough tokens");

		uint256 _withoutFeeTokens = makeFeeWithTransfer(_msgSender(), owner(), _tokens, false);
		uint256 _amount = tokensToEth(_withoutFeeTokens);
		_transfer(_msgSender(), owner(), _withoutFeeTokens);

		payable(_msgSender()).transfer(_amount);

		emit Sell(_msgSender(), _amount, _tokens);
	}

	function makeFeeWithTransfer(
		address _sender, address _recipient, uint256 _amount, bool withReferrer
	) private returns(uint256 _withoutFeeAmount) {

		getTokenReward(_sender);

		uint256 burnFeeAmount = _amount * burnFee / 100;
		_transfer(_sender, burnWallet, burnFeeAmount);

		uint256 allUserFeeAmount = _amount * allUserFee / 100;

		uint256 referrerFeeAmount = _amount * referrerFee / 100;
		address referrerWallet = referrer[_recipient];

		if(withReferrer && referrerWallet != address(0)) {
			_transfer(_sender, referrerWallet, referrerFeeAmount);
		} else {
			allUserFeeAmount += referrerFeeAmount;
		}

		_transfer(_sender, address(this), allUserFeeAmount);

		dividendPerToken += allUserFeeAmount;
		getTokenReward(_recipient);

		_withoutFeeAmount = _amount - (burnFeeAmount + allUserFeeAmount);
	}

	function ethToTokens(uint256 _ether) public view returns(uint256) {
		uint256 eth = _ether;
		uint256 supply = totalSupply();
		uint256 supplyInt = supply / 1 ether;
		uint256 supplyFract = supply - (supplyInt * (1 ether));
		uint256 currentPrice = supplyInt * increment + initialPrice;
		uint256 tokens;
		uint256 tempTokens = eth * (1 ether) / currentPrice;

		if (tempTokens < supplyFract) {
			return tempTokens;
		}

		tokens = tokens + supplyFract;

		eth = eth - (supplyFract * currentPrice / (1 ether));
		if (supplyFract > 0) {
			currentPrice = currentPrice + increment;
		}
		tempTokens = eth * (1 ether) / currentPrice;

		if (tempTokens <= 1 ether) {
			return tokens + tempTokens;
		}

		uint256 d = currentPrice * 2 - increment;
		d = d * d;
		d = d + (increment * eth * 8);

		uint256 sqrtD = sqrt(d);

		tempTokens = increment + sqrtD - (currentPrice * 2);
		tempTokens = tempTokens * (1 ether) / (increment * 2);
		tokens = tokens + tempTokens;

		return tokens;
	}

	function tokensToEth(uint256 _tokens) public view returns(uint256) {
		uint256 tokens = _tokens;
		uint256 supply = totalSupply();
		if (tokens > supply) return 0;
		uint256 supplyInt = supply / (1 ether);
		uint256 supplyFract = supply - (supplyInt * (1 ether));
		uint256 currentPrice = supplyInt * increment + initialPrice;
		uint256 eth;

		if (tokens < supplyFract) {
			return tokens * currentPrice / (1 ether);
		}

		eth = eth + (supplyFract * currentPrice / (1 ether));
		tokens = tokens - supplyFract;

		if (supplyFract > 0) {
			currentPrice = currentPrice - increment;
		}

		if (tokens <= 1 ether) {
			return eth + (tokens * currentPrice / (1 ether));
		}

		uint256 tokensInt = tokens / (1 ether);
		uint256 tokensFract;
		if (tokensInt > 1) {
			tokensFract = tokens - (tokensInt * (1 ether));
		}

		uint256 tempEth = currentPrice * 2 - (increment * (tokensInt - 1));

		tempEth = tempEth * tokensInt / 2;

		eth = eth + tempEth;

		currentPrice = currentPrice - (increment * tokensInt);
		eth = eth + (currentPrice * tokensFract / (1 ether));
		return eth;
	}

	function sqrt(uint x) public pure returns (uint y) {
		uint z = (x + 1) / 2;
		y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}
	}

	function contractBalance() public view returns(uint256) {
		return address(this).balance;
	}

	function transfer(address recipient, uint256 amount) override public returns(bool) {
		checkOneYearLock(_msgSender());
		uint256 _amountWithoutFee = makeFeeWithTransfer(_msgSender(), recipient, amount, false);

		return super.transfer(recipient, _amountWithoutFee);
	}

	function transferFrom(address sender, address recipient, uint256 amount) override public returns(bool) {
		checkOneYearLock(sender);
		uint256 _amountWithoutFee = makeFeeWithTransfer(sender, recipient, amount, false);

		return super.transferFrom(sender, recipient, _amountWithoutFee);
	}

	function unlockWallet(address wallet) public onlyOwner {
		require(wallet != address(0), "OPTN: wrong parameter");
		_lockWallet[wallet] = false;
		emit UnlockWallet(wallet);
	}

	function checkLockWallet(address wallet) private view {
		require(_lockWallet[wallet] == false, "OPTN: locked tokens cannot be used");
	}

	function checkOneYearLock(address wallet) private view {
		if (_msgSender() == teamWallet || _msgSender() == futureDevWallet
		|| wallet == teamWallet || wallet == futureDevWallet) {
			require(block.timestamp > endBlockDate, "OPTN: team tokens cannot be used");
		}
	}

	function lockWallet(address wallet) private {
		require(wallet != address(0), "OPTN: wrong parameter");
		_lockWallet[wallet] = true;
		emit LockWallet(wallet);
	}

	function initWallet(address _wallet, uint256 _amount) private {
		_balances[_wallet] = _amount;
		emit Transfer(address(0) , _wallet, _amount);
	}
}