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

import "../IERC20.sol";

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
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "../library/ERC20.sol";

import "../interfaces/IERC900.sol";


contract BasicStakeContract is IERC900 {
  // @TODO: deploy this separately so we don't have to deploy it multiple times for each contract

  // Token used for staking
  ERC20 stakingToken;

  // The default duration of stake lock-in (in seconds)
  uint256 public defaultLockInDuration;

  // To save on gas, rather than create a separate mapping for totalStakedFor & personalStakes,
  //  both data structures are stored in a single mapping for a given addresses.
  mapping (address => StakeContract) public stakeHolders;

  // Struct for personal stakes (i.e., stakes made by this address)
  // unlockedTimestamp - when the stake unlocks (in seconds since Unix epoch)
  // actualAmount - the amount of tokens in the stake
  // stakedFor - the address the stake was staked for
  struct Stake {
    uint256 unlockedTimestamp;
    uint256 actualAmount;
    address stakedFor;
  }

  // Struct for all stake metadata at a particular address
  // totalStakedFor - the number of tokens staked for this address
  // personalStakeIndex - the index in the personalStakes array.
  // personalStakes - append only array of stakes made by this address
  // exists - whether or not there are stakes that involve this address
  struct StakeContract {
    uint256 totalStakedFor;

    uint256 personalStakeIndex;

    Stake[] personalStakes;

    bool exists;
  }

  /**
   * @dev Modifier that checks that this contract can transfer tokens from the
   *  balance in the stakingToken contract for the given address.
   * @dev This modifier also transfers the tokens.
   * @param _address address to transfer tokens from
   * @param _amount uint256 the number of tokens
   */
  modifier canStake(address _address, uint256 _amount) {
    require(
      stakingToken.transferFrom(_address, address(this), _amount),
      "Stake required");

    _;
  }

  /**
   * @dev Constructor function
   * @param _stakingToken ERC20 The address of the token contract used for staking
   */
  constructor(ERC20 _stakingToken) {
    stakingToken = _stakingToken;
  }

  /**
   * @dev Returns the timestamps for when active personal stakes for an address will unlock
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of timestamps
   */
  function getPersonalStakeUnlockedTimestamps(address _address) external view returns (uint256[] memory) {
    uint256[] memory timestamps;
    (timestamps,,) = getPersonalStakes(_address);

    return timestamps;
  }

  /**
   * @dev Returns the stake actualAmount for active personal stakes for an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of actualAmounts
   */
  function getPersonalStakeActualAmounts(address _address) external view returns (uint256[] memory) {
    uint256[] memory actualAmounts;
    (,actualAmounts,) = getPersonalStakes(_address);

    return actualAmounts;
  }

  /**
   * @dev Returns the addresses that each personal stake was created for by an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return address[] array of amounts
   */
  function getPersonalStakeForAddresses(address _address) external view returns (address[] memory) {
    address[] memory stakedFor;
    (,,stakedFor) = getPersonalStakes(_address);

    return stakedFor;
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stake(uint256 _amount, bytes memory _data) public virtual override {
    createStake(
      msg.sender,
      _amount,
      defaultLockInDuration,
      _data);
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
   * @notice MUST trigger Staked event
   * @param _user address the address the tokens are staked for
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stakeFor(address _user, uint256 _amount, bytes memory _data) public virtual override {
    createStake(
      _user,
      _amount,
      defaultLockInDuration,
      _data);
  }

  /**
   * @notice Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
   * @notice MUST trigger Unstaked event
   * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
   * @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
   *  transferred back to their account, and their personalStakeIndex will increment to the next active stake.
   * @param _amount uint256 the amount of tokens to unstake
   * @param _data bytes optional data to include in the Unstake event
   */
  function unstake(uint256 _amount, bytes memory _data) public override {
    withdrawStake(
      _amount,
      _data);
  }

  /**
   * @notice Returns the current total of tokens staked for an address
   * @param _address address The address to query
   * @return uint256 The number of tokens staked for the given address
   */
  function totalStakedFor(address _address) public view override returns (uint256) {
    return stakeHolders[_address].totalStakedFor;
  }

  /**
   * @notice Returns the current total of tokens staked
   * @return uint256 The number of tokens staked in the contract
   */
  function totalStaked() public view override returns (uint256) {
    return stakingToken.balanceOf(address(this));
  }

  /**
   * @notice Address of the token being used by the staking interface
   * @return address The address of the ERC20 token used for staking
   */
  function token() public view override returns (address) {
    return address(stakingToken);
  }

  /**
   * @notice MUST return true if the optional history functions are implemented, otherwise false
   * @dev Since we don't implement the optional interface, this always returns false
   * @return bool Whether or not the optional history functions are implemented
   */
  function supportsHistory() public pure override returns (bool) {
    return false;
  }

  /**
   * @dev Helper function to get specific properties of all of the personal stakes created by an address
   * @param _address address The address to query
   * @return (uint256[], uint256[], address[])
   *  timestamps array, actualAmounts array, stakedFor array
   */
  function getPersonalStakes(
    address _address
  )
    view
    public
    returns(uint256[] memory, uint256[] memory, address[] memory)
  {
    StakeContract storage stakeContract = stakeHolders[_address];

    uint256 arraySize = stakeContract.personalStakes.length - stakeContract.personalStakeIndex;
    uint256[] memory unlockedTimestamps = new uint256[](arraySize);
    uint256[] memory actualAmounts = new uint256[](arraySize);
    address[] memory stakedFor = new address[](arraySize);

    for (uint256 i = stakeContract.personalStakeIndex; i < stakeContract.personalStakes.length; i++) {
      uint256 index = i - stakeContract.personalStakeIndex;
      unlockedTimestamps[index] = stakeContract.personalStakes[i].unlockedTimestamp;
      actualAmounts[index] = stakeContract.personalStakes[i].actualAmount;
      stakedFor[index] = stakeContract.personalStakes[i].stakedFor;
    }

    return (
      unlockedTimestamps,
      actualAmounts,
      stakedFor
    );
  }

  /**
   * @dev Helper function to create stakes for a given address
   * @param _address address The address the stake is being created for
   * @param _amount uint256 The number of tokens being staked
   * @param _lockInDuration uint256 The duration to lock the tokens for
   * @param _data bytes optional data to include in the Stake event
   */
  function createStake(
    address _address,
    uint256 _amount,
    uint256 _lockInDuration,
    bytes memory _data
  )
    internal
    virtual
    canStake(msg.sender, _amount)
  {
    if (!stakeHolders[msg.sender].exists) {
      stakeHolders[msg.sender].exists = true;
    }

    stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor + _amount;
    stakeHolders[msg.sender].personalStakes.push(
      Stake(
        block.timestamp + _lockInDuration,
        _amount,
        _address)
      );

    emit Staked(
      _address,
      _amount,
      totalStakedFor(_address),
      _data);
  }

  /**
   * @dev Helper function to withdraw stakes for the msg.sender
   * @param _amount uint256 The amount to withdraw. MUST match the stake amount for the
   *  stake at personalStakeIndex.
   * @param _data bytes optional data to include in the Unstake event
   */
  function withdrawStake(
    uint256 _amount,
    bytes memory _data
  )
    internal virtual
  {
    Stake storage personalStake = stakeHolders[msg.sender].personalStakes[stakeHolders[msg.sender].personalStakeIndex];

    // Check that the current stake has unlocked & matches the unstake amount
    require(
      personalStake.unlockedTimestamp <= block.timestamp,
      "The current stake hasn't unlocked yet");

    require(
      personalStake.actualAmount == _amount,
      "The unstake amount does not match the current stake");

    // Transfer the staked tokens from this contract back to the sender
    // Notice that we are using transfer instead of transferFrom here, so
    //  no approval is needed beforehand.
    require(
      stakingToken.transfer(msg.sender, _amount),
      "Unable to withdraw stake");

    stakeHolders[personalStake.stakedFor].totalStakedFor = stakeHolders[personalStake.stakedFor]
      .totalStakedFor - personalStake.actualAmount;

    personalStake.actualAmount = 0;
    stakeHolders[msg.sender].personalStakeIndex++;

    emit Unstaked(
      personalStake.stakedFor,
      _amount,
      totalStakedFor(personalStake.stakedFor),
      _data);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./BasicStakeContract.sol";

abstract contract CompoundingStakeContract is BasicStakeContract {
    // For token staked longer than a year, they will become more valuable by this coefficient
    //  e.g., if annualizedInterestRate is 10e17 (0.1 ether), after 1 year the perceived stake is 10% more valuable.
    // Stakeholders will have to ping the contract via updatePerceivedStakeAmounts to have
    //  the contract update the perceived amounts of their stakes.
    uint256 public annualizedInterestRate;

    // The number of seconds in a year (365.25 days)
    // Used for determining when stakes are eligible for interest
    uint256 public constant YEAR_IN_SECONDS = 31557600;

    mapping(address => CompoundingStake[]) public perceivedAmountBalances;

    struct CompoundingStake {
        uint256 lastUpdatedTimestamp;
        uint256 perceivedAmount;
    }

    // constructor(ERC20 _stakingToken) BasicStakeContract(_stakingToken){

    // }

    /**
     * @dev Returns the stake perceivedAmount for active personal stakes for an address
     * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
     * @param _address address that created the stakes
     * @return uint256[] array of perceivedAmounts
     */
    function getPersonalStakePerceivedAmounts(address _address)
        external
        view
        returns (uint256[] memory)
    {
        StakeContract storage stakeContract = stakeHolders[_address];

        uint256 arraySize = stakeContract.personalStakes.length -
            stakeContract.personalStakeIndex;
        uint256[] memory perceivedAmounts = new uint256[](arraySize);

        for (
            uint256 i = stakeContract.personalStakeIndex;
            i < stakeContract.personalStakes.length;
            i++
        ) {
            uint256 index = i - stakeContract.personalStakeIndex;
            perceivedAmounts[index] = perceivedAmountBalances[_address][i]
                .perceivedAmount;
        }

        return perceivedAmounts;
    }

    function collectInterest(address _address) external {
        StakeContract storage stakeContract = stakeHolders[_address];

        for (
            uint256 i = stakeContract.personalStakeIndex;
            i < stakeContract.personalStakes.length;
            i++
        ) {
            Stake storage currentStake = stakeContract.personalStakes[i];
            CompoundingStake storage compoundingStake = perceivedAmountBalances[
                _address
            ][i];
            uint256 lastUpdatedTimestamp = compoundingStake
                .lastUpdatedTimestamp;

            // If interest has accrued over multiple years, the actual interest received will be higher than the
            //  annualized interest rate, so we use a loop to accrue this over multiple years
            // @TODO: There are some gas optimizations that can be made here (i.e., calculated the compoundedInterest rate)
            while (block.timestamp - lastUpdatedTimestamp >= YEAR_IN_SECONDS) {
                uint256 unit = 1 ether;

                uint256 newAmount = (compoundingStake.perceivedAmount *
                    (annualizedInterestRate + unit)) / unit;
                uint256 difference = newAmount -
                    compoundingStake.perceivedAmount;

                // Update the totalStakedFor with the interest received
                stakeHolders[currentStake.stakedFor].totalStakedFor =
                    stakeHolders[currentStake.stakedFor].totalStakedFor +
                    difference;

                // Update the perceivedAmount with the interest received
                compoundingStake.perceivedAmount = newAmount;

                // SafeMath not needed here
                lastUpdatedTimestamp += YEAR_IN_SECONDS;
            }

            // Update the timestamp, so this stake is only eligible for interest a year from now
            if (compoundingStake.lastUpdatedTimestamp != lastUpdatedTimestamp) {
                compoundingStake.lastUpdatedTimestamp = block.timestamp;
            }
        }
    }

    /**
     * @dev Helper function to create stakes for a given address
     * @param _address address The address the stake is being created for
     * @param _amount uint256 The number of tokens being staked
     * @param _lockInDuration uint256 The duration to lock the tokens for
     */
    function createStake(
        address _address,
        uint256 _amount,
        uint256 _lockInDuration,
        bytes memory _data
    ) internal override {
        super.createStake(_address, _amount, _lockInDuration, _data);

        perceivedAmountBalances[msg.sender].push(
            CompoundingStake(block.timestamp, _amount)
        );
    }

    function withdrawStake(uint256 _amount, bytes memory _data)
        internal
        override
    {
        // @NOTE: We just update values involving the perceivedAmount here.
        // Other values will be taken care of in the call to the base class.
        Stake storage personalStake = stakeHolders[msg.sender].personalStakes[
            stakeHolders[msg.sender].personalStakeIndex
        ];
        CompoundingStake storage compoundingStake = perceivedAmountBalances[
            msg.sender
        ][stakeHolders[msg.sender].personalStakeIndex];

        uint256 difference = compoundingStake.perceivedAmount -
            personalStake.actualAmount;

        stakeHolders[personalStake.stakedFor].totalStakedFor =
            stakeHolders[personalStake.stakedFor].totalStakedFor -
            difference;

        compoundingStake.perceivedAmount = 0;

        super.withdrawStake(_amount, _data);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;


interface IERC900 {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    /**
     * @dev Stake a certain amount of tokens
     * @param _amount Amount of tokens to be staked
     * @param _data Optional data that can be used to add signalling information in more complex staking applications
     */
    function stake(uint256 _amount, bytes calldata _data) external;

    /**
     * @dev Stake a certain amount of tokens to another address
     * @param _user Address to stake tokens to
     * @param _amount Amount of tokens to be staked
     * @param _data Optional data that can be used to add signalling information in more complex staking applications
     */
    function stakeFor(address _user, uint256 _amount, bytes calldata _data) external;

    /**
     * @dev Unstake a certain amount of tokens
     * @param _amount Amount of tokens to be unstaked
     * @param _data Optional data that can be used to add signalling information in more complex staking applications
     */
    function unstake(uint256 _amount, bytes calldata _data) external;

    /**
     * @dev Tell the current total amount of tokens staked for an address
     * @param _addr Address to query
     * @return Current total amount of tokens staked for the address
     */
    function totalStakedFor(address _addr) external view returns (uint256);

    /**
     * @dev Tell the current total amount of tokens staked from all addresses
     * @return Current total amount of tokens staked from all addresses
     */
    function totalStaked() external view returns (uint256);

    /**
     * @dev Tell the address of the staking token
     * @return Address of the staking token
     */
    function token() external view returns (address);

    /*
     * @dev Tell if the optional history functions are implemented
     * @return True if the optional history functions are implemented
     */
    function supportsHistory() external pure returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "../ERC900/CompoundingStakeContract.sol";

/**
 * @title CompoundingStakeContractMock
 */
contract CompoundingStakeContractMock is CompoundingStakeContract {
    /**
     * @dev Constructor function
     * @param _stakingToken ERC20 The address of the token used for staking
     * @param _lockInDuration uint256 The default duration (in seconds) that stakes are created with
     * @param _annualizedInterestRate uint256 The default interest rate to use (should be an integer)
     */
    constructor(
        ERC20 _stakingToken,
        uint256 _lockInDuration,
        uint256 _annualizedInterestRate
    ) BasicStakeContract(_stakingToken) {
        defaultLockInDuration = _lockInDuration;
        annualizedInterestRate = _annualizedInterestRate;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}