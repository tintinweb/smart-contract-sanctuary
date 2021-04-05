/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File contracts/timelock/TimelockStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimelockStorage
 * @author Hifi
 */
abstract contract TimelockStorage {
    /// @notice Duration of the execution period for the transactions
    uint256 public constant GRACE_PERIOD = 14 days;

    /// @notice Minimum delay of execution that can be set
    uint256 public constant MINIMUM_DELAY = 2 days;

    /// @notice Maximum delay of execution that can be set
    uint256 public constant MAXIMUM_DELAY = 30 days;

    /// @notice Current admin of the contract
    address public admin;

    /// @notice Pending admin of the contract
    address public pendingAdmin;

    /// @notice Current delay of execution
    uint256 public delay;

    /// @notice Tracks the queued transactions
    mapping (bytes32 => bool) public queuedTransactions;
}


// File contracts/timelock/TimelockInterface.sol

/**
 * @title TimelockInterface
 * @author Hifi
 */
abstract contract TimelockInterface is TimelockStorage {
    // Events

    /**
     * @notice Emitted when a new admin is set
     * @param newAdmin The address of the new admin
     */
    event NewAdmin(address indexed newAdmin);

    /**
     * @notice Emitted when a new pending admin is set
     * @param newPendingAdmin The address of the new pending admin
     */
    event NewPendingAdmin(address indexed newPendingAdmin);

    /**
     * @notice Emitted when a new delay is set
     * @param newDelay The new duration of the delay
     */
    event NewDelay(uint256 indexed newDelay);

    /**
     * @notice Emitted when a transaction is canceled
     * @param transactionHash The hash of the transaction
     * @param target The target of the transaction
     * @param value The value (msg.value) passed with the transaction
     * @param signature The signature of the function to call
     * @param data The data to pass with the call
     * @param executionTime The time when the transaction will be ready for execution
     */
    event TransactionCanceled(
        bytes32 indexed transactionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime
    );

    /**
     * @notice Emitted when a transaction is executed
     * @param transactionHash The hash of the transaction
     * @param target The target of the transaction
     * @param value The value (msg.value) passed with the transaction
     * @param signature The signature of the function to call
     * @param data The data to pass with the call
     * @param executionTime The time when the transaction will be ready for execution
     */
    event TransactionExecuted(
        bytes32 indexed transactionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime
    );

    /**
     * @notice Emitted when a transaction is queued
     * @param transactionHash The hash of the transaction
     * @param target The target of the transaction
     * @param value The value (msg.value) passed with the transaction
     * @param signature The signature of the function to call
     * @param data The data to pass with the call
     * @param executionTime The time when the transaction will be ready for execution
     */
    event TransactionQueued(
        bytes32 indexed transactionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime
    );

    // Non-constant Functions

    /**
     * @notice Sets a new execution delay (only if the new delay is valid)
     * @dev Can only be called by the admin
     * @param newDelay The duration of the new delay
     */
    function setDelay(uint256 newDelay) external virtual;

    /**
     * @notice Accepts to become the new admin
     * @dev Can only be called by the pending admin
     */
    function acceptAdmin() external virtual;

    /**
     * @notice Sets a new pending admin
     * @dev Can only be called by the admin
     * @param newPendingAdmin The address of the new pending admin
     */
    function setPendingAdmin(address newPendingAdmin) external virtual;

    /**
     * @notice Queues a transaction
     * @dev Can only be called by the admin
     * @param target The target of the transaction
     * @param value The value (msg.value) passed with the transaction
     * @param signature The signature of the function to call
     * @param data The data to pass with the call
     * @param executionTime The time when the transaction will be ready for execution
     * @return The transaction hash
     */
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime
    ) external virtual returns (bytes32);

    /**
     * @notice Cancels a transaction
     * @dev Can only be called by the admin
     * @param target The target of the transaction
     * @param value The value (msg.value) passed with the transaction
     * @param signature The signature of the function to call
     * @param data The data to pass with the call
     * @param executionTime The time when the transaction will be ready for execution
     */
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime
    ) external virtual;

    /**
     * @notice Executes a transaction
     * @dev Can only be called by the admin
     * @param target The target of the transaction
     * @param value The value (msg.value) passed with the transaction
     * @param signature The signature of the function to call
     * @param data The data to pass with the call
     * @param executionTime The time when the transaction will be ready for execution
     * @return The data returned by the transaction call
     */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime
    ) external payable virtual returns (bytes memory);
}


// File @paulrberg/contracts/token/erc20/[email protected]

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


// File contracts/governor/GovernorStorage.sol


