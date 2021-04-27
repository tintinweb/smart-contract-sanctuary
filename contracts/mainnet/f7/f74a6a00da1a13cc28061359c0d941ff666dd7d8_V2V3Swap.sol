/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.6.6;


// SPDX-License-Identifier: MIT
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
}

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract V2V3Swap{

    using SafeMath for uint256;

    address payable public owner;

    address public token;
    address public v3;
    address public v2;
    mapping(address=>uint256) claimants;

    constructor(address token_, address v2_, address v3_) public {
        owner = msg.sender;
        v3 = v3_;
        v2 = v2_;
        token = token_;

        //hardcode all claimants here
        claimants[0x2a8600bBDAab254A2F8A8E00912799295C3DD601] = 20520000000000000000000;
        claimants[0xA67f3A9a43380E471296b897E5Bda2EC9372984e] = 16367000000000000000000;
        claimants[0xDD0DDAd1cA7B57aCAc3E1eD2ceAC6ebC5526431a] = 14880000000000000000000;
        claimants[0x814fcC59F54C375729084f48A91eAfD232e8F19e] = 11480000000000000000000;
        claimants[0x392365d5954A9b8Bce72cC6b55BC206120145220] = 10448000000000000000000;
        claimants[0x5814eBfA4c49c60fE898A63C907f8E345419308a] = 9848000000000000000000;
        claimants[0xcbBC5D06BE48B9B1D90A8E787B4d42bc4A3B74a8] = 8904000000000000000000;
        claimants[0x9310Bcc37E24667A83acA7a495371a47f7401AD0] = 8640000000000000000000;
        claimants[0x6ed1cDfe242E653980c37AEB498B997Fa0b584FD] = 8558000000000000000000;
        claimants[0xC67C6E8F19eEb70D3FFFBA95E5ce9dE2D163ED31] = 6400000000000000000000;
        claimants[0x3DAc271d1B36A434880C527A678B6487AC9C1F8c] = 6000000000000000000000;
        claimants[0x0682EBeC1F898110D1E5741e2c7DAFFfB6a47870] = 4240000000000000000000;
        claimants[0x7329Dd949aA536E23e0a8962F5829c8a3c24b805] = 3360000000000000000000;
        claimants[0x261377cfB52E6FD3048B0aB991D991EE43eF2d4A] = 3160000000000000000000;
        claimants[0x20A56da502f9398DB0B3698D984427CD62A7a560] = 2640000000000000000000;
        claimants[0x9a5A4aEB2c93e6eD27B8C5d2392828182ec01bDa] = 2640000000000000000000;
        claimants[0x8eD67985496fDdfF1721033908a5Af3bcf2d9DE9] = 2600000000000000000000;
        claimants[0xdec08cb92a506B88411da9Ba290f3694BE223c26] = 2568000000000000000000;
        claimants[0xf994b0748195D347A16E84D261B17a22d8D96135] = 2000000000000000000000;
        claimants[0x590dfbD53781c6d9D8404eB8e1847fEA1AfAD319] = 1920000000000000000000;
        claimants[0x62D107C7555d246a6d2C19CB2A13d256168276Eb] = 1920000000000000000000;
        claimants[0x880D930b4ac0B73966de27C5267E304d2093BdDE] = 1920000000000000000000;
        claimants[0x656fAFABBf1B8C42b4f63AB15F9bEE8027A25978] = 1680000000000000000000;
        claimants[0x9a568bFeB8CB19e4bAfcB57ee69498D57D9591cA] = 1680000000000000000000;
        claimants[0x6e5d43A620fC9456A1F23BE69933a516E177dDec] = 1440000000000000000000;
        claimants[0x02E4F367fc7cb77d9b6818440648fC4dD5d21891] = 1280000000000000000000;
        claimants[0x6ee25007B73Fa79902A152A78cAB50f4f7fA9eFF] = 1200000000000000000000;
        claimants[0xfEEAa6A2aE0D4a15e947AFC71DC249A29Dc2778d] = 1200000000000000000000;
        claimants[0xF309921083CdaEB3758Bc8c24a4156eDfA64ca2F] = 1000000000000000000000;
        claimants[0xa76B0152fE8BC2eC3CbfAC3D3ecee4A397747051] = 960000000000000000000;
        claimants[0xBE719b05B4dBF02ed9555ef92d36d746312403AE] = 960000000000000000000;
        claimants[0x59cE5702F124ae45D63ae1c531E41b8c456a072d] = 896000000000000000000;
        claimants[0xF58075DAbB3fFa6BE8f577c037ceF8EA60a7B0b8] = 808000000000000000000;
        claimants[0x1ad3E1493A5486f8CB675549cA4d6D124986613B] = 720000000000000000000;
        claimants[0x92b5a3f06fe24CeA07a6F92aA94F2994d481Afc8] = 720000000000000000000;
        claimants[0xE995E2A9Ae5210FEb6DD07618af28ec38B2D7ce1] = 720000000000000000000;
        claimants[0x6ee4741bC0C4928f8d878Ac7FE0421E35065aD1b] = 648000000000000000000;
        claimants[0x304d0370B024dBEf25d49055c38cd0AC349C01E6] = 496000000000000000000;
        claimants[0x1250F4a6Aa70fE37880d2028B7664EFF3f3a8a76] = 496000000000000000000;
        claimants[0x8950D9117C136B29A9b1aE8cd38DB72226404243] = 490000000000000000000;
        claimants[0x0ac125137553A2938c61E6591098443db12F6FE8] = 480000000000000000000;
        claimants[0x3AE8a332A51361aB6b9159529A1A007804F6F3B5] = 480000000000000000000;
        claimants[0x61E754d261c39eE4A5FC772EB7d3D086fd70Bd0c] = 480000000000000000000;
        claimants[0x75bD4CBe90caFE7e15B0694c2d03D8345006EE7E] = 480000000000000000000;
        claimants[0xC6234859138EB19e17B3D752ac7744B1169191eF] = 480000000000000000000;
        claimants[0x48b576c87e788a762D6f95A456f2A39113b46950] = 408000000000000000000;
        claimants[0xA50341f5e72eD061cD0adbD338cbF070DC45784C] = 400000000000000000000;
        claimants[0x9125b2457479964540a0557e3B010681317B635E] = 336000000000000000000;
        claimants[0x9E60aC8A2D7E0339101b8a16335480322bdEE781] = 320000000000000000000;
        claimants[0xE0b795554Ed78c7889635c0044A38c1F5F2F7e0a] = 320000000000000000000;
        claimants[0x2319fc093bEaD97D0a5c329F09895031ca1eE955] = 240000000000000000000;
        claimants[0x75CaCe0BabA984F721F40443ce4aCB6Bb229a9B0] = 240000000000000000000;
        claimants[0x89b35895E55e51a549D068E695c62063744F576B] = 240000000000000000000;
        claimants[0x9528Aa2822b730260731EC080D959C8E55135810] = 240000000000000000000;
        claimants[0xB3A8EaB7eFD3e7cdC18567AbF4725B99106A259D] = 240000000000000000000;
        claimants[0xc7083893735F9Aa7e9CCC4B41f8A3a0b188e9fda] = 240000000000000000000;
        claimants[0xcA7F8f6A21C6e0F3b0177207407Fc935429BdD27] = 240000000000000000000;
        claimants[0xD80775766186eF44c73422fDF97D92701C27f70E] = 240000000000000000000;
        claimants[0xe7Bed7fD83CBd8C548Cc59F103b6CeC6FabE53A9] = 240000000000000000000;
        claimants[0xF27696C8BCa7D54D696189085Ae1283f59342fA6] = 240000000000000000000;
        claimants[0xFeB620b14A9C3683CEcB9097802AF9c32e51C701] = 240000000000000000000;
        claimants[0x3b7318457f091965c488dac7e58559993e4971DE] = 240000000000000000000;
        claimants[0x5EeFef8238B759BD8B8498EC3D1001be34fbf835] = 240000000000000000000;
        claimants[0x88551e0e83b1A8A47Fb7b50507298B229cF12586] = 240000000000000000000;
        claimants[0xDBfe857A4cE4673d99cba3FB7073aab5421d1e77] = 168000000000000000000;
        claimants[0x6B67623ff56c10d9dcFc2152425f90285fC74DDD] = 160000000000000000000;
        claimants[0xeA1C4d527F34F7372554B24b9feF950224E4351E] = 160000000000000000000;
        claimants[0x0fD84d7cb911728737556684050782B298F70f0f] = 40000000000000000000;
        claimants[0xF12657e7A1e2320b85b2Dd10C5F047eB14F02517] = 32000000000000000000;
        claimants[0xF41d1950282ad07C28E1d469f2cb5586FCd6173B] = 24000000000000000000;
        claimants[0x36cbd78b71a161dfEd7C30DB2b5989d81fa31F52] = 8000000000000000000;
        claimants[0x7b0aD03877e2311cd0FEB6D8DCFb4574e2915b8d] = 8000000000000000000;
        claimants[0x97cdd8176084B24ae8a385d4eA9177C31bA0022B] = 8000000000000000000;

    }
    
     modifier onlyOwner() {
      require(msg.sender == owner, "Only callable by owner");
      _;
    }

    function open(uint256 total) public onlyOwner {
        ERC20 v4 = ERC20(token);
        v4.transferFrom(msg.sender, address(this), total);
    }

    function withdraw() public onlyOwner {
        ERC20 v4 = ERC20(token);
        uint256 balance = v4.balanceOf(address(this));
        v4.transfer(msg.sender, balance);
    }

    function transferOwner(address payable newOwner_) public onlyOwner {
        owner = newOwner_;
    }

     /**
     * @dev one time swap of v2 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv2v4(uint256 amount) external {
        
        require(claimants[msg.sender] >= amount, "not enough whitelisted for u");
        claimants[msg.sender] = claimants[msg.sender].sub(amount);
        ERC20 b2 = ERC20(v2);
        ERC20 v4 = ERC20(token);
        uint256 balance = b2.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv2 balance");
        require(v4.balanceOf(address(this)) >= amount);
        require(b2.transferFrom(msg.sender, address(this), amount), "transfer failed");
        v4.transfer(msg.sender, amount);
    }

    /**
     * @dev one time swap of v3 to v4 tokens
     * @param amount the amount of tokens to swap
     */
    function swapv3v4(uint256 amount) external {
        require(claimants[msg.sender] >= amount, "not enough whitelisted for u");
        claimants[msg.sender] = claimants[msg.sender].sub(amount);
        ERC20 b3 = ERC20(v3);
        ERC20 v4 = ERC20(token);
        uint256 balance = b3.balanceOf(msg.sender);
        require(balance >= amount, "insufficent biopv3 balance");
        require(v4.balanceOf(address(this)) >= amount);
        require(b3.transferFrom(msg.sender, address(this), amount), "transfer failed");
        v4.transfer(msg.sender, amount);
    }
}