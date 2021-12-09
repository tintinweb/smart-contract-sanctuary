// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import { PoolTokenFactory } from "./libs/PoolTokenFactory.sol";

contract PlatformPool is Context, Pausable {
	/* Here we create an Assess Control slot for the Cent Admin */
	bytes32 public constant ASSETS_ADMIN_ROLE = keccak256("ASSETS_ADMIN_ROLE");
	string public _poolBaseURI;
	address private _owner;
	mapping(address => address) private acceptableTokens;

	/**
	 * @dev dictionary to track the attributes of asset pools on the blockchain
	 * Contract Address has an interface of IERC-20 because they are ERC-20 tokens
	 * that will be distributed, and the uri is bytes32 hash of the name and ID from Cent
	 * Admin Gateway generated off-chain but used to track both chain and onchain records.
	 */
	struct AssetPool {
		PoolTokenFactory _contractAddress;
		string _name;
		string _ticker;
		string _uri; /* The _id generated from the off-chain backend*/
		string _templateTag;
		address payable _paymentAddress;
	}

	/**
	 * @dev create a mapping of pool token contract address to Asset pool
	 * struct so that we can easily retrieve pool props and execute requests
	 */
	mapping(PoolTokenFactory => AssetPool) public _pools;
	event AssetPoolCreated(PoolTokenFactory contractAddress, string name, string ticker, string uri);

	/**
	 * @dev ledger of transactions on pool tokens
	 * map the pool token contract address to transactions
	 */

	struct PoolTransaction {
		uint256 _tokenValueIssued;
		address _recipient;
	}
	mapping(address => PoolTransaction[]) public _ledger;
	event PoolTokenFunded(address tokenAddress, address recipient, uint256 tokenValueIssued);

	constructor(string memory poolBaseURI) {
		// 		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		// 		_setupRole(ASSETS_ADMIN_ROLE, _msgSender());

		// Set the base URI for Asset pools, use for retriving pool templates and statuses
		_poolBaseURI = poolBaseURI;
		_owner = _msgSender();
	}

	/**
	 * @dev modifier to only allow an admin to perform an action
	 */
	modifier onlyCentAdmin() {
		// 		require(hasRole(ASSETS_ADMIN_ROLE, _msgSender()), "Cent: account not allowed");
		require(_msgSender() == _owner, "Only admins allowed");
		_;
	}

	/**
	 * @dev Pauses all token transfers.
	 * See {Pausable-_pause}.
	 *
	 * Requirements:
	 * - the caller must have the `ASSETS_ADMIN_ROLE`.
	 */
	function pause() public virtual onlyCentAdmin {
		_pause();
	}

	/**
	 * @dev Unpauses all token transfers.
	 * See {Pausable-_unpause}.
	 *
	 * Requirements:
	 * - the caller must have the `ASSETS_ADMIN_ROLE`.
	 */
	function unpause() public virtual onlyCentAdmin {
		_unpause();
	}

	// 	function addUserToAdminRole(address user) public onlyCentAdmin returns(bool) {
	// 		grantRole(ASSETS_ADMIN_ROLE, user);
	// return true;
	// 	}

	function setBaseUriForPools(string memory baseURI) public onlyCentAdmin whenNotPaused {
		_setBaseUriForPools(baseURI);
	}

	function addERCTokenToAcceptanceList(address tokenAddress) external onlyCentAdmin returns (address) {
		acceptableTokens[tokenAddress] = tokenAddress;
		return acceptableTokens[tokenAddress];
	}

	/**
	 * @dev Internal function to set the base URI for all token IDs. It is
	 * automatically added as a prefix to the value returned in {tokenURI},
	 * or to the token ID if {tokenURI} is empty.
	 */
	function _setBaseUriForPools(string memory baseURI) internal virtual {
		_poolBaseURI = baseURI;
	}

	function createNewAssetPool(
		uint256 salePrice,
		string memory name,
		string memory ticker,
		string memory templateTag,
		string memory poolTokenUri,
		address payable paymentAddress
	) public onlyCentAdmin whenNotPaused {
		PoolTokenFactory poolToken = new PoolTokenFactory(name, ticker, salePrice);

		// store pools to pool token mapping
		AssetPool memory pool = AssetPool(poolToken, name, ticker, poolTokenUri, templateTag, paymentAddress);
		_pools[poolToken] = pool;

		// emit event once pool token create
		emit AssetPoolCreated(poolToken, name, ticker, poolTokenUri);
	}

	function fundPoolWithToken(
		uint256 amount,
		PoolTokenFactory poolTokenAddress,
		address erc20Token
	) external returns (bool) {
		AssetPool memory pool = _pools[poolTokenAddress];
		address recipient = _msgSender();

		require(acceptableTokens[erc20Token] != address(0), "fundPoolWithToken: cant transact"); // single check for acceptable token

		require(IERC20(erc20Token).transferFrom(recipient, pool._paymentAddress, amount), "tether transfer failed");

		address tokenAddress = address(pool._contractAddress);
		uint256 tokenValueToIssue = amount / pool._contractAddress._salePrice();

		pool._contractAddress.mint(recipient, tokenValueToIssue);

		// Store transaction in Ledger
		PoolTransaction memory record = PoolTransaction(tokenValueToIssue, recipient);
		PoolTransaction[] storage transactions = _ledger[tokenAddress];
		transactions.push(record);

		emit PoolTokenFunded(tokenAddress, recipient, tokenValueToIssue);
		return true;
	}

	/** @dev Fund Pool with native token, in this case ETH, given the hash map of the pool token
	 * Will Take the ETH equivalent and fund the pool with corresponding amount
	 *
	 * AssetPool Struct need to track ETH price per pool or wei equivalent
	 * AssetPool Struct to also track USDC Price or Equivalent and retrieve from external oracle.
	 * _uri is the bytes32 hash of the pool token name and id off-chain
	 */
	function fundPoolWithNativeToken(PoolTokenFactory poolTokenAddress) public payable returns (bool) {
		require(msg.value > 0, "You need to send some ether");

		uint256 tokenValueToIssue = msg.value * 100;
		AssetPool memory pool = _pools[poolTokenAddress];
		address recipient = msg.sender;
		address tokenAddress = address(pool._contractAddress);
		// uint256 dexBalance = poolToken.balanceOf(address(this));

		// EXTCALL to Mint PoolToken for recipient
		// @TODO use require and run checks interaction to ensure pool token must be funded
		// require(pool._contractAddress.mint(recipient, tokenValueToIssue), "failed to fund pool token");
		pool._contractAddress.mint(recipient, tokenValueToIssue);

		// Store transaction in Ledger
		PoolTransaction memory record = PoolTransaction(tokenValueToIssue, recipient);
		PoolTransaction[] storage transactions = _ledger[tokenAddress];
		transactions.push(record);

		emit PoolTokenFunded(tokenAddress, recipient, tokenValueToIssue);
		return true;
	}

	/** @dev mint token after conditions are met
	 * Internal function can only be called from within contract
	 */

	function _mintPoolTokenToInvestor(
		PoolTokenFactory poolTokenAddress,
		uint256 amount,
		address to
	) internal whenNotPaused {
		AssetPool memory pool = _pools[poolTokenAddress];
		pool._contractAddress.mint(to, amount);

		// update ledger balance
		// ledger[]
		emit PoolTokenFunded(address(pool._contractAddress), to, amount);
	}
}