/**
 * @title GovernorStorage
 * @author Hifi
 */
abstract contract GovernorStorage {
    /// @notice EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice EIP-712 typehash for the vote
    bytes32 public constant VOTEBYSIG_TYPEHASH = keccak256("VoteBySig(uint256 proposalId,bool support)");

    /// @notice The name of the Governance contract
    string public name;

    /// @notice The current version of the contract
    string public version;

    /// @notice The address of the Timelock contract
    TimelockInterface public timelock;

    /// @notice An array of governance tokens used to vote and propose
    GovernanceToken[] public governanceTokens;

    /// @notice The address of the guardian
    address public guardian;

    /// @notice Total count of all the proposals
    uint256 public proposalsCount;

    /**
     * @notice Base structure of a proposal
     * @param id Unique id of the proposal
     * @param proposer The creator of the proposal
     * @param executionTime The execution timestamp, set after the vote succeeds
     * @param targets An array of target addresses to call
     * @param values An array of values (msg.value) passed with the calls
     * @param signatures An array of function signatures to call
     * @param calldatas An array of calldata to be passed with the calls
     * @param startBlock The block number at which the voting starts
     * @param endBlock The block number at which the voting ends
     * @param forVotes The number of votes in favor of the proposal
     * @param againstVotes The number of votes against the proposal
     * @param canceled True if the proposal has been canceled
     * @param executed True if the proposal has been executed
     */
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 executionTime;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool canceled;
        bool executed;
    }

    /// @notice All the proposals
    mapping (uint256 => Proposal) public proposals;

    /**
     * @notice The receipt of a vote
     * @param hasVoted True if has voted
     * @param support True if the vote is for the proposal
     * @param power The power of the voter
     */
    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 power;
    }

    /// @notice The receipts stored by voters for each proposal
    mapping (uint256 => mapping (address => Receipt)) public receipts;

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The latest proposal for each proposer
    mapping (address => uint256) public latestProposalOf;
}


// File contracts/governor/GovernorInterface.sol

/**
 * @title GovernanceInterface
 * @author Hifi
 */
abstract contract GovernorInterface is GovernorStorage {
    // Events

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        bytes32 ipfsHash
    );

    /// @notice An event emitted when a vote has been made on a proposal
    event HasVoted(address voter, uint256 proposalId, bool support, uint256 power);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 proposalId);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 proposalId, uint256 executionTime);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 proposalId);

    // View Functions

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view virtual returns (uint256);

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public view virtual returns (uint256);

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() external virtual pure returns (uint256);

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() external virtual pure returns (uint256);

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() external virtual pure returns (uint256);

    /**
     * @notice Gets the receipt of a voter for a specific proposal
     * @param proposalId The id of the proposal to check
     * @param voter The address of the voter
     * @return The receipt as a Receipt struct
     */
    function getReceipt(uint256 proposalId, address voter) external virtual view returns (Receipt memory);

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal to check
     * @return The proposal state as an enum
     */
    function getProposalState(uint256 proposalId) public virtual view returns (ProposalState);

    /**
     * @notice Gets the actions of a proposal
     * @param proposalId The id of the proposal to check
     * @return targets An array of target addresses to call
     * @return values An array of values (msg.value) passed with the calls
     * @return signatures An array of function signatures to call
     * @return calldatas An array of calldata to be passed with the calls
     */
    function getActions(
        uint256 proposalId
    ) external virtual view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    );

    /**
     * @notice Gets the prior power of an account
     * @param account The address of the account to check
     * @param atBlock The block the look for
     * @return The power
     */
    function getPriorPower(address account, uint256 atBlock) public view virtual returns (uint256);

    // Non-Constant Functions

    /**
     * @notice Proposes a new proposal
     * @param targets An array of target addresses to call
     * @param values An array of values passed with the call
     * @param signatures An array of function signatures to call
     * @param calldatas An array of calldata to be passed with the call
     * @param ipfsHash The IPFS hash describing the proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bytes32 ipfsHash
    ) external virtual returns (uint256);

    /**
     * @notice Queues a proposal
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint256 proposalId) external virtual;

    /**
     * @notice Executes a proposal
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external virtual payable;

    /**
     * @notice Cancels a proposal
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external virtual;

    /**
     * @notice Votes for or against a proposal
     * @param proposalId The id of the proposal
     * @param support True if for the proposal, false if against
     */
    function vote(uint256 proposalId, bool support) external virtual;

    /**
     * @notice Votes for or against a proposal using a signature
     * @param proposalId The id of the proposal
     * @param support True if for the proposal, false if against
     * @param v V part of the signature
     * @param r R part of the signature
     * @param s S part of the signature
     */
    function voteBySig(uint256 proposalId, bool support, uint8 v, bytes32 r, bytes32 s) external virtual;

    /**
     * @notice Accepts the admin role
     */
    function acceptAdmin() external virtual;

    /**
     * @notice Abdicates the guardian role
     */
    function abdicate() external virtual;

    /**
     * @notice Queues the set pending admin function of the Timelock
     * @param newPendingAdmin The address of the new pending admin
     * @param executionTime The execution time of the transaction
     */
    function queueTimelockSetPendingAdmin(address newPendingAdmin, uint256 executionTime) external virtual;

    /**
     * @notice Executes the set pending admin function of the Timelock
     * @param newPendingAdmin The address of the new pending admin
     * @param executionTime The execution time of the transaction
     */
    function executeTimelockSetPendingAdmin(address newPendingAdmin, uint256 executionTime) external virtual;
}


