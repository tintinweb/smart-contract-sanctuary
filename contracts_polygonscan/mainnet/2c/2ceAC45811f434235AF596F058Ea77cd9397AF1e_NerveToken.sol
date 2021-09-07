/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/******************************************/
/*           IERC20 starts here           */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

/******************************************/
/*           Context starts here          */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

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

/******************************************/
/*      IERC20Metadata starts here        */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

/******************************************/
/*           ERC20 starts here            */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * will be to transferred to `to`.
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
}

/******************************************/
/*   FundsDistributionToken starts here   */
/******************************************/

/** 
 * @title FundsDistributionToken
 * @author Johannes Escherich
 * @author Roger-Wu
 * @author Johannes Pfeffer
 * @author Tom Lam
 * @dev A  mintable token that can represent claims on cash flow of arbitrary assets such as dividends, loan repayments, 
 * fee or revenue shares among large numbers of token holders. Anyone can deposit funds, token holders can withdraw 
 * their claims.
 */

contract FundsDistributionToken is ERC20 {

	uint256 constant internal pointsMultiplier = 2**128;
	uint256 internal pointsPerShare;

	mapping(address => int256) public pointsCorrection;
	mapping(address => uint256) internal withdrawnFunds;
	
	event FundsDistributed(address indexed by, uint256 fundsDistributed);
	event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn);


	constructor (string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

	/** 
	 * prev. distributeDividends
	 * @notice Distributes funds to token holders.
	 * @dev It reverts if the total supply of tokens is 0.
	 * It emits the `FundsDistributed` event if the amount of received ether is greater than 0.
	 * About undistributed funds:
	 *   In each distribution, there is a small amount of funds which does not get distributed,
	 *     which is `(msg.value * pointsMultiplier) % totalSupply()`.
	 *   With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed
	 *     in a distribution can be less than 1 (base unit).
	 */
	function _distributeFunds(uint256 value) internal {
		require(totalSupply() > 0, "FundsDistributionToken._distributeFunds: SUPPLY_IS_ZERO");

		if (value > 0) {
			pointsPerShare = pointsPerShare + (value * pointsMultiplier / totalSupply());
			emit FundsDistributed(msg.sender, value);
		}
	}

	/**
	 * prev. withdrawDividend
	 * @notice Prepares funds withdrawal
	 * @dev It emits a `FundsWithdrawn` event if the amount of withdrawn ether is greater than 0.
	 */
	function _prepareWithdraw(address recipient) internal returns (uint256) {
		uint256 _withdrawableDividend = withdrawableFundsOf(recipient);
	
		withdrawnFunds[recipient] = withdrawnFunds[recipient] + _withdrawableDividend;
		
		emit FundsWithdrawn(recipient, _withdrawableDividend);

		return _withdrawableDividend;
	}

	/** 
	 * prev. withdrawableDividendOf
	 * @notice View the amount of funds that an address can withdraw.
	 * @param _owner The address of a token holder.
	 * @return The amount funds that `_owner` can withdraw.
	 */
	function withdrawableFundsOf(address _owner) public view returns(uint256) {
		return accumulativeFundsOf(_owner) - withdrawnFunds[_owner];
	}
	
	/**
	 * prev. withdrawnDividendOf
	 * @notice View the amount of funds that an address has withdrawn.
	 * @param _owner The address of a token holder.
	 * @return The amount of funds that `_owner` has withdrawn.
	 */
	function withdrawnFundsOf(address _owner) public view returns(uint256) {
		return withdrawnFunds[_owner];
	}

	/**
	 * prev. accumulativeDividendOf
	 * @notice View the amount of funds that an address has earned in total.
	 * @dev accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)
	 * = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
	 * @param _owner The address of a token holder.
	 * @return The amount of funds that `_owner` has earned in total.
	 */
	function accumulativeFundsOf(address _owner) public view returns(uint256) {
	    if (pointsCorrection[_owner] >= 0) {
		    return (pointsPerShare * balanceOf(_owner) + uint256(pointsCorrection[_owner])) / pointsMultiplier;
	    } else {
	        return (pointsPerShare * balanceOf(_owner) - uint256(abs(pointsCorrection[_owner]))) / pointsMultiplier;
	    }
	    
	}

	/**
	 * @dev Internal function that transfer tokens from one address to another.
	 * Update pointsCorrection to keep funds unchanged.
	 * @param from The address to transfer from.
	 * @param to The address to transfer to.
	 * @param value The amount to be transferred.
	 */
	function _transfer(address from, address to, uint256 value) internal override {
		ERC20._transfer(from, to, value);

		uint256 magCorrection = pointsPerShare * value;
		pointsCorrection[from] = pointsCorrection[from] + int256(magCorrection);
		pointsCorrection[to] = pointsCorrection[to] - int256(magCorrection);
	}

	/**
	 * @dev Internal function that mints tokens to an account.
	 * Update pointsCorrection to keep funds unchanged.
	 * @param account The account that will receive the created tokens.
	 * @param value The amount that will be created.
	 */
	function _mint(address account, uint256 value) internal override {
		ERC20._mint(account, value);

		pointsCorrection[account] = pointsCorrection[account] - int256(pointsPerShare * value);
	}
	
	/** 
	 * @dev Internal function that burns an amount of the token of a given account.
	 * Update pointsCorrection to keep funds unchanged.
	 * @param account The account whose tokens will be burnt.
	 * @param value The amount that will be burnt.
	 */
	function _burn(address account, uint256 value) internal override {
		ERC20._burn(account, value);

		pointsCorrection[account] = pointsCorrection[account] + int256(pointsPerShare * value);
	}
}

