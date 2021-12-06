// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./extension/checkpointable/ERC20Checkpointable.sol";

import "../../access/manager/ManagerRole.sol";
import "../../access/governance/GovernanceRole.sol";

import "../../pool/interface/IPoolFactory.sol";

// ANW Finanace token with Governance.
contract ProtocolToken is IERC20Metadata, ERC20, ERC20Checkpointable {
    using ManagerRole for RoleStore;
    using GovernanceRole for RoleStore;
    
    RoleStore private _s;

    address public poolFactory;

    modifier onlyManagerOrGovernance() {
        require(
            _s.isManager(_msgSender()) || _s.isGovernor(_msgSender()),
            "ProtocolToken::onlyManagerOrGovernance: NOT_MANAGER_NOR_GOVERNANCE_ACCOUNT"
        );
        _;
    }

    constructor (address _poolFactory, string memory _tokenName, string memory _tokenSymbol) ERC20(_tokenName, _tokenSymbol) { 
        poolFactory = _poolFactory;
        _s.initializeManagerRole(_msgSender());
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by a pool with this token as it's reward.
    function mint(address _to, uint256 _amount) public {
        require(
            _msgSender() == IPoolFactory(poolFactory).rewardPools(address(this)),
            "ProtocolToken::mint: FORBIDDEN"
        );
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(_msgSender(), _amount);
    }

    function setFactory(address _poolFactory) public onlyManagerOrGovernance {
        poolFactory = _poolFactory;
    }

    // record checkpoint data after successful token transfer
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 oldFrom = balanceOf(from);
        uint256 oldTo = balanceOf(to);

        if (from != address(0)){ // no need to checkpoint the 0x0 address during mint
            _writeCheckpoint(from, oldFrom, oldFrom - amount);
        }

        if (to != address(0)) { // no need to checkpoint the 0x0 address during burn
            _writeCheckpoint(to, oldTo, oldTo + amount);
        }

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
pragma solidity >=0.8.2 <0.9.0;

import "./interface/IERC20Checkpointable.sol";

// ERC20Checkpointable.sol
contract ERC20Checkpointable is IERC20Checkpointable {

    /// @notice The number of checkpoints for each account
    mapping (address => uint256) public override numCheckpoints;

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint256 => Checkpoint)) private  _checkpoints;


    function getCheckpoint(address account, uint256 index) external view override returns (Checkpoint memory) {
        return _checkpoints[account][index];
    }

    /**
     * @notice Determine the prior balance for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The final balance the account had as of the given block
     */
    function getPriorBalance(address account, uint256 blockNumber)
        external
        view
        override
        returns (uint256)
    {
        require(blockNumber < block.number, "ERC20Checkpointable::getPriorBalance: INVALID_BLOCK_NUMBER");

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (_checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return _checkpoints[account][nCheckpoints - 1].balance;
        }

        // Next check implicit zero balance
        if (_checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = _checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.balance;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _checkpoints[account][lower].balance;
    }

    function _writeCheckpoint(
        address account,
        uint256 oldBalance,
        uint256 newBalance
    )
        internal
    {
        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints > 0 && _checkpoints[account][nCheckpoints - 1].fromBlock == block.number) {
            _checkpoints[account][nCheckpoints - 1].balance = newBalance;
        } else {
            _checkpoints[account][nCheckpoints] = Checkpoint(block.number, newBalance);
            numCheckpoints[account] = nCheckpoints + 1;
        }

        emit BalanceChanged(account, oldBalance, newBalance);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "../RoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";
import "../../util/ContextLib.sol";

library ManagerRole {
    /* LIBRARY USAGE */
    
    using Roles for Role;

    /* EVENTS */

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    /* MODIFIERS */

    modifier onlyUninitialized(RoleStore storage s) {
        require(!s.initialized, "ManagerRole::onlyUninitialized: ALREADY_INITIALIZED");
        _;
    }

    modifier onlyInitialized(RoleStore storage s) {
        require(s.initialized, "ManagerRole::onlyInitialized: NOT_INITIALIZED");
        _;
    }

    modifier onlyManager(RoleStore storage s) {
        require(s.managers.has(ContextLib._msgSender()), "ManagerRole::onlyManager: NOT_MANAGER");
        _;
    }

    /* INITIALIZE METHODS */
    
    // NOTE: call only in calling contract context initialize function(), do not expose anywhere else
    function initializeManagerRole(
        RoleStore storage s,
        address account
    )
        external
        onlyUninitialized(s)
     {
        _addManager(s, account);
        s.initialized = true;
    }

    /* EXTERNAL STATE CHANGE METHODS */
    
    function addManager(
        RoleStore storage s,
        address account
    )
        external
        onlyManager(s)
        onlyInitialized(s)
    {
        _addManager(s, account);
    }

    function renounceManager(
        RoleStore storage s
    )
        external
        onlyInitialized(s)
    {
        _removeManager(s, ContextLib._msgSender());
    }

    /* EXTERNAL GETTER METHODS */

    function isManager(
        RoleStore storage s,
        address account
    )
        external
        view
        returns (bool)
    {
         return s.managers.has(account);
    }

    /* INTERNAL LOGIC METHODS */

    function _addManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(
        RoleStore storage s,
        address account
    )
        internal
    {
        s.managers.safeRemove(account);
        emit ManagerRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "../RoleStore.sol";

/* LIBRARY IMPORTS */

import "../base/Roles.sol";
import "../manager/ManagerRole.sol";
import "../../util/ContextLib.sol";

library GovernanceRole {

    /* LIBRARY USAGE */
    
    using Roles for Role;
    using ManagerRole for RoleStore;

    /* EVENTS */

    event GovernanceAccountAdded(address indexed account, address indexed governor);
    event GovernanceAccountRemoved(address indexed account, address indexed governor);

    /* MODIFIERS */

    modifier onlyManagerOrGovernance(RoleStore storage s, address account) {
        require(
            s.isManager(account) || _isGovernor(s, account), 
            "GovernanceRole::onlyManagerOrGovernance: NOT_MANAGER_NOR_GOVERNANCE_ACCOUNT"
        );
        _;
    }

    /* EXTERNAL STATE CHANGE METHODS */

    /* a manager or existing governance account can add new governance accounts */
    function addGovernor(
        RoleStore storage s,
        address governor
    )
        external
        onlyManagerOrGovernance(s, ContextLib._msgSender())
    {
        _addGovernor(s, governor);
    }

    /* an Governance account can renounce thier own governor status */
    function renounceGovernance(
        RoleStore storage s
    )
        external
    {
        _removeGovernor(s, ContextLib._msgSender());
    }

    /* manger accounts can remove governance accounts */
    function removeGovernor(
        RoleStore storage s,
        address governor
    )
        external
    {
        require(s.isManager(ContextLib._msgSender()), "GovernanceRole::removeGovernance: NOT_MANAGER_ACCOUNT");
        _removeGovernor(s, governor);
    }

    /* EXTERNAL GETTER METHODS */

    function isGovernor(
        RoleStore storage s,
        address account
    )
        external
        view
        returns (bool)
    {
        return _isGovernor(s, account);
    }

    /* INTERNAL LOGIC METHODS */

    function _isGovernor(
        RoleStore storage s,
        address account
    )
        internal
        view
        returns (bool)
    {
        return s.governance.has(account);
    }

    function _addGovernor(
        RoleStore storage s,
        address governor
    )
        internal
    {
        require(
            governor != address(0), 
            "GovernanceRole::_addGovernor: INVALID_GOVERNOR_ZERO_ADDRESS"
        );
        
        s.governance.add(governor);

        emit GovernanceAccountAdded(ContextLib._msgSender(), governor);
    }

    function _removeGovernor(
        RoleStore storage s,
        address governor
    )
        internal
    {
        require(
            governor != address(0),
            "GovernanceRole::_removeGovernor: INVALID_GOVERNOR_ZERO_ADDRESS"
        );

        s.governance.remove(governor);

        emit GovernanceAccountRemoved(ContextLib._msgSender(), governor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IPoolFactory {
    event PoolCreated(address indexed rewardToken, address indexed pool);

    function treasury() external view returns(address);

    function WNATIVE() external view returns(address);

    function rewardPools(address) external view returns(address);

    function isManager(address account) external view returns (bool);
    function isGovernor(address account) external view returns (bool);

    function deployPool(
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _nativeAllocPoint,
        uint256 _nativeStartBlock,
        uint256 _nativeBonusMultiplier,
        uint256 _nativeBonusEndBlock,
        uint256 _nativeMinStakePeriod
    ) external;

    function setTreasury(address newTreasury) external;
    function setNative(address newNative) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of ERC20 Blance checkpointing for off-chain voting functionality.
 */

interface IERC20Checkpointable {

    /// @notice A checkpoint for marking an account's balance changes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 balance;
    }

    /// @notice An event thats emitted when an account's token balance changes
    event BalanceChanged(address indexed account, uint previousBalance, uint newBalance);

    function numCheckpoints (address) external returns (uint256);

    function getCheckpoint(address account, uint256 index) external view returns (Checkpoint memory);

    function getPriorBalance(address account, uint256 blockNumber) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./base/RoleStruct.sol";

struct RoleStore {
    bool initialized;
    Role managers;
    Role governance;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* DATA STRUCT IMPORTS */

import "./RoleStruct.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    /* GETTER METHODS */

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles.has: ZERO_ADDRESS");
        return role.bearer[account];
    }

    /**
     * @dev Check if this role has at least one account assigned to it.
     * @return bool
     */
    function atLeastOneBearer(uint256 numberOfBearers) internal pure returns (bool) {
        if (numberOfBearers > 0) {
            return true;
        } else {
            return false;
        }
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Give an account access to this role.
     */
    function add(
        Role storage role,
        address account
    )
        internal
    {
        require(
            !has(role, account),
            "Roles.add: ALREADY_ASSIGNED"
        );

        role.bearer[account] = true;
        role.numberOfBearers += 1;
    }

    /**
     * @dev Remove an account's access to this role. (1 account minimum enforced for safeRemove)
     */
    function safeRemove(
        Role storage role,
        address account
    )
        internal
    {
        require(
            has(role, account),
            "Roles.safeRemove: INVALID_ACCOUNT"
        );
        uint256 numberOfBearers = role.numberOfBearers -= 1; // roles that use safeRemove must implement initializeRole() and onlyIntialized() and must set the contract deployer as the first account, otherwise this can underflow below zero
        require(
            atLeastOneBearer(numberOfBearers),
            "Roles.safeRemove: MINIMUM_ACCOUNTS"
        );
        
        role.bearer[account] = false;
    }

    /**
     * @dev Remove an account's access to this role. (no minimum enforced)
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles.remove: INVALID_ACCOUNT");
        role.numberOfBearers -= 1;
        
        role.bearer[account] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
library ContextLib {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/* STRUCTS */

struct Role {
    mapping (address => bool) bearer;
    uint256 numberOfBearers;
}