/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
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
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

pragma solidity ^0.8.0;

contract MyToken is ERC20 {
  uint256 constant INIT_SUPPLY_POC = 1000000000;
  uint256 constant MAX_MINT_POC = 2000000000;
    
 address constant _approver1 = 0x2C76A35B071b9299b538c93686903c8Ab9F06e5e;
 address constant _approver2 = 0x65d6D8353566Be8866a03B41d21173C647DBa0dD;
 address constant _approver3 = 0x116EE03B66e0AbF4098B86f8C666cbc919fb7A8D;
 address constant _approver4 = 0xb03aB8c62b6119248720f3E0B1E1404493a25980;
  
//  address constant _approver1 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
//  address constant _approver2 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
//  address constant _approver3 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
//  address constant _approver4 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
  
  address _owner; 
  
  uint8 private _seconds_per_block;
  uint256 private _schedule_term;
  uint256 private _mint_term;
  
  uint256 private _addedSupplyToken;
  uint256 private _listingDate;
  uint256 private _burnApproved1 = 0;
  uint256 private _burnApproved2 = 0;
  uint256 private _burnApproved3 = 0;
  uint256 private _burnApproved4 = 0;
  uint256 private _mintApproved1 = 0;
  uint256 private _mintApproved2 = 0;
  uint256 private _mintApproved3 = 0;
  uint256 private _mintApproved4 = 0;
  uint256 private _rescheduleApproved1 = 0;
  uint256 private _rescheduleApproved2 = 0;
  uint256 private _rescheduleApproved3 = 0;
  uint256 private _rescheduleApproved4 = 0;
  
  struct Schedule{
    uint256 day;
    uint256 POC;
  }
  Schedule[] private schedule;
  
  constructor() ERC20("PocketArena", "POC") {
    _seconds_per_block = 15;
    _schedule_term = (60 * 60 * 24 * 30) / _seconds_per_block;  // during 30 days
    _mint_term = (60 * 60 * 24 * 730) / _seconds_per_block;     // during 730 days
//    _schedule_term = 30 / _seconds_per_block;  // during 30 seconds
//    _mint_term = 730 / _seconds_per_block;     // during 730 seconds
       
    _listingDate = block.number;
    _owner = msg.sender;
    _mint(_owner, (INIT_SUPPLY_POC * (10 ** uint256(decimals()))));
    _addedSupplyToken = 0;  
    
    schedule.push(Schedule(_listingDate, 501666667));  
    schedule.push(Schedule((_listingDate + _schedule_term), 503333334));
    schedule.push(Schedule((_listingDate + (_schedule_term * 2)), 505000001));
    schedule.push(Schedule((_listingDate + (_schedule_term * 3)), 506666668));
    schedule.push(Schedule((_listingDate + (_schedule_term * 4)), 508333335));
    schedule.push(Schedule((_listingDate + (_schedule_term * 5)), 510000002));
    schedule.push(Schedule((_listingDate + (_schedule_term * 6)), 526666669));
    schedule.push(Schedule((_listingDate + (_schedule_term * 7)), 528333336));
    schedule.push(Schedule((_listingDate + (_schedule_term * 8)), 552500003));
    schedule.push(Schedule((_listingDate + (_schedule_term * 9)), 554166670));
    schedule.push(Schedule((_listingDate + (_schedule_term * 10)), 578333337));
    schedule.push(Schedule((_listingDate + (_schedule_term * 11)), 580000004));
    schedule.push(Schedule((_listingDate + (_schedule_term * 12)), 754166671));
    schedule.push(Schedule((_listingDate + (_schedule_term * 13)), 755833338));
    schedule.push(Schedule((_listingDate + (_schedule_term * 14)), 780000005));
    schedule.push(Schedule((_listingDate + (_schedule_term * 15)), 781666672));
    schedule.push(Schedule((_listingDate + (_schedule_term * 16)), 805833339));
    schedule.push(Schedule((_listingDate + (_schedule_term * 17)), 807500006));
    schedule.push(Schedule((_listingDate + (_schedule_term * 18)), 831666673));  
    schedule.push(Schedule((_listingDate + (_schedule_term * 19)), 1666667));
    schedule.push(Schedule((_listingDate + (_schedule_term * 119)), INIT_SUPPLY_POC));
  }
  function scheduleGet(uint16 round) external view returns (Schedule memory) {
    return schedule[round];
  }
  function lockedPOC(uint256 currentDate) public view returns (uint256) {
    if (schedule[(schedule.length - 1)].day <= currentDate) {
      //return (INIT_SUPPLY_POC - schedule[(schedule.length - 1)].POC);
      return 0;
    }
    else if (schedule[(schedule.length - 2)].day <= currentDate) { 
      uint dateDiff = ((currentDate - schedule[(schedule.length - 2)].day) / _schedule_term);
      uint256 newUnlockPOC = (schedule[(schedule.length - 2)].POC * (dateDiff + 1));
      return (INIT_SUPPLY_POC - (schedule[(schedule.length - 3)].POC + newUnlockPOC));
    }
    else {
      for (uint i=(schedule.length - 1); i>0; i--) {
        if (schedule[i-1].day <= currentDate) {
          return (INIT_SUPPLY_POC - schedule[i-1].POC);
        }
      }
      return INIT_SUPPLY_POC;
    }
  }
  function transferable() public view returns (uint256) {
    uint256 locked = (lockedPOC(block.number) * (10 ** uint256(decimals())));
    if (balanceOf(_owner) > locked) {
	  return (balanceOf(_owner) - locked);
    }
    else {
      return 0;
    }
  }

  modifier listingDT() {
    require(_listingDate <= block.number, "listing is not yet");
    _;
  }
  modifier onlyApprover() {
    require((msg.sender == _approver1 || msg.sender == _approver2 || msg.sender == _approver3 || msg.sender == _approver4), "only approver is possible");
    _;
  }
  modifier onlyOwner() {
    require(msg.sender == _owner, "only owner is possible");
    _;
  }
  modifier unlocking(uint256 amount) {
    if (msg.sender != _owner){
       _;
    }
    else {
      require(transferable() >= amount, "lack of transferable token");
      _;
    }
  }
  
  function burn_approve_up(uint256 approveToken) onlyApprover external returns (bool) {
    if (msg.sender == _approver1) {
      _burnApproved1 = approveToken;
    }
    else if (msg.sender == _approver2) {
      _burnApproved2 = approveToken;
    }
    else if (msg.sender == _approver3) {
      _burnApproved3 = approveToken;
    }
    else if (msg.sender == _approver4) {
      _burnApproved4 = approveToken;
    }
    return true;
  }
  function burn_approve_down() onlyApprover external returns (bool) {
    if (msg.sender == _approver1) {
      _burnApproved1 = 0;
    }
    else if (msg.sender == _approver2) {
      _burnApproved2 = 0;
    }
    else if (msg.sender == _approver3) {
      _burnApproved3 = 0;
    }
    else if (msg.sender == _approver4) {
      _burnApproved4 = 0;
    }
    return true;
  }
  function burn(uint256 burnToken) listingDT onlyOwner external returns (bool) {
    require(_addedSupplyToken >= burnToken, "you can burn newly added token only");
    require(balanceOf(msg.sender) >= burnToken, "you can burn in your balance only");
    uint8 sum_approval = 0;
    if (_burnApproved1 > 0) {
      require(_burnApproved1 == burnToken, "you must get the right approval from approver1");
      sum_approval++;
    }
    if (_burnApproved2 > 0) {
      require(_burnApproved2 == burnToken, "you must get the right approval from approver2");
      sum_approval++;
    }
    if (_burnApproved3 > 0) {
      require(_burnApproved3 == burnToken, "you must get the right approval from approver3");
      sum_approval++;
    }
    if (_burnApproved4 > 0) {
      require(_burnApproved4 == burnToken, "you must get the right approval from approver4");
      sum_approval++;
    }
    require((sum_approval >= 2), "you must get the 2 approvals at least");
    _burn(msg.sender, burnToken);
    _addedSupplyToken = (_addedSupplyToken - burnToken);
    _burnApproved1 = 0;
    _burnApproved2 = 0;
    _burnApproved3 = 0;
    _burnApproved4 = 0;
    return true;
  }
  
  function mint_approve_up(uint256 approveToken) onlyApprover external returns (bool) {
    if (msg.sender == _approver1) {
      _mintApproved1 = approveToken;
    }
    else if (msg.sender == _approver2) {
      _mintApproved2 = approveToken;
    }
    else if (msg.sender == _approver3) {
      _mintApproved3 = approveToken;
    }
    else if (msg.sender == _approver4) {
      _mintApproved4 = approveToken;
    }
    return true;
  }
  function mint_approve_down() onlyApprover external returns (bool) {
    if (msg.sender == _approver1) {
      _mintApproved1 = 0;
    }
    else if (msg.sender == _approver2) {
      _mintApproved2 = 0;
    }
    else if (msg.sender == _approver3) {
      _mintApproved3 = 0;
    }
    else if (msg.sender == _approver4) {
      _mintApproved4 = 0;
    }
    return true;
  }
  function mint(uint256 addedToken) listingDT onlyOwner external returns (bool) {
    require((_listingDate + _mint_term) <= block.number, "creating new token is not yet");
    require(MAX_MINT_POC >= (_addedSupplyToken + addedToken), "mint is reached on max");
    uint8 sum_approval = 0;
    if (_mintApproved1 > 0) {
      require(_mintApproved1 == addedToken, "you must get the right approval from approver1");
      sum_approval++;
    }
    if (_mintApproved2 > 0) {
      require(_mintApproved2 == addedToken, "you must get the right approval from approver2");
      sum_approval++;
    }
    if (_mintApproved3 > 0) {
      require(_mintApproved3 == addedToken, "you must get the right approval from approver3");
      sum_approval++;
    }
    if (_mintApproved4 > 0) {
      require(_mintApproved4 == addedToken, "you must get the right approval from approver4");
      sum_approval++;
    }
    require((sum_approval >= 2), "you must get the 2 approvals at least");
    _mint(_owner, addedToken);
    _addedSupplyToken = (_addedSupplyToken + addedToken);
    _mintApproved1 = 0;
    _mintApproved2 = 0;
    _mintApproved3 = 0;
    _mintApproved4 = 0;
    return true;
  }
  
  function reschedule_approve_up(uint256 approveBlock) onlyApprover external returns (bool) {
    if (msg.sender == _approver1) {
      _rescheduleApproved1 = approveBlock;
    }
    else if (msg.sender == _approver2) {
      _rescheduleApproved2 = approveBlock;
    }
    else if (msg.sender == _approver3) {
      _rescheduleApproved3 = approveBlock;
    }
    else if (msg.sender == _approver4) {
      _rescheduleApproved4 = approveBlock;
    }
    return true;
  }
  function reschedule_approve_down() onlyApprover external returns (bool) {
    if (msg.sender == _approver1) {
      _rescheduleApproved1 = 0;
    }
    else if (msg.sender == _approver2) {
      _rescheduleApproved2 = 0;
    }
    else if (msg.sender == _approver3) {
      _rescheduleApproved3 = 0;
    }
    else if (msg.sender == _approver4) {
      _rescheduleApproved4 = 0;
    }
    return true;
  }
  function reschedule(uint256 term_hour_changeDate, uint8 new_seconds_per_block) onlyOwner external {
    uint8 sum_approval = 0;
    if (_rescheduleApproved1 > 0) {
      require(_rescheduleApproved1 == new_seconds_per_block, "you must get the right approval from approver1");
      sum_approval++;
    }
    if (_rescheduleApproved2 > 0) {
      require(_rescheduleApproved2 == new_seconds_per_block, "you must get the right approval from approver2");
      sum_approval++;
    }
    if (_rescheduleApproved3 > 0) {
      require(_rescheduleApproved3 == new_seconds_per_block, "you must get the right approval from approver3");
      sum_approval++;
    }
    if (_rescheduleApproved4 > 0) {
      require(_rescheduleApproved4 == new_seconds_per_block, "you must get the right approval from approver4");
      sum_approval++;
    }
    require((sum_approval >= 2), "you must get the 2 approvals at least");
    // changeDate means the date(block.number) of when ETH2.0 chagnes the rule to 6s
    uint256 changeDate = block.number;
    if (term_hour_changeDate > 0) {
      changeDate = changeDate - (term_hour_changeDate * 60 * 60 / new_seconds_per_block);
    }
    // recalculate some schedules only which it's not used(reached) yet
    uint256 recalculate_target;
    for (uint i=(schedule.length - 1); i>0; i--) {
      if (changeDate <= schedule[i-1].day) {
        recalculate_target = (schedule[i-1].day - changeDate) * _seconds_per_block;
        schedule[i-1].day = changeDate + (recalculate_target / new_seconds_per_block);
      } 
      else {
        break;
      }
    }
    _seconds_per_block = new_seconds_per_block;
  }
  
    function approve_clear(uint8 target) onlyOwner external returns (bool) {
      if (target == 1) {
        _burnApproved1 = 0;
        _burnApproved2 = 0;
        _burnApproved3 = 0;
        _burnApproved4 = 0;
        return true;
      }
      else if (target == 2) {
        _mintApproved1 = 0;
        _mintApproved2 = 0;
        _mintApproved3 = 0;
        _mintApproved4 = 0;
        return true;
      }
      else if (target == 3) {
        _rescheduleApproved1 = 0;
        _rescheduleApproved2 = 0;
        _rescheduleApproved3 = 0;
        _rescheduleApproved4 = 0;
        return true;
      }
      else {
       return false;   
      }
  }

  function transfer(address recipient, uint256 amount) listingDT unlocking(amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) listingDT public virtual override returns (bool) {
    if (msg.sender == _owner){
      require(transferable() >= amount, "lack of transferable token");
    }
    if (super.transferFrom(sender, recipient, amount)) {
      return true;
    }
    else 
    {
      return false;
    }
  }
  
}