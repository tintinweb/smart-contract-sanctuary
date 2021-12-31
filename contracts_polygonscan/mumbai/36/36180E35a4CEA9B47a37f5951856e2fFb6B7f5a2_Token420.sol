// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IDaoManager.sol";
import "./libraries/Config.sol";

/// @title  Token 420 conforms to ERC20
/// @notice Token 420 is fully conformed to ERC20 standard. It has extra mint and burn features.
/// @dev    These capabilities are delegated to DaoManager, i.e only DaoManager can call mint and burn
contract Token420 is ERC20 {
    IDaoManager public dao;

    event DaoManagerRegistration(address indexed account);
    event DaoManagerMigration(address indexed account);
    event Mint(address indexed account, uint256 indexed amount);
    event Burn(address indexed account, uint256 indexed amount);

    /* solhint-disable-next-line no-empty-blocks */
    constructor() public ERC20("Token 420", "420") {}

    function decimals() public pure override returns (uint8) {
        return Constant.TOKEN_DECIMALS;
    }

    /// @notice Register DaoManager to delegate minting and burning permission
    /// @dev    Register can only be called once
    function registerDaoManager() external {
        require(address(dao) == address(0), "DAO Manager has been registered");
        dao = IDaoManager(msg.sender);
        emit DaoManagerRegistration(address(dao));
    }

    /// @notice Migrate the DAO Manager to the new version
    /// @dev    Migration can only called by DAO's admin
    function upgrateDaoManager(address newDao) external {
        require(msg.sender == dao.admin(), "Only admin can upgrade");
        require(dao.isBlockedForMigration(), "DAO is not at migration state");
        dao = IDaoManager(newDao);
        emit DaoManagerMigration(address(dao));
    }

    /// @notice Delegate minting permission to DaoManager
    /// @param  _account account that receive token newly minted
    /// @param  _amount  amount of the tokens to be minted
    function mint(address _account, uint256 _amount) external {
        require(msg.sender == address(dao), "Only DAO Manager can mint tokens");
        _mint(_account, _amount);
        emit Mint(_account, _amount);
    }

    /// @notice Delegate burning permission to DaoManager
    /// @param _account account that burn token
    /// @param _amount  amount of the tokens to be burned
    function burn(address _account, uint256 _amount) external {
        require(msg.sender == address(dao), "Only DAO Manager can burn tokens");
        _burn(_account, _amount);
        emit Burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.9;

/**
 * @dev Interface of the DaoManager that will be commonly used by other smart contracts.
 *
 *      This interface help to get DAO's global information
 *        - admin of the entire DAO
 *        - current auction day
 *        - state of token's emission
 *        - migration status
 *
 *      When the token's total supply reach its maxium, the DAO should be in the state of
 *      terminating token emission. This is implemented through function emissionTerminated.
 *      When this happens, users can not deposit to the auction or to staking pool anymore
 *      because there will be no interest for them, as there are no new tokens to be minted
 *
 *      When the system wants to upgrate, there are two steps
 *        - First admin move the DAO to the preparation state, where it notifies the entire
 *          community this will be the last day running on this old system. At this state,
 *          the isGoingToMigrate() return true
 *        - After the first state has been set, when DAO move to the next day, that will be
 *          the last, and everything will be frozen on the old system. If users want to do
 *          anything, that will be done through the newly deployed system
 */
interface IDaoManager {
    /**
     * @dev Get DAO's admin address
     */
    function admin() external view returns (address);

    /**
     * @dev Get current auction day
     */
    function day() external view returns (uint256);

    /**
     * @dev Get token's emission status
     */
    function emissionTerminated() external view returns (bool);

    /**
     * @dev Dao is about to migrate. This state determine the last day just before being blocked for the migration
     */
    function isGoingToMigrate() external view returns (bool);

    /**
     * @dev Dao is blocked for migration
     */
    function isBlockedForMigration() external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Constant library provides most of constants used in smart contracts among project
library Constant {
    uint8   internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_SCALE    = 10**TOKEN_DECIMALS;
    uint256 internal constant TOKEN_MAX_SUPPLY_THRESHOLD = 420000000 * TOKEN_SCALE; // Max supply ~ 420 M
    uint8   internal constant EPSILON = 10;

    /// @notice In the Treasury, the tokens are split by percentages:
    ///     Asset Fund:     50%
    ///     Insurance Fund: 30%
    ///     Operation Fund: 20%
    uint256 internal constant TREASURY_PERCENTAGE_ASSET     = 50;
    uint256 internal constant TREASURY_PERCENTAGE_INSURANCE = 30;

    /// @notice In the Treasury, claiming is locked up to a certain timestamp
    ///     Max lock:     6 months
    uint256 internal constant TREASURY_MAX_LOCK = 15552000;

    /// @notice In the Mirror Pool, the tokens are split by percentages:
    ///     Development & Marketing: 30%
    ///     Early Supporters:        10%
    ///     Reservation:             60%
    uint256 internal constant MIRROR_PERCENTAGE_EARLY_SUPPORTERS = 10;
    uint256 internal constant MIRROR_PERCENTAGE_RESERVATION      = 60;

    /// TODO: write description
    uint256 internal constant STAKING_FEE_CONVERGENCE_DAY = 787;
    uint256 internal constant STAKING_FEE_BASE_PERCENTAGE = 42;

    uint256 internal constant AUCTION_DEFAULT_FLOOR_DEPOSIT = 1;
    uint256 internal constant AUCTION_FLOOR_DEPOSIT_COEFFICIENT = 200;

    uint256 internal constant AUCTION_DEFAULT_CAP_DEPOSIT = 4200000 * TOKEN_SCALE;
    uint256 internal constant AUCTION_CAP_DEPOSIT_COEFFICIENT_1 = 284;
    uint256 internal constant AUCTION_CAP_DEPOSIT_COEFFICIENT_2 = 42;
}

/// TODO: write description
library DoubleHalving {
    uint256 internal constant PHASE_1 =  420;
    uint256 internal constant PHASE_2 =  630;
    uint256 internal constant PHASE_3 =  735;
    uint256 internal constant PHASE_4 =  787;

    uint256 internal constant AUCTION_EMISSION_1 = 100000;
    uint256 internal constant AUCTION_EMISSION_2 =  50000;
    uint256 internal constant AUCTION_EMISSION_3 =  25000;
    uint256 internal constant AUCTION_EMISSION_4 =  12500;
    uint256 internal constant AUCTION_EMISSION_5 =  12500;

    uint256 internal constant STAKING_REWARD_1 = 220000;
    uint256 internal constant STAKING_REWARD_2 = 110000;
    uint256 internal constant STAKING_REWARD_3 =  55000;
    uint256 internal constant STAKING_REWARD_4 =  27000;
    uint256 internal constant STAKING_REWARD_5 =  27000;

    function tokenInflation(uint256 _day) internal pure returns (uint256, uint256) {
        if (_day <= PHASE_1) return (AUCTION_EMISSION_1, STAKING_REWARD_1);
        if (_day <= PHASE_2) return (AUCTION_EMISSION_2, STAKING_REWARD_2);
        if (_day <= PHASE_3) return (AUCTION_EMISSION_3, STAKING_REWARD_3);
        if (_day <= PHASE_4) return (AUCTION_EMISSION_4, STAKING_REWARD_4);
        return (AUCTION_EMISSION_5, STAKING_REWARD_5);
    }
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