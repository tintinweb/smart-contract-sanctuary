/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-07-13
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

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


pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;


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



pragma solidity ^0.8.0;




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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
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
     * - `to` cannot be the zero address.
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
        _balances[account] = accountBalance - amount;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity 0.8.4;


contract Owned {
    address public owner;
    address public nominatedOwner;
    address public benefitial;
    constructor(address _owner) public {
        require(_owner != address(0), 'Owner address cannot be 0');
        owner = _owner;
        benefitial = _owner;
        emit OwnerChanged(address(0), _owner);
    }
    function nominateNewOwner(address _owner) external isOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }
    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, 'You must be nominated before you can accept ownership');
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }
    function transferBenefitial(address _benefitial) external isOwner {
        address oldBenefitial = benefitial;
        benefitial = _benefitial;
        emit BenefitialChanged(oldBenefitial, benefitial);
    }
    modifier isOwner() {
        require(owner == msg.sender, "You are not Owner");
        _;
    }
    
    event OwnerNominated(address indexed newOwner);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event BenefitialChanged(address indexed oldBenefitial, address indexed newBenefitial);
}

contract RCG is ERC20, Owned {
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string public constant tokenName = "Recharge";
  string public constant tokenSymbol = "RCG";
  uint256 _totalSupply = 0;
  uint256 public basePercent = 0;

  constructor(address _owner, uint256 amount) ERC20(tokenName, tokenSymbol) Owned(_owner) {
    _issue(msg.sender, amount);
    _totalSupply=amount;
  }
    
  function changeBurnRate(uint256 rate) public isOwner returns (bool){
    basePercent = rate;
    return true;
  }
  
  /// @notice Returns total token supply
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Returns user balance
  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  /// @notice Returns number of tokens that the owner has allowed the spender to withdraw
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  /// @notice Returns value of calculate the quantity to destory during transfer
  function cut(uint256 value) public view returns (uint256)  {
    if(basePercent==0) return 0;
    uint256 c = value+basePercent;
    uint256 d = c-1;
    uint256 roundValue = d/basePercent*basePercent;
    uint256 cutValue = roundValue*basePercent/10000;
    return cutValue;
  }

  /// @notice From owner address sends value to address.
  function transfer(address to, uint256 value) public override returns (bool) {
    require(to != address(0), "Address cannot be 0x0");
      
    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value-tokensToBurn;

    _balances[msg.sender] = _balances[msg.sender]-value;
    _balances[to] = _balances[to]+tokensToTransfer;
    _balances[benefitial] = _balances[benefitial]+tokensToBurn;

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, benefitial, tokensToBurn);
    return true;
  }

  /// @notice Give Spender the right to withdraw as much tokens as value
  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0), "Address cannot be 0x0");
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /** @notice From address sends value to address.
              However, this function can only be performed by a spender 
              who is entitled to withdraw through the aprove function. 
  */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require(to != address(0), "Address cannot be 0x0");

    _balances[from] = _balances[from]-value;

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value-tokensToBurn;

    _balances[to] = _balances[to]+tokensToTransfer;
    _balances[benefitial] = _balances[benefitial]+tokensToBurn;

    _allowed[from][msg.sender] = _allowed[from][msg.sender]-value;

    emit Approval(from, msg.sender, _allowed[from][msg.sender]);
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, benefitial, tokensToBurn);

    return true;
  }

  /// @notice Add the value of the privilege granted through the allowance function
  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0), "Address cannot be 0x0");
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender]+addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /// @notice Subtract the value of the privilege granted through the allowance function
  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0), "Address cannot be 0x0");
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender]-subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /// @notice Issue token from 0x address
  function _issue(address account, uint256 amount) internal {
    require(amount != 0, "Amount cannot be 0");
    _balances[account] = _balances[account]+amount;
    emit Transfer(address(0), account, amount);
  }

  /// @notice Returns _destory function
  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  /// @notice Destroy the token by transferring it to the 0x address.
  function _destroy(address account, uint256 amount) internal {
    require(amount != 0, "Amount Cannot be 0");
    _balances[account] = _balances[account]-amount;
    _totalSupply = _totalSupply-amount;
    emit Transfer(account, address(0), amount);
  }

  /** @notice From address sends value 0x address.
              However, this function can only be performed by a spender 
              who is entitled to withdraw through the aprove function. 
  */
  function destroyFrom(address account, uint256 amount) external {
    _allowed[account][msg.sender] = _allowed[account][msg.sender]-amount;
    _destroy(account, amount);

    emit Approval(account, msg.sender, _allowed[account][msg.sender]);
  }
    
}