// File contracts/governor/Governor.sol

/**
 * @title Governor
 * @notice Governance contract
 * @author Hifi
 */
contract Governor is GovernorInterface {
    modifier onlyGuardian() {
        require(msg.sender == guardian, "ERR_ONLY_BY_GUARDIAN");
        _;
    }

    /**
     * @param initialName The name of the contract
     * @param initialVersion The version of the contract
     * @param initialGovernanceTokens An array containing the governance tokens
     * @param initialTimelock The address of the Timelock contract
     * @param initialGuardian The address of the guardian
     */
    constructor(
        string memory initialName,
        string memory initialVersion,
        GovernanceToken[] memory initialGovernanceTokens,
        address initialTimelock,
        address initialGuardian
    ) {
        name = initialName;
        version = initialVersion;
        governanceTokens = initialGovernanceTokens;
        timelock = TimelockInterface(initialTimelock);
        guardian = initialGuardian;
    }

    /// @inheritdoc GovernorInterface
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bytes32 ipfsHash
    ) external override returns (uint256) {
        require(
            getPriorPower(msg.sender, block.number - 1) > proposalThreshold(),
            "ERR_PROPOSER_POWER_BELOW_THRESHOLD"
        );
        require(
            targets.length == values.length
            && targets.length == signatures.length
            && targets.length == calldatas.length,
            "ERR_PROPOSAL_INFO_MISMATCH"
        );
        require(targets.length != 0, "ERR_NO_ACTIONS_PROVIDED");
        require(targets.length <= proposalMaxOperations(), "ERR_TOO_MANY_ACTIONS");

        uint256 latestProposalId = latestProposalOf[msg.sender];

        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = getProposalState(latestProposalId);

            require(
                proposersLatestProposalState != ProposalState.Active,
                "ERR_ONLY_ONE_ACTIVE_PROPOSAL_PER_PROPOSER"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "ERR_ONLY_ONE_PENDING_PROPOSAL_PER_PROPOSER"
            );
        }

        uint256 startBlock = block.number + votingDelay();
        uint256 endBlock = startBlock + votingPeriod();

        proposalsCount += 1;

        Proposal memory newProposal = Proposal({
            id: proposalsCount,
            proposer: msg.sender,
            executionTime: 0,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[newProposal.id] = newProposal;
        latestProposalOf[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            ipfsHash
        );

        return newProposal.id;
    }

    /// @inheritdoc GovernorInterface
    function queue(uint256 proposalId) external override {
        require(
            getProposalState(proposalId) == ProposalState.Succeeded,
            "ERR_ONLY_SUCCEEDED_PROPOSALS_CAN_BE_QUEUED"
        );

        Proposal storage proposal = proposals[proposalId];
        uint256 executionTime = block.timestamp + timelock.delay();

        for (uint256 i = 0; i < proposal.targets.length; i +=1) {
            _queueOrRevert(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                executionTime
            );
        }

        proposal.executionTime = executionTime;

        emit ProposalQueued(proposalId, executionTime);
    }

    /// @inheritdoc GovernorInterface
    function cancel(uint256 proposalId) external override {
        require(
            getProposalState(proposalId) != ProposalState.Executed,
            "ERR_CANNOT_CANCEL_EXECUTED_PROPOSALS"
        );

        Proposal storage proposal = proposals[proposalId];

        require(
            msg.sender == guardian
            || getPriorPower(proposal.proposer, block.number - 1) < proposalThreshold(),
            "ERR_PROPOSER_POWER_ABOVE_THRESHOLD"
        );

        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i += 1) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.executionTime
            );
        }

        emit ProposalCanceled(proposalId);
    }

    /// @inheritdoc GovernorInterface
    function getActions(uint256 proposalId) external override view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage proposal = proposals[proposalId];

        return (
            proposal.targets,
            proposal.values,
            proposal.signatures,
            proposal.calldatas
        );
    }

    /// @inheritdoc GovernorInterface
    function getReceipt(uint256 proposalId, address voter) external override view returns (Receipt memory) {
        return receipts[proposalId][voter];
    }

    /// @inheritdoc GovernorInterface
    function getProposalState(uint256 proposalId) public override view returns (ProposalState) {
        require(proposalsCount >= proposalId && proposalId > 0, "ERR_INVALID_PROPOSAL_ID");

        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.executionTime == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.executionTime + timelock.GRACE_PERIOD()) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /// @inheritdoc GovernorInterface
    function vote(uint256 proposalId, bool support) external override {
        return _vote(msg.sender, proposalId, support);
    }

    /// @inheritdoc GovernorInterface
    function voteBySig(uint256 proposalId, bool support, uint8 v, bytes32 r, bytes32 s) external override {
        bytes32 domainSeparator = keccak256(abi.encode(
            DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            getChainId(),
            address(this))
        );
        bytes32 structHash = keccak256(abi.encode(VOTEBYSIG_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "ERR_INVALID_CAST_VOTE_SIG");

        return _vote(signatory, proposalId, support);
    }

    /// @inheritdoc GovernorInterface
    function proposalThreshold() public view override returns (uint256) {
        // We assume that the first governance token is the main one and that
        // the other tokens represent staked tokens
        return (governanceTokens[0].totalSupply() / 100);
    }

    /// @inheritdoc GovernorInterface
    function quorumVotes() public view override returns (uint256) {
        return (governanceTokens[0].totalSupply() / 10);
    }

    /// @inheritdoc GovernorInterface
    function proposalMaxOperations() public pure override returns (uint256) {
        return 10;
    }

    /// @inheritdoc GovernorInterface
    function votingDelay() public pure override returns (uint256) {
        return 1;
    }

    /// @inheritdoc GovernorInterface
    function votingPeriod() public pure override returns (uint256) {
        return 17280;
    }

    function _vote(address voter, uint256 proposalId, bool support) private {
        require(
            getProposalState(proposalId) == ProposalState.Active,
            "ERR_VOTE_IS_CLOSED"
        );

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = receipts[proposalId][voter];

        require(receipt.hasVoted == false, "ERR_VOTER_ALREADY_VOTED");
        uint256 power = getPriorPower(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes += power;
        } else {
            proposal.againstVotes += power;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.power = power;

        emit HasVoted(voter, proposalId, support, power);
    }

    /// @inheritdoc GovernorInterface
    function execute(uint256 proposalId) external override payable {
        require(
            getProposalState(proposalId) == ProposalState.Queued,
            "ERR_ONLY_QUEUED_PROPOSALS_CAN_BE_EXECUTED"
        );

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i += 1) {
            timelock.executeTransaction{value: proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.executionTime
            );
        }

        emit ProposalExecuted(proposalId);
    }

    /// @inheritdoc GovernorInterface
    function acceptAdmin() external override onlyGuardian() {
        timelock.acceptAdmin();
    }

    /// @inheritdoc GovernorInterface
    function abdicate() external override onlyGuardian() {
        guardian = address(0);
    }

    /// @inheritdoc GovernorInterface
    function queueTimelockSetPendingAdmin(
        address newPendingAdmin,
        uint256 executionTime
    ) external override onlyGuardian() {
        timelock.queueTransaction(
            address(timelock),
            0,
            "setPendingAdmin(address)",
            abi.encode(newPendingAdmin),
            executionTime
        );
    }

    /// @inheritdoc GovernorInterface
    function executeTimelockSetPendingAdmin(
        address newPendingAdmin,
        uint256 executionTime
    ) external override onlyGuardian() {
        timelock.executeTransaction(
            address(timelock),
            0,
            "setPendingAdmin(address)",
            abi.encode(newPendingAdmin),
            executionTime
        );
    }

    /// @inheritdoc GovernorInterface
    function getPriorPower(address user, uint256 atBlock) public override view returns (uint256) {
        uint256 power;

        for (uint256 i = 0; i < governanceTokens.length; i += 1) {
            power += governanceTokens[i].getPriorPower(user, atBlock);
        }

        return power;
    }

    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime
    ) private {
        require(
            !timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, executionTime))),
            "ERR_PROPOSAL_ACTION_ALREADY_QUEUED_AT_ETA"
        );

        timelock.queueTransaction(target, value, signature, data, executionTime);
    }

    function getChainId() private view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}