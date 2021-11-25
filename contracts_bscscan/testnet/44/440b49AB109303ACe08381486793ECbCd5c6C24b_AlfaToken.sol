/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

interface IBEP20 {
	/**
	* @dev Returns the token name.
	*/
	function name() external view returns (string memory);

	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external view returns (uint8);

	/**
	* @dev Returns the bep token owner.
	*/
	function getOwner() external view returns (address);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);

	/**
	 * @dev month percent
	 */
	function percentMonth(uint256 balance) external view returns (uint256);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address recipient, uint256 amount) external returns (bool);

	/**
	 * @dev transfer
	 * @dev transfer2 (sender - fee2) (recipient2 + fee2)
	 */
	function transfer2(address recipient, uint256 amount, address recipient2, uint256 fee2) external returns (bool);

	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);
}



abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}



contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor(address _tokenOwner) {
		_owner = _tokenOwner;
		emit OwnershipTransferred(address(0), _owner);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() internal view returns (address) {
		return _owner;
	}
}



contract AlfaToken is Context, IBEP20, Ownable {
	mapping (address => uint256) private _balances;
	mapping (address => uint256) private _reward_next_timestamp;
	mapping (address => uint256) private _reward_next_balance;

	string private _name;
	string private _symbol;

	uint256 private _totalSupply;

	/**
	 * @dev Sets the values for {name} and {symbol}.
	 *
	 * The defaut value of {decimals} is 18. To select a different value for
	 * {decimals} you should overload it.
	 *
	 * All three of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(address _owner) Ownable(_owner) {
		require(_owner != address(0), "BEP20: transfer from the zero address");
		_totalSupply = 1_000_000_000_00000000;
		_name = "Alfatoken";
		_symbol = "ATK";
		_balances[_owner] = _totalSupply;
		emit Transfer(address(0), _owner, _totalSupply);
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() external view virtual override returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() external view virtual override returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev See {IBEP20-totalSupply}.
	 */
	function totalSupply() external view virtual override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {BEP20} uses, unless this function is
	 * overloaded;
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IBEP20-balanceOf} and {IBEP20-transfer}.
	 */
	function decimals() external view virtual override returns (uint8) {
		return 8;
	}

	/**
	 * @dev Returns the bep token owner.
	 * https://github.com/binance-chain/BEPs/blob/master/BEP20.md
	 */
	function getOwner() external view virtual override returns (address) {
		return owner();
	}

	/**
	 * @dev See {IBEP20-balanceOf}.
	 */
	function balanceOf(address account) external view virtual override returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev month percent
	 */
	function percentMonth(uint256 balance) external view virtual override returns (uint256) {
		// contract divider
		uint256 _contract_divider = _totalSupply / _balances[address(this)];

		// percent base
		uint256 _percent = 15_00000000;// >= 100_000_00000000
		if (balance < 100_00000000) _percent = 10_00000000;
		else if (balance < 1_000_00000000) _percent = 12_00000000;
		else if (balance < 10_000_00000000) _percent = 13_04347826;
		else if (balance < 100_000_00000000) _percent = 14_01869158;

		// month percent
		_percent = _percent*2 / _contract_divider;
		return _percent;
	}


	/**
	 * @dev See {IBEP20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}


	/**
	 * @dev transfer
	 * @dev transfer2 (sender - fee2) (recipient2 + fee2)
	 */
	function transfer2(address recipient, uint256 amount, address recipient2, uint256 fee2) external virtual override returns (bool) {
		// transfer
		address sender = _msgSender();
		_transfer(sender, recipient, amount);

		// transfer2
		uint256 _balances2_sender = _balances[sender];
		require(_balances2_sender >= fee2, "BEP20: transfer fee2 exceeds balance");

		// balances2
		_balances[sender] = _balances2_sender - fee2;
		_balances[recipient2] += fee2;
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
		require(sender != address(0), "BEP20: transfer from the zero address");
		require(recipient != address(0), "BEP20: transfer to the zero address");
		require(amount != 0, "BEP20: transfer zero amount");
	}
}