// SPDX-License-Identifier: MIT

/* ERC-20 Preset with Minter and Pauser functionality */
pragma solidity ^0.8.0;

import { ERC20, ERC20Burnable, ERC20Pausable } from "./ERC20Impl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract PoolTokenFactory is Context, ERC20Burnable, ERC20Pausable {
	/**
	 * @dev define the smart contract that owns this pool token
	 */
	address private _owner;

	/**
	 * @dev sale price to handle sales for pools
	 * decimal points max = 3
	 *
	 * Price will be calculated according to the allocation in decimal places
	 * All inputs will be divided by 100
	 */
	uint256 public _salePrice;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor(
		string memory name,
		string memory symbol,
		uint256 salePrice
	) ERC20(name, symbol) {
		_salePrice = salePrice;
		_setOwner(_msgSender());
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
		require(owner() == _msgSender(), "PTF: caller is not owner");
		_;
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "PTF: new owner is zero address");
		_setOwner(newOwner);
	}

	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}

	/**
	 * @dev Creates `amount` new tokens for `to`.
	 *
	 * See {ERC20-_mint}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `MINTER_ROLE`.
	 */
	function mint(address to, uint256 amount) public virtual onlyOwner {
		_mint(to, amount);
	}

	/**
	 * @dev Pauses all token transfers.
	 *
	 * See {ERC20Pausable} and {Pausable-_pause}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `PAUSER_ROLE`.
	 */
	function pause() public virtual onlyOwner {
		_pause();
	}

	/**
	 * @dev Unpauses all token transfers.
	 *
	 * See {ERC20Pausable} and {Pausable-_unpause}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `PAUSER_ROLE`.
	 */
	function unpause() public virtual onlyOwner {
		_unpause();
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override(ERC20, ERC20Pausable) {
		super._beforeTokenTransfer(from, to, amount);
	}
}

// SPDX-License-Identifier: MIT
/* solhint-disable reason-string */

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;

	/**
	 * @dev Sets the values for {name} and {symbol}.
	 *
	 * The default value of {decimals} is 18. To select a different value for
	 * {decimals} you should overload it.
	 *
	 * All two of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5.05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless this function is
	 * overridden;
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view virtual override returns (uint8) {
		return 18;
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
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}

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
		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	/**
	 * @dev Moves `amount` of tokens from `sender` to `recipient`.
	 *
	 * This internal function is equivalent to {transfer}, and can be used to
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
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[sender] = senderBalance - amount;
		}
		_balances[recipient] += amount;

		emit Transfer(sender, recipient, amount);

		_afterTokenTransfer(sender, recipient, amount);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
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

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		unchecked {
			_balances[account] = accountBalance - amount;
		}
		_totalSupply -= amount;

		emit Transfer(account, address(0), amount);

		_afterTokenTransfer(account, address(0), amount);
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
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Hook that is called before any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * will be transferred to `to`.
	 * - when `from` is zero, `amount` tokens will be minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}

	/**
	 * @dev Hook that is called after any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * has been transferred to `to`.
	 * - when `from` is zero, `amount` tokens have been minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
	/**
	 * @dev Destroys `amount` tokens from the caller.
	 *
	 * See {ERC20-_burn}.
	 */
	function burn(uint256 amount) public virtual {
		_burn(_msgSender(), amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, deducting from the caller's
	 * allowance.
	 *
	 * See {ERC20-_burn} and {ERC20-allowance}.
	 *
	 * Requirements:
	 *
	 * - the caller must have allowance for ``accounts``'s tokens of at least
	 * `amount`.
	 */
	function burnFrom(address account, uint256 amount) public virtual {
		uint256 currentAllowance = allowance(account, _msgSender());
		require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
		unchecked {
			_approve(account, _msgSender(), currentAllowance - amount);
		}
		_burn(account, amount);
	}
}

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
	/**
	 * @dev See {ERC20-_beforeTokenTransfer}.
	 *
	 * Requirements:
	 *
	 * - the contract must not be paused.
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override {
		super._beforeTokenTransfer(from, to, amount);

		require(!paused(), "ERC20Pausable: token transfer while paused");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}