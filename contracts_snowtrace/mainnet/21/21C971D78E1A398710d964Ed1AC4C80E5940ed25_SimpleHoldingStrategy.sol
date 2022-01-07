// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20FlashMint.sol)

pragma solidity ^0.8.0;

import "../../../interfaces/IERC3156.sol";
import "../ERC20.sol";

/**
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMint is ERC20, IERC3156FlashLender {
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amont of token that can be loaned.
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        return token == address(this) ? type(uint256).max - ERC20.totalSupply() : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        // silence warning about unused variable without the addition of bytecode.
        amount;
        return 0;
    }

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower.onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` is the flash loan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bool) {
        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            "ERC20FlashMint: invalid return value"
        );
        uint256 currentAllowance = allowance(address(receiver), address(this));
        require(currentAllowance >= amount + fee, "ERC20FlashMint: allowance does not allow refund");
        _approve(address(receiver), address(this), currentAllowance - amount - fee);
        _burn(address(receiver), amount + fee);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./oracles/OracleAware.sol";
import "./roles/RoleAware.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./roles/DependsOnOracleListener.sol";
import "../interfaces/IOracle.sol";

/// Central hub and router for all oracles
contract OracleRegistry is RoleAware, DependsOracleListener {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => mapping(address => address)) public tokenOracle;
    mapping(address => mapping(address => EnumerableSet.AddressSet))
        internal _listeners;
    mapping(address => uint256) public borrowablePer10ks;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(ORACLE_REGISTRY);
    }

    function setBorrowable(address token, uint256 borrowablePer10k)
        external
        onlyOwnerExec
    {
        borrowablePer10ks[token] = borrowablePer10k;
        emit SubjectParameterUpdated("borrowable", token, borrowablePer10k);
    }

    /// Initialize oracle for a specific token
    function setOracleParams(
        address token,
        address pegCurrency,
        address oracle,
        uint256 borrowablePer10k,
        bool primary,
        bytes calldata data
    ) external onlyOwnerExecActivator {
        borrowablePer10ks[token] = borrowablePer10k;
        IOracle(oracle).setOracleParams(
            token,
            pegCurrency,
            data
        );

        // only overwrite oracle and update listeners if update is for a primary
        // or there is no pre-existing oracle
        address previousOracle = tokenOracle[token][pegCurrency];
        if (previousOracle == address(0) || primary) {
            tokenOracle[token][pegCurrency] = oracle;

            EnumerableSet.AddressSet storage listeners = _listeners[token][
                pegCurrency
            ];
            for (uint256 i; listeners.length() > i; i++) {
                OracleAware(listeners.at(i)).newCurrentOracle(
                    token,
                    pegCurrency
                );
            }
        }

        emit SubjectParameterUpdated("borrowable", token, borrowablePer10k);
    }

    /// Which oracle contract is currently responsible for a token is cached
    /// This updates
    function listenForCurrentOracleUpdates(address token, address pegCurrency)
        external
        returns (address)
    {
        require(isOracleListener(msg.sender), "Not allowed to listen");
        _listeners[token][pegCurrency].add(msg.sender);
        return tokenOracle[token][pegCurrency];
    }

    /// View converted value in currently registered oracle
    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public view returns (uint256) {
        return
            IOracle(tokenOracle[token][pegCurrency]).viewAmountInPeg(
                token,
                inAmount,
                pegCurrency
            );
    }

    /// View amounts for an array of tokens
    function viewAmountsInPeg(
        address[] calldata tokens,
        uint256[] calldata inAmounts,
        address pegCurrency
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](inAmounts.length);
        for (uint256 i; inAmounts.length > i; i++) {
            result[i] = viewAmountInPeg(tokens[i], inAmounts[i], pegCurrency);
        }
        return result;
    }

    /// Update converted value in currently registered oracle
    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public returns (uint256) {
        return
            IOracle(tokenOracle[token][pegCurrency]).getAmountInPeg(
                token,
                inAmount,
                pegCurrency
            );
    }

    /// Get amounts for an array of tokens
    function getAmountsInPeg(
        address[] calldata tokens,
        uint256[] calldata inAmounts,
        address pegCurrency
    ) external returns (uint256[] memory) {
        uint256[] memory result = new uint256[](inAmounts.length);
        for (uint256 i; inAmounts.length > i; i++) {
            result[i] = getAmountInPeg(tokens[i], inAmounts[i], pegCurrency);
        }
        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IProxyOwnership.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./roles/DependsOnTrancheTransferer.sol";

/// Provides a transitive closure over ownership relations for NFTs containing
/// other assets
abstract contract ProxyOwnershipERC721 is
    ERC721Enumerable,
    IProxyOwnership,
    DependsOnTrancheTransferer
{
    using Address for address;

    mapping(uint256 => uint256) public _containedIn;

    /// Allows for tokens to have not just an owner address, but also container
    /// within the owner contract which they belong to
    function containedIn(uint256 tokenId)
        public
        view
        override
        returns (address owner, uint256 containerId)
    {
        return (ownerOf(tokenId), _containedIn[tokenId]);
    }

    /// Check that spender is approved, owner or approved for container
    function isAuthorized(address spender, uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        address tokenOwner = ownerOf(tokenId);
        return
            isTrancheTransferer(spender) ||
            _isApprovedOrOwner(spender, tokenId) ||
            (tokenOwner.isContract() &&
                IProxyOwnership(tokenOwner).isAuthorized(
                    spender,
                    _containedIn[tokenId]
                ));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./roles/RoleAware.sol";
import "./roles/DependsOnMinterBurner.sol";
import "./roles/DependsOnFeeRecipient.sol";
import "../interfaces/IFeeReporter.sol";

contract Stablecoin is
    RoleAware,
    ERC20FlashMint,
    ReentrancyGuard,
    DependsOnMinterBurner,
    DependsOnFeeRecipient,
    ERC20Permit,
    IFeeReporter
{
    uint256 public globalDebtCeiling = 2_000_000 ether;

    uint256 public flashFeePer10k = (0.05 * 10_000) / 100;
    bool public flashLoansEnabled = true;
    uint256 public override viewAllFeesEver;

    mapping(address => uint256) public minBalance;

    constructor(address _roles)
        RoleAware(_roles)
        ERC20("Moremoney USD", "MONEY")
        ERC20Permit("MONEY")
    {
        _charactersPlayed.push(STABLECOIN);
    }

    // --------------------------- Mint / burn --------------------------------------//

    /// Mint stable, restricted to MinterBurner role (respecting global debt ceiling)
    function mint(address account, uint256 amount) external nonReentrant {
        require(isMinterBurner(msg.sender), "Not an autorized minter/burner");
        _mint(account, amount);

        require(
            globalDebtCeiling > totalSupply(),
            "Total supply exceeds global debt ceiling"
        );
    }

    /// Burn stable, restricted to MinterBurner role
    function burn(address account, uint256 amount) external nonReentrant {
        require(isMinterBurner(msg.sender), "Not an authorized minter/burner");
        _burn(account, amount);
    }

    /// Set global debt ceiling
    function setGlobalDebtCeiling(uint256 debtCeiling) external onlyOwnerExec {
        globalDebtCeiling = debtCeiling;
        emit ParameterUpdated("debt ceiling", debtCeiling);
    }

    // --------------------------- Min balances -------------------------------------//

    /// For some applications we may want to mint balances that can't be withdrawn or burnt.
    /// Contracts using this should first check balance before setting in a transaction
    function setMinBalance(address account, uint256 balance) external {
        require(isMinterBurner(msg.sender), "Not an authorized minter/burner");

        minBalance[account] = balance;
    }

    /// Check transfer and burn transactions for minimum balance compliance
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);
        require(
            balanceOf(from) >= minBalance[from],
            "Moremoney: below min balance"
        );
    }

    // ----------------- Flash loan related functions ------------------------------ //

    /// Calculate the fee taken on a flash loan
    function flashFee(address, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        return (amount * flashFeePer10k) / 10_000;
    }

    /// Set flash fee
    function setFlashFeePer10k(uint256 fee) external onlyOwnerExec {
        flashFeePer10k = fee;

        emit ParameterUpdated("flash fee", fee);
    }

    /// Take out a flash loan, sending fee to feeRecipient
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public override returns (bool) {
        require(flashLoansEnabled, "Flash loans are disabled");
        uint256 fee = flashFee(token, amount);
        _mint(feeRecipient(), fee);
        viewAllFeesEver += fee;
        return super.flashLoan(receiver, token, amount, data);
    }

    /// Enable or disable flash loans
    function setFlashLoansEnabled(bool setting) external onlyOwnerExec {
        flashLoansEnabled = setting;
        emit SubjectUpdated("flash loans enabled/disabled", address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IStrategy.sol";
import "./oracles/OracleAware.sol";
import "./Tranche.sol";
import "./roles/DependsOnStrategyRegistry.sol";
import "./roles/CallsStableCoinMintBurn.sol";
import "./roles/DependsOnTranche.sol";
import "./roles/DependsOnFundTransferer.sol";
import "../interfaces/IFeeReporter.sol";

/// Base class for strategies with facilities to manage (deposit/withdraw)
/// collateral in yield bearing system as well as yield distribution
abstract contract Strategy is
    IStrategy,
    OracleAware,
    CallsStableCoinMintBurn,
    DependsOnStrategyRegistry,
    DependsOnTranche,
    DependsOnFundTransferer,
    TrancheIDAware,
    ReentrancyGuard,
    IFeeReporter
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public override isActive = true;

    bytes32 public immutable override strategyName;

    EnumerableSet.AddressSet internal _approvedTokens;
    EnumerableSet.AddressSet internal _disapprovedTokens;
    EnumerableSet.AddressSet internal _allTokensEver;

    struct CollateralAccount {
        uint256 collateral;
        uint256 yieldCheckptIdx;
        address trancheToken;
    }

    mapping(uint256 => CollateralAccount) public _accounts;

    struct TokenMetadata {
        uint256[] yieldCheckpoints;
        uint256 totalCollateralThisPhase;
        uint256 totalCollateralNow;
        uint256 apfLastUpdated;
        uint256 apf;
    }

    uint256 public apfSmoothingPer10k = 5000;

    mapping(address => TokenMetadata) public tokenMetadata;

    uint256 internal constant FP64 = 2**64;

    constructor(bytes32 stratName) {
        strategyName = stratName;
    }

    /// Run only if the strategy has not been deactivated
    modifier onlyActive() {
        require(isActive, "Strategy is not active");
        _;
    }

    /// Allows tranche contracts to register new tranches
    function registerMintTranche(
        address minter,
        uint256 trancheId,
        address assetToken,
        uint256,
        uint256 assetAmount
    ) external override onlyActive nonReentrant {
        require(
            isFundTransferer(msg.sender) && tranche(trancheId) == msg.sender,
            "Invalid tranche"
        );
        _mintTranche(minter, trancheId, assetToken, assetAmount);
    }

    /// Internals for minting or migrating a tranche
    function _mintTranche(
        address minter,
        uint256 trancheId,
        address assetToken,
        uint256 assetAmount
    ) internal {
        TokenMetadata storage meta = tokenMetadata[assetToken];
        _accounts[trancheId].yieldCheckptIdx = meta.yieldCheckpoints.length;
        _setAndCheckTrancheToken(trancheId, assetToken);
        _deposit(minter, trancheId, assetAmount, yieldCurrency(), minter);
    }

    /// Register deposit to tranche on behalf of user (to be called by other contract)
    function registerDepositFor(
        address depositor,
        uint256 trancheId,
        uint256 amount,
        address yieldRecipient
    ) external virtual override onlyActive nonReentrant {
        require(
            isFundTransferer(msg.sender),
            "Not authorized to transfer user funds"
        );
        _deposit(depositor, trancheId, amount, yieldCurrency(), yieldRecipient);
    }

    /// Internal function to manage depositing
    function _deposit(
        address depositor,
        uint256 trancheId,
        uint256 amount,
        address yieldToken,
        address yieldRecipient
    ) internal virtual {
        address token = trancheToken(trancheId);
        _collectYield(trancheId, yieldToken, yieldRecipient);

        collectCollateral(depositor, token, amount);
        uint256 oldBalance = _accounts[trancheId].collateral;
        _accounts[trancheId].collateral = oldBalance + amount;

        TokenMetadata storage meta = tokenMetadata[token];
        meta.totalCollateralNow += amount;
        _handleBalanceUpdate(trancheId, token, oldBalance + amount);
    }

    /// Callback for strategy-specific logic
    function _handleBalanceUpdate(
        uint256 trancheId,
        address token,
        uint256 balance
    ) internal virtual {}

    /// Withdraw tokens from tranche (only callable by fund transferer)
    function withdraw(
        uint256 trancheId,
        uint256 amount,
        address yieldToken,
        address recipient
    ) external virtual override onlyActive nonReentrant {
        require(isFundTransferer(msg.sender), "Not authorized to withdraw");
        require(recipient != address(0), "Don't send to zero address");

        _withdraw(trancheId, amount, yieldToken, recipient);
    }

    /// Internal machinations of withdrawals and returning collateral
    function _withdraw(
        uint256 trancheId,
        uint256 amount,
        address yieldToken,
        address recipient
    ) internal virtual {
        CollateralAccount storage account = _accounts[trancheId];
        address token = trancheToken(trancheId);

        _collectYield(trancheId, yieldToken, recipient);

        amount = min(amount, viewTargetCollateralAmount(trancheId));
        returnCollateral(recipient, token, amount);

        account.collateral -= amount;

        TokenMetadata storage meta = tokenMetadata[token];
        // compounding strategies must add any additional collateral to totalCollateralNow
        // in _collectYield, so we don't get an underflow here
        meta.totalCollateralNow -= amount;

        if (meta.yieldCheckpoints.length > account.yieldCheckptIdx) {
            // this account is participating in the current distribution phase, remove it
            meta.totalCollateralThisPhase -= amount;
        }
        _handleBalanceUpdate(trancheId, token, account.collateral);
    }

    /// Migrate contents of tranche to new strategy
    function migrateStrategy(
        uint256 trancheId,
        address targetStrategy,
        address yieldToken,
        address yieldRecipient
    )
        external
        virtual
        override
        onlyActive
        returns (
            address,
            uint256,
            uint256
        )
    {
        require(msg.sender == tranche(trancheId), "Not authorized to migrate");

        address token = trancheToken(trancheId);
        uint256 targetAmount = viewTargetCollateralAmount(trancheId);
        IERC20(token).safeIncreaseAllowance(targetStrategy, targetAmount);
        _collectYield(trancheId, yieldToken, yieldRecipient);
        uint256 subCollateral = returnCollateral(
            address(this),
            token,
            targetAmount
        );
        tokenMetadata[token].totalCollateralNow -= subCollateral;

        return (token, 0, subCollateral);
    }

    /// Accept migrated assets from another tranche
    function acceptMigration(
        uint256 trancheId,
        address sourceStrategy,
        address tokenContract,
        uint256,
        uint256 amount
    ) external virtual override nonReentrant {
        require(msg.sender == tranche(trancheId), "Not authorized to migrate");
        _mintTranche(sourceStrategy, trancheId, tokenContract, amount);
    }

    /// Migrate all tranches managed to a new strategy, using strategy registry as
    /// go-between
    function migrateAllTo(address destination)
        external
        override
        onlyActive
        onlyOwnerExecDisabler
    {
        tallyHarvestBalance();

        for (uint256 i; _allTokensEver.length() > i; i++) {
            address token = _allTokensEver.at(i);

            uint256 totalAmount = _viewTVL(token);
            StrategyRegistry registry = strategyRegistry();
            returnCollateral(address(registry), token, totalAmount);
            IERC20(token).safeApprove(address(registry), 0);
            IERC20(token).safeApprove(address(registry), type(uint256).max);

            registry.depositMigrationTokens(destination, token);
        }
        isActive = false;
    }

    /// Account for harvested yield which has lapped up upon the shore of this
    /// contract's balance and convert it into yield for users, for all tokens
    function tallyHarvestBalance() internal virtual returns (uint256 balance) {}

    function collectYield(
        uint256 trancheId,
        address currency,
        address recipient
    ) external virtual override nonReentrant returns (uint256) {
        require(
            isFundTransferer(msg.sender) ||
                Tranche(tranche(trancheId)).isAuthorized(msg.sender, trancheId),
            "Not authorized to collect yield"
        );

        return _collectYield(trancheId, currency, recipient);
    }

    /// For a specific tranche, collect yield and view value and borrowable per 10k
    function collectYieldValueBorrowable(
        uint256 trancheId,
        address _yieldCurrency,
        address valueCurrency,
        address recipient
    )
        external
        override
        nonReentrant
        returns (
            uint256 yield,
            uint256 value,
            uint256 borrowablePer10k
        )
    {
        require(
            isFundTransferer(msg.sender) ||
                Tranche(tranche(trancheId)).isAuthorized(msg.sender, trancheId),
            "Not authorized to collect yield"
        );

        yield = _collectYield(trancheId, _yieldCurrency, recipient);
        (value, borrowablePer10k) = _getValueBorrowable(
            trancheToken(trancheId),
            viewTargetCollateralAmount(trancheId),
            valueCurrency
        );
    }

    /// For a specific tranche, view its accrued yield, value and borrowable per 10k
    function viewYieldValueBorrowable(
        uint256 trancheId,
        address _yieldCurrency,
        address valueCurrency
    )
        external
        view
        override
        returns (
            uint256 yield,
            uint256 value,
            uint256 borrowablePer10k
        )
    {
        yield = viewYield(trancheId, _yieldCurrency);
        (value, borrowablePer10k) = _viewValueBorrowable(
            trancheToken(trancheId),
            viewTargetCollateralAmount(trancheId),
            valueCurrency
        );
    }

    /// View the value of a tranche
    function viewValue(uint256 trancheId, address valueCurrency)
        external
        view
        override
        returns (uint256 value)
    {
        (value, ) = _viewValueBorrowable(
            trancheToken(trancheId),
            viewTargetCollateralAmount(trancheId),
            valueCurrency
        );
    }

    /// View value and borrowable per10k of tranche
    function viewValueBorrowable(uint256 trancheId, address valueCurrency)
        external
        view
        override
        returns (uint256 value, uint256 borrowable)
    {
        return
            _viewValueBorrowable(
                trancheToken(trancheId),
                viewTargetCollateralAmount(trancheId),
                valueCurrency
            );
    }

    /// View borrowable per10k of tranche
    function viewBorrowable(uint256 trancheId)
        external
        view
        override
        returns (uint256 borrowablePer10k)
    {
        (, borrowablePer10k) = _viewValueBorrowable(
            trancheToken(trancheId),
            viewTargetCollateralAmount(trancheId),
            yieldCurrency()
        );
    }

    /// Withdraw collateral from source account
    function collectCollateral(
        address source,
        address token,
        uint256 collateralAmount
    ) internal virtual;

    /// Return collateral to user
    function returnCollateral(
        address recipient,
        address token,
        uint256 collateralAmount
    ) internal virtual returns (uint256 collteral2Subtract);

    /// Returns the token associated with a tranche
    function trancheToken(uint256 trancheId)
        public
        view
        virtual
        override
        returns (address token)
    {
        return _accounts[trancheId].trancheToken;
    }

    /// Internal, sets the tranche token and checks that it's supported
    function _setAndCheckTrancheToken(uint256 trancheId, address token)
        internal
        virtual
    {
        require(_approvedTokens.contains(token), "Not an approved token");
        _accounts[trancheId].trancheToken = token;
    }

    /// Is a token supported by this strategy?
    function approvedToken(address token) public view override returns (bool) {
        return _approvedTokens.contains(token);
    }

    /// Internal, collect yield and disburse it to recipient
    function _collectYield(
        uint256 trancheId,
        address currency,
        address recipient
    ) internal virtual returns (uint256 yieldEarned);

    /// Internal, view accrued yield for account
    function _viewYield(
        CollateralAccount storage account,
        TokenMetadata storage tokenMeta,
        address currency
    ) internal view returns (uint256) {
        require(currency == yieldCurrency(), "Wrong yield currency");

        uint256[] storage checkPts = tokenMeta.yieldCheckpoints;
        if (checkPts.length > account.yieldCheckptIdx) {
            uint256 yieldDelta = checkPts[checkPts.length - 1] -
                checkPts[account.yieldCheckptIdx];
            return (account.collateral * yieldDelta) / FP64;
        } else {
            return 0;
        }
    }

    /// View accrued yield for a tranche
    function viewYield(uint256 trancheId, address currency)
        public
        view
        virtual
        override
        returns (uint256)
    {
        CollateralAccount storage account = _accounts[trancheId];
        return
            _viewYield(
                account,
                tokenMetadata[trancheToken(trancheId)],
                currency
            );
    }

    /// The currency used to aggregate yield in this strategy (mintable)
    function yieldCurrency() public view virtual override returns (address) {
        return address(stableCoin());
    }

    /// set up a token to be supported by this strategy
    function approveToken(address token, bytes calldata data)
        external
        virtual
        onlyOwnerExecActivator
    {
        _approveToken(token, data);

        // Kick the oracle to update
        _getValue(token, 1e18, address(stableCoin()));
    }

    /// Internals to approving token and informing the strategy registry
    function _approveToken(address token, bytes calldata) internal virtual {
        _approvedTokens.add(token);
        _disapprovedTokens.remove(token);
        _allTokensEver.add(token);
        tokenMetadata[token].apf = 10_000;
        tokenMetadata[token].apfLastUpdated = block.timestamp;

        strategyRegistry().updateTokenCount(address(this));
    }

    /// Give some token the stink-eye and tell it to never show its face again
    function disapproveToken(address token, bytes calldata)
        external
        virtual
        onlyOwnerExec
    {
        _approvedTokens.remove(token);
        _disapprovedTokens.add(token);
        strategyRegistry().updateTokenCount(address(this));
    }

    /// Calculate collateral amount held by tranche (e.g. taking into account
    /// compounding)
    function viewTargetCollateralAmount(uint256 trancheId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        CollateralAccount storage account = _accounts[trancheId];
        return account.collateral;
    }

    /// The ID of the tranche token (relevant if not handling ERC20)
    function trancheTokenID(uint256) external pure override returns (uint256) {
        return 0;
    }

    /// All the tokens this strategy has ever touched
    function viewAllTokensEver() external view returns (address[] memory) {
        return _allTokensEver.values();
    }

    /// View all tokens currently supported by this strategy
    function viewAllApprovedTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return _approvedTokens.values();
    }

    /// View all tokens currently supported by this strategy
    function viewAllDisapprovedTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return _disapprovedTokens.values();
    }

    /// count the number of tokens this strategy currently supports
    function approvedTokensCount() external view override returns (uint256) {
        return _approvedTokens.length();
    }

    /// count the number of tokens this strategy currently supports
    function disapprovedTokensCount() external view override returns (uint256) {
        return _disapprovedTokens.length();
    }

    /// View metadata for a token
    function viewStrategyMetadata(address token)
        public
        view
        override
        returns (IStrategy.StrategyMetadata memory)
    {
        (uint256 value, uint256 borrowablePer10k) = _viewValueBorrowable(
            token,
            1 ether,
            address(stableCoin())
        );

        return
            IStrategy.StrategyMetadata({
                strategy: address(this),
                token: token,
                APF: viewAPF(token),
                totalCollateral: tokenMetadata[token].totalCollateralNow,
                borrowablePer10k: borrowablePer10k,
                valuePer1e18: value,
                strategyName: strategyName,
                tvl: _viewTVL(token),
                harvestBalance2Tally: viewHarvestBalance2Tally(token),
                yieldType: yieldType(),
                stabilityFee: stabilityFeePer10k(token),
                underlyingStrategy: viewUnderlyingStrategy(token)
            });
    }

    /// view metadata for all tokens in an array
    function viewAllStrategyMetadata()
        external
        view
        override
        returns (IStrategy.StrategyMetadata[] memory)
    {
        uint256 tokenCount = _approvedTokens.length();
        IStrategy.StrategyMetadata[]
            memory result = new IStrategy.StrategyMetadata[](tokenCount);
        for (uint256 i; tokenCount > i; i++) {
            result[i] = viewStrategyMetadata(_approvedTokens.at(i));
        }
        return result;
    }

    // view metadata for all tokens that have been disapproved
    function viewAllDisapprovedTokenStrategyMetadata()
        external
        view
        override
        returns (IStrategy.StrategyMetadata[] memory)
    {
        uint256 tokenCount = _disapprovedTokens.length();
        IStrategy.StrategyMetadata[]
            memory result = new IStrategy.StrategyMetadata[](tokenCount);
        for (uint256 i; tokenCount > i; i++) {
            result[i] = viewStrategyMetadata(_disapprovedTokens.at(i));
        }
        return result;
    }

    /// Annual percentage factor, APR = APF - 100%
    function viewAPF(address token)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return tokenMetadata[token].apf;
    }

    /// Miniumum of two numbes
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    /// View TVL in a token
    function _viewTVL(address token) public view virtual returns (uint256) {
        return tokenMetadata[token].totalCollateralNow;
    }

    /// View Stability fee if any
    function stabilityFeePer10k(address) public view virtual returns (uint256) {
        return 0;
    }

    /// Internal, update APF number
    function _updateAPF(
        address token,
        uint256 addedBalance,
        uint256 basisValue
    ) internal {
        TokenMetadata storage tokenMeta = tokenMetadata[token];
        if (addedBalance > 0 && tokenMeta.apfLastUpdated < block.timestamp) {
            uint256 lastUpdated = tokenMeta.apfLastUpdated;
            uint256 timeDelta = lastUpdated > 0
                ? block.timestamp - lastUpdated
                : 1 weeks;

            uint256 newRate = ((addedBalance + basisValue) *
                10_000 *
                (365 days)) /
                basisValue /
                timeDelta;

            uint256 smoothing = lastUpdated > 0 ? apfSmoothingPer10k : 0;
            tokenMeta.apf =
                (tokenMeta.apf * smoothing) /
                10_000 +
                (newRate * (10_000 - smoothing)) /
                10_000;
            tokenMeta.apfLastUpdated = block.timestamp;
        }
    }

    /// Since return rates vary, we smooth
    function setApfSmoothingPer10k(uint256 smoothing) external onlyOwnerExec {
        apfSmoothingPer10k = smoothing;
        emit ParameterUpdated("apf smoothing", smoothing);
    }

    /// View outstanding yield that needs to be distributed to accounts of an asset
    /// if any
    function viewHarvestBalance2Tally(address)
        public
        view
        virtual
        returns (uint256)
    {
        return 0;
    }

    /// Returns whether the strategy is compounding repaying or no yield
    function yieldType() public view virtual override returns (YieldType);

    /// In an emergency, withdraw tokens from yield generator
    function rescueCollateral(
        address token,
        uint256 amount,
        address recipient
    ) external onlyOwnerExec {
        require(recipient != address(0), "Don't send to zero address");
        returnCollateral(recipient, token, amount);
    }

    /// In an emergency, withdraw any tokens stranded in this contract's balance
    function rescueStrandedTokens(
        address token,
        uint256 amount,
        address recipient
    ) external onlyOwnerExec {
        require(recipient != address(0), "Don't send to zero address");
        IERC20(token).safeTransfer(recipient, amount);
    }

    /// Rescue any stranded native currency
    function rescueNative(uint256 amount, address recipient)
        external
        onlyOwnerExec
    {
        require(recipient != address(0), "Don't send to zero address");
        payable(recipient).transfer(amount);
    }

    /// Accept native deposits
    fallback() external payable {}

    receive() external payable {}

    /// View estimated harvestable amount in source strategy
    function viewSourceHarvestable(address)
        public
        view
        virtual
        returns (uint256)
    {
        return 0;
    }

    /// View estimated harvestable amount
    function viewEstimatedHarvestable(address token)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return viewHarvestBalance2Tally(token) + viewSourceHarvestable(token);
    }

    // View the underlying yield strategy (if any)
    function viewUnderlyingStrategy(address token)
        public
        view
        virtual
        override
        returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "../interfaces/IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// TODO: handle non-ERC20 migrations

/// Central clearing house for all things strategy, for activating and migrating
contract StrategyRegistry is RoleAware, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    mapping(address => address) public replacementStrategy;

    EnumerableSet.AddressSet internal enabledStrategies;
    EnumerableSet.AddressSet internal allStrategiesEver;

    mapping(address => uint256) public _tokenCount;
    mapping(address => uint256) public _disabledTokenCount;
    uint256 public totalTokenStratRows;
    uint256 public totalDisabledTokenStratRows;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(STRATEGY_REGISTRY);
    }

    /// View all enabled strategies
    function allEnabledStrategies() external view returns (address[] memory) {
        return enabledStrategies.values();
    }

    /// Enable a strategy
    function enableStrategy(address strat) external onlyOwnerExec {
        enabledStrategies.add(strat);
        allStrategiesEver.add(strat);
        updateTokenCount(strat);
    }

    /// Disable a strategy
    function disableStrategy(address strat) external onlyOwnerExec {
        totalTokenStratRows -= _tokenCount[strat];
        enabledStrategies.remove(strat);
    }

    /// View whether a strategy is enabled
    function enabledStrategy(address strat) external view returns (bool) {
        return enabledStrategies.contains(strat);
    }

    /// Replace a strategy and migrate all its assets to replacement
    /// beware not to introduce cycles :)
    function replaceStrategy(address legacyStrat, address replacementStrat)
        external
        onlyOwnerExec
    {
        require(
            enabledStrategies.contains(replacementStrat),
            "Replacement strategy is not enabled"
        );
        IStrategy(legacyStrat).migrateAllTo(replacementStrat);
        enabledStrategies.remove(legacyStrat);
        replacementStrategy[legacyStrat] = replacementStrat;
    }

    /// Get strategy or any replacement of it
    function getCurrentStrategy(address strat) external view returns (address) {
        address result = strat;
        while (replacementStrategy[result] != address(0)) {
            result = replacementStrategy[result];
        }
        return result;
    }

    /// Endpoint for strategies to deposit tokens for migration destinations
    /// to later withdraw
    function depositMigrationTokens(address destination, address token)
        external
        nonReentrant
    {
        uint256 amount = IERC20(token).balanceOf(msg.sender);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeIncreaseAllowance(destination, amount);
    }

    /// update accounting cache for view function
    function updateTokenCount(address strat) public {
        require(enabledStrategies.contains(strat), "Not an enabled strategy!");

        uint256 oldCount = _tokenCount[strat];
        uint256 newCount = IStrategy(strat).approvedTokensCount();
        totalTokenStratRows = totalTokenStratRows + newCount - oldCount;
        _tokenCount[strat] = newCount;

        oldCount = _disabledTokenCount[strat];
        newCount = IStrategy(strat).disapprovedTokensCount();
        totalDisabledTokenStratRows =
            totalDisabledTokenStratRows +
            newCount -
            oldCount;
        _disabledTokenCount[strat] = newCount;
    }

    /// Return a big ol list of strategy metadata
    function viewAllEnabledStrategyMetadata()
        external
        view
        returns (IStrategy.StrategyMetadata[] memory)
    {
        IStrategy.StrategyMetadata[]
            memory result = new IStrategy.StrategyMetadata[](
                totalTokenStratRows
            );
        uint256 enabledTotal = enabledStrategies.length();
        uint256 resultI;
        for (uint256 stratI; enabledTotal > stratI; stratI++) {
            IStrategy strat = IStrategy(enabledStrategies.at(stratI));
            IStrategy.StrategyMetadata[] memory meta = strat
                .viewAllStrategyMetadata();
            for (uint256 i; meta.length > i; i++) {
                result[resultI + i] = meta[i];
            }
            resultI += meta.length;
        }

        return result;
    }

    function viewAllDisabledTokenStrategyMetadata()
        external
        view
        returns (IStrategy.StrategyMetadata[] memory)
    {
        IStrategy.StrategyMetadata[]
            memory result = new IStrategy.StrategyMetadata[](
                totalDisabledTokenStratRows
            );

        uint256 enabledTotal = enabledStrategies.length();
        uint256 resultI;

        for (uint256 stratI; enabledTotal > stratI; stratI++) {
            IStrategy strat = IStrategy(enabledStrategies.at(stratI));
            IStrategy.StrategyMetadata[] memory meta = strat
                .viewAllDisapprovedTokenStrategyMetadata();

            for (uint256 i; meta.length > i; i++) {
                result[resultI + i] = meta[i];
            }
            resultI += meta.length;
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ProxyOwnershipERC721.sol";
import "./roles/RoleAware.sol";
import "./StrategyRegistry.sol";
import "./TrancheIDService.sol";
import "./roles/DependsOnTrancheIDService.sol";
import "./roles/DependsOnStrategyRegistry.sol";
import "./roles/DependsOnFundTransferer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// Express an amount of token held in yield farming strategy as an ERC721
contract Tranche is
    ProxyOwnershipERC721,
    DependsOnTrancheIDService,
    DependsOnStrategyRegistry,
    DependsOnFundTransferer,
    RoleAware,
    IAsset,
    ReentrancyGuard
{
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    event TrancheUpdated(uint256 indexed trancheId);

    mapping(uint256 => address) public _holdingStrategies;

    mapping(uint256 => EnumerableSet.UintSet) internal updatedTranches;
    uint256 public updateTrackingPeriod = 7 days;

    constructor(
        string memory _name,
        string memory _symbol,
        address _roles
    ) ERC721(_name, _symbol) RoleAware(_roles) {
        _rolesPlayed.push(TRANCHE);
    }

    /// internal function managing the minting of new tranches
    /// letting the holding strategy collect the asset
    function _mintTranche(
        address minter,
        uint256 vaultId,
        address strategy,
        address assetToken,
        uint256 assetTokenId,
        uint256 assetAmount
    ) internal returns (uint256 trancheId) {
        require(
            strategyRegistry().enabledStrategy(strategy),
            "Strategy not approved"
        );

        trancheId = trancheIdService().getNextTrancheId();

        _holdingStrategies[trancheId] = strategy;
        _containedIn[trancheId] = vaultId;
        _checkAssetToken(assetToken);
        _safeMint(minter, trancheId, abi.encode(vaultId));

        IStrategy(strategy).registerMintTranche(
            minter,
            trancheId,
            assetToken,
            assetTokenId,
            assetAmount
        );

        _trackUpdated(trancheId);
    }

    /// Mint a new tranche
    function mintTranche(
        uint256 vaultId,
        address strategy,
        address assetToken,
        uint256 assetTokenId,
        uint256 assetAmount
    ) external nonReentrant returns (uint256 trancheId) {
        return
            _mintTranche(
                msg.sender,
                vaultId,
                strategy,
                assetToken,
                assetTokenId,
                assetAmount
            );
    }

    /// Deposit more collateral to the tranche
    function deposit(uint256 trancheId, uint256 tokenAmount)
        external
        nonReentrant
    {
        _deposit(msg.sender, trancheId, tokenAmount);
    }

    /// Endpoint for authorized fund transferer to deposit on behalf of user
    function registerDepositFor(
        address depositor,
        uint256 trancheId,
        uint256 tokenAmount
    ) external {
        require(isFundTransferer(msg.sender), "Unauthorized fund transfer");
        _deposit(depositor, trancheId, tokenAmount);
    }

    /// Internal logic for depositing
    function _deposit(
        address depositor,
        uint256 trancheId,
        uint256 tokenAmount
    ) internal virtual {
        IStrategy strat = IStrategy(getCurrentHoldingStrategy(trancheId));
        strat.registerDepositFor(
            depositor,
            trancheId,
            tokenAmount,
            ownerOf(trancheId)
        );
        _trackUpdated(trancheId);
    }

    /// Withdraw tokens from tranche, checing viability
    function withdraw(
        uint256 trancheId,
        uint256 tokenAmount,
        address yieldCurrency,
        address recipient
    ) external override nonReentrant {
        require(
            isAuthorized(msg.sender, trancheId),
            "not authorized to withdraw"
        );
        require(recipient != address(0), "Don't burn");

        _withdraw(trancheId, tokenAmount, yieldCurrency, recipient);
    }

    /// Withdraw tokens from tranche, checing viability, internal logic
    function _withdraw(
        uint256 trancheId,
        uint256 tokenAmount,
        address yieldCurrency,
        address recipient
    ) internal virtual {
        address holdingStrategy = getCurrentHoldingStrategy(trancheId);
        IStrategy(holdingStrategy).withdraw(
            trancheId,
            tokenAmount,
            yieldCurrency,
            recipient
        );
        require(isViable(trancheId), "Tranche unviable");
        _trackUpdated(trancheId);
    }

    /// Make strategy calculate and disburse yield
    function _collectYield(
        uint256 trancheId,
        address currency,
        address recipient
    ) internal returns (uint256) {
        address holdingStrategy = getCurrentHoldingStrategy(trancheId);
        uint256 yield = IStrategy(holdingStrategy).collectYield(
            trancheId,
            currency,
            recipient
        );

        _trackUpdated(trancheId);
        return yield;
    }

    /// Disburse yield in tranche to recipient
    function collectYield(
        uint256 trancheId,
        address currency,
        address recipient
    ) external virtual override nonReentrant returns (uint256) {
        require(
            isAuthorized(msg.sender, trancheId),
            "not authorized to withdraw yield"
        );
        return _collectYield(trancheId, currency, recipient);
    }

    /// Collect yield in a batch
    function batchCollectYield(
        uint256[] calldata trancheIds,
        address currency,
        address recipient
    ) external nonReentrant returns (uint256) {
        uint256 yield;

        for (uint256 i; trancheIds.length > i; i++) {
            uint256 trancheId = trancheIds[i];
            require(
                isAuthorized(msg.sender, trancheId),
                "not authorized to withdraw"
            );

            yield += _collectYield(trancheId, currency, recipient);
        }
        return yield;
    }

    /// View accrued yield in a tranche
    function viewYield(uint256 trancheId, address currency)
        public
        view
        virtual
        override
        returns (uint256)
    {
        address holdingStrategy = _holdingStrategies[trancheId];
        return IStrategy(holdingStrategy).viewYield(trancheId, currency);
    }

    /// View yield jointly in a batch
    function batchViewYield(uint256[] calldata trancheIds, address currency)
        public
        view
        returns (uint256)
    {
        uint256 yield;

        for (uint256 i; trancheIds.length > i; i++) {
            uint256 trancheId = trancheIds[i];

            yield += viewYield(trancheId, currency);
        }
        return yield;
    }

    /// View borrowable per 10k of tranche
    function viewBorrowable(uint256 trancheId)
        public
        view
        override
        returns (uint256)
    {
        address holdingStrategy = _holdingStrategies[trancheId];
        return IStrategy(holdingStrategy).viewBorrowable(trancheId);
    }

    /// View value, and borrowable (average weighted by value) for a batch, jointly
    function batchViewValueBorrowable(
        uint256[] calldata trancheIds,
        address currency
    ) public view returns (uint256, uint256) {
        uint256 totalValue;
        uint256 totalBorrowablePer10k;
        for (uint256 i; trancheIds.length > i; i++) {
            uint256 trancheId = trancheIds[i];

            (uint256 value, uint256 borrowablePer10k) = IStrategy(
                _holdingStrategies[trancheId]
            ).viewValueBorrowable(trancheId, currency);
            totalBorrowablePer10k += value * borrowablePer10k;
        }

        return (totalValue, totalBorrowablePer10k / totalValue);
    }

    /// Collect yield and view value and borrowable per 10k
    function collectYieldValueBorrowable(
        uint256 trancheId,
        address yieldCurrency,
        address valueCurrency,
        address recipient
    )
        public
        virtual
        override
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(
            isAuthorized(msg.sender, trancheId) || isFundTransferer(msg.sender),
            "not authorized to withdraw"
        );
        return
            _collectYieldValueBorrowable(
                trancheId,
                yieldCurrency,
                valueCurrency,
                recipient
            );
    }

    /// Internal function to collect yield and view value and borrowable per 10k
    function _collectYieldValueBorrowable(
        uint256 trancheId,
        address yieldCurrency,
        address valueCurrency,
        address recipient
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address holdingStrategy = getCurrentHoldingStrategy(trancheId);
        return
            IStrategy(holdingStrategy).collectYieldValueBorrowable(
                trancheId,
                yieldCurrency,
                valueCurrency,
                recipient
            );
    }

    /// Collect yield and view value and borrowable jointly and in weighted avg.
    function batchCollectYieldValueBorrowable(
        uint256[] calldata trancheIds,
        address yieldCurrency,
        address valueCurrency,
        address recipient
    )
        public
        returns (
            uint256 yield,
            uint256 value,
            uint256 borrowablePer10k
        )
    {
        for (uint256 i; trancheIds.length > i; i++) {
            uint256 trancheId = trancheIds[i];

            // these calls are nonReentrant individually
            (
                uint256 _yield,
                uint256 _value,
                uint256 _borrowablePer10k
            ) = collectYieldValueBorrowable(
                    trancheId,
                    yieldCurrency,
                    valueCurrency,
                    recipient
                );
            yield += _yield;
            value += _value;
            borrowablePer10k += _borrowablePer10k * _value;
        }
        borrowablePer10k = borrowablePer10k / value;
    }

    /// View yield value and borrowable together
    function viewYieldValueBorrowable(
        uint256 trancheId,
        address yieldCurrency,
        address valueCurrency
    )
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address holdingStrategy = _holdingStrategies[trancheId];
        return
            IStrategy(holdingStrategy).viewYieldValueBorrowable(
                trancheId,
                yieldCurrency,
                valueCurrency
            );
    }

    /// Check if a tranche is viable. Can be overriden to check
    /// collateralization ratio. By default defer to container.
    function isViable(uint256 trancheId)
        public
        view
        virtual
        override
        returns (bool)
    {
        address tokenOwner = ownerOf(trancheId);
        if (tokenOwner.isContract()) {
            IProxyOwnership bearer = IProxyOwnership(tokenOwner);
            return bearer.isViable(_containedIn[trancheId]);
        } else {
            return true;
        }
    }

    /// Migrate assets from one strategy to another, collecting yield if any
    function migrateStrategy(
        uint256 trancheId,
        address destination,
        address yieldToken,
        address yieldRecipient
    )
        external
        override
        nonReentrant
        returns (
            address token,
            uint256 tokenId,
            uint256 targetAmount
        )
    {
        require(
            isAuthorized(msg.sender, trancheId),
            "not authorized to migrate"
        );

        require(
            strategyRegistry().enabledStrategy(destination),
            "Strategy not approved"
        );

        address sourceStrategy = getCurrentHoldingStrategy(trancheId);
        (token, tokenId, targetAmount) = IStrategy(sourceStrategy)
            .migrateStrategy(
                trancheId,
                destination,
                yieldToken,
                yieldRecipient
            );

        _acceptStrategyMigration(
            trancheId,
            sourceStrategy,
            destination,
            token,
            tokenId,
            targetAmount
        );

        _trackUpdated(trancheId);
    }

    /// Notify a recipient strategy that they have been migrated to
    function _acceptStrategyMigration(
        uint256 trancheId,
        address tokenSource,
        address destination,
        address token,
        uint256 tokenId,
        uint256 targetAmount
    ) internal {
        IStrategy(destination).acceptMigration(
            trancheId,
            tokenSource,
            token,
            tokenId,
            targetAmount
        );

        _holdingStrategies[trancheId] = destination;
    }

    /// Retrieve current strategy and update if necessary
    function getCurrentHoldingStrategy(uint256 trancheId)
        public
        returns (address)
    {
        address oldStrat = _holdingStrategies[trancheId];
        StrategyRegistry registry = strategyRegistry();
        address newStrat = registry.getCurrentStrategy(oldStrat);

        if (oldStrat != newStrat) {
            _acceptStrategyMigration(
                trancheId,
                address(registry),
                newStrat,
                IStrategy(oldStrat).trancheToken(trancheId),
                IStrategy(oldStrat).trancheTokenID(trancheId),
                IStrategy(oldStrat).viewTargetCollateralAmount(trancheId)
            );
        }

        return newStrat;
    }

    /// View which strategy should be holding assets for a tranche,
    /// taking into account global migrations
    function viewCurrentHoldingStrategy(uint256 trancheId)
        public
        view
        returns (address)
    {
        return
            StrategyRegistry(strategyRegistry()).getCurrentStrategy(
                _holdingStrategies[trancheId]
            );
    }

    /// Internals of tranche transfer, correctly tracking containement
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal override {
        super._safeTransfer(from, to, tokenId, _data);
        if (_data.length > 0) {
            _containedIn[tokenId] = abi.decode(_data, (uint256));
        }

        _trackUpdated(tokenId);
    }

    /// Set up an ID slot for this tranche with the id service
    function setupTrancheSlot() external {
        trancheIdService().setupTrancheSlot();
    }

    /// Check whether an asset token is admissible
    function _checkAssetToken(address token) internal view virtual {}

    /// View all the tranches of an owner
    function viewTranchesByOwner(address owner)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 num = balanceOf(owner);
        uint256[] memory result = new uint256[](num);
        for (uint256 i; num > i; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    function trancheToken(uint256 trancheId) external view returns (address) {
        return
            IStrategy(viewCurrentHoldingStrategy(trancheId)).trancheToken(
                trancheId
            );
    }

    /// track that a tranche was updated
    function _trackUpdated(uint256 trancheId) internal {
        updatedTranches[block.timestamp / updateTrackingPeriod].add(trancheId);
        emit TrancheUpdated(trancheId);
    }

    /// Set update tracking period
    function setUpdateTrackingPeriod(uint256 period) external onlyOwnerExec {
        require(period != 0, "Period can't be zero");
        updateTrackingPeriod = period;

        emit ParameterUpdated("tracking period", period);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "./TrancheIDService.sol";
import "./roles/DependsOnTrancheIDService.sol";

abstract contract TrancheIDAware is RoleAware, DependsOnTrancheIDService {
    uint256 immutable totalTrancheSlots;

    constructor(address _roles) RoleAware(_roles) {
        totalTrancheSlots = TrancheIDService(
            Roles(_roles).mainCharacters(TRANCHE_ID_SERVICE)
        ).totalTrancheSlots();
    }

    mapping(uint256 => address) _slotTranches;

    function tranche(uint256 trancheId) public view returns (address) {
        uint256 slot = trancheId % totalTrancheSlots;
        address trancheContract = _slotTranches[slot];
        if (trancheContract == address(0)) {
            trancheContract = trancheIdService().slotTranches(slot);
        }

        return trancheContract;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "./roles/DependsOnTranche.sol";

contract TrancheIDService is RoleAware, DependsOnTranche {
    uint256 public constant totalTrancheSlots = 1e8;
    uint256 public nextTrancheSlot = 1;

    struct TrancheSlot {
        uint256 nextTrancheIdRange;
        uint256 trancheSlot;
    }

    mapping(address => TrancheSlot) public trancheSlots;
    mapping(uint256 => address) public slotTranches;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(TRANCHE_ID_SERVICE);
    }

    function getNextTrancheId() external returns (uint256 id) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        TrancheSlot storage slot = trancheSlots[msg.sender];
        require(slot.trancheSlot != 0, "Caller doesn't have a slot");
        id = slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
        slot.nextTrancheIdRange++;
    }

    function setupTrancheSlot() external returns (TrancheSlot memory) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        require(
            trancheSlots[msg.sender].trancheSlot == 0,
            "Tranche already has a slot"
        );
        trancheSlots[msg.sender] = TrancheSlot({
            nextTrancheIdRange: 1,
            trancheSlot: nextTrancheSlot
        });
        slotTranches[nextTrancheSlot] = msg.sender;
        nextTrancheSlot++;
        return trancheSlots[msg.sender];
    }

    function viewNextTrancheId(address trancheContract)
        external
        view
        returns (uint256)
    {
        TrancheSlot storage slot = trancheSlots[trancheContract];
        return slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
    }

    function viewTrancheContractByID(uint256 trancheId)
        external
        view
        returns (address)
    {
        return slotTranches[trancheId % totalTrancheSlots];
    }

    function viewSlotByTrancheContract(address tranche)
        external
        view
        returns (uint256)
    {
        return trancheSlots[tranche].trancheSlot;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../TrancheIDAware.sol";
import "../OracleRegistry.sol";
import "../../interfaces/IOracle.sol";
import "../roles/DependsOnOracleRegistry.sol";

/// Mixin for contracts that depend on oracles, caches current oracles
/// resposible for a token pair
abstract contract OracleAware is RoleAware, DependsOnOracleRegistry {
    mapping(address => mapping(address => address)) public _oracleCache;

    constructor() {
        _rolesPlayed.push(ORACLE_LISTENER);
    }

    /// Notify contract to update oracle cache
    function newCurrentOracle(address token, address pegCurrency) external {
        // make sure we don't init cache if we aren't listening
        if (_oracleCache[token][pegCurrency] != address(0)) {
            _oracleCache[token][pegCurrency] = oracleRegistry().tokenOracle(
                token,
                pegCurrency
            );
        }
    }

    /// get current oracle and subscribe to cache updates if necessary
    function _getOracle(address token, address pegCurrency)
        internal
        returns (address oracle)
    {
        oracle = _oracleCache[token][pegCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().listenForCurrentOracleUpdates(
                token,
                pegCurrency
            );
        }
    }

    /// View value of a token amount in value currency
    function _viewValue(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal view virtual returns (uint256 value) {
        address oracle = _oracleCache[token][valueCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().tokenOracle(token, valueCurrency);
        }
        return IOracle(oracle).viewAmountInPeg(token, amount, valueCurrency);
    }

    /// Get value of a token amount in value currency, updating oracle state
    function _getValue(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal virtual returns (uint256 value) {
        address oracle = _getOracle(token, valueCurrency);

        return IOracle(oracle).getAmountInPeg(token, amount, valueCurrency);
    }

    /// View value and borrowable together
    function _viewValueBorrowable(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal view virtual returns (uint256 value, uint256 borrowablePer10k) {
        address oracle = _oracleCache[token][valueCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().tokenOracle(token, valueCurrency);
        }
        (value, borrowablePer10k) = IOracle(oracle).viewPegAmountAndBorrowable(
            token,
            amount,
            valueCurrency
        );
    }

    /// Retrieve value (updating oracle) as well as borrowable per 10k
    function _getValueBorrowable(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal virtual returns (uint256 value, uint256 borrowablerPer10k) {
        address oracle = _getOracle(token, valueCurrency);

        (value, borrowablerPer10k) = IOracle(oracle).getPegAmountAndBorrowable(
            token,
            amount,
            valueCurrency
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependsOnStableCoin.sol";

abstract contract CallsStableCoinMintBurn is DependsOnStableCoin {
    constructor() {
        _rolesPlayed.push(MINTER_BURNER);
    }

    function _mintStable(address account, uint256 amount) internal {
        stableCoin().mint(account, amount);
    }

    function _burnStable(address account, uint256 amount) internal {
        stableCoin().burn(account, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";

/// @title DependentContract.
abstract contract DependentContract {
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    uint256[] public _dependsOnCharacters;
    uint256[] public _dependsOnRoles;

    uint256[] public _charactersPlayed;
    uint256[] public _rolesPlayed;

    /// @dev returns all characters played by this contract (e.g. stable coin, oracle registry)
    function charactersPlayed() public view returns (uint256[] memory) {
        return _charactersPlayed;
    }

    /// @dev returns all roles played by this contract
    function rolesPlayed() public view returns (uint256[] memory) {
        return _rolesPlayed;
    }

    /// @dev returns all the character dependencies like FEE_RECIPIENT
    function dependsOnCharacters() public view returns (uint256[] memory) {
        return _dependsOnCharacters;
    }

    /// @dev returns all the roles dependencies of this contract like FUND_TRANSFERER
    function dependsOnRoles() public view returns (uint256[] memory) {
        return _dependsOnRoles;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnFeeRecipient is DependentContract {
    constructor() {
        _dependsOnCharacters.push(FEE_RECIPIENT);
    }

    function feeRecipient() internal view returns (address) {
        return mainCharacterCache[FEE_RECIPIENT];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnFundTransferer is DependentContract {
    constructor() {
        _dependsOnRoles.push(FUND_TRANSFERER);
    }

    function isFundTransferer(address contr) internal view returns (bool) {
        return roleCache[contr][FUND_TRANSFERER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnMinterBurner is DependentContract {
    constructor() {
        _dependsOnRoles.push(MINTER_BURNER);
    }

    function isMinterBurner(address contr) internal view returns (bool) {
        return roleCache[contr][MINTER_BURNER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOracleListener is DependentContract {
    constructor() {
        _dependsOnRoles.push(ORACLE_LISTENER);
    }

    function isOracleListener(address contr) internal view returns (bool) {
        return roleCache[contr][ORACLE_LISTENER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../OracleRegistry.sol";

abstract contract DependsOnOracleRegistry is DependentContract {
    constructor() {
        _dependsOnCharacters.push(ORACLE_REGISTRY);
    }

    function oracleRegistry() internal view returns (OracleRegistry) {
        return OracleRegistry(mainCharacterCache[ORACLE_REGISTRY]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../Stablecoin.sol";

abstract contract DependsOnStableCoin is DependentContract {
    constructor() {
        _dependsOnCharacters.push(STABLECOIN);
    }

    function stableCoin() internal view returns (Stablecoin) {
        return Stablecoin(mainCharacterCache[STABLECOIN]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../StrategyRegistry.sol";

abstract contract DependsOnStrategyRegistry is DependentContract {
    constructor() {
        _dependsOnCharacters.push(STRATEGY_REGISTRY);
    }

    function strategyRegistry() internal view returns (StrategyRegistry) {
        return StrategyRegistry(mainCharacterCache[STRATEGY_REGISTRY]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnTranche is DependentContract {
    constructor() {
        _dependsOnRoles.push(TRANCHE);
    }

    function isTranche(address contr) internal view returns (bool) {
        return roleCache[contr][TRANCHE];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../TrancheIDService.sol";

abstract contract DependsOnTrancheIDService is DependentContract {
    constructor() {
        _dependsOnCharacters.push(TRANCHE_ID_SERVICE);
    }

    function trancheIdService() internal view returns (TrancheIDService) {
        return TrancheIDService(mainCharacterCache[TRANCHE_ID_SERVICE]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnTrancheTransferer is DependentContract {
    constructor() {
        _dependsOnRoles.push(TRANCHE_TRANSFERER);
    }

    function isTrancheTransferer(address contr) internal view returns (bool) {
        return roleCache[contr][TRANCHE_TRANSFERER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./DependentContract.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware is DependentContract {
    Roles public immutable roles;

    event SubjectUpdated(string param, address subject);
    event ParameterUpdated(string param, uint256 value);
    event SubjectParameterUpdated(string param, address subject, uint256 value);

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Roles(_roles);
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        require(owner() == msg.sender, "Roles: caller is not the owner");
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || executor() == msg.sender,
            "Roles: caller is not the owner or executor"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or disabler
    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                disabler() == msg.sender,
            "Caller is not the owner, executor or authorized disabler"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or activator
    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                isActivator(msg.sender),
            "Caller is not the owner, executor or authorized activator"
        );
        _;
    }

    /// @dev Updates the role cache for a specific role and address
    function updateRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.roles(contr, role);
    }

    /// @dev Updates the main character cache for a speciic character
    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    /// @dev returns the owner's address
    function owner() internal view returns (address) {
        return roles.owner();
    }

    /// @dev returns the executor address
    function executor() internal returns (address) {
        return roles.executor();
    }

    /// @dev returns the disabler address
    function disabler() internal view returns (address) {
        return roles.mainCharacters(DISABLER);
    }

    /// @dev checks whether the passed address is activator or not
    function isActivator(address contr) internal view returns (bool) {
        return roles.roles(contr, ACTIVATOR);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MINTER_BURNER = 2;
uint256 constant TRANCHE = 3;
uint256 constant ORACLE_LISTENER = 4;
uint256 constant TRANCHE_TRANSFERER = 5;
uint256 constant UNDERWATER_LIQUIDATOR = 6;
uint256 constant LIQUIDATION_PROTECTED = 7;

uint256 constant PROTOCOL_TOKEN = 100;
uint256 constant FUND = 101;
uint256 constant STABLECOIN = 102;
uint256 constant FEE_RECIPIENT = 103;
uint256 constant STRATEGY_REGISTRY = 104;
uint256 constant TRANCHE_ID_SERVICE = 105;
uint256 constant ORACLE_REGISTRY = 106;
uint256 constant ISOLATED_LENDING = 107;
uint256 constant TWAP_ORACLE = 108;
uint256 constant CURVE_POOL = 109;
uint256 constant ISOLATED_LENDING_LIQUIDATION = 110;

uint256 constant DIRECT_LIQUIDATOR = 200;
uint256 constant LPT_LIQUIDATOR = 201;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;
uint256 constant ACTIVATOR = 1003;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet during
/// beta and will then be transfered to governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    event RoleGiven(uint256 indexed role, address player);
    event CharacterAssigned(
        uint256 indexed character,
        address playerBefore,
        address playerNew
    );
    event RoleRemoved(uint256 indexed role, address player);

    constructor(address targetOwner) Ownable() {
        transferOwnership(targetOwner);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                mainCharacters[DEPENDENCY_CONTROLLER] == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    /// @dev assign role to an account
    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleGiven(role, actor);
        roles[actor][role] = true;
    }

    /// @dev revoke role of a particular account
    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleRemoved(role, actor);
        roles[actor][role] = false;
    }

    /// @dev set main character
    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit CharacterAssigned(role, mainCharacters[role], actor);
        mainCharacters[role] = actor;
    }

    /// @dev returns the current executor
    function executor() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_CONTROLLER];
        if (depController != address(0)) {
            exec = IDependencyController(depController).currentExecutor();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../Strategy.sol";
import "../roles/DependsOnFeeRecipient.sol";

import "../../interfaces/IFeeReporter.sol";

/// Do-nothing strategy
/// This is just intended for testing, not production at this time
contract SimpleHoldingStrategy is Strategy, DependsOnFeeRecipient {
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _stabilityFeePer10k;
    mapping(uint256 => uint256) public depositTime;

    uint256 public override viewAllFeesEver;

    constructor(address _roles)
        Strategy("Simple holding")
        TrancheIDAware(_roles)
    {}

    /// get that collateral
    function collectCollateral(
        address source,
        address token,
        uint256 collateralAmount
    ) internal override {
        IERC20(token).safeTransferFrom(source, address(this), collateralAmount);
    }

    /// give it back
    function returnCollateral(
        address recipient,
        address token,
        uint256 collateralAmount
    ) internal override returns (uint256) {
        require(recipient != address(0), "Don't send to zero address");

        IERC20(token).safeTransfer(recipient, collateralAmount);
        return collateralAmount;
    }

    /// how much collateral does a tranche have
    function viewTargetCollateralAmount(uint256 trancheId)
        public
        view
        override
        returns (uint256)
    {
        CollateralAccount storage account = _accounts[trancheId];
        uint256 amount = account.collateral;
        uint256 delta = (amount *
            (block.timestamp - depositTime[trancheId]) *
            _stabilityFeePer10k[account.trancheToken]) /
            (365 days) /
            10_000;
        if (amount > delta) {
            return amount - delta;
        } else {
            return 0;
        }
    }

    /// If we need a stability fee we take it here
    function _collectYield(
        uint256 trancheId,
        address,
        address
    ) internal virtual override returns (uint256) {
        CollateralAccount storage account = _accounts[trancheId];
        if (account.collateral > 0) {
            address token = account.trancheToken;
            TokenMetadata storage tokenMeta = tokenMetadata[token];
            uint256 newAmount = viewTargetCollateralAmount(trancheId);
            uint256 oldAmount = account.collateral;

            if (oldAmount > newAmount) {
                returnCollateral(feeRecipient(), token, oldAmount - newAmount);
                viewAllFeesEver += _getValue(
                    token,
                    oldAmount - newAmount,
                    yieldCurrency()
                );

                tokenMeta.totalCollateralNow =
                    tokenMeta.totalCollateralNow +
                    newAmount -
                    oldAmount;
            }

            account.collateral = newAmount;
        }
        depositTime[trancheId] = block.timestamp;

        return 0;
    }

    /// Set stability fee, if any
    function setStabilityFeePer10k(address token, uint256 yearlyFeePer10k)
        external
        onlyOwnerExec
    {
        _stabilityFeePer10k[token] = yearlyFeePer10k;
        emit SubjectParameterUpdated("stability fee", token, yearlyFeePer10k);
    }

    /// Internal, approve token
    function _approveToken(address token, bytes calldata data)
        internal
        override
    {
        uint256 stabilityFee = abi.decode(data, (uint256));
        _stabilityFeePer10k[token] = stabilityFee;

        super._approveToken(token, data);
    }

    /// Initialize token
    function checkApprovedAndEncode(address token, uint256 stabilityFee)
        public
        view
        returns (bool, bytes memory)
    {
        return (approvedToken(token), abi.encode(stabilityFee));
    }

    /// Here we do no yield
    function yieldType() public pure override returns (IStrategy.YieldType) {
        return IStrategy.YieldType.NOYIELD;
    }

    /// Stability fee if any
    function stabilityFeePer10k(address token)
        public
        view
        override
        returns (uint256)
    {
        return _stabilityFeePer10k[token];
    }

    function harvestPartially(address token) external override {}

    // View the underlying yield strategy (if any)
    function viewUnderlyingStrategy(address)
        public
        view
        virtual
        override
        returns (address)
    {
        return address(this);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IAsset {
    function withdraw(
        uint256 trancheId,
        uint256 tokenAmount,
        address yieldToken,
        address recipient
    ) external;

    function migrateStrategy(
        uint256 trancheId,
        address targetStrategy,
        address yieldToken,
        address yieldRecipient
    )
        external
        returns (
            address token,
            uint256 tokenId,
            uint256 targetAmount
        );

    function collectYield(
        uint256 tokenId,
        address currency,
        address recipient
    ) external returns (uint256);

    function viewYield(uint256 tokenId, address currency)
        external
        view
        returns (uint256);

    function viewBorrowable(uint256 tokenId) external view returns (uint256);

    function collectYieldValueBorrowable(
        uint256 tokenId,
        address yieldCurrency,
        address valueCurrency,
        address recipient
    )
        external
        returns (
            uint256 yield,
            uint256 value,
            uint256 borrowablePer10k
        );

    function viewYieldValueBorrowable(
        uint256 tokenId,
        address yieldCurrency,
        address valueCurrency
    )
        external
        view
        returns (
            uint256 yield,
            uint256 value,
            uint256 borrowablePer10k
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDependencyController {
    function currentExecutor() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IFeeReporter {
    function viewAllFeesEver() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOracle {
    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view returns (uint256);

    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external returns (uint256);

    function viewPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view returns (uint256, uint256);

    function getPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external returns (uint256, uint256);

    function setOracleParams(
        address token,
        address pegCurrency,
        bytes calldata data
    ) external;
}

// TODO: compatible with NFTs

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// TODO naming of these different proxy functions

interface IProxyOwnership {
    function containedIn(uint256 tokenId)
        external
        view
        returns (address containerAddress, uint256 containerId);

    function isAuthorized(address spender, uint256 tokenId)
        external
        view
        returns (bool);

    function isViable(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IAsset.sol";

interface IStrategy is IAsset {
    enum YieldType {
        REPAYING,
        COMPOUNDING,
        NOYIELD
    }

    struct StrategyMetadata {
        address strategy;
        address token;
        uint256 APF;
        uint256 totalCollateral;
        uint256 borrowablePer10k;
        uint256 valuePer1e18;
        bytes32 strategyName;
        uint256 tvl;
        uint256 harvestBalance2Tally;
        YieldType yieldType;
        uint256 stabilityFee;
        address underlyingStrategy;
    }

    function acceptMigration(
        uint256 trancheId,
        address sourceStrategy,
        address tokenContract,
        uint256 tokenId,
        uint256 amount
    ) external;

    function registerMintTranche(
        address minter,
        uint256 trancheId,
        address assetToken,
        uint256 assetTokenId,
        uint256 assetAmount
    ) external;

    function registerDepositFor(
        address depositor,
        uint256 trancheId,
        uint256 amount,
        address yieldRecipient
    ) external;

    function strategyName() external view returns (bytes32);

    function isActive() external returns (bool);

    function migrateAllTo(address destination) external;

    function trancheToken(uint256 trancheId)
        external
        view
        returns (address token);

    function trancheTokenID(uint256 trancheId)
        external
        view
        returns (uint256 tokenId);

    function viewTargetCollateralAmount(uint256 trancheId)
        external
        view
        returns (uint256);

    function approvedToken(address token) external view returns (bool);

    function viewAllApprovedTokens() external view returns (address[] memory);

    function approvedTokensCount() external view returns (uint256);

    function viewAllDisapprovedTokens()
        external
        view
        returns (address[] memory);

    function disapprovedTokensCount() external view returns (uint256);

    function viewStrategyMetadata(address token)
        external
        view
        returns (StrategyMetadata memory);

    function viewAllStrategyMetadata()
        external
        view
        returns (StrategyMetadata[] memory);

    function viewAllDisapprovedTokenStrategyMetadata()
        external
        view
        returns (StrategyMetadata[] memory);

    function viewAPF(address token) external view returns (uint256);

    function viewValueBorrowable(uint256 trancheId, address valueCurrency)
        external
        view
        returns (uint256, uint256);

    function yieldType() external view returns (YieldType);

    function harvestPartially(address token) external;

    function viewValue(uint256 tokenId, address currency)
        external
        view
        returns (uint256);

    function yieldCurrency() external view returns (address);

    // View estimated harvestable amount
    function viewEstimatedHarvestable(address token)
        external
        view
        returns (uint256);

    // View the underlying yield strategy (if any)
    function viewUnderlyingStrategy(address token)
        external
        view
        returns (address);
}