// SPDX-License-Identifier: Apache license 2.0
pragma solidity ^0.7.0;


abstract contract Context {
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this;
    return msg.data;
  }
}

interface IERC20 {
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
}


contract ERC20 is Context, IERC20 {
  using SafeMathUint for uint256;

  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 internal _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name, string memory symbol) {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
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

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public override view returns (uint256) {
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
  function allowance(address owner, address spender)
    public
    virtual
    override
    view
    returns (uint256)
  {
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
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
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

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
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

    _beforeMint();
    _beforeTokenTransfer(address(0), account, amount);

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
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called before any token mint.
   */
  function _beforeMint() internal virtual {}
}


abstract contract ERC20Mintable is Context, ERC20 {
  /**
   * @dev Creates `amount` tokens for `account`.
   *
   * See {ERC20-_mint}.
   */
  function mint(address account, uint256 amount) external virtual returns (bool success) {
    _mint(account, amount);
    return true;
  }
}


interface IStaking {
  /**
   * @dev Emitted when the `user` stakes an `amount` of tokens and
   * passes arbitrary `data`, therefore `total` is changed as well,
   * `personalStakeIndex`, `unlockedTimestamp` and `stakePercentageBasisPoints` are captured
   * according to the chosen stake option.
   */
  event LogStaked(
    address indexed user,
    uint256 amount,
    uint256 personalStakeIndex,
    uint256 unlockedTimestamp,
    uint16 stakePercentageBasisPoints,
    uint256 total,
    bytes data
  );

  /**
   * @dev Emitted when the `user` unstakes an `amount` of tokens and
   * passes arbitrary `data`, therefore `total` is changed as well,
   * `personalStakeIndex` and `stakeReward` are captured.
   */
  event LogUnstaked(
    address indexed user,
    uint256 amount,
    uint256 personalStakeIndex,
    uint256 stakeReward,
    uint256 total,
    bytes data
  );

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
   * @notice MUST trigger Staked event
   * @param stakeOptionIndex uint8 the chosen stake option
   * @param amount uint256 the amount of tokens to stake
   * @param data bytes optional data to include in the Stake event
   */
  function stake(
    uint8 stakeOptionIndex,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
   * @notice MUST trigger Staked event
   * @param stakeOptionIndex uint8 the chosen stake option
   * @param user address the address the tokens are staked for
   * @param amount uint256 the amount of tokens to stake
   * @param data bytes optional data to include in the Stake event
   */
  function stakeFor(
    uint8 stakeOptionIndex,
    address user,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @notice Unstakes tokens, this SHOULD return the given amount of tokens to the user,
   * if unstaking is currently not possible the function MUST revert
   * @notice MUST trigger Unstaked event
   * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
   * @dev Stake reward is minted if function is called after the stake's `unlockTimestamp`.
   * @param personalStakeIndex uint256 index of the stake to withdraw in the personalStakes mapping
   * @param data bytes optional data to include in the Unstake event
   */
  function unstake(uint256 personalStakeIndex, bytes calldata data) external;

  /**
   * @notice Returns the current total of tokens staked for an address
   * @param addr address The address to query
   * @return uint256 The number of tokens staked for the given address
   */
  function totalStakedFor(address addr) external view returns (uint256);

  /**
   * @notice Returns the current total of tokens staked
   * @return uint256 The number of tokens staked in the contract
   */
  function totalStaked() external view returns (uint256);

  /**
   * @notice Address of the token being used by the staking interface
   * @return address The address of the ERC20 token used for staking
   */
  function token() external view returns (address);

  /**
   * @notice MUST return true if the optional history functions are implemented, otherwise false
   * @dev Since we don't implement the optional interface, this always returns false
   * @return bool Whether or not the optional history functions are implemented
   */
  function supportsHistory() external pure returns (bool);

  /**
   * @notice Sets the pairs of currently available staking options,
   * which will regulate the stake duration and reward percentage.
   * Stakes that were created through the old stake options will remain unchanged.
   * @param stakeDurations uint256[] array of stake option durations
   * @param stakePercentageBasisPoints uint16[] array of stake rewarding percentages (basis points)
   */
  function setStakingOptions(
    uint256[] memory stakeDurations,
    uint16[] memory stakePercentageBasisPoints
  ) external;

  /**
   * @notice Returns the pairs of currently available staking options,
   * so that staker can choose a suitable combination of
   * stake duration and reward percentage.
   * @return stakeOptionIndexes uint256[] array of the stake option indexes used in other functions of this contract
   * @return stakeDurations uint256[] array of stake option durations
   * @return stakePercentageBasisPoints uint16[] array of stake rewarding percentages (basis points)
   */
  function getStakingOptions()
    external
    view
    returns (
      uint256[] memory stakeOptionIndexes,
      uint256[] memory stakeDurations,
      uint16[] memory stakePercentageBasisPoints
    );

  /**
   * @dev Returns the stake indexes for
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake indexes array
   */
  function getPersonalStakeIndexes(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns the stake unlock timestamps for
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake unlock timestamps array
   */
  function getPersonalStakeUnlockedTimestamps(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns the stake values of
   * the last `amountToRetrieve` (with `offset` for pagination)
   * the personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake values array
   */
  function getPersonalStakeActualAmounts(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns the adresses of stake owners of
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return address[] addresses of stake owners array
   */
  function getPersonalStakeForAddresses(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (address[] memory);

  /**
   * @dev Returns the stake rewards percentage (basis points) of
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake rewards percentage (basis points) array
   */
  function getPersonalStakePercentageBasisPoints(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);
}

library SafeMathUint {
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  /**
   * @dev Converts an unsigned integer to a signed integer,
   * Reverts when convertation overflows.
   *
   * Requirements:
   *
   * - Operation cannot overflow.
   */
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0, "SafeMath: convertation overflow");
    return b;
  }
}




abstract contract Ownable is Context {
  event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  address private _owner;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _owner = _msgSender();
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
    require(_msgSender() == _owner, "Ownable: only contract owner can call this function.");
    _;
  }

  /**
   * @dev Checks if transaction sender account is an owner.
   */
  function isOwner() external view returns (bool) {
    return _msgSender() == _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit LogOwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract Staking is IStaking, Context, Ownable {
  using SafeMathUint for uint256;

  ERC20Mintable _stakingToken;

  // To save on gas, rather than create a separate mapping for totalStakedFor & personalStakes,
  // both data structures are stored in a single mapping for a given addresses.
  // It's possible to have a non-existing personalStakes, but have tokens in totalStakedFor
  // if other users are staking on behalf of a given address.
  mapping(address => StakeContract) public _stakeHolders;
  mapping(uint256 => StakeOption[]) private _stakeOptions;
  uint256 private _currentStakeOptionArrayIndex;

  // Struct for staking options
  // stakeDuration - seconds to pass before the stake unlocks
  // stakePercentageBasisPoints - the staking reward percentage (basis points)
  struct StakeOption {
    uint256 stakeDuration;
    uint16 stakePercentageBasisPoints;
  }

  // Struct for personal stakes (i.e., stakes made by this address)
  // unlockedTimestamp - when the stake unlocks (in seconds since Unix epoch)
  // actualAmount - the amount of tokens in the stake
  // stakedFor - the address the stake was staked for
  struct Stake {
    uint256 unlockedTimestamp;
    uint256 actualAmount;
    address stakedFor;
    uint256 stakePercentageBasisPoints;
  }

  // Struct for all stake metadata at a particular address
  // totalStakedFor - the number of tokens staked for this address
  // personalStakesLastIndex - index of the last stake in the personalStakes mapping
  // personalStakes - append only mapping of stakes made by this address
  // exists - whether or not there are stakes that involve this address
  struct StakeContract {
    uint256 totalStakedFor;
    uint256 personalStakesLastIndex;
    mapping(uint256 => Stake) personalStakes;
    bool exists;
  }

  /**
   * @dev Sets the {ERC20Mintable} staking token.
   */
  constructor(ERC20Mintable stakingToken) {
    _stakingToken = stakingToken;
  }

  /**
   * @dev See {IStaking-setStakingOptions}
   *
   * Requirements:
   *
   * - `stakeDurations` and `stakePercentageBasisPoints` arrays passed to
   * this function cannot be empty or have a different length.
   */
  function setStakingOptions(
    uint256[] memory stakeDurations,
    uint16[] memory stakePercentageBasisPoints
  ) external override onlyOwner {
    require(
      stakeDurations.length == stakePercentageBasisPoints.length && stakeDurations.length > 0,
      "Staking: stake duration and percentage basis points arrays should be equal in size and non-empty"
    );

    _currentStakeOptionArrayIndex = _currentStakeOptionArrayIndex.add(1);
    for (uint256 i = 0; i < stakeDurations.length; i++) {
      _stakeOptions[_currentStakeOptionArrayIndex].push(
        StakeOption(stakeDurations[i], stakePercentageBasisPoints[i])
      );
    }
  }

  /**
   * @dev See {IStaking-getStakingOptions}
   */
  function getStakingOptions()
    external
    override
    view
    returns (
      uint256[] memory stakeOptionIndexes,
      uint256[] memory stakeDurations,
      uint16[] memory stakePercentageBasisPoints
    )
  {
    stakeOptionIndexes = new uint256[](_stakeOptions[_currentStakeOptionArrayIndex].length);
    stakeDurations = new uint256[](_stakeOptions[_currentStakeOptionArrayIndex].length);
    stakePercentageBasisPoints = new uint16[](_stakeOptions[_currentStakeOptionArrayIndex].length);

    for (uint256 i = 0; i < _stakeOptions[_currentStakeOptionArrayIndex].length; i++) {
      stakeOptionIndexes[i] = i;
      stakeDurations[i] = _stakeOptions[_currentStakeOptionArrayIndex][i].stakeDuration;
      stakePercentageBasisPoints[i] = _stakeOptions[_currentStakeOptionArrayIndex][i]
        .stakePercentageBasisPoints;
    }

    return (stakeOptionIndexes, stakeDurations, stakePercentageBasisPoints);
  }

  /**
   * @dev See {IStaking-getPersonalStakeIndexes}
   */
  function getPersonalStakeIndexes(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external override view returns (uint256[] memory) {
    uint256[] memory indexes;
    (indexes, , , , ) = getPersonalStakes(user, amountToRetrieve, offset);

    return indexes;
  }

  /**
   * @dev See {IStaking-getPersonalStakeUnlockedTimestamps}
   */
  function getPersonalStakeUnlockedTimestamps(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external override view returns (uint256[] memory) {
    uint256[] memory timestamps;
    (, timestamps, , , ) = getPersonalStakes(user, amountToRetrieve, offset);

    return timestamps;
  }

  /**
   * @dev See {IStaking-getPersonalStakeActualAmounts}
   */
  function getPersonalStakeActualAmounts(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external override view returns (uint256[] memory) {
    uint256[] memory actualAmounts;
    (, , actualAmounts, , ) = getPersonalStakes(user, amountToRetrieve, offset);

    return actualAmounts;
  }

  /**
   * @dev See {IStaking-getPersonalStakeForAddresses}
   */
  function getPersonalStakeForAddresses(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external override view returns (address[] memory) {
    address[] memory stakedFor;
    (, , , stakedFor, ) = getPersonalStakes(user, amountToRetrieve, offset);

    return stakedFor;
  }

  /**
   * @dev See {IStaking-getPersonalStakePercentageBasisPoints}
   */
  function getPersonalStakePercentageBasisPoints(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external override view returns (uint256[] memory) {
    uint256[] memory stakePercentageBasisPoints;
    (, , , , stakePercentageBasisPoints) = getPersonalStakes(user, amountToRetrieve, offset);

    return stakePercentageBasisPoints;
  }

  /**
   * @dev Helper function to get specific properties of all of the personal stakes created by the `user`
   * @param user address The address to query
   * @return (uint256[], uint256[], address[], uint256[] memory)
   *  timestamps array, actualAmounts array, stakedFor array, stakePercentageBasisPoints array
   */
  function getPersonalStakes(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  )
    public
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      address[] memory,
      uint256[] memory
    )
  {
    StakeContract storage stakeContract = _stakeHolders[user];

    uint256 offsetStakeAmount = stakeContract.personalStakesLastIndex.sub(offset);
    if (amountToRetrieve > offsetStakeAmount) {
      amountToRetrieve = offsetStakeAmount;
    }
    uint256[] memory stakeIndexes = new uint256[](amountToRetrieve);
    uint256[] memory unlockedTimestamps = new uint256[](amountToRetrieve);
    uint256[] memory actualAmounts = new uint256[](amountToRetrieve);
    address[] memory stakedFor = new address[](amountToRetrieve);
    uint256[] memory stakePercentageBasisPoints = new uint256[](amountToRetrieve);

    uint256 retrieved;
    for (uint256 i = stakeContract.personalStakesLastIndex.sub(1).sub(offset); i >= 0; i--) {
      stakeIndexes[retrieved] = i;
      unlockedTimestamps[retrieved] = stakeContract.personalStakes[i].unlockedTimestamp;
      actualAmounts[retrieved] = stakeContract.personalStakes[i].actualAmount;
      stakedFor[retrieved] = stakeContract.personalStakes[i].stakedFor;
      stakePercentageBasisPoints[retrieved] = stakeContract.personalStakes[i]
        .stakePercentageBasisPoints;

      if (++retrieved >= amountToRetrieve) {
        break;
      }
    }

    return (stakeIndexes, unlockedTimestamps, actualAmounts, stakedFor, stakePercentageBasisPoints);
  }

  /**
   * @dev See {IStaking-stake}
   */
  function stake(
    uint8 stakeOptionIndex,
    uint256 amount,
    bytes calldata data
  ) external override validStakeOption(stakeOptionIndex) {
    createStake(
      _msgSender(),
      amount,
      _stakeOptions[_currentStakeOptionArrayIndex][stakeOptionIndex].stakeDuration,
      _stakeOptions[_currentStakeOptionArrayIndex][stakeOptionIndex].stakePercentageBasisPoints,
      data
    );
  }

  /**
   * @dev See {IStaking-stakeFor}
   */
  function stakeFor(
    uint8 stakeOptionIndex,
    address user,
    uint256 amount,
    bytes calldata data
  ) public override validStakeOption(stakeOptionIndex) {
    createStake(
      user,
      amount,
      _stakeOptions[_currentStakeOptionArrayIndex][stakeOptionIndex].stakeDuration,
      _stakeOptions[_currentStakeOptionArrayIndex][stakeOptionIndex].stakePercentageBasisPoints,
      data
    );
  }

  /**
   * @dev See {IStaking-unstake}
   */
  function unstake(uint256 personalStakeIndex, bytes calldata data) external override {
    withdrawStake(personalStakeIndex, data);
  }

  /**
   * @dev See {IStaking-totalStakedFor}
   */
  function totalStakedFor(address user) public override view returns (uint256) {
    return _stakeHolders[user].totalStakedFor;
  }

  /**
   * @dev See {IStaking-totalStaked}
   */
  function totalStaked() external override view returns (uint256) {
    return _stakingToken.balanceOf(address(this));
  }

  /**
   * @dev See {IStaking-token}
   */
  function token() external override view returns (address) {
    return address(_stakingToken);
  }

  /**
   * @dev See {IStaking-supportsHistory}
   *
   * Since we don't implement the optional interface, this always returns false
   */
  function supportsHistory() external override pure returns (bool) {
    return false;
  }

  /**
   * @dev Helper function to create stakes for a given address
   * @param user address The address the stake is being created for
   * @param amount uint256 The number of tokens being staked
   * @param lockInDuration uint256 The duration to lock the tokens for
   * @param data bytes optional data to include in the Stake event
   * @param stakePercentageBasisPoints uint16 stake reward percentage (basis points)
   *
   * Requirements:
   *
   * - `_stakingToken` allowance should be granted to {Staking} contract
   * address in order for the stake creation to be successful.
   */
  function createStake(
    address user,
    uint256 amount,
    uint256 lockInDuration,
    uint16 stakePercentageBasisPoints,
    bytes calldata data
  ) internal {
    require(
      _stakingToken.transferFrom(_msgSender(), address(this), amount),
      "Staking: stake required"
    );

    if (!_stakeHolders[user].exists) {
      _stakeHolders[user].exists = true;
    }

    uint256 unlockedTimestamp = block.timestamp.add(lockInDuration);
    _stakeHolders[user].totalStakedFor = _stakeHolders[user].totalStakedFor.add(amount);
    _stakeHolders[user].personalStakes[_stakeHolders[user].personalStakesLastIndex] = Stake({
      unlockedTimestamp: unlockedTimestamp,
      actualAmount: amount,
      stakedFor: user,
      stakePercentageBasisPoints: stakePercentageBasisPoints
    });

    emit LogStaked(
      user,
      amount,
      _stakeHolders[user].personalStakesLastIndex,
      unlockedTimestamp,
      stakePercentageBasisPoints,
      totalStakedFor(user),
      data
    );
    _stakeHolders[user].personalStakesLastIndex = _stakeHolders[user].personalStakesLastIndex.add(
      1
    );
  }

  /**
   * @dev Helper function to withdraw stakes for the msg.sender
   * @param personalStakeIndex uint256 index of the stake to withdraw in the personalStakes mapping
   * @param data bytes optional data to include in the Unstake event
   *
   * Requirements:
   *
   * - valid personal stake index is passed.
   * - stake should not be already withdrawn.
   * - `_stakingToken` should transfer the stake amount successfully.
   * - `_stakingToken` should {mint} the stake reward successfully
   * if function is called after the stake's `unlockTimestamp`.
   */
  function withdrawStake(uint256 personalStakeIndex, bytes calldata data) internal {
    require(
      personalStakeIndex <= _stakeHolders[_msgSender()].personalStakesLastIndex.sub(1),
      "Staking: passed the wrong personal stake index"
    );

    Stake storage personalStake = _stakeHolders[_msgSender()].personalStakes[personalStakeIndex];

    require(personalStake.actualAmount > 0, "Staking: already withdrawn this stake");

    require(
      _stakingToken.transfer(_msgSender(), personalStake.actualAmount),
      "Staking: unable to withdraw the stake"
    );

    uint256 stakeReward = 0;
    if (personalStake.unlockedTimestamp <= block.timestamp) {
      stakeReward = personalStake.actualAmount.mul(personalStake.stakePercentageBasisPoints).div(
        uint256(10000)
      );
      require(
        _stakingToken.mint(_msgSender(), stakeReward),
        "Staking: unable to mint the stake reward"
      );
    }

    _stakeHolders[personalStake.stakedFor].totalStakedFor = _stakeHolders[personalStake.stakedFor]
      .totalStakedFor
      .sub(personalStake.actualAmount);

    emit LogUnstaked(
      personalStake.stakedFor,
      personalStake.actualAmount,
      personalStakeIndex,
      stakeReward,
      totalStakedFor(personalStake.stakedFor),
      data
    );

    personalStake.actualAmount = 0;
  }

  /**
   * @dev Modifier that checks if passed `stakeOptionIndex` is valid.
   *
   * Requirements:
   *
   * - `_stakeOptions[_currentStakeOptionArrayIndex]` should not be empty,
   * which means there are valid staking options at the moment.
   * - `stakeOptionIndex` should be a valid index of any stake option
   * in `_stakeOptions[_currentStakeOptionArrayIndex]`.
   */
  modifier validStakeOption(uint8 stakeOptionIndex) {
    require(
      _currentStakeOptionArrayIndex > 0 && _stakeOptions[_currentStakeOptionArrayIndex].length > 0,
      "Staking: no available staking options at the moment."
    );
    require(
      stakeOptionIndex < _stakeOptions[_currentStakeOptionArrayIndex].length,
      "Staking: passed a non-valid stake option index."
    );
    _;
  }
}