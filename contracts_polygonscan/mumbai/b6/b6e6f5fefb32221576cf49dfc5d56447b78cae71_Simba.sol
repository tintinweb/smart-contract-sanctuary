/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: MIT

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

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

contract Simba is ERC20 {
    using SafeMath for uint256;
    address public owner;
    mapping(address => bool) public exclidedFromTax;
    bool Owner_Tax;
    uint Stage1_Burn;
    uint Stage1_Tax;
    uint Stage2_Burn;
    uint Stage2_Tax;
    uint Stage3_Burn;
    uint Stage3_Tax;
    uint Stage4_Burn;
    uint Stage4_Tax;
    uint Stage5_Burn;
    uint Stage5_Tax;
    uint Stage6_Burn;
    uint Stage6_Tax;
    uint Stage7_Burn;
    uint Stage7_Tax;
    uint Stage8_Burn;
    uint Stage8_Tax;
    uint Stage9_Burn;
    uint Stage9_Tax;
    uint Stage10_Burn;
    uint Stage10_Tax;
    uint Stage11_Burn;
    uint Stage11_Tax;
    uint Stage12_Burn;
    uint Stage12_Tax;
    uint Owner_Stage1_Burn;
    uint Owner_Stage1_Tax;
    uint Owner_Stage2_Burn;
    uint Owner_Stage2_Tax;
    uint Owner_Stage3_Burn;
    uint Owner_Stage3_Tax;
    uint Owner_Stage4_Burn;
    uint Owner_Stage4_Tax;
    uint Owner_Stage5_Burn;
    uint Owner_Stage5_Tax;
    uint Owner_Stage6_Burn;
    uint Owner_Stage6_Tax;
    uint Owner_Stage7_Burn;
    uint Owner_Stage7_Tax;
    uint Owner_Stage8_Burn;
    uint Owner_Stage8_Tax;
    uint Owner_Stage9_Burn;
    uint Owner_Stage9_Tax;
    uint Owner_Stage10_Burn;
    uint Owner_Stage10_Tax;
    uint Owner_Stage11_Burn;
    uint Owner_Stage11_Tax;
    uint Owner_Stage12_Burn;
    uint Owner_Stage12_Tax;


    constructor() ERC20('Simba', 'Simba Lion') {
        Stage1_Burn = 3;
        Stage1_Tax = 3;
        Stage2_Burn = 3;
        Stage2_Tax = 3;
        Stage3_Burn = 3;
        Stage3_Tax = 3;
        Stage4_Burn = 3;
        Stage4_Tax = 3;
        Stage5_Burn = 3;
        Stage5_Tax = 3;
        Stage6_Burn = 3;
        Stage6_Tax = 3;
        Stage7_Burn = 3;
        Stage7_Tax = 3;
        Stage8_Burn = 3;
        Stage8_Tax = 3;
        Stage9_Burn = 3;
        Stage9_Tax = 3;
        Stage10_Burn = 3;
        Stage10_Tax = 3;
        Stage11_Burn = 3;
        Stage11_Tax = 3;
        Stage12_Burn = 3;
        Stage12_Tax = 3;
        Owner_Stage1_Burn = 3;
        Owner_Stage1_Tax = 3;
        Owner_Stage2_Burn = 3;
        Owner_Stage2_Tax = 3;
        Owner_Stage3_Burn = 3;
        Owner_Stage3_Tax = 3;
        Owner_Stage4_Burn = 3;
        Owner_Stage4_Tax = 3;
        Owner_Stage5_Burn = 3;
        Owner_Stage5_Tax = 3;
        Owner_Stage6_Burn = 3;
        Owner_Stage6_Tax = 3;
        Owner_Stage7_Burn = 3;
        Owner_Stage7_Tax = 3;
        Owner_Stage8_Burn = 3;
        Owner_Stage8_Tax = 3;
        Owner_Stage9_Burn = 3;
        Owner_Stage9_Tax = 3;
        Owner_Stage10_Burn = 3;
        Owner_Stage10_Tax = 3;
        Owner_Stage11_Burn = 3;
        Owner_Stage11_Tax = 3;
        Owner_Stage12_Burn = 3;
        Owner_Stage12_Tax = 3;
        _mint(msg.sender, 2000000000000 * 10 ** 18);
        owner = msg.sender;
        exclidedFromTax[msg.sender] = true;
        Owner_Tax = true;
    }
    
    function Get_Owner_Tax() public view returns(bool){
        return Owner_Tax;
    }
    function Get_Stage1_Burn() public view returns(uint){
        return Stage1_Burn;
    }
    function Get_Stage1_Tax() public view returns(uint){
        return Stage1_Tax;
    }
    function Get_Stage2_Burn() public view returns(uint){
        return Stage2_Burn;
    }
    function Get_Stage2_Tax() public view returns(uint){
        return Stage2_Tax;
    }
    function Get_Stage3_Burn() public view returns(uint){
        return Stage3_Burn;
    }
    function Get_Stage3_Tax() public view returns(uint){
        return Stage3_Tax;
    }
    function Get_Stage4_Burn() public view returns(uint){
        return Stage4_Burn;
    }
    function Get_Stage4_Tax() public view returns(uint){
        return Stage4_Tax;
    }
    function Get_Stage5_Burn() public view returns(uint){
        return Stage5_Burn;
    }
    function Get_Stage5_Tax() public view returns(uint){
        return Stage5_Tax;
    }
    function Get_Stage6_Burn() public view returns(uint){
        return Stage6_Burn;
    }
    function Get_Stage6_Tax() public view returns(uint){
        return Stage6_Tax;
    }
    function Get_Stage7_Burn() public view returns(uint){
        return Stage7_Burn;
    }
    function Get_Stage7_Tax() public view returns(uint){
        return Stage7_Tax;
    }
    function Get_Stage8_Burn() public view returns(uint){
        return Stage8_Burn;
    }
    function Get_Stage8_Tax() public view returns(uint){
        return Stage8_Tax;
    }
    function Get_Stage9_Burn() public view returns(uint){
        return Stage9_Burn;
    }
    function Get_Stage9_Tax() public view returns(uint){
        return Stage9_Tax;
    }
    function Get_Stage10_Burn() public view returns(uint){
        return Stage10_Burn;
    }
    function Get_Stage10_Tax() public view returns(uint){
        return Stage10_Tax;
    }
    function Get_Stage11_Burn() public view returns(uint){
        return Stage11_Burn;
    }
    function Get_Stage11_Tax() public view returns(uint){
        return Stage11_Tax;
    }
    function Get_Stage12_Burn() public view returns(uint){
        return Stage12_Burn;
    }
    function Get_Stage12_Tax() public view returns(uint){
        return Stage12_Tax;
    }
    function Get_Owner_Stage1_Burn() public view returns(uint){
        return Owner_Stage1_Burn;
    }
    function Get_Owner_Stage1_Tax() public view returns(uint){
        return Owner_Stage1_Tax;
    }
    function Get_Owner_Stage2_Burn() public view returns(uint){
        return Owner_Stage2_Burn;
    }
    function Get_Owner_Stage2_Tax() public view returns(uint){
        return Owner_Stage2_Tax;
    }
    function Get_Owner_Stage3_Burn() public view returns(uint){
        return Owner_Stage3_Burn;
    }
    function Get_Owner_Stage3_Tax() public view returns(uint){
        return Owner_Stage3_Tax;
    }
    function Get_Owner_Stage4_Burn() public view returns(uint){
        return Owner_Stage4_Burn;
    }
    function Get_Owner_Stage4_Tax() public view returns(uint){
        return Owner_Stage4_Tax;
    }
    function Get_Owner_Stage5_Burn() public view returns(uint){
        return Owner_Stage5_Burn;
    }
    function Get_Owner_Stage5_Tax() public view returns(uint){
        return Owner_Stage5_Tax;
    }
    function Get_Owner_Stage6_Burn() public view returns(uint){
        return Owner_Stage6_Burn;
    }
    function Get_Owner_Stage6_Tax() public view returns(uint){
        return Owner_Stage6_Tax;
    }
    function Get_Owner_Stage7_Burn() public view returns(uint){
        return Owner_Stage7_Burn;
    }
    function Get_Owner_Stage7_Tax() public view returns(uint){
        return Owner_Stage7_Tax;
    }
    function Get_Owner_Stage8_Burn() public view returns(uint){
        return Owner_Stage8_Burn;
    }
    function Get_Owner_Stage8_Tax() public view returns(uint){
        return Owner_Stage8_Tax;
    }
    function Get_Owner_Stage9_Burn() public view returns(uint){
        return Owner_Stage9_Burn;
    }
    function Get_Owner_Stage9_Tax() public view returns(uint){
        return Owner_Stage9_Tax;
    }
    function Get_Owner_Stage10_Burn() public view returns(uint){
        return Owner_Stage10_Burn;
    }
    function Get_Owner_Stage10_Tax() public view returns(uint){
        return Owner_Stage10_Tax;
    }
    function Get_Owner_Stage11_Burn() public view returns(uint){
        return Owner_Stage11_Burn;
    }
    function Get_Owner_Stage11_Tax() public view returns(uint){
        return Owner_Stage11_Tax;
    }
    function Get_Owner_Stage12_Burn() public view returns(uint){
        return Owner_Stage12_Burn;
    }
    function Get_Owner_Stage12_Tax() public view returns(uint){
        return Owner_Stage12_Tax;
    }
    function Set_Owner_Tax(bool _Owner_Tax) public {
        Owner_Tax = _Owner_Tax;
    }
    function Set_Whale1_Burn(uint _Whale1_Burn) public {
        if(msg.sender == owner) {
            Stage1_Burn = _Whale1_Burn;
            Stage2_Burn = _Whale1_Burn;
            Stage3_Burn = _Whale1_Burn;
            Stage4_Burn = _Whale1_Burn;
            Stage5_Burn = _Whale1_Burn;
            Stage6_Burn = _Whale1_Burn;
            Stage7_Burn = _Whale1_Burn;
            Stage8_Burn = _Whale1_Burn;
            Stage9_Burn = _Whale1_Burn;
            Stage10_Burn = _Whale1_Burn;
            Stage11_Burn = _Whale1_Burn;
            Stage12_Burn = _Whale1_Burn;
        }
    }
    function Set_Whale1_Tax(uint _Whale1_Tax) public {
        if(msg.sender == owner) {
            Stage1_Tax = _Whale1_Tax;
            Stage2_Tax = _Whale1_Tax;
            Stage3_Tax = _Whale1_Tax;
            Stage4_Tax = _Whale1_Tax;
            Stage5_Tax = _Whale1_Tax;
            Stage6_Tax = _Whale1_Tax;
            Stage7_Tax = _Whale1_Tax;
            Stage8_Tax = _Whale1_Tax;
            Stage9_Tax = _Whale1_Tax;
            Stage10_Tax = _Whale1_Tax;
            Stage11_Tax = _Whale1_Tax;
            Stage12_Tax = _Whale1_Tax;
        }
    }
    function Set_Whale2_Burn(uint _Whale2_Burn) public {
        if(msg.sender == owner) {
            Stage2_Burn = _Whale2_Burn;
            Stage3_Burn = _Whale2_Burn;
            Stage4_Burn = _Whale2_Burn;
            Stage5_Burn = _Whale2_Burn;
            Stage6_Burn = _Whale2_Burn;
            Stage7_Burn = _Whale2_Burn;
            Stage8_Burn = _Whale2_Burn;
            Stage9_Burn = _Whale2_Burn;
            Stage10_Burn = _Whale2_Burn;
            Stage11_Burn = _Whale2_Burn;
            Stage12_Burn = _Whale2_Burn;
        }
    }
    function Set_Whale2_Tax(uint _Whale2_Tax) public {
        if(msg.sender == owner) {
            Stage2_Tax = _Whale2_Tax;
            Stage3_Tax = _Whale2_Tax;
            Stage4_Tax = _Whale2_Tax;
            Stage5_Tax = _Whale2_Tax;
            Stage6_Tax = _Whale2_Tax;
            Stage7_Tax = _Whale2_Tax;
            Stage8_Tax = _Whale2_Tax;
            Stage9_Tax = _Whale2_Tax;
            Stage10_Tax = _Whale2_Tax;
            Stage11_Tax = _Whale2_Tax;
            Stage12_Tax = _Whale2_Tax;
        }
    }
    function Set_Whale3_Burn(uint _Whale3_Burn) public {
        if(msg.sender == owner) {
            Stage3_Burn = _Whale3_Burn;
            Stage4_Burn = _Whale3_Burn;
            Stage5_Burn = _Whale3_Burn;
            Stage6_Burn = _Whale3_Burn;
            Stage7_Burn = _Whale3_Burn;
            Stage8_Burn = _Whale3_Burn;
            Stage9_Burn = _Whale3_Burn;
            Stage10_Burn = _Whale3_Burn;
            Stage11_Burn = _Whale3_Burn;
            Stage12_Burn = _Whale3_Burn;
        }
    }
    function Set_Whale3_Tax(uint _Whale3_Tax) public {
        if(msg.sender == owner) {
            Stage3_Tax = _Whale3_Tax;
            Stage4_Tax = _Whale3_Tax;
            Stage5_Tax = _Whale3_Tax;
            Stage6_Tax = _Whale3_Tax;
            Stage7_Tax = _Whale3_Tax;
            Stage8_Tax = _Whale3_Tax;
            Stage9_Tax = _Whale3_Tax;
            Stage10_Tax = _Whale3_Tax;
            Stage11_Tax = _Whale3_Tax;
            Stage12_Tax = _Whale3_Tax;
        }
    }
    function Set_Whale4_Burn(uint _Whale4_Burn) public {
        if(msg.sender == owner) {
            Stage4_Burn = _Whale4_Burn;
            Stage5_Burn = _Whale4_Burn;
            Stage6_Burn = _Whale4_Burn;
            Stage7_Burn = _Whale4_Burn;
            Stage8_Burn = _Whale4_Burn;
            Stage9_Burn = _Whale4_Burn;
            Stage10_Burn = _Whale4_Burn;
            Stage11_Burn = _Whale4_Burn;
            Stage12_Burn = _Whale4_Burn;
        }
    }
    function Set_Whale4_Tax(uint _Whale4_Tax) public {
        if(msg.sender == owner) {
            Stage4_Tax = _Whale4_Tax;
            Stage5_Tax = _Whale4_Tax;
            Stage6_Tax = _Whale4_Tax;
            Stage7_Tax = _Whale4_Tax;
            Stage8_Tax = _Whale4_Tax;
            Stage9_Tax = _Whale4_Tax;
            Stage10_Tax = _Whale4_Tax;
            Stage11_Tax = _Whale4_Tax;
            Stage12_Tax = _Whale4_Tax;
        }
    }
    function Set_Whale5_Burn(uint _Whale5_Burn) public {
        if(msg.sender == owner) {
            Stage5_Burn = _Whale5_Burn;
            Stage6_Burn = _Whale5_Burn;
            Stage7_Burn = _Whale5_Burn;
            Stage8_Burn = _Whale5_Burn;
            Stage9_Burn = _Whale5_Burn;
            Stage10_Burn = _Whale5_Burn;
            Stage11_Burn = _Whale5_Burn;
            Stage12_Burn = _Whale5_Burn;
        }
    }
    function Set_Whale5_Tax(uint _Whale5_Tax) public {
        if(msg.sender == owner) {
            Stage5_Tax = _Whale5_Tax;
            Stage6_Tax = _Whale5_Tax;
            Stage7_Tax = _Whale5_Tax;
            Stage8_Tax = _Whale5_Tax;
            Stage9_Tax = _Whale5_Tax;
            Stage10_Tax = _Whale5_Tax;
            Stage11_Tax = _Whale5_Tax;
            Stage12_Tax = _Whale5_Tax;
        }
    }
    function Set_Whale6_Burn(uint _Whale6_Burn) public {
        if(msg.sender == owner) {
            Stage6_Burn = _Whale6_Burn;
            Stage7_Burn = _Whale6_Burn;
            Stage8_Burn = _Whale6_Burn;
            Stage9_Burn = _Whale6_Burn;
            Stage10_Burn = _Whale6_Burn;
            Stage11_Burn = _Whale6_Burn;
            Stage12_Burn = _Whale6_Burn;
        }
    }
    function Set_Whale6_Tax(uint _Whale6_Tax) public {
        if(msg.sender == owner) {
            Stage6_Tax = _Whale6_Tax;
            Stage7_Tax = _Whale6_Tax;
            Stage8_Tax = _Whale6_Tax;
            Stage9_Tax = _Whale6_Tax;
            Stage10_Tax = _Whale6_Tax;
            Stage11_Tax = _Whale6_Tax;
            Stage12_Tax = _Whale6_Tax;
        }
    }
    function Set_Whale7_Burn(uint _Whale7_Burn) public {
        if(msg.sender == owner) {
            Stage7_Burn = _Whale7_Burn;
            Stage8_Burn = _Whale7_Burn;
            Stage9_Burn = _Whale7_Burn;
            Stage10_Burn = _Whale7_Burn;
            Stage11_Burn = _Whale7_Burn;
            Stage12_Burn = _Whale7_Burn;
        }
    }
    function Set_Whale7_Tax(uint _Whale7_Tax) public {
        if(msg.sender == owner) {
            Stage7_Tax = _Whale7_Tax;
            Stage8_Tax = _Whale7_Tax;
            Stage9_Tax = _Whale7_Tax;
            Stage10_Tax = _Whale7_Tax;
            Stage11_Tax = _Whale7_Tax;
            Stage12_Tax = _Whale7_Tax;
        }
    }
    function Set_Whale8_Burn(uint _Whale8_Burn) public {
        if(msg.sender == owner) {
            Stage8_Burn = _Whale8_Burn;
            Stage9_Burn = _Whale8_Burn;
            Stage10_Burn = _Whale8_Burn;
            Stage11_Burn = _Whale8_Burn;
            Stage12_Burn = _Whale8_Burn;
        }
    }
    function Set_Whale8_Tax(uint _Whale8_Tax) public {
        if(msg.sender == owner) {
            Stage8_Tax = _Whale8_Tax;
            Stage9_Tax = _Whale8_Tax;
            Stage10_Tax = _Whale8_Tax;
            Stage11_Tax = _Whale8_Tax;
            Stage12_Tax = _Whale8_Tax;
        }
    }
    function Set_Whale9_Burn(uint _Whale9_Burn) public {
        if(msg.sender == owner) {
            Stage9_Burn = _Whale9_Burn;
            Stage10_Burn = _Whale9_Burn;
            Stage11_Burn = _Whale9_Burn;
            Stage12_Burn = _Whale9_Burn;
        }
    }
    function Set_Whale9_Tax(uint _Whale9_Tax) public {
        if(msg.sender == owner) {
            Stage9_Tax = _Whale9_Tax;
            Stage10_Tax = _Whale9_Tax;
            Stage11_Tax = _Whale9_Tax;
            Stage12_Tax = _Whale9_Tax;
        }
    }
    function Set_Whale10_Burn(uint _Whale10_Burn) public {
        if(msg.sender == owner) {
            Stage10_Burn = _Whale10_Burn;
            Stage11_Burn = _Whale10_Burn;
            Stage12_Burn = _Whale10_Burn;
        }
    }
    function Set_Whale10_Tax(uint _Whale10_Tax) public {
        if(msg.sender == owner) {
            Stage10_Tax = _Whale10_Tax;
            Stage11_Tax = _Whale10_Tax;
            Stage12_Tax = _Whale10_Tax;
        }
    }
    function Set_Whale11_Burn(uint _Whale11_Burn) public {
        if(msg.sender == owner) {
            Stage11_Burn = _Whale11_Burn;
            Stage12_Burn = _Whale11_Burn;
        }
    }
    function Set_Whale11_Tax(uint _Whale11_Tax) public {
        if(msg.sender == owner) {
            Stage11_Tax = _Whale11_Tax;
            Stage12_Tax = _Whale11_Tax;
        }
    }
    function Set_Whale12_Burn(uint _Whale12_Burn) public {
        if(msg.sender == owner) {
            Stage12_Burn = _Whale12_Burn;
        }
    }
    function Set_Whale12_Tax(uint _Whale12_Tax) public {
        if(msg.sender == owner) {
            Stage12_Tax = _Whale12_Tax;
        }
    }
    function Set_Owner_Stage1_Burn(uint _Owner_Stage1_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage1_Burn = _Owner_Stage1_Burn;
            Owner_Stage2_Burn = _Owner_Stage1_Burn;
            Owner_Stage3_Burn = _Owner_Stage1_Burn;
            Owner_Stage4_Burn = _Owner_Stage1_Burn;
            Owner_Stage5_Burn = _Owner_Stage1_Burn;
            Owner_Stage6_Burn = _Owner_Stage1_Burn;
            Owner_Stage7_Burn = _Owner_Stage1_Burn;
            Owner_Stage8_Burn = _Owner_Stage1_Burn;
            Owner_Stage9_Burn = _Owner_Stage1_Burn;
            Owner_Stage10_Burn = _Owner_Stage1_Burn;
            Owner_Stage11_Burn = _Owner_Stage1_Burn;
            Owner_Stage12_Burn = _Owner_Stage1_Burn;
        }
    }
    function Set_Owner_Stage1_Tax(uint _Owner_Stage1_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage1_Tax = _Owner_Stage1_Tax;
            Owner_Stage2_Tax = _Owner_Stage1_Tax;
            Owner_Stage3_Tax = _Owner_Stage1_Tax;
            Owner_Stage4_Tax = _Owner_Stage1_Tax;
            Owner_Stage5_Tax = _Owner_Stage1_Tax;
            Owner_Stage6_Tax = _Owner_Stage1_Tax;
            Owner_Stage7_Tax = _Owner_Stage1_Tax;
            Owner_Stage8_Tax = _Owner_Stage1_Tax;
            Owner_Stage9_Tax = _Owner_Stage1_Tax;
            Owner_Stage10_Tax = _Owner_Stage1_Tax;
            Owner_Stage11_Tax = _Owner_Stage1_Tax;
            Owner_Stage12_Tax = _Owner_Stage1_Tax;
        }
    }
    function Set_Owner_Stage2_Burn(uint _Owner_Stage2_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage2_Burn = _Owner_Stage2_Burn;
            Owner_Stage3_Burn = _Owner_Stage2_Burn;
            Owner_Stage4_Burn = _Owner_Stage2_Burn;
            Owner_Stage5_Burn = _Owner_Stage2_Burn;
            Owner_Stage6_Burn = _Owner_Stage2_Burn;
            Owner_Stage7_Burn = _Owner_Stage2_Burn;
            Owner_Stage8_Burn = _Owner_Stage2_Burn;
            Owner_Stage9_Burn = _Owner_Stage2_Burn;
            Owner_Stage10_Burn = _Owner_Stage2_Burn;
            Owner_Stage11_Burn = _Owner_Stage2_Burn;
            Owner_Stage12_Burn = _Owner_Stage2_Burn;
        }
    }
    function Set_Owner_Stage2_Tax(uint _Owner_Stage2_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage2_Tax = _Owner_Stage2_Tax;
            Owner_Stage3_Tax = _Owner_Stage2_Tax;
            Owner_Stage4_Tax = _Owner_Stage2_Tax;
            Owner_Stage5_Tax = _Owner_Stage2_Tax;
            Owner_Stage6_Tax = _Owner_Stage2_Tax;
            Owner_Stage7_Tax = _Owner_Stage2_Tax;
            Owner_Stage8_Tax = _Owner_Stage2_Tax;
            Owner_Stage9_Tax = _Owner_Stage2_Tax;
            Owner_Stage10_Tax = _Owner_Stage2_Tax;
            Owner_Stage11_Tax = _Owner_Stage2_Tax;
            Owner_Stage12_Tax = _Owner_Stage2_Tax;
        }
    }
    function Set_Owner_Stage3_Burn(uint _Owner_Stage3_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage3_Burn = _Owner_Stage3_Burn;
            Owner_Stage4_Burn = _Owner_Stage3_Burn;
            Owner_Stage5_Burn = _Owner_Stage3_Burn;
            Owner_Stage6_Burn = _Owner_Stage3_Burn;
            Owner_Stage7_Burn = _Owner_Stage3_Burn;
            Owner_Stage8_Burn = _Owner_Stage3_Burn;
            Owner_Stage9_Burn = _Owner_Stage3_Burn;
            Owner_Stage10_Burn = _Owner_Stage3_Burn;
            Owner_Stage11_Burn = _Owner_Stage3_Burn;
            Owner_Stage12_Burn = _Owner_Stage3_Burn;
        }
    }
    function Set_Owner_Stage3_Tax(uint _Owner_Stage3_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage3_Tax = _Owner_Stage3_Tax;
            Owner_Stage4_Tax = _Owner_Stage3_Tax;
            Owner_Stage5_Tax = _Owner_Stage3_Tax;
            Owner_Stage6_Tax = _Owner_Stage3_Tax;
            Owner_Stage7_Tax = _Owner_Stage3_Tax;
            Owner_Stage8_Tax = _Owner_Stage3_Tax;
            Owner_Stage9_Tax = _Owner_Stage3_Tax;
            Owner_Stage10_Tax = _Owner_Stage3_Tax;
            Owner_Stage11_Tax = _Owner_Stage3_Tax;
            Owner_Stage12_Tax = _Owner_Stage3_Tax;
        }
    }
    function Set_Owner_Stage4_Burn(uint _Owner_Stage4_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage4_Burn = _Owner_Stage4_Burn;
            Owner_Stage5_Burn = _Owner_Stage4_Burn;
            Owner_Stage6_Burn = _Owner_Stage4_Burn;
            Owner_Stage7_Burn = _Owner_Stage4_Burn;
            Owner_Stage8_Burn = _Owner_Stage4_Burn;
            Owner_Stage9_Burn = _Owner_Stage4_Burn;
            Owner_Stage10_Burn = _Owner_Stage4_Burn;
            Owner_Stage11_Burn = _Owner_Stage4_Burn;
            Owner_Stage12_Burn = _Owner_Stage4_Burn;
        }
    }
    function Set_Owner_Stage4_Tax(uint _Owner_Stage4_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage4_Tax = _Owner_Stage4_Tax;
            Owner_Stage5_Tax = _Owner_Stage4_Tax;
            Owner_Stage6_Tax = _Owner_Stage4_Tax;
            Owner_Stage7_Tax = _Owner_Stage4_Tax;
            Owner_Stage8_Tax = _Owner_Stage4_Tax;
            Owner_Stage9_Tax = _Owner_Stage4_Tax;
            Owner_Stage10_Tax = _Owner_Stage4_Tax;
            Owner_Stage11_Tax = _Owner_Stage4_Tax;
            Owner_Stage12_Tax = _Owner_Stage4_Tax;
        }
    }
    function Set_Owner_Stage5_Burn(uint _Owner_Stage5_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage5_Burn = _Owner_Stage5_Burn;
            Owner_Stage6_Burn = _Owner_Stage5_Burn;
            Owner_Stage7_Burn = _Owner_Stage5_Burn;
            Owner_Stage8_Burn = _Owner_Stage5_Burn;
            Owner_Stage9_Burn = _Owner_Stage5_Burn;
            Owner_Stage10_Burn = _Owner_Stage5_Burn;
            Owner_Stage11_Burn = _Owner_Stage5_Burn;
            Owner_Stage12_Burn = _Owner_Stage5_Burn;
        }
    }
    function Set_Owner_Stage5_Tax(uint _Owner_Stage5_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage5_Tax = _Owner_Stage5_Tax;
            Owner_Stage6_Tax = _Owner_Stage5_Tax;
            Owner_Stage7_Tax = _Owner_Stage5_Tax;
            Owner_Stage8_Tax = _Owner_Stage5_Tax;
            Owner_Stage9_Tax = _Owner_Stage5_Tax;
            Owner_Stage10_Tax = _Owner_Stage5_Tax;
            Owner_Stage11_Tax = _Owner_Stage5_Tax;
            Owner_Stage12_Tax = _Owner_Stage5_Tax;
        }
    }
    function Set_Owner_Stage6_Burn(uint _Owner_Stage6_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage6_Burn = _Owner_Stage6_Burn;
            Owner_Stage7_Burn = _Owner_Stage6_Burn;
            Owner_Stage8_Burn = _Owner_Stage6_Burn;
            Owner_Stage9_Burn = _Owner_Stage6_Burn;
            Owner_Stage10_Burn = _Owner_Stage6_Burn;
            Owner_Stage11_Burn = _Owner_Stage6_Burn;
            Owner_Stage12_Burn = _Owner_Stage6_Burn;
        }
    }
    function Set_Owner_Stage6_Tax(uint _Owner_Stage6_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage6_Tax = _Owner_Stage6_Tax;
            Owner_Stage7_Tax = _Owner_Stage6_Tax;
            Owner_Stage8_Tax = _Owner_Stage6_Tax;
            Owner_Stage9_Tax = _Owner_Stage6_Tax;
            Owner_Stage10_Tax = _Owner_Stage6_Tax;
            Owner_Stage11_Tax = _Owner_Stage6_Tax;
            Owner_Stage12_Tax = _Owner_Stage6_Tax;
        }
    }
    function Set_Owner_Stage7_Burn(uint _Owner_Stage7_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage7_Burn = _Owner_Stage7_Burn;
            Owner_Stage8_Burn = _Owner_Stage7_Burn;
            Owner_Stage9_Burn = _Owner_Stage7_Burn;
            Owner_Stage10_Burn = _Owner_Stage7_Burn;
            Owner_Stage11_Burn = _Owner_Stage7_Burn;
            Owner_Stage12_Burn = _Owner_Stage7_Burn;
        }
    }
    function Set_Owner_Stage7_Tax(uint _Owner_Stage7_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage7_Tax = _Owner_Stage7_Tax;
            Owner_Stage8_Tax = _Owner_Stage7_Tax;
            Owner_Stage9_Tax = _Owner_Stage7_Tax;
            Owner_Stage10_Tax = _Owner_Stage7_Tax;
            Owner_Stage11_Tax = _Owner_Stage7_Tax;
            Owner_Stage12_Tax = _Owner_Stage7_Tax;
        }
    }
    function Set_Owner_Stage8_Burn(uint _Owner_Stage8_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage8_Burn = _Owner_Stage8_Burn;
            Owner_Stage9_Burn = _Owner_Stage8_Burn;
            Owner_Stage10_Burn = _Owner_Stage8_Burn;
            Owner_Stage11_Burn = _Owner_Stage8_Burn;
            Owner_Stage12_Burn = _Owner_Stage8_Burn;
        }
    }
    function Set_Owner_Stage8_Tax(uint _Owner_Stage8_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage8_Tax = _Owner_Stage8_Tax;
            Owner_Stage9_Tax = _Owner_Stage8_Tax;
            Owner_Stage10_Tax = _Owner_Stage8_Tax;
            Owner_Stage11_Tax = _Owner_Stage8_Tax;
            Owner_Stage12_Tax = _Owner_Stage8_Tax;
        }
    }
    function Set_Owner_Stage9_Burn(uint _Owner_Stage9_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage9_Burn = _Owner_Stage9_Burn;
            Owner_Stage10_Burn = _Owner_Stage9_Burn;
            Owner_Stage11_Burn = _Owner_Stage9_Burn;
            Owner_Stage12_Burn = _Owner_Stage9_Burn;
        }
    }
    function Set_Owner_Stage9_Tax(uint _Owner_Stage9_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage9_Tax = _Owner_Stage9_Tax;
            Owner_Stage10_Tax = _Owner_Stage9_Tax;
            Owner_Stage11_Tax = _Owner_Stage9_Tax;
            Owner_Stage12_Tax = _Owner_Stage9_Tax;
        }
    }
    function Set_Owner_Stage10_Burn(uint _Owner_Stage10_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage10_Burn = _Owner_Stage10_Burn;
            Owner_Stage11_Burn = _Owner_Stage10_Burn;
            Owner_Stage12_Burn = _Owner_Stage10_Burn;
        }
    }
    function Set_Owner_Stage10_Tax(uint _Owner_Stage10_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage10_Tax = _Owner_Stage10_Tax;
            Owner_Stage11_Tax = _Owner_Stage10_Tax;
            Owner_Stage12_Tax = _Owner_Stage10_Tax;
        }
    }
    function Set_Owner_Stage11_Burn(uint _Owner_Stage11_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage11_Burn = _Owner_Stage11_Burn;
            Owner_Stage12_Burn = _Owner_Stage11_Burn;
        }
    }
    function Set_Owner_Stage11_Tax(uint _Owner_Stage11_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage11_Tax = _Owner_Stage11_Tax;
            Owner_Stage12_Tax = _Owner_Stage11_Tax;
        }
    }
    function Set_Owner_Stage12_Burn(uint _Owner_Stage12_Burn) public {
        if(msg.sender == owner) {
            Owner_Stage12_Burn = _Owner_Stage12_Burn;
        }
    }
    function Set_Owner_Stage12_Tax(uint _Owner_Stage12_Tax) public {
        if(msg.sender == owner) {
            Owner_Stage12_Tax = _Owner_Stage12_Tax;
        }
    }

    function transfer(address recipient,uint256 amount) public override returns (bool) {
        if(exclidedFromTax[msg.sender] == true) {
            if(Owner_Tax == true) {
                if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                    uint burnAmount = amount;
                    uint adminAmount = amount.mul(0) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else {
                    _transfer(_msgSender(), recipient, amount);
                }
            }
            else {
                if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                    uint burnAmount = amount;
                    uint adminAmount = amount.mul(0) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 100 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage1_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage1_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 100 * 10 ** 18 && amount <= 1000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage2_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage2_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 1000 * 10 ** 18 && amount <= 10000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage3_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage3_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 10000 * 10 ** 18 && amount <= 100000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage4_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage4_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount > 100000 * 10 ** 18 && amount <= 1000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage5_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage5_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 1000000 * 10 ** 18 && amount <= 10000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage6_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage6_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 10000000 * 10 ** 18 && amount <= 100000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage7_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage7_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 100000000 * 10 ** 18 && amount <= 1000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage8_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage8_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 1000000000 * 10 ** 18 && amount <= 10000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage9_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage9_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 10000000000 * 10 ** 18 && amount <= 50000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage10_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage10_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else if(amount <= 50000000000 * 10 ** 18 && amount <= 100000000000 * 10 ** 18) {
                    uint burnAmount = amount.mul(Owner_Stage11_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage11_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }
                else {
                    uint burnAmount = amount.mul(Owner_Stage12_Burn) / 100;
                    uint adminAmount = amount.mul(Owner_Stage12_Tax) / 100;
                    _burn(_msgSender(), burnAmount);
                    _transfer(_msgSender(), owner, adminAmount);
                    _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
                }

            }
        } 
        else {
            if(recipient == address(0x000000000000000000000000000000000000dEaD)) {
                uint burnAmount = amount;
                uint adminAmount = amount.mul(0) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 100 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage1_Burn) / 100;
                uint adminAmount = amount.mul(Stage1_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 100 * 10 ** 18 && amount <= 1000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage2_Burn) / 100;
                uint adminAmount = amount.mul(Stage2_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 1000 * 10 ** 18 && amount <= 10000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage3_Burn) / 100;
                uint adminAmount = amount.mul(Stage3_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 10000 * 10 ** 18 && amount <= 100000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage4_Burn) / 100;
                uint adminAmount = amount.mul(Stage4_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount > 100000 * 10 ** 18 && amount <= 1000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage5_Burn) / 100;
                uint adminAmount = amount.mul(Stage5_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 1000000 * 10 ** 18 && amount <= 10000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage6_Burn) / 100;
                uint adminAmount = amount.mul(Stage6_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 10000000 * 10 ** 18 && amount <= 100000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage7_Burn) / 100;
                uint adminAmount = amount.mul(Stage7_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 100000000 * 10 ** 18 && amount <= 1000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage8_Burn) / 100;
                uint adminAmount = amount.mul(Stage8_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 1000000000 * 10 ** 18 && amount <= 10000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage9_Burn) / 100;
                uint adminAmount = amount.mul(Stage9_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 10000000000 * 10 ** 18 && amount <= 50000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage10_Burn) / 100;
                uint adminAmount = amount.mul(Stage10_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else if(amount <= 50000000000 * 10 ** 18 && amount <= 100000000000 * 10 ** 18) {
                uint burnAmount = amount.mul(Stage11_Burn) / 100;
                uint adminAmount = amount.mul(Stage11_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
            else {
                uint burnAmount = amount.mul(Stage12_Burn) / 100;
                uint adminAmount = amount.mul(Stage12_Tax) / 100;
                _burn(_msgSender(), burnAmount);
                _transfer(_msgSender(), owner, adminAmount);
                _transfer(_msgSender(), recipient, amount.sub(burnAmount).sub(adminAmount));
            }
        }
        return true;
    }
}