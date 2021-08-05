/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

pragma solidity 0.6.12;
// SPDX-License-Identifier: MIT







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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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




/* 
    ____                   
   / __ )__  ______  __  __
  / __  / / / / __ \/ / / /
 / /_/ / /_/ / /_/ / /_/ / 
/_____/\__,_/\____/\__, /  
                  /____/   
                  
Alan Stacks
Thanks to Statera, Stonks, and Unipower for inspiration
*/

contract Buoy is ERC20, ReentrancyGuard {
    using SafeMath for uint256;
    
//================================Mappings and Variables=============================//
    
    //owner
    address payable owner;
    //mappings
    mapping (address => uint) reserves;
    mapping (address => uint) ethPaid;
    //booleans
    bool withdrawable;
    bool withdrawPeriodOver;
    bool addressLocked;
    bool ethInjected;
    bool saleHalted;
    //token info
    string private _name = "Buoy";
    string private _symbol = "BUOY";
    uint _totalReserved;
    //public sale dates
    uint startDate;
    uint stage1;
    uint stage2;
    uint endDate;
    uint safetySwitch;
    uint withdrawalLimit;
    //used as a redundancy to keep track of stages of public sale
    uint nonce = 0;
    //address for liquidity injection
    address payable public davysAddress;
    address payable public buoyPresale = 0xD10Fd220efC658E72fcB09a1422394eE48A39d54;
    

//================================Constructor================================//

    constructor() public payable ERC20(_name, _symbol) {
        owner = msg.sender;
        _mintOriginPool();
    }
    
//===========================ownership functionality================================//

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
//=============================Public Sale Functionality==============================//

    /*
    mints the tokens which are used to generate the Origin Pool
    */
    function _mintOriginPool() private {
        require(nonce == 0, 'NONCE_ERROR');
        uint poolTokens = (40 * (10 ** 18));
        _mint(msg.sender, poolTokens);
        emit Transfer(address(0), msg.sender, poolTokens);
        nonce ++;
    }
    
    /*
    sets startDate to now and defines the sale stages off of that. 
    */
    function startSale() onlyOwner public {
        require(addressLocked == true, 'ADDRESS_NOT_APPROVED');
        require(nonce == 1, 'NONCE_ERROR');
        startDate = now;
        saleHalted = false;
        stage1 = startDate + 2 days;
        stage2 = startDate + 6 days;
        endDate = startDate + 14 days;
        safetySwitch = endDate + 2 days;
        nonce ++;
        }

    /*
    the function the user will use to buy tokens. adds tokens to reserves to be withdrawn after 
    the sale ends. contains sale logic and limits tokens sold to 1000000
    */
    function buySale() public payable {
        require(now >= startDate, 'SALE_NOT_STARTED'); 
        require(now < endDate, 'END_DATE_PASSED');
        require(nonce == 2);
        uint tokens;
        if (now <= stage1) {
            tokens = msg.value.mul(225);
        } else if (now <= stage2) {
                tokens = msg.value.mul(200);
        } else if (now <- endDate) {
            tokens = msg.value.mul(175);
        }
        require((_totalReserved + tokens) <= 1000000 * (10 ** 18), 'TOTAL_SUPPLY_OVERFLOW');
        uint currentReserve = reserves[msg.sender];
        uint newReserve = currentReserve.add(tokens);
        reserves[msg.sender] = newReserve;
        ethPaid[msg.sender] = ethPaid[msg.sender].add(msg.value);
        _totalReserved = _totalReserved.add(tokens);
    }
    
    /*
    any ETH sent directly to the contract falls back to the buySale function
    */
    receive() payable external {
        buySale();
    }
    
    /*
    This function requires the user to have funds reserved, as well as requiring the withdrawal
    dates to be active. Because unwithrawn tokens are eventually forfeit, tokens are added to
    the total supply only when withdrawn.
    */
    function withdrawBuoy() public {
        require(reserves[msg.sender] > 0, 'INPUT_TOO_LOW');
        require(withdrawable == true, 'WITHDRAWABLE_FALSE');
        require(now >= endDate, 'END_DATE_NOT_REACHED');
        require(now <= withdrawalLimit, 'WITHDRAW_LIMIT_PASSED');
        uint withdrawal = reserves[msg.sender];
        reserves[msg.sender] = 0;
        _mint(msg.sender, withdrawal);
        emit Transfer(address(0), msg.sender, withdrawal);
        _totalReserved = _totalReserved.sub(withdrawal);
    }
    
    /*
    The withdraw period is actually ended automatically. This function just clears the reserved count
    */
    function endWithdrawPeriod() onlyOwner public {
        require(withdrawPeriodOver == false, 'WITHDRAW_PERIOD_TRUE');
        require(now >= withdrawalLimit, 'WITHDRAWL_LIMIT_NOT_PASSED');
        _totalReserved = 0;
        withdrawPeriodOver = true;
        
    }

    /*
    12,000 Buoy tokens are eligible to be received via presale tokens. Each token redeemed = 400 Buoy.
    avoids supply limitations to guarentee private sales can be redeemed during sale period
    */
    function redeemPresale() nonReentrant public {
        require(now >= startDate, 'SALE_NOT_STARTED');
        require(nonce == 2, 'NONCE_ERROR');
        require(now < endDate, 'END_DATE_PASSED');
        IERC20 transferContract = IERC20(buoyPresale);
        uint presaleTokens = transferContract.balanceOf(msg.sender);
        require(presaleTokens > 0, 'NO_PRESALE_TOKENS');
        transferContract.transferFrom(msg.sender, address(this), presaleTokens);
        uint tokens = 400*(presaleTokens)*(10 ** 18);
        uint currentReserve = reserves[msg.sender];
        uint newReserve = currentReserve.add(tokens);
        reserves[msg.sender] = newReserve;
        _totalReserved = _totalReserved.add(tokens);
    }
    

//===================================view fucntions============================//
    
    /*
    all the see functions return uint values in wei, and so need to be divided by (10 ** 18) to give an accurate decimal count
    */
    
    function viewStage() public view returns(string memory) {
        if(now <= startDate) {
            return("Public sale has not yet started");
        } else if(now <= stage1) {
            return("Stage 1 of the sale, 225 BUOY per ETH");
        } else if(now <= stage2) { 
            return("Stage 2 of the sale, 200 BUOY per ETH");
        } else if(now <= endDate) { 
            return("Stage 3 of the sale, 175 BUOY per ETH");
        } else return("Sale over, please withdraw your Buoy");
    }

    function viewPossibleReserved(uint256 a) public view returns(uint) {
        uint bonus;
        if(now <= stage1) {
            bonus = (a * (10 ** 18)) * 225;
        } else if(now <= stage2) { 
            bonus = (a * (10 ** 18)) * 200;
        } else if(now <= endDate) {
            bonus =  (a * (10 ** 18)) * 175;
        } else bonus = 0;
        return bonus;
    }
    
    function viewReserved() external view returns(uint) {
        return _totalReserved;
    }
    
    function viewMyReserved() external view returns(uint) {
        if (withdrawPeriodOver == false) { 
            return reserves[msg.sender];
        } else return 0;
    }
    
    function viewMyEthPaid() external view returns(uint) {
        return ethPaid[msg.sender];
    }
    
    function viewEthRaised() external view returns(uint) {
        return address(this).balance;
    }
    
    
//==============================Injection Functionality=================================//
    
    /*
    sets the address for the asset locking contract called Davy Jones, should be done before sale starts
    */
    function setAddress(address payable davy) onlyOwner public {
        require(addressLocked == false, 'ADDRESS_ALREADY_LOCKED');
        davysAddress = davy;
    }
    
    /*
    the addresses must be locked in order to start the sale, ensuring the destination of the sale funds
    cannot be changed
    */
    function lockAddress() onlyOwner public {
        addressLocked = true;
    }
    
    /*
    trasfers eth to locking contract, mints and transters liquidity tokens to the locking contract, 
    gives dev funds, then ends the sale, locking out sale functions
    */
    function injectLiquidity() onlyOwner public {
        require(now >= endDate, 'END_DATE_NOT_REACHED');
        require(nonce == 2, 'NONCE_ERROR');
        require(ethInjected == false, 'ETH_INJECTED_TRUE');
        _injectEth();
        _injectLiquidityTokens();
        ethInjected = true;
        _giveDevFunds();
        _finalize();
    }
    
    
    /*
    Sends 90% of the ETH to the locking contract.
    */
    function _injectEth() nonReentrant private {
        require(now >= endDate, 'END_DATE_NOT_REACHED');
        require(nonce == 2, 'NONCE_ERROR');
        uint256 funds = address(this).balance;
        uint ethToInject = (funds / 10).mul(9);
        davysAddress.transfer(ethToInject);
        ethInjected = true;
    }
    
    /*
    Mints liquidity token and sends them to the locking contract. 
    */
    function _injectLiquidityTokens() private {
        require(now >= endDate, 'END_DATE_NOT_REACHED');
        require(nonce == 2, 'NONCE_ERROR');
        require(withdrawable == false, 'WITHDRAWABLE_TRUE');
        uint tokens = _totalReserved.div(2);
        _mint(davysAddress, tokens);
        emit Transfer(address(0), davysAddress, tokens);
    }
    
    /*
    Deposits 10% of the raised funds into the owners wallet. Can only be called via 
    the functions to inject liquidity
    */
    function _giveDevFunds() private {
        require(now >= endDate, 'END_DATE_NOT_REACHED');
        require(nonce == 2, 'NONCE_ERROR');
        require(ethInjected == true, 'ETH_INJECTED_FALSE');
        uint256 funds = (address(this).balance);
        owner.transfer(funds);
    }
    
    /*
    Locks out the last of the sale functionalities, opens withdrawls of tokens, and 
    sets the withdral limit for 2 months
    */
    function _finalize() private {
        require(now >= endDate, 'END_DATE_NOT_REACHED');
        require(nonce == 2, 'NONCE_ERROR');
        withdrawable = true;
        withdrawalLimit = now + 60 days;  
        nonce ++;
    }
    
//==================================safety releases======================================//
    
    /*
    emergency halt to protect user funds in case of error. rolls the nonce back to stop sales
    while allowing still startSale to be used again if needed. opens refund function for users
    */
    function haltSale() onlyOwner public {
        require(now < endDate, 'END_DATE_PASSED'); 
        require(nonce == 2, 'NONCE_ERROR');
        require(saleHalted == false, 'SALE_HALTED');
        nonce --;   
        saleHalted = true;
    }
    
    /*
    allows users to refund their ETH in case of the sale being
    halted
    */
    function emergencyRefund() nonReentrant public {
        require(now < endDate, 'END_DATE_PASSED'); 
        require(saleHalted == true); 
        require(ethPaid[msg.sender] > 0);
        uint256 refund = ethPaid[msg.sender];
        ethPaid[msg.sender] = 0;
        reserves[msg.sender] = 0;
        msg.sender.transfer(refund);
    }
    
    /*
    If the sale sells all the supply, the sale can be ended early
    */
    function endSaleEarly() public {
        require(now < endDate, 'END_DATE_PASSED');
        require(_totalReserved >= 999999 * (10 ** 18), 'TOTAL_SUPPLY_NOT_REACHED');
        require(nonce == 2, 'NONCE_ERROR');
        endDate = now + 1 seconds;
    }

    /*
    if the liquidity isn't injected 48 hours after the sale ends, functionality is 
    opened to the public. uint gasPrice is used twice
    */
    function publicInjectLiquidity() public {
        require(now >= endDate, 'END_DATE_NOT_REACHED');
        require(nonce == 2, 'NONCE_ERROR');
        require(ethInjected == false, 'ETH_INJECTED_TRUE');
        require(now >= safetySwitch, 'SAFETY_SWITCH_NOT_PASSED');
        _injectEth();
        _injectLiquidityTokens();
        ethInjected = true;
        _giveDevFunds();
        _finalize();
    }

}