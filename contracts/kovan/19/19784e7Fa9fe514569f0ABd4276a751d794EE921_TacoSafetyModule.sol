/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File @paulrberg/contracts/token/erc20/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Erc20Storage
/// @author Paul Razvan Berg
/// @notice The storage interface of an Erc20 contract.
abstract contract Erc20Storage {
    /// @notice Returns the number of decimals used to get its user representation.
    uint8 public decimals;

    /// @notice Returns the name of the token.
    string public name;

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    string public symbol;

    /// @notice Returns the amount of tokens in existence.
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;
}


// File @paulrberg/contracts/token/erc20/[email protected]

/// @title Erc20Interface
/// @author Paul Razvan Berg
/// @notice Contract interface adhering to the Erc20 standard.
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/IERC20.sol
abstract contract Erc20Interface is Erc20Storage {
    /// CONSTANT FUNCTIONS ///
    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///
    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    /// EVENTS ///
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Burn(address indexed holder, uint256 burnAmount);

    event Mint(address indexed beneficiary, uint256 mintAmount);

    event Transfer(address indexed from, address indexed to, uint256 amount);
}


// File @paulrberg/contracts/token/erc20/[email protected]

/// @title Erc20
/// @author Paul Razvan Berg
/// @notice Implementation of the {Erc20Interface} interface.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
///@dev Forked from OpenZeppelin
///https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/Erc20/Erc20.sol
contract Erc20 is Erc20Interface {
    /// @notice All three of these values are immutable: they can only be set once during construction.
    /// @param name_ Erc20 name of this token.
    /// @param symbol_ Erc20 symbol of this token.
    /// @param decimals_ Erc20 decimal precision of this token.
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        approveInternal(msg.sender, spender, amount);
        return true;
    }

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least
    /// `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 newAllowance = allowances[msg.sender][spender] - subtractedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems
    /// described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        uint256 newAllowance = allowances[msg.sender][spender] + addedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        transferInternal(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have allowance for ``sender``'s tokens of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        transferInternal(sender, recipient, amount);
        uint256 newAllowance = allowances[sender][msg.sender] - amount;
        approveInternal(sender, msg.sender, newAllowance);
        return true;
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// This is internal function is equivalent to `approve`, and can be used to e.g. set automatic
    /// allowances for certain subsystems, etc.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    function approveInternal(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0x00), "ERR_ERC20_APPROVE_FROM_ZERO_ADDRESS");
        require(spender != address(0x00), "ERR_ERC20_APPROVE_TO_ZERO_ADDRESS");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Destroys `burnAmount` tokens from `holder`, recuding the token supply.
    ///
    /// @dev Emits a {Burn} event.
    ///
    /// Requirements:
    ///
    /// - `holder` must have at least `amount` tokens.
    function burnInternal(address holder, uint256 burnAmount) internal {
        // Burn the tokens.
        balances[holder] = balances[holder] - burnAmount;

        // Reduce the total supply.
        totalSupply = totalSupply - burnAmount;

        emit Burn(holder, burnAmount);
    }

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the
    /// the total supply.
    ///
    /// @dev Emits a {Mint} event.
    ///
    /// Requirements:
    ///
    /// - The beneficiary's balance and the total supply cannot overflow.
    function mintInternal(address beneficiary, uint256 mintAmount) internal {
        /// Mint the new tokens.
        balances[beneficiary] = balances[beneficiary] + mintAmount;

        /// Increase the total supply.
        totalSupply = totalSupply + mintAmount;

        emit Mint(beneficiary, mintAmount);
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient`.
    ///
    /// @dev This is internal function is equivalent to {transfer}, and can be used to e.g. implement
    /// automatic token fees, slashing mechanisms, etc.
    ///
    /// Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    function transferInternal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0x00), "ERR_ERC20_TRANSFER_FROM_ZERO_ADDRESS");
        require(recipient != address(0x00), "ERR_ERC20_TRANSFER_TO_ZERO_ADDRESS");

        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
    }
}


// File @paulrberg/contracts/token/erc20/[email protected]

/// @notice Erc20PermitStorage
/// @author Paul Razvan Berg
abstract contract Erc20PermitStorage {
    /// @notice The Eip712 domain's keccak256 hash.
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;

    /// @notice Provides replay protection.
    mapping(address => uint256) public nonces;

    /// @notice Eip712 version of this implementation.
    string public constant version = "1";
}


// File @paulrberg/contracts/token/erc20/[email protected]

/// @notice Erc20PermitInterface
/// @author Paul Razvan Berg
abstract contract Erc20PermitInterface is Erc20PermitStorage {
    /// NON-CONSTANT FUNCTIONS ///
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;
}


// File @paulrberg/contracts/token/erc20/[email protected]

/// @title Erc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
contract Erc20Permit is
    Erc20PermitInterface, /// one dependency
    Erc20 /// three dependencies
{
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) Erc20(name_, symbol_, decimals_) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /// @notice Sets `amount` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0x00), "ERR_ERC20_PERMIT_OWNER_ZERO_ADDRESS");
        require(spender != address(0x00), "ERR_ERC20_PERMIT_SPENDER_ZERO_ADDRESS");
        require(deadline >= block.timestamp, "ERR_ERC20_PERMIT_EXPIRED");

        // It's safe to use the "+" operator here because the nonce cannot realistically overflow, ever.
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address recoveredOwner = ecrecover(digest, v, r, s);

        require(recoveredOwner != address(0x00), "ERR_ERC20_PERMIT_RECOVERED_OWNER_ZERO_ADDRESS");
        require(recoveredOwner == owner, "ERR_ERC20_PERMIT_INVALID_SIGNATURE");

        approveInternal(owner, spender, amount);
    }
}


// File contracts/governanceToken/GovernanceTokenStorage.sol

/**
 * @title GovernanceTokenStorage
 * @author Hifi
 */
abstract contract GovernanceTokenStorage {
    /// @notice Tracks the delegation between the holders
    mapping (address => address) public delegates;

    /// @notice Chekpoint structure to keep track of the previous power
    struct Checkpoint {
        uint256 fromBlock;
        uint256 power;
    }

    /// @notice Tracks the checkpoints
    mapping (address => mapping (uint256 => Checkpoint)) public checkpoints;

    /// @notice Tracks the most recent checkpoint of an account
    mapping (address => uint256) public checkpointsOf;

    bytes32 public constant UPDATEDELEGATEBYSIG_TYPEHASH = keccak256("UpdateDelegateBySig(address delegator,address delegate,uint256 nonce,uint256 expiry)");
}


// File contracts/governanceToken/GovernanceTokenInterface.sol

/**
 * @title GovernanceTokenInterface
 * @author Hifi
 */
abstract contract GovernanceTokenInterface is GovernanceTokenStorage {
    // Events

    /**
     * @notice Emitted when a delegate is changed
     * @param delegator The holder delegating their power
     * @param fromDelegate The address of the previous delegate
     * @param toDelegate The address of the new delegate
     */
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /**
     * @notice Emitted when the power of a delegate changes
     * @param delegate The address of the delegate
     * @param oldPower The previous power of the delegate
     * @param newPower The new power of the delegate
     */
    event DelegatePowerChanged(
        address indexed delegate,
        uint256 oldPower,
        uint256 newPower
    );

    // View Functions

    /**
     * @notice Gets the current power of an account
     * @param account The address of the account
     * @return The current power of the account
     */
    function getCurrentPower(address account) external virtual view returns (uint256);

    /**
     * @notice Gets the prior power of an account
     * @param account The address of the account
     * @param blockNumber The block number to check
     * @return The prior power of the account
     */
    function getPriorPower(address account, uint256 blockNumber) external virtual view returns (uint256);

    // Non-constant Functions

    /**
     * @notice Delegates the power of the sender to a delegate (auto-delegation is possible)
     * @param delegate The address of the delegate
     */
    function updateDelegate(address delegate) external virtual;

    /**
     * @notice Delegates the power to a delegate using a signature
     * @param delegator The address of the delegator
     * @param delegate The address of the delegate
     * @param nonce The current nonce of the delegator
     * @param expiry The expiration timestamp of the signature
     * @param v The V part of the signature
     * @param r The r part of the signature
     * @param s The s part of the signature
     */
    function updateDelegateBySig(
        address delegator,
        address delegate,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;
}


// File contracts/governanceToken/GovernanceToken.sol


/**
 * @title GovernanceToken
 * @notice The base of a governance token
 * @author Hifi
 */
contract GovernanceToken is GovernanceTokenInterface, Erc20Permit {
    /**
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The amount of decimals of the token
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) Erc20Permit(name, symbol, decimals) {}

    /// @inheritdoc GovernanceTokenInterface
    function updateDelegate(address delegate) external override {
        return updateDelegateInternal(msg.sender, delegate);
    }

    /// @inheritdoc GovernanceTokenInterface
    function updateDelegateBySig(
        address delegator,
        address delegate,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes32 hashedData = keccak256(
            abi.encode(
                UPDATEDELEGATEBYSIG_TYPEHASH,
                delegator,
                delegate,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashedData
            )
        );

        address signer = ecrecover(digest, v, r, s);
        require(signer == delegator, "ERR_INVALID_SIG");
        require(nonce == nonces[signer], "ERR_INVALID_NONCE");
        require(block.timestamp <= expiry, "ERR_EXPIRED_SIG");

        nonces[signer] += 1;

        return updateDelegateInternal(signer, delegate);
    }

    /// @inheritdoc GovernanceTokenInterface
    function getCurrentPower(address account) external view override returns (uint256) {
        uint256 accountCheckpoints = checkpointsOf[account];
        return accountCheckpoints > 0 ? checkpoints[account][accountCheckpoints - 1].power : 0;
    }

    /// @inheritdoc GovernanceTokenInterface
    function getPriorPower(address account, uint256 blockNumber) external view override returns (uint256) {
        require(blockNumber < block.number, "ERR_INVALID_BLOCK");

        uint256 accountCheckpoints = checkpointsOf[account];

        if (accountCheckpoints == 0) {
            return 0;
        }

        if (checkpoints[account][accountCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][accountCheckpoints - 1].power;
        }

        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = accountCheckpoints - 1;

        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory checkpoint = checkpoints[account][center];

            if (checkpoint.fromBlock == blockNumber) {
                return checkpoint.power;
            } else if (checkpoint.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        return checkpoints[account][lower].power;
    }

    /// @dev Overrides the internal transfer function to move the delegated power during a transfer
    function transferInternal(address sender, address recipient, uint256 amount) internal override {
        super.transferInternal(sender, recipient, amount);
        movePower(delegates[sender], delegates[recipient], amount);
    }

    /**
     * @dev Updates the delegate of a delegator
     * @param delegator The address of the delegator
     * @param delegate The address of the new delegate
     */
    function updateDelegateInternal(address delegator, address delegate) internal {
        address fromDelegate = delegates[delegator];
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegate;

        emit DelegateChanged(delegator, fromDelegate, delegate);

        movePower(fromDelegate, delegate, delegatorBalance);
    }

    /**
     * @dev Moves the power from a delegate to another
     * @param oldDelegate The address of the old delegate
     * @param newDelegate The address of the new delegate
     * @param amount The amount of power to move
     */
    function movePower(address oldDelegate, address newDelegate, uint256 amount) internal {
        if (oldDelegate != newDelegate && amount > 0) {
            if (oldDelegate != address(0)) {
                uint256 oldDelegateCheckpoints = checkpointsOf[oldDelegate];
                uint256 oldPower = oldDelegateCheckpoints > 0 ? checkpoints[oldDelegate][oldDelegateCheckpoints - 1].power : 0;
                uint256 newPower = oldPower - amount;
                writeCheckpoints(oldDelegate, oldDelegateCheckpoints, oldPower, newPower);
            }

            if (newDelegate != address(0)) {
                uint256 newDelegateCheckpoints = checkpointsOf[newDelegate];
                uint256 oldPower = newDelegateCheckpoints > 0 ? checkpoints[newDelegate][newDelegateCheckpoints - 1].power : 0;
                uint256 newPower = oldPower + amount;
                writeCheckpoints(newDelegate, newDelegateCheckpoints, oldPower, newPower);
            }
        }
    }

    /**
     * @dev Saves the new power of a delegate
     * @param delegate The address of the delegate
     * @param delegateCheckpoints The current amount of checkpoints of the delegate
     * @param oldPower The previous power of the delegate
     * @param newPower The new power of the delegate
     */
    function writeCheckpoints(
        address delegate,
        uint256 delegateCheckpoints,
        uint256 oldPower,
        uint256 newPower
    ) internal {
        if (delegateCheckpoints > 0 && checkpoints[delegate][delegateCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegate][delegateCheckpoints - 1].power = newPower;
        } else {
            checkpoints[delegate][delegateCheckpoints] = Checkpoint(block.number, newPower);
            checkpointsOf[delegate] = delegateCheckpoints + 1;
        }

        emit DelegatePowerChanged(delegate, oldPower, newPower);
    }
}


// File contracts/safetyModule/SafetyModuleStorage.sol

/**
 * @title SafetyModuleStorage
 * @author Hifi
 */
abstract contract SafetyModuleStorage {
  /// @notice The owner of this contract (likely a timelock)
  address public owner;

  /// @notice The rewards distributor (TBD)
  address public rewardsDistributor;

  /// @notice Token required to stake (Do not confuse it with the token minted when staking)
  Erc20Interface public stakedToken;

  /// @notice Token rewarded to stakers
  Erc20Interface public rewardToken;

  /// @notice The end of the period
  uint256 public periodFinish;

  /// @notice The reward rate
  uint256 public rewardRate = 0;

  /// @notice The duration of the reward period
  uint256 public rewardsDuration = 7 days;

  /// @notice The last time the reward was updated
  uint256 public lastUpdateTime;

  uint8 public constant PRECISION = 18;

  /// @notice
  uint256 public rewardPerTokenStored;

  /// @notice The duration (in seconds) of the cooldown before unstaking
  uint256 public cooldown;

  /// @notice The duration (in seconds) of the unstake window (when missed another cooldown is required)
  uint256 public unstakeWindow;

  /// @notice Rewards
  mapping (address => uint256) public userRewardPerTokenPaid;

  /// @notice Rewards of each user
  mapping (address => uint256) public rewardsOf;

  /// @notice Starting time of the cooldown for each user
  mapping (address => uint256) public cooldownOf;

  // This will be used to prevent people from withdrawing reward tokens too soon
  mapping (address => mapping (uint256 => uint256)) public rewardsByTimestampOf;
}


// File contracts/safetyModule/SafetyModuleInterface.sol

/**
 * @title SafetyModuleInterface
 * @author Hifi
 */
abstract contract SafetyModuleInterface is SafetyModuleStorage {
  // Events

  /**
   * @notice Emitted when tokens are staked
   * @param from The address calling the function
   * @param onBehalfOf The address of the staker
   * @param amount The amount of tokens to stake
   */
  event Staked(
    address indexed from,
    address indexed onBehalfOf,
    uint256 amount
  );

  /**
   * @notice Emitted when tokens are unstaked
   * @param from The address of the staker
   * @param to The address of the recipient of the tokens
   * @param amount The amount of tokens to unstake
   */
  event Unstaked(
    address indexed from,
    address indexed to,
    uint256 amount
  );

  /**
   * @notice Emitted when a reward is added
   * @param amount The amount of the reward
   */
  event RewardAdded(
    uint256 amount
  );

  /**
   * @notice Emitted when rewards are claimed
   * @param from The address of the staker
   * @param to The address of the recipient of the rewards
   * @param amount The amount of rewards claimed
   */
  event RewardsClaimed(
    address indexed from,
    address indexed to,
    uint256 amount
  );

  /**
   * @notice Emitted when the rewards duration is updated
   * @param rewardsDuration The new rewards duration
   */
  event RewardsDurationUpdated(
    uint256 rewardsDuration
  );

  /**
   * @notice Emitted when a staker starts their cooldown period
   * @param staker The address of the staker
   */
  event CooldownStarted(
    address indexed staker
  );

  // Non-Constant Functions

  /**
   * @notice Stakes tokens
   * @param onBehalfOf The address of the staker
   * @param amount The amount of tokens to stake
   */
  function stake(
    address onBehalfOf,
    uint256 amount
  ) external virtual;

  /**
   * @notice Unstakes tokens (if the cooldown period is valid)
   * @param to The address of the recipient of the tokens
   * @param amount The amount of tokens to unstake
   */
  function unstake(
    address to,
    uint256 amount
  ) public virtual;

  /**
   * @notice Claim rewards
   * @param to The address of the recipient of the rewards
   */
  function claimRewards(
    address to
  ) public virtual;

  /**
   * @notice Unstakes tokens and claim rewards (if the cooldown period is valid)
   * @param to The address of the recipient of the tokens and the rewards
   */
  function exit(
    address to
  ) external virtual;

  /**
   * @notice Starts the cooldown period of the sender
   */
  function startCooldown() external virtual;

  // View Functions

  /// @notice Gets the end of the reward period as a timestamp
  function lastTimeRewardApplicable() public view virtual returns (uint256);

  /// @notice Gets the current reward per token rate
  function rewardPerToken() public view virtual returns (uint256);

  /// @notice Gets the current total of rewards earned by an address
  function earned(address account) public view virtual returns (uint256);

  /// @notice Gets the reward amount for the current reward period
  function getRewardForDuration() external view virtual returns (uint256);

  /**
   * @notice Notifies a new reward amount
   * @param reward The reward amount to notify
   */
  function notifyRewardAmount(uint256 reward) external virtual;

  /**
   * @notice Sets a new rewards duration
   * @param newRewardsDuration The new rewards duration
   */
  function setRewardsDuration(uint256 newRewardsDuration) external virtual;

  /**
   * @notice Updates the end of the reward period
   * @param timestamp The end of the reward period as a timestamp
   */
  function updatePeriodFinish(uint256 timestamp) external virtual;
}


// File contracts/safetyModule/SafetyModule.sol

/**
 * @title SafetyModule
 * @notice The SafetyModule rewards users staking a specifing token
 * @author Hifi
 */
contract SafetyModule is GovernanceToken, SafetyModuleInterface {
  /// @notice Restricts the call to the owner
  modifier onlyOwner() {
    require(msg.sender == owner, "ERR_ONLY_OWNER");
    _;
  }

  /// @notice Restricts the call to the rewards distributor
  modifier onlyRewardsDistributor() {
    require(msg.sender == rewardsDistributor, "ERR_ONLY_REWARDS_DISTRIBUTOR");
    _;
  }

  /// @notice Updates the reward of an account
  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();

    if (account != address(0)) {
      rewardsOf[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    _;
  }

  /**
   * @param name The name of the token issued when staking tokens
   * @param symbol The symbol of the token distributed to stakers
   * @param decimals The number of decimals of the token
   * @param initialStakedToken The token used to stake
   * @param initialRewardToken The token rewarded to stakers
   * @param initialCooldown The duration of the cooldown period before unstaking becomes possible
   * @param initialUnstakeWindow The duration of the period while unstaking is possible
   * @param initialRewardsDistributor The contract triggering the distribution of rewards
   * @param initialOwner The address owning this contract (likely a governance contract)
   */
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    Erc20Interface initialStakedToken,
    Erc20Interface initialRewardToken,
    uint256 initialCooldown,
    uint256 initialUnstakeWindow,
    address initialRewardsDistributor,
    address initialOwner
  ) GovernanceToken(name, symbol, decimals) {
    stakedToken = initialStakedToken;
    rewardToken = initialRewardToken;
    cooldown = initialCooldown;
    unstakeWindow = initialUnstakeWindow;
    rewardsDistributor = initialRewardsDistributor;
    owner = initialOwner;
  }

  /// @inheritdoc SafetyModuleInterface
  function lastTimeRewardApplicable() public view override returns (uint256) {
    return block.timestamp > periodFinish ? periodFinish : block.timestamp;
  }

  /// @inheritdoc SafetyModuleInterface
  function rewardPerToken() public view override returns (uint256) {
    if (totalSupply == 0) {
      return rewardPerTokenStored;
    }

    return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * PRECISION / totalSupply);
  }

  /// @inheritdoc SafetyModuleInterface
  function earned(address account) public view override returns (uint256) {
    return (balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / PRECISION) + rewardsOf[account];
  }

  /// @inheritdoc SafetyModuleInterface
  function getRewardForDuration() external view override returns (uint256) {
    return rewardRate * rewardsDuration;
  }

  /// @inheritdoc SafetyModuleInterface
  function stake(address onBehalfOf, uint256 amount) external override updateReward(onBehalfOf) {
    require(amount != 0, "ERR_CANNOT_STAKE_ZERO");

    mintInternal(onBehalfOf, amount);
    stakedToken.transferFrom(msg.sender, address(this), amount);
    cooldownOf[onBehalfOf] = getNextCooldown(0, amount, onBehalfOf, amount);

    emit Staked(msg.sender, onBehalfOf, amount);
  }

  /// @inheritdoc SafetyModuleInterface
  function unstake(address to, uint256 amount) public override updateReward(msg.sender) {
    require(amount > 0, "ERR_CANNOT_UNSTAKE_ZERO");
    require(
      block.timestamp >= cooldownOf[msg.sender] + cooldown,
      "ERR_COOLDOWN_NOT_FINISHED"
    );
    require(
      block.timestamp < cooldownOf[msg.sender] + cooldown + unstakeWindow,
      "ERR_UNSTAKE_WINDOW_MISSED"
    );

    burnInternal(msg.sender, amount);
    stakedToken.transfer(to, amount);

    emit Unstaked(msg.sender, to, amount);
  }

  /// @inheritdoc SafetyModuleInterface
  function claimRewards(address to) public override updateReward(msg.sender) {
    uint256 reward = rewardsOf[msg.sender];

    if (reward > 0) {
      rewardsOf[msg.sender] = 0;
      rewardToken.transfer(msg.sender, reward);
      // TODO: Tokens must be locked for one year before being transferred
      emit RewardsClaimed(msg.sender, to, reward);
    }
  }

  /// @inheritdoc SafetyModuleInterface
  function exit(address to) external override {
    unstake(to, balanceOf(msg.sender));
    claimRewards(to);
  }

  /// @inheritdoc SafetyModuleInterface
  function startCooldown() external override {
    require(balanceOf(msg.sender) != 0, "ERR_BALANCE_IS_ZERO");

    cooldownOf[msg.sender] = block.timestamp;

    emit CooldownStarted(
      msg.sender
    );
  }

  /// @inheritdoc SafetyModuleInterface
  function notifyRewardAmount(
    uint256 reward
  ) external override onlyRewardsDistributor() updateReward(address(0)) {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward / rewardsDuration;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftOver = remaining * rewardRate;
      rewardRate = (reward + leftOver) / rewardsDuration;
    }

    uint256 balance = rewardToken.balanceOf(address(this));

    require(rewardRate <= balance / rewardsDuration, "ERR_REWARD_TOO_HIGH");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardsDuration;

    emit RewardAdded(reward);
  }

  /// @inheritdoc SafetyModuleInterface
  function updatePeriodFinish(uint256 timestamp) external override onlyOwner() {
    periodFinish = timestamp;
  }

  /// @inheritdoc SafetyModuleInterface
  function setRewardsDuration(uint256 newRewardsDuration) external override onlyOwner() {
    require(
      block.timestamp > periodFinish,
      "ERR_CANNOT_CHANGE_DURATION_DURING_PERIOD"
    );

    rewardsDuration = newRewardsDuration;

    emit RewardsDurationUpdated(newRewardsDuration);
  }

  function getNextCooldown(
    uint256 fromCooldown,
    uint256 amountToReceive,
    address to,
    uint256 toBalance
  ) private returns (uint256) {
    uint256 toCooldown = cooldownOf[to];

    if (toCooldown == 0) {
      return 0;
    }

    uint256 minimalValidCooldown = block.timestamp - cooldown - unstakeWindow;

    if (minimalValidCooldown > toCooldown) {
      toCooldown = 0;
    } else {
      uint256 fromCooldownTimestamp = (minimalValidCooldown > fromCooldown) ? block.timestamp : fromCooldown;

      if (fromCooldownTimestamp < toCooldown) {
        return toCooldown;
      } else {
        toCooldown = (amountToReceive * fromCooldown + toBalance) / (amountToReceive + toBalance);
      }
    }

    cooldownOf[to] = toCooldown;

    return toCooldown;
  }
}


// File contracts/safetyModule/TacoSafetyModule.sol

pragma solidity ^0.8.0;

/**
 * @title Taco Safety Module
 * @notice Allows users to stake HIFI tokens in order to secure the protocol.
 * Stakers will earn HIFI tokens as rewards in compensation.
 * @author Taco
 */
contract TacoSafetyModule is SafetyModule {
  constructor(
    Erc20Interface hifiTokenAddress,
    address rewardsDistributor,
    address owner
  ) SafetyModule(
    "Staked Taco",
    "stkTACO",
    18,
    hifiTokenAddress,
    hifiTokenAddress,
    864000,
    172800,
    rewardsDistributor,
    owner
  ) {}
}