/******************************************/
/*          NrvToken starts here          */
/******************************************/

contract NerveToken is FundsDistributionToken {

    address[] public nrv;
    address public nrvGov;
    address internal base;
    bool internal initialized;
    uint256 nrvRate;
    uint256 baseRate;

    event NrvMinted(address to, uint256 amount);
    event NrvBurned(address from, uint256 amount);

    modifier onlyNrv() { //array
        require(isNrv(msg.sender) == true, "Caller is not nrv.");
        _;
    }
    
    modifier onlyGov() {
        require(msg.sender == address(nrvGov), "Caller is not nrvGov.");
        _;
    }

	constructor(string memory name, string memory symbol) FundsDistributionToken(name, symbol) {
    }

    function initialize(address _nrv, address _nrvGov, address _base) public {
        require(initialized == false, "Already initialized.");
        initialized = true;
        nrv.push(_nrv);
        nrvGov = _nrvGov;
        base = _base;
    }

    /**
    * @dev Mint NRV.
    */
    function mintNrv(address _to, uint256 _amount) external onlyNrv {
        _mint(_to, _amount * nrvRate);
        _mint(base, _amount * baseRate);
        emit NrvMinted(_to, _amount);
    }

    /**
    * @dev Burn NRV.
    */
    function burnNrv(address _from, uint256 _amount) external onlyNrv {
        _burn(_from, _amount);
        emit NrvBurned(_from, _amount);
    }

    /**
    * @dev Withdraw accumulated fees.
    */
    function withdrawEth(address recipient) public {
		uint256 withdrawableFunds = _prepareWithdraw(recipient);
		payable(recipient).transfer(withdrawableFunds);
	}

    /**
    * @dev Receive fees.
    */
    function receiveFee() external payable {
		if (msg.value > 0) {
			_distributeFunds(msg.value);
			emit FundsDistributed(msg.sender, msg.value);
		}
	}

/******************************************/
/*        Governance starts here          */
/******************************************/

    function setGovernance(address _nrvGov) external onlyGov {
        nrvGov = _nrvGov;
    }

    function setRates(uint256 _nrvRate, uint256 _baseRate) external onlyGov {
        nrvRate = _nrvRate;
        baseRate = _baseRate;
    }

    function setBase(address _base) external onlyGov {
        base = _base;
    }

    function addNrv(address _nrv) external onlyGov {
        nrv.push(_nrv);
    }

    function removeNrv(uint256 _index) external onlyGov {
        delete nrv[_index];
    }

    function isNrv(address caller) internal view returns(bool) {
        bool valid;
        uint256 arrayLength = nrv.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (caller == nrv[i]) {
                valid = true;
                break;
            } 
        }    
        return valid;
    }
}