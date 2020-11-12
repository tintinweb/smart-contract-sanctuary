// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     * @dev Emitted when burned totalSupply, transferring tokens
     */
    event burnTotalSupply(uint256 value);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ShitCoinContract is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _threshold;
    uint256 private _burnRate;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        _name = "Shitcoin";
        _symbol = "SHIT";
        _decimals = 18;
        _burnRate = 42; // burnRate when transfering tokens should be divided by 1000
        _threshold = 42069E16;
        
        // distribute tokens
        _mint(0x4342e82B94b128fcCBe1bDDF454e51336cC5fde2, 45E18);
        _mint(0x2041Ea0efD9702b1Ca13C0FCa2899Ed31B9167dB, 45E18);
        _mint(0x0B11FB8E5072A0C48cf90cDbcFc117776a73605D, 45E18);
        _mint(0xEF572FbBdB552A00bdc2a3E3Bc9306df9E9e169d, 45E18);
        _mint(0xA7a99dDB57DA5119030a5eC80eDcE6A8CE9b4606, 45E18);
        _mint(0xd62a38Bd99376013D485214CC968322C20A6cC40, 45E18);
        _mint(0x88Eb97E5ECbf1c5b4ecA19aCF659d4724392eD86, 45E18);
        _mint(0x1EBB9eE2b0cd222877e4BcA8a56d4444EfC5e28B, 45E18);
        _mint(0x03E1Fe6B95BEFBC99835C6313d01d3075a81BbE2, 45E18);
        _mint(0x907b4128FF43eD92b14b8145a01e8f9bC6890E3E, 45E18);
        _mint(0x7e319b0140091625786c4Bedd74dAa68df243c82, 45E18);
        _mint(0xd00c8e3A99aE3C87657ed12005598855DC59f433, 45E18);
        _mint(0x298c80FCaB43fA9eE0a1EF8E6abF86374e0498d9, 45E18);
        _mint(0xfAcb29bE46ccA69Dcb40806eCf2E4C0Bb300ba73, 45E18);
        _mint(0x3111413a49f62be9b9547620E660780a1AC9bae1, 45E18);
        _mint(0x4E7e1C73C116649c1C684acB6ec98bAc4FbB4ef6, 45E18);
        _mint(0x8F18fc10277A2d0DdE935A40386fFE30B9A5BC17, 45E18);
        _mint(0xf1a72A1B1571402e1071BFBfbBa481a50Fb65885, 45E18);
        _mint(0xF874a182b8Cbf5BA2d6F65A21BC9e8368C8C5B07, 45E18);
        _mint(0x167bB613c031cB387c997c82c02B106939Fd8F07, 45E18);
        _mint(0x99685f834B99b3c6F3e910c8454eC64101f02296, 45E18);
        _mint(0x29f19A306Ee4BFd114Aa1cA06eC30FC57055E1E9, 45E18);
        _mint(0xDA2B7416aCcb991a6391f34341ebe8735E17Ea0e, 45E18);
        _mint(0xe8e749a426A030D291b96886AEFf644B4ccea67B, 45E18);
        _mint(0xb1776C152080228214c2E84e39A93311fF3c03C1, 45E18);
        _mint(0xf422c173264dCd512E3CEE0DB4AcB568707C0b8D, 45E18);
        _mint(0xD86e5a51a1f062c534cd9A7B9c978b16c40A802A, 45E18);
        _mint(0x2604afb5A64992e5aBBF25865C9d3387adE92bad, 45E18);
        _mint(0xdF1cb2e9B48C830154CE6030FFc5E2ce7fD6c328, 45E18);
        _mint(0x05BaD2724b1415a8B6B3000a30E37d9C637D7340, 45E18);
        _mint(0xa4BD82608192EDdF2A587215085786D1630085E8, 45E18);
        _mint(0xac25C07464c0A53ebA6450c945f62dD66Cf5c1A7, 45E18);
        _mint(0x143186645f60607cade2465e6C5B9cf96F7c8f51, 45E18);
        _mint(0xE9919D66314255A97d9F53e70Bf28075E65535B4, 45E18);
        _mint(0xeAe344EF0Dcd6dcf66fb8a1a090fD9b256b08521, 45E18);
        _mint(0x06C8940CFEc1e9596123a2b0fA965F9E3758422f, 45E18);
        _mint(0xE58Ea0ceD4417f0551Fb82ddF4F6477072DFb430, 45E18);
        _mint(0xC0Bc8226527038F95d0b02b3Fa7Cfd0D2F344968, 45E18);
        _mint(0x5AaAEF91F93bE4dE932b8e7324aBBF9f26DAa706, 45E18);
        _mint(0xc76bf7e1a02a7fe636F1698ba5F4e28e88E3Af3c, 45E18);
        _mint(0x4B424674eA391E5Ee53925DBAbD73027D06699A9, 45E18);
        _mint(0x652df8A98005416a7e32eea90a86e02a0F33F92e, 45E18);
        _mint(0x3FFC8b9721f96776beF8468f48F65E0ca573fcF2, 45E18);
        _mint(0xAB00Bf9544f10EF2cF7e8C24E845ae6B62dcd413, 45E18);
        _mint(0xDFA7C075D408D7BFfBe8691c025Ca33271b2eCCc, 45E18);
        _mint(0x97D3F96c89eEF4De83c336b8715f78F45CA32411, 45E18);
        _mint(0x47262B32A23B902A5083B3be5e6A270A71bE83E0, 45E18);
        _mint(0xbb257625458a12374daf2AD0c91d5A215732F206, 45E18);
        _mint(0x0C780749E6d0bE3C64c130450B20C40b843fbEC4, 45E18);
        _mint(0x6EB118679E7915391e4e9D49Fe3d46DD089623d0, 45E18);
        _mint(0x8eC686860fe3196667E878ed1D5497EB7fd35872, 45E18);
        _mint(0x7Bf7Dedb68CAC2cFD0d99DFdDb703c4CE9640941, 45E18);
        _mint(0x27fa60d49C82379373a76A858742D72D154e96B2, 45E18);
        _mint(0x662F6ef2092c126b6EE0Da44e6B863f30971880d, 45E18);
        _mint(0x1aa0b915BEeA961e6c09121Bb5f9ED98a10b7658, 45E18);
        _mint(0xd03A083589edC2aCcf09593951dCf000475cc9f2, 45E18);
        _mint(0x0530F30d85A6Ceb341544aB7a740B2BdBBc69444, 45E18);
        _mint(0xf5f737C6B321126723BF0afe38818ac46411b5D9, 45E18);
        _mint(0x34b7339C3D515b4a82eE58a6C6884A1f2B429872, 45E18);
        _mint(0xFC527e222254F7fd7451853a18c77935b582f9dB, 45E18);
        _mint(0x076C48C9Ef4C50D84C689526d086bA56270e406c, 45E18);
        _mint(0x2f442C704c3D4Bd081531175Ce05C2C88603ce09, 45E18);
        _mint(0xcb794D53530BEE50ba48C539fbc8C5689Ffae34F, 45E18);
        _mint(0x7914254AD6b6c6dBcbDcC4c964Ecda52DCe588a7, 45E18);
        _mint(0xf916D5D0310BFCD0D9B8c43D0a29070670D825f9, 45E18);
        _mint(0x10C223dFB77F49d7Cf95Cc044C2A2216b1253211, 45E18);
        _mint(0x3293A92372Ae49390a97e1bB3B185EbC30e68870, 45E18);
        _mint(0x3481fBA85c1b227Cd401d4ef2e2390f505738B08, 45E18);
        _mint(0x0c6d54839de473480Fe24eC82e4Da65267C6be46, 45E18);
        _mint(0xC419528eDA383691e1aA13C381D977343CB9E5D0, 45E18);

        // Listing wallet 2700 $SHIT
        _mint(0xDD1EA7EEEa92D7b03E1c5cFF8ADC695ecE796DdC, 2700E18);

        // TEAM 348 $SHIT
        _mint(0x34Ba737f5195e354047a68f1eb42073AF41b153F, 348E18);

        // Marketing 300 $SHIT
        _mint(0x9725548D0aa23320F1004F573086D1F4cba0804c, 300E18);

        // Airdrop 471 $SHIT
        _mint(0xc346D86B69ab3F3f8415b87493E75179FC4997B5, 471E18);
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");



        uint256 burnAmount = _getBurnAmount(amount);
        _burnTotalSupply(amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount.sub(burnAmount));
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
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev reducing the total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burnTotalSupply(uint256 amount) internal virtual {
        _totalSupply = _totalSupply.sub(amount);
        emit burnTotalSupply(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Get the burnAmount when transfering tokens.
     */
    function _getBurnAmount(uint256 amount) internal view virtual returns (uint256) {
        if (_totalSupply<=_threshold) {
            return 0;
        }
        return amount.mul(_burnRate).div(1000);
    }
}