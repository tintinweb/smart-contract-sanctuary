/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▒░░░░░░▒▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░▓▓▓▓▓▓▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░▒▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓░░░░░░░▒▓▒░░░░░░░░░░░░
//░░░░░░░░░░░░▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▓▒░░░░░░░▓▓▓▓▒░░░░░░░░░░░
//░░░░░░░░░░░▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▒░░░░░░░▒▓▓▓▓▓▓▓░░░░░░░░░░
//░░░░░░░░░░▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓░░░░░░░░░
//░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░
//░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▒▓▓▓▓▓▓▓▓▓░░░░░░░░░░▓▓▓▓▓▓▓▓▓░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░
//░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░▓▓▓▓▓▓▓▒░░░░░░░░░░░▒▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░
//░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░
//░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░▓▓▒░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒░░░
//░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░▒▓▓▓▓▓▒░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░
//░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░▓▓▓▓▓▓▓▓▓░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░
//░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░▒▓▓▓▓▓▓▓▓▓▒░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░
//░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░▓▓▓▓▓▓▓▓▒░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░
//░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░▒▓▓▓▓▓░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░
//░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒░░░
//░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▒▓▓▓▒░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░▒░░░
//░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░▓▓▓▓▓▓▓▒░░░░░░░░░░░▓▓▓▓▓▓▓▓░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░
//░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░▒▓▓▓▓▓▓▓▓▓░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▒░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░
//░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▒░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░
//░░░░░░░░░░▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓░░░░░░░░░
//░░░░░░░░░░░▓▓▓▓▓▓▓░░░░░░░▒▓▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▒░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓░░░░░░░░░░
//░░░░░░░░░░░░▓▓▓▓▒░░░░░░░▓▓▓▓▓▓░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▒░░░░░░░░░░░
//░░░░░░░░░░░░░▒▓░░░░░░░▒▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▒░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▓░░░░░░░▒▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░▒▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▓▓▓▓▓▒░░░░░░▒▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//         __ _         _       _
//  _ __  / _| |_ _   _| | __ _| |__  ___
// | '_ \| |_| __| | | | |/ _` | '_ \/ __|
// | | | |  _| |_| |_| | | (_| | |_) \__ \
// |_| |_|_|  \__|\__, |_|\__,_|_.__/|___/
//                |___/
//
// Name: NFTY Token
// Symbol: NFTY
// Decimals: 18
// Initial Supply: 509684123 NFTY
// Supply Limit:  1456240353 NFTY
// Emissions Limit: 88 NFTY per block

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract AuxContract is Ownable {
  function cron(address rewardTo) external virtual;
}

contract NFTY is ERC20, Ownable {
  using SafeMath for *;

  // constants
  uint8 constant private DECIMALS = 18;
  uint256 constant public SUPPLY_LIMIT   =       1456240353 * 10 ** DECIMALS;
  uint256 constant public INITIAL_SUPPLY =        509684123 * 10 ** DECIMALS;

  // amount of token per block (88 token max)
  uint256 constant public MAX_AMOUNT_PER_BLOCK =         88 * 10 ** DECIMALS;
  uint256 public amountMinedPerBlock =                  MAX_AMOUNT_PER_BLOCK;

  AuxContract auxContract;

  // wallets
  address public w1; address public w2; address public w3; address public w4;
  // ratios
  uint256 public r1; uint256 public r2; uint256 public r3; uint256 public r4;

  // state variables
  uint256 public lastBlockMined;
  bool public miningPaused;
  uint256 public amountBurned;

  event AlreadyMined(uint256 block);
  event Mined(uint256 block, uint256 amountMined, uint256 amountBurned, uint256 totalSupply, uint256 totalBurned);
  event EmissionsLowered(uint256 block, uint256 newAmountPerBlock);
  event Paused(uint256 block);
  event Unpaused(uint256 block);
  event AuthDelegated(address from, address to);
  event VoteDelegated(address from, address to);

  /// @dev Decimals override
  function decimals() public pure override returns (uint8){
    return DECIMALS;
  }

  /// @notice Burn an amount of tokens, and increment the global amountBurned variable
  function burn(uint256 amount) public {
      _burn(_msgSender(), amount);
      amountBurned += amount; // add this burnAmount to amountBurned total
  }

  /**
   * @notice
   * Constructor called on contract deployment
   * This function mints the initial supploy to the contract deployer.
   * This function also initializes miningPaused to True, and lastBlockMined to the current block
   */
  constructor() ERC20("NFTY Token", "NFTY") {
    _mint(msg.sender, INITIAL_SUPPLY); // initial supply
    lastBlockMined = block.number; // init block number
    miningPaused = true;
  }
  
  mapping (address=>address) public delegatedAuth;

  /// @notice Delegate wallet authentication to another address
  /// @param to The address to delegate authentication to
  function delegateAuth(address to) public {
    delegatedAuth[msg.sender] = to;
    emit AuthDelegated(msg.sender, to);
  }

  mapping (address=>address) public delegatedVote;

  /// @notice Delegate wallet voting to another address
  /// @param to The address to delegate authentication to
  function delegateVote(address to) public {
    delegatedVote[msg.sender] = to;
    emit VoteDelegated(msg.sender, to);
  }

  /**
   * @dev calculates & returns the TOTAL pending emission and its subsequent split,
   * based on the current stream ratios (r1,r2,r3,r4). 
   * These values are stored & returned as amt2mine,amt1,amt2,amt3,amt4,amt2burn
   * If any checks fail, returns all values as 0 - `(0,0,0,0,0,0)`
   */
  /**
   * @return six-element tuple of uint256's, which represent
   * 1. TOTAL amount to mine 
   * 2. amount for stream wallet 1
   * 3. amount for stream wallet 2
   * 4. amount for stream wallet 3
   * 5. amount for stream wallet 4
   * 6. amount to burn
   */
  function getAmounts() public view returns 
  (uint256, uint256, uint256, uint256, uint256, uint256) {
    // Check if miningPaused OR no difference between now and lastBlockMined 
    int256 since = int256(block.number) - int256(lastBlockMined);
    if (since <= 0 || miningPaused) {
      return (0,0,0,0,0,0);
    }
    // Determine current reward
    uint256 tReward = amountMinedPerBlock.mul(uint256(since));

    // Check if supply limit has been reached
    uint256 supply = totalSupply().add(amountBurned);
    if (SUPPLY_LIMIT <= supply) {
      return (0,0,0,0,0,0);
    }

    // Ensure correct amount should be mined
    // If full amount is over limit, only mine the spare change
    if (tReward.add(supply) > SUPPLY_LIMIT) {
      tReward = SUPPLY_LIMIT.sub(supply);
    }

    // Check if tReward is 0 at this point
    if (tReward == 0) {
      return (0,0,0,0,0,0);
    }

    // split the stream amounts
    uint256 amt1 = tReward.mul(r1).div(100);
    uint256 amt2 = tReward.mul(r2).div(100);
    uint256 amt3 = tReward.mul(r3).div(100);
    uint256 amt4 = tReward.mul(r4).div(100);
    uint256 summed = amt1.add(amt2).add(amt3).add(amt4);

    // Burn remainder
    uint256 burnAmount;
    if (summed != tReward) { 
      burnAmount = tReward.sub(summed);
    }

    // Verify splits add up
    require(tReward == burnAmount.add(amt1).add(amt2).add(amt3).add(amt4), "mismatch");
    return (tReward, amt1, amt2, amt3, amt4, burnAmount);
  }

  /// @dev This function calls mineTo, but with rewardTo set as zero-address 
  function mine() public {
    mineTo(address(0));
  }

  /**
   * @dev If miningPaused, this function does nothing
   * If tokens were already mined this block, this function does nothing
   * If amountBurned + totalSupply >= SUPPLY_LIMIT, this function does nothing.
   */
  /// @notice Create tokens and send down the pre-defined streams. 
  /// @param rewardTo Which address to send reward to for mining tokens
  function mineTo(address rewardTo) public {
    if (miningPaused) {
      return;
    }
    // only mine once per block, maximum.
    // don't revert, in case called via some downstream contract
    if (lastBlockMined >= block.number) {
      emit AlreadyMined(block.number);
      return;
    }

    // use getAmounts() to calculate splits
    (uint256 amt2mine, uint256 amount1, uint256 amount2, uint256 amount3, uint256 amount4, uint256 amt2burn) = getAmounts();
    if (amt2mine == 0) {
      return;
    }
    lastBlockMined = block.number;

    // transfer downstream if amount is not zero
    if (amount1 != 0) { _mint(w1, amount1); }
    if (amount2 != 0) { _mint(w2, amount2); }
    if (amount3 != 0) { _mint(w3, amount3); }
    if (amount4 != 0) { _mint(w4, amount4); }

    // There are tokens to burn, so add them to amt2burn
    // No point in burning then minting, so simply track these in global amountBurned variable
    if (amt2burn != 0) {
      amountBurned += amt2burn; 
    }
    emit Mined(block.number, amt2mine, amt2burn, totalSupply(), amountBurned);

    // Call auxiliary contract for reward, passing rewardTo address
    AuxContract aux = auxContract;
    if (address(aux) != address(0)) {
        try aux.cron(rewardTo) {} catch {}
    }
  }

  /// @notice Assign stream wallets for token emissions (available to contract owner only)
  /// @notice Order matters for these addresses, as they correspond to the matching numbered ratio
  /// @param a1 First stream address 
  /// @param a2 Second stream address
  /// @param a3 Third stream address
  /// @param a4 Fourth stream address
  function updateStreams(address a1, address a2, address a3, address a4) public onlyOwner {
    require(a1 != address(0), "address 1 cannot be zero address");
    w1 = a1; w2 = a2; w3 = a3; w4 = a4;
    // disable slot if zero address (will burn in 'mine' step)
    if (w2 == address(0)) { r2 = 0; }
    if (w3 == address(0)) { r3 = 0; }
    if (w4 == address(0)) { r4 = 0; }
  }


  /// @notice Assign stream ratios for token emissions (available to contract owner only)
  /// @notice Order matters for these ratios, as they correspond to the matching numbered wallet
  /// @param a1 First stream ratio
  /// @param a2 Second stream ratio
  /// @param a3 Third stream ratio
  /// @param a4 Fourth stream ratio
  function updateStreamRatios(uint256 a1, uint256  a2, uint256 a3, uint256 a4) public onlyOwner {
    require(a1.add(a2).add(a3).add(a4) <= 100, "parts exceed 100");
    if (w2 == address(0)){ require(a2 == 0, "cannot mint to zero address 2"); }
    if (w3 == address(0)){ require(a3 == 0, "cannot mint to zero address 3"); }
    if (w4 == address(0)){ require(a4 == 0, "cannot mint to zero address 4"); }
    r1 = a1; r2 = a2; r3 = a3; r4 = a4;
  }

  /// @notice Pause token emissions.
  /// @notice Mining pause does not gather reserves or burn, as lastBlockMined is reset on unpause
  function pauseEmissions() public onlyOwner {
    require(!miningPaused, "mining already paused");
    miningPaused = true;
    emit Paused(block.number);
  }

  /// @notice Unpause token emissions, 10 blocks after function call
  function unpauseEmissions() public onlyOwner {
    require(miningPaused, "mining not paused");
    lastBlockMined = block.number + 10; // re-enable after 10 blocks
    miningPaused = false;
    emit Unpaused(block.number + 10);
  }

  /// @notice Decrease token per block emissions
  /// @notice This function can only decrease emissions, not increase
  function decreaseEmissions(uint256 amount) public onlyOwner {
    require(amount >= 1 * 10**DECIMALS, "amount < one token");
    require(amount < amountMinedPerBlock, "amount >= current emission rate");
    amountMinedPerBlock = amount;
    emit EmissionsLowered(block.number, amount);
  }
  
  /// @notice Set a new AuxContract to be used for the reward mechanism in mineTo
  /// @param aux Contract address for new auxiliary contract
  function setContract(address aux) public onlyOwner {
    auxContract = AuxContract(aux);
  }
}