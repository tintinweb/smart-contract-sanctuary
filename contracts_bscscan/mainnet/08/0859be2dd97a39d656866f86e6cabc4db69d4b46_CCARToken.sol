pragma solidity 0.6.4;

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CCARToken is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;
  
    // /**
    //  * @notice We usually require to know who are all the stakeholders.
    //  */
    // address[] internal stakeholders;

    // /**
    //  * @notice The stakes for each stakeholder.
    //  */
    // mapping(address => uint256) internal stakes;

    // /**
    //  * @notice The accumulated rewards for each stakeholder.
    //  */
    // mapping(address => uint256) internal rewards;

  constructor() public {
    _name = "Crypto Cars Token";
    _symbol = "CCAR";
    _decimals = 18;
    _totalSupply = 100000000000000000000000000;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint256) {
    return _decimals;
  }
  
  function name() external view returns (string memory) {
      return _name;
  }

  /**
   * @dev Returns the contract owner.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
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
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
  }
  
  
    // /**
    //  * @notice A method for a stakeholder to create a stake.
    //  * @param _stake The size of the stake to be created.
    //  */
    // function createStake(uint256 _stake)
    //     public
    // {
    //     require(_balances[msg.sender] >= _stake, "Insufficient coin to staking");
    //     // _burn(msg.sender, _stake);
    //     if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
    //     stakes[msg.sender] = stakes[msg.sender].add(_stake);
    //     _transfer(msg.sender, owner(), _stake);
    // }

    // /**
    //  * @notice A method for a stakeholder to remove a stake.
    //  * @param _stake The size of the stake to be removed.
    //  */
    // function removeStake(uint256 _stake)
    //     public
    // {
    //     require(stakes[msg.sender] >= _stake,  "Insufficient stake coins");
    //     stakes[msg.sender] = stakes[msg.sender].sub(_stake);
    //     if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
    //     _transfer(owner(), msg.sender, _stake);
    // }

    // /**
    //  * @notice A method to retrieve the stake for a stakeholder.
    //  * @param _stakeholder The stakeholder to retrieve the stake for.
    //  * @return uint256 The amount of wei staked.
    //  */
    // function stakeOf(address _stakeholder)
    //     public
    //     view
    //     returns(uint256)
    // {
    //     return stakes[_stakeholder];
    // }

    // /**
    //  * @notice A method to the aggregated stakes from all stakeholders.
    //  * @return uint256 The aggregated stakes from all stakeholders.
    //  */
    // function totalStakes()
    //     public
    //     view
    //     returns(uint256)
    // {
    //     uint256 _totalStakes = 0;
    //     for (uint256 s = 0; s < stakeholders.length; s += 1){
    //         _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
    //     }
    //     return _totalStakes;
    // }

    // // ---------- STAKEHOLDERS ----------

    // /**
    //  * @notice A method to check if an address is a stakeholder.
    //  * @param _address The address to verify.
    //  * @return bool, uint256 Whether the address is a stakeholder, 
    //  * and if so its position in the stakeholders array.
    //  */
    // function isStakeholder(address _address)
    //     public
    //     view
    //     returns(bool, uint256)
    // {
    //     for (uint256 s = 0; s < stakeholders.length; s += 1){
    //         if (_address == stakeholders[s]) return (true, s);
    //     }
    //     return (false, 0);
    // }

    // /**
    //  * @notice A method to add a stakeholder.
    //  * @param _stakeholder The stakeholder to add.
    //  */
    // function addStakeholder(address _stakeholder)
    //     public
    // {
    //     (bool _isStakeholder, ) = isStakeholder(_stakeholder);
    //     if(!_isStakeholder) stakeholders.push(_stakeholder);
    // }

    // /**
    //  * @notice A method to remove a stakeholder.
    //  * @param _stakeholder The stakeholder to remove.
    //  */
    // function removeStakeholder(address _stakeholder)
    //     public
    // {
    //     (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
    //     if(_isStakeholder){
    //         stakeholders[s] = stakeholders[stakeholders.length - 1];
    //         stakeholders.pop();
    //     } 
    // }

    // // ---------- REWARDS ----------
    
    // /**
    //  * @notice A method to allow a stakeholder to check his rewards.
    //  * @param _stakeholder The stakeholder to check rewards for.
    //  */
    // function rewardOf(address _stakeholder) 
    //     public
    //     view
    //     returns(uint256)
    // {
    //     return rewards[_stakeholder];
    // }

    // /**
    //  * @notice A method to the aggregated rewards from all stakeholders.
    //  * @return uint256 The aggregated rewards from all stakeholders.
    //  */
    // function totalRewards()
    //     public
    //     view
    //     returns(uint256)
    // {
    //     uint256 _totalRewards = 0;
    //     for (uint256 s = 0; s < stakeholders.length; s += 1){
    //         _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
    //     }
    //     return _totalRewards;
    // }

    // /** 
    //  * @notice A simple method that calculates the rewards for each stakeholder.
    //  * @param _stakeholder The stakeholder to calculate rewards for.
    //  */
    // function calculateReward(address _stakeholder)
    //     public
    //     view
    //     returns(uint256)
    // {
    //     return stakes[_stakeholder] / 100;
    // }

    // /**
    //  * @notice A method to distribute rewards to all stakeholders.
    //  */
    // function distributeRewards() 
    //     public
    //     onlyOwner
    // {
    //     for (uint256 s = 0; s < stakeholders.length; s += 1){
    //         address stakeholder = stakeholders[s];
    //         uint256 reward = calculateReward(stakeholder);
    //         rewards[stakeholder] = rewards[stakeholder].add(reward);
    //     }
    // }

    // /**
    //  * @notice A method to allow a stakeholder to withdraw his rewards.
    //  */
    // function withdrawReward(uint256 amount) 
    //     public
    // {
    //     uint256 reward = rewards[msg.sender];
    //     require(reward >= amount, "Insufficient rewards coins");
    //     rewards[msg.sender].sub(amount);
    //     _transfer(owner(), msg.sender, amount);
    // }
  
}