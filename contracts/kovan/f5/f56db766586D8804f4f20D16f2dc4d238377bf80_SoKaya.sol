// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "ERC20.sol";
import "Initializable.sol";
import "Math.sol";

import "KayaCenter.sol";
import "KayaDistributor.sol";
import "IKaya.sol";

struct User {
  uint256 value;
  uint256 until;
  address game;
}

contract SoKaya is ERC20("", ""), Initializable {
  IKaya public kaya;
  KayaDistributor public dist;
  KayaCenter public center;
  mapping(address => User) public users;

  /// @dev Initializes the SoKaya smart contract with the corrent Kaya Center.
  function initialize(KayaCenter _center, KayaDistributor _dist) external initializer {
    center = _center;
    kaya = _center.kaya();
    dist = _dist;
    dist.setSoKaya();
  }

  /// @dev Returns the name of soKAYA token.
  function name() public view override returns (string memory) {
    return "Super Owner of KAYA";
  }

  /// @dev Returns the symbol of soKAYA token.
  function symbol() public view override returns (string memory) {
    return "soKAYA";
  }

  /// @dev Locks KAYA tokens to earn soKAYA tokens. Newly earned tokens must be delegated.
  /// @param value The value of KAYA tokens to lock up.
  /// @param commitment The time commitment enum. Existing locked tokens will also be affected.
  /// @param game (First lock only) The address to delegate soKAYA power to.
  function lock(
    uint256 value,
    uint256 commitment,
    address game
  ) external {
    _lock(value, commitment, game);
  }

  /// @dev Similar to lock functionality, but with an addtional permit call.
  function lockWithPermit(
    uint256 value,
    uint256 commitment,
    address game,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    kaya.permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
    _lock(value, commitment, game);
  }

  function _lock(
    uint256 value,
    uint256 commitment,
    address game
  ) internal {
    require(kaya.transferFrom(msg.sender, address(this), value));
    User storage user = users[msg.sender];
    if (user.game == address(0)) {
      require(game != address(0) && center.isGame(game), "!game");
      user.game = game;
    } else {
      require(game == address(0) || game == user.game, "!game");
    }
    user.value += value;
    user.until += Math.max(user.until, block.timestamp + toLockTime(commitment));
    uint256 morePower = toLockMultiplier(commitment) * value;
    dist.increasePower(user.game, morePower);
    _mint(msg.sender, morePower);
  }

  /// @dev Unlocks KAYA tokens back to the sender. Must already pass lock period.
  /// @param value The amount of tokens to unlock.
  function unlock(uint256 value) external {
    User storage user = users[msg.sender];
    require(block.timestamp > user.until, "!until");
    uint256 lessPower = Math.ceilDiv(balanceOf(msg.sender) * value, user.value);
    user.value -= value;
    dist.decreasePower(user.game, lessPower);
    _burn(msg.sender, lessPower);
  }

  /// @dev Change voting power allocation to a new game.
  /// @param game The game contract to switch voting power to.
  function vote(address game) external {
    require(game != address(0) && center.isGame(game), "!game");
    User storage user = users[msg.sender];
    uint256 power = balanceOf(msg.sender);
    dist.transferPower(user.game, game, power);
    user.game = game;
  }

  /// @dev Given the commitment enum value, returns the duration of lock time in seconds.
  /// @param commitment The commitment value to query.
  function toLockTime(uint256 commitment) public pure returns (uint256) {
    if (commitment == 0) return 7 days;
    if (commitment == 1) return 30 days;
    if (commitment == 2) return 182 days;
    if (commitment == 3) return 365 days;
    if (commitment == 4) return 730 days;
    if (commitment == 5) return 1461 days;
    require(false, "!commitment");
  }

  /// @dev Given the commitment enum value, returns the SoKaya multiplier.
  /// @param commitment The commitment value to query.
  function toLockMultiplier(uint256 commitment) public pure returns (uint256) {
    if (commitment == 0) return 1;
    if (commitment == 1) return 2;
    if (commitment == 2) return 3;
    if (commitment == 3) return 5;
    if (commitment == 4) return 10;
    if (commitment == 5) return 20;
    require(false, "!commitment");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Initializable.sol";

import "KayaGame.sol";
import "WithGovernor.sol";
import "IKaya.sol";
import "IKayaCenter.sol";

contract KayaCenter is Initializable, WithGovernor, IKayaCenter {
  event SetCfo(address indexed cfo);
  event NewGame(address indexed game, string name, string uri);
  event EditGame(address indexed game, string name, string uri);
  event Deposit(address indexed game, address indexed user, uint256 value);
  event Withdraw(address indexed game, address indexed user, uint256 value);
  event Reward(address indexed game, uint256 value);

  IKaya public kaya;
  address public cfo;
  mapping(address => bool) public isGame;

  function initialize(IKaya _kaya, address _gov) external initializer {
    kaya = _kaya;
    cfo = _gov;
    initialize__WithGovernor(_gov);
  }

  /// @dev Sets the address that is authorized to initiate withdrawal from any games.
  /// @param _cfo The address to become the CFO.
  function setCfo(address _cfo) external onlyGov {
    cfo = _cfo;
    emit SetCfo(_cfo);
  }

  /// @dev Adds a new game to the ecosystem. The game will be able to earn KAYA rewards.
  /// @param name The name of the newly added game.
  /// @param uri The uri of the newly added game.
  function add(string memory name, string memory uri) external onlyGov returns (address) {
    address game = address(new KayaGame(name, uri));
    isGame[game] = true;
    emit NewGame(game, name, uri);
    return game;
  }

  /// @dev Edits the information of an existing game.
  /// @param game The address of the game contract to edit.
  /// @param name The name to edit to.
  /// @param uri The uri to edit to.
  function edit(
    address game,
    string memory name,
    string memory uri
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).edit(name, uri);
    emit EditGame(address(game), name, uri);
  }

  /// @dev Deposits KAYA into the given game.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  function deposit(address game, uint256 value) external {
    _deposit(game, value);
  }

  /// @dev Deposits KAYA into the given game using EIP-2612 permit to permit for max int.
  /// @param game The address of the game custody smart contract.
  /// @param value The value of KAYA token to deposit.
  /// @param deadline The deadline for EIP-2616 permit parameter.
  /// @param v Part of permit signature.
  /// @param r Part of permit signature.
  /// @param s Part of permit signature.
  function depositWithPermit(
    address game,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    kaya.permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
    _deposit(game, value);
  }

  /// @dev Internal function to process KAYA deposits to games.
  /// @param game The game address to deposit KAYA to.
  /// @param value The size of KAYA to deposit.
  function _deposit(address game, uint256 value) internal {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value), "!transferFrom");
    emit Deposit(game, msg.sender, value);
  }

  /// @dev TODO
  /// @param game TODO
  /// @param to TODO
  /// @param value TODO
  function withdraw(
    address game,
    address to,
    uint256 value
  ) external {
    require(msg.sender == cfo, "!cfo");
    require(isGame[game], "!game");
    KayaGame(game).withdraw(to, value);
    emit Withdraw(game, to, value);
  }

  /// @dev Adds more KAYA reward to the game. Can technically be called by anyone.
  /// @param game The game contract to reward.
  /// @param value The size of KAYA tokens to add as rewards.
  function reward(address game, uint256 value) external {
    require(isGame[game], "!game");
    require(kaya.transferFrom(msg.sender, game, value));
    emit Reward(game, value);
  }

  /// @dev TODO
  /// @param game TODO
  /// @param to TODO
  /// @param data TODO
  function sos(
    address game,
    address to,
    bytes memory data
  ) external onlyGov {
    require(isGame[game], "!game");
    KayaGame(game).sos(to, data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "IKaya.sol";
import "IKayaCenter.sol";
import "IKayaGame.sol";

contract KayaGame is IKayaGame {
  IKaya public immutable kaya;
  address public immutable controller;

  string public name;
  string public uri;

  /// @dev Initializes the smart contract with the initial state values.
  constructor(string memory _name, string memory _uri) {
    kaya = IKaya(IKayaCenter(msg.sender).kaya());
    controller = msg.sender;
    name = _name;
    uri = _uri;
  }

  /// @dev Edits the name and uri of this game contract.
  /// @param _name The new name to update, or "" if do-not-modify.
  /// @param _uri The new uri to update, or "" if do-not-modify.
  function edit(string memory _name, string memory _uri) external {
    require(msg.sender == controller, "!controller");
    if (bytes(_name).length > 0) {
      name = _name;
    }
    if (bytes(_uri).length > 0) {
      uri = _uri;
    }
  }

  /// @dev Withdraws KAYA tokens to the target address. Must be called by the controller.
  /// @param to The address to send KAYA tokens to.
  /// @param value The size of KAYA tokens to send.
  function withdraw(address to, uint256 value) external {
    require(msg.sender == controller, "!controller");
    require(kaya.transfer(to, value), "!transfer");
  }

  /// @dev Called by controller to ask this contract to any action. Primarily for recovering
  /// lost assets, whether in the forms of ERC20, ERC721, ERC1155, punks, or any other standard
  /// that get accidietnally sent to this contract.
  /// @param to The contract address to execute the acton.
  /// @param data The data attached the call.
  function sos(address to, bytes memory data) external payable {
    require(msg.sender == controller, "!controller");
    (bool ok, ) = to.call{ value: msg.value }(data);
    require(ok, "!ok");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "IERC20.sol";

interface IKaya is IERC20 {
  function mint(address to, uint256 amount) external;

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "IKaya.sol";

interface IKayaCenter {
  function kaya() external view returns (IKaya);

  function reward(address game, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IKayaGame {
  function withdraw(address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Initializable.sol";

contract WithGovernor is Initializable {
  address public gov;
  address public pendingGov;

  event AcceptGov(address gov);
  event SetPendingGov(address gov);

  modifier onlyGov() {
    require(msg.sender == gov, "!gov");
    _;
  }

  function initialize__WithGovernor(address _gov) internal initializer {
    require(_gov != address(0), "!gov");
    gov = _gov;
    emit AcceptGov(_gov);
  }

  /// @dev Updates the address to become the new governor after it accepts.
  /// @param _pendingGov The new pending governor address.
  function setPendingGov(address _pendingGov) external onlyGov {
    pendingGov = _pendingGov;
    emit SetPendingGov(_pendingGov);
  }

  /// @dev Called by the pending governor to become the governor.
  function acceptGov() external {
    require(msg.sender == pendingGov, "!pendingGov");
    pendingGov = address(0);
    gov = msg.sender;
    emit AcceptGov(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Initializable.sol";

import "WithGovernor.sol";
import "IKaya.sol";
import "IKayaGame.sol";
import "IKayaCenter.sol";

contract KayaDistributor is Initializable, WithGovernor {
  IKaya public kaya;
  IKayaCenter public center;
  address public soKaya;

  uint256 public accKayaPerPower;
  uint256 public totalPower;

  uint256 public inflation;
  uint256 public lastTick;

  mapping(address => uint256) public powers;
  mapping(address => uint256) public prevKayaPerPowers;

  function initialize(IKayaCenter _center, address _gov) external initializer {
    kaya = _center.kaya();
    center = _center;
    kaya.approve(address(center), type(uint256).max);
    lastTick = block.timestamp;
    initialize__WithGovernor(_gov);
  }

  /// @dev Initializes SoKAYA address to the invoker. Can and must only be called once.
  function setSoKaya() external {
    require(soKaya == address(0), "!setSoKaya");
    soKaya = msg.sender;
  }

  /// @dev Updates inflation rate per year imposed on KAYA for game distribution.
  /// @param _inflation Inflation rate per year, multiplied by 1e18.
  function setInflation(uint256 _inflation) external onlyGov {
    require(_inflation <= 1e18, "!inflation");
    tick();
    inflation = _inflation;
  }

  /// @dev Increases allocation power to the given game. Must be called by SoKAYA.
  /// @param game The game contract address to add power.
  /// @param power The power to increase.
  function increasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower += power;
    powers[game] += power;
  }

  /// @dev Decreases allocation power from the given game. Must be called by SoKAYA.
  /// @param game The game contract address to reduct power.
  /// @param power The power to decrease.
  function decreasePower(address game, uint256 power) external {
    require(msg.sender == soKaya, "!SoKaya");
    tick();
    flush(game);
    totalPower -= power;
    powers[game] -= power;
  }

  /// @dev Transfers allocation power from one game to another. Must be called by SoKAYA.
  /// @param src The game contract address to move allocation from.
  /// @param dst The game contract address to send allocation to.
  /// @param power The power to decrease.
  function transferPower(
    address src,
    address dst,
    uint256 power
  ) external {
    require(msg.sender == soKaya, "!SoKaya");
    require(src != dst, "!transfer");
    tick();
    flush(src);
    flush(dst);
    powers[src] -= power;
    powers[dst] += power;
  }

  /// @dev Triggers inflation logic to mint more KAYA and accumulate to the games.
  function tick() public {
    uint256 timePast = block.timestamp - lastTick;
    lastTick = block.timestamp;
    if (timePast > 0 && inflation > 0 && totalPower > 1e18) {
      uint256 value = (kaya.totalSupply() * inflation * timePast) / 1e18 / 365 days;
      kaya.mint(address(this), value);
      accKayaPerPower += (value * 1e12) / totalPower;
    }
  }

  /// @dev Flushes KAYA rewards to a specific game.
  /// @param game The game contract address to flush rewards to.
  function flush(address game) public {
    uint256 dist = ((accKayaPerPower - prevKayaPerPowers[game]) * powers[game]) / 1e12;
    prevKayaPerPowers[game] = accKayaPerPower;
    if (dist > 0) {
      center.reward(game, dist);
    }
  }
}