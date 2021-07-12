/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: MIT

// File: contracts/cards/ICard.sol

pragma solidity ^0.6.8;

interface ICard {

    function swap(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _destTokenId
    )
        external;

    function purchase(
        uint256 _tokenId,
        uint256 _paymentAmount,
        uint256 _expiration,
        bytes32 _orderId,
        bytes calldata _orderSignature
    )
        external;

    function liquidate(
        uint256 _tokenId,
        uint256 _liquidationAmount
    )
        external;

    function estimateSwap(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _destTokenId
    )
        external view returns (uint expectedRate, uint slippageRate);

    function estimatePurchase(
        uint256 _tokenId,
        uint256 _paymentAmount
    )
        external view returns (uint expectedRate, uint slippageRate);

    function estimateLiquidate(
        uint256 _tokenId,
        uint256 _liquidationAmount
    )
        external view returns (uint expectedRate, uint slippageRate);
}

// File: contracts/bondedERC20/IBondedERC20Transfer.sol

pragma solidity ^0.6.8;

interface IBondedERC20Transfer {
    function bondedERC20Transfer(
        uint256 _tokenId,
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

// File: @openzeppelin/contracts/GSN/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
}

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


pragma solidity ^0.6.0;





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

// File: contracts/bondedERC20/BondedERC20.sol


pragma solidity ^0.6.8;

// This Contract is not upgradable.




/**
 * @title BondedERC20
 */
contract BondedERC20 is Ownable, ERC20 {

    using SafeMath for uint256;

    uint256 public tokenId;

    // Keeps track of the reserve balance.
    uint256 public poolBalance;

    // Represented in PPM 1-1000000
    uint32 public reserveRatio;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _tokenId
    )
        public Ownable() ERC20(_name, _symbol)
    {
        tokenId = _tokenId;

        // sets the reserve ratio for the token
        reserveRatio = 333333;
    }

    /**
     * @dev Sets reserve ratio for the token
     * @param _reserveRatio in PPM 1-1000000
     */
    function setReserveRatio(uint32 _reserveRatio) public onlyOwner {
        require(
            _reserveRatio > 1 && _reserveRatio <= 1000000,
            "BondedERC20: invalid _reserveRatio"
        );

        reserveRatio = _reserveRatio;
    }

    /**
     * @dev Issues an amount of tokens quivalent to a value reserve.
     *  Can only be called by the owner of the contract
     * @param _to beneficiary address of the tokens
     * @param _amount of tokens to mint
     * @param _value value in reserve of the minted tokens
     */
    function mint(address _to, uint256 _amount, uint256 _value) public onlyOwner {
        _mint(_to, _amount);

        // update reserve balance
        poolBalance = poolBalance.add(_value);
    }

    /**
     * @dev Burns an amount of tokens quivalent to a value reserve.
     *  Can only be called by the owner of the contract
     * @param _burner address
     * @param _amount of tokens to burn
     * @param _value value in reserve of the burned tokens
     */
    function burn(address _burner, uint256 _amount, uint256 _value) public onlyOwner {
        _burn(_burner, _amount);

        // update reserve balance
        poolBalance = poolBalance.sub(_value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        super.transferFrom(_from, _to, _value);

        // Notify owner NFT transfer.
        IBondedERC20Transfer(owner()).bondedERC20Transfer(
            tokenId,
            _from,
            _to,
            _value
        );

        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        super.transfer(_to, _value);

        // Notify owner NFT transfer.
        IBondedERC20Transfer(owner()).bondedERC20Transfer(
            tokenId,
            msg.sender,
            _to,
            _value
        );

        return true;
    }
}

// File: contracts/lib/ERC20Manager.sol


pragma solidity ^0.6.8;


/// All methods are internal. Implemented throught a JUMP call on the EVM.
library ERC20Manager {

    function deploy(
        string memory _symbol,
        string memory _name,
        uint256 _tokenId
    )
        internal returns(address)
    {
        BondedERC20 newContract = new BondedERC20(
            _name,
            _symbol,
            _tokenId
        );

        return address(newContract);
    }

    function mint(
        address _token,
        address _beneficiary,
        uint256 _amount,
        uint256 _value
    )
        internal
    {
        BondedERC20(_token).mint(
            _beneficiary,
            _amount,
            _value
        );
    }

    function burn(
        address _token,
        address _burner,
        uint256 _amount,
        uint256 _value
    )
        internal
    {
        BondedERC20(_token).burn(
            _burner,
            _amount,
            _value
        );
    }

    function setReserveRatio(address _token, uint32 _reserveRatio) internal {
        return BondedERC20(_token).setReserveRatio(_reserveRatio);
    }

    function totalSupply(address _token) internal view returns (uint256) {
        return BondedERC20(_token).totalSupply();
    }

    function poolBalance(address _token) internal view returns (uint256) {
        return BondedERC20(_token).poolBalance();
    }

    function reserveRatio(address _token) internal view returns (uint32) {
        return BondedERC20(_token).reserveRatio();
    }
}

// File: @openzeppelin/contracts/cryptography/ECDSA.sol


pragma solidity ^0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/utils/Administrable.sol


pragma solidity ^0.6.8;



contract Administrable is Ownable {
    using ECDSA for bytes32;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    // Admins map
    mapping(address => bool) private adminsMap;

    modifier onlyAdmin {
        require(adminsMap[msg.sender], "Administrable: sender is not admin");
        _;
    }

    /**
     * @dev Add new admin. Can only be called by owner
     * @param _wallet address of new admin
     */
    function addAdmin(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Administrable: invalid wallet address");
        require(!isAdmin(_wallet), "Administrable: wallet already admin");

        adminsMap[_wallet] = true;

        emit AdminAdded(_wallet);
    }

    /**
     * @dev Removes admin account. Can only be called by owner
     * @param _wallet address revoke admin role
     */
    function removeAdmin(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Administrable: invalid wallet address");
        require(isAdmin(_wallet), "Administrable: wallet is not admin");

        adminsMap[_wallet] = false;

        emit AdminRemoved(_wallet);
    }

    function renounceAdmin() external onlyAdmin {
        adminsMap[msg.sender] = false;

        emit AdminRemoved(msg.sender);
    }

    /**
     * @dev Check if the provided wallet has an admin role
     * @param _wallet address of wallet to update
     */
    function isAdmin(address _wallet) public view returns (bool) {
        return adminsMap[_wallet];
    }

    /**
     * @dev Check if provided provided message hash and signature are OK
     */
    function _isValidAdminHash(bytes32 _hash, bytes memory _sig) internal view returns (bool) {
        address signer = _hash.toEthSignedMessageHash().recover(_sig);
        return isAdmin(signer);
    }
}

// File: contracts/utils/GasPriceLimited.sol


pragma solidity ^0.6.8;


contract GasPriceLimited is Administrable {

    event GasPriceLimitChanged(address indexed account, uint256 value);

    uint256 public gasPriceLimit;

    // Limits max amount of gas for buy/sell Tx.
    modifier gasPriceLimited {
        require(tx.gasprice <= gasPriceLimit, "tx.gasprice is > than gasPriceLimit");
        _;
    }

    function setGasPriceLimit(uint256 value) external onlyAdmin {
        require(value > 0, "new price value should be greater than 0");
        gasPriceLimit = value;

        emit GasPriceLimitChanged(msg.sender, gasPriceLimit);
    }
}

// File: contracts/fractionable/IFractionableERC721.sol


pragma solidity ^0.6.8;

interface IFractionableERC721 {

    event TransferBondedERC20(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 value
    );

    function getBondedERC20(uint256 _tokenId) external view returns(address);

    function mintToken(
        uint256 _tokenId,
        address _beneficiary,
        string calldata _symbol,
        string calldata _name
    )
        external;

    function mintBondedERC20(
        uint256 _tokenId,
        address _beneficiary,
        uint256 _amount,
        uint256 _value
    )
        external;

    function burnBondedERC20(
        uint256 _tokenId,
        address _burner,
        uint256 _amount,
        uint256 _value
    )
        external;

    function estimateBondedERC20Tokens(
        uint256 _tokenId,
        uint256 _value
    )
        external view returns (uint256);

    function estimateBondedERC20Value(
        uint256 _tokenId,
        uint256 _amount
    )
        external view returns (uint256);

}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/cards/PerformanceCard.sol


pragma solidity ^0.6.8;









// Simple
interface EIP712 {
    function transferWithSig(
        bytes calldata sig,
        uint256 tokenIdOrAmount,
        bytes32 data,
        uint256 expiration,
        address to
    ) external returns (address);
}

// Simple ERC721 interface

interface IERC721Simple {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// Main Contract

contract PerformanceCard is Administrable, ICard, GasPriceLimited {

    using ECDSA for bytes32;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // .0001 precision.
    uint32 public constant MATH_PRECISION = 1e4;

    // Constant values for creating bonded ERC20 tokens.
    uint256 public constant ERC20_INITIAL_SUPPLY = 100000e18; // 100000 units
    uint256 public constant ERC20_INITIAL_POOL_SHARE = 250; // 2.5%
    uint256 public constant PLATFORM_CUT = 250; // 2.5%

    // Reserve Token.
    IERC20 private reserveToken;

    // Registry
    IFractionableERC721 private nftRegistry;

    // Relayed signatures map
    mapping(bytes => bool) private relayedSignatures;

    /**
     * @dev Initializer for PerformanceCard contract
     * @param _nftRegistry - NFT Registry address
     * @param _reserveToken - Reserve registry address
     */
     constructor(
        address _nftRegistry,
        address _reserveToken
    )
        public
    {
        // Set Reseve Token addresses
        reserveToken = IERC20(_reserveToken);

        // Set the NFT Registry
        nftRegistry = IFractionableERC721(_nftRegistry);
    }

    /**
     * @dev Executes a transaction that was relayed by a 3rd party
     * @param _nonce tx nonce
     * @param _signer signer who's the original beneficiary
     * @param _abiEncoded function signature
     * @param _orderHashSignature keccak256(nonce, signer, function)
     */
    function executeRelayedTx(
        uint256 _nonce,
        address _signer,
        bytes calldata _abiEncoded,
        bytes calldata _orderHashSignature
    )
        external returns (bytes memory)
    {
        require(
            relayedSignatures[_orderHashSignature] == false,
            "PerformanceCard: Invalid _orderSignature"
        );

        // Check hashed message & signature
        bytes32 _hash = keccak256(
            abi.encodePacked(_nonce, _signer, _abiEncoded)
        );

        require(
            _signer == _hash.toEthSignedMessageHash().recover(_orderHashSignature),
            "PerformanceCard: invalid signature verification"
        );

        relayedSignatures[_orderHashSignature] = true;

        // Append signer address at the end to extract it from calling context
        (bool success, bytes memory returndata) = address(this).call(
            abi.encodePacked(_abiEncoded, _signer)
        );

        if (success) {
            return returndata;
        }

        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {

            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }

        } else {
            revert("PerformanceCard: error in call()");
        }
    }

    /**
     * @dev Create Performance Card
     * @param _tokenId card id
     * @param _symbol card symbol
     * @param _name card name
     * @param _reserveAmount creation value for the card
     * @param _msgHash hash of card parameters
     * @param _signature admin signature
     */
    function createCard(
        uint256 _tokenId,
        string memory _symbol,
        string memory _name,
        uint256 _reserveAmount,
        bytes32 _msgHash,
        bytes memory _signature,
        // These are required for EIP712
        uint256 _expiration,
        bytes32 _orderId,
        bytes memory _orderSignature
    )
        public gasPriceLimited
    {
        require(
            nftRegistry.getBondedERC20(_tokenId) == address(0),
            "PerformanceCard: card already created"
        );

        // Check hashed message & admin signature
        bytes32 checkHash = keccak256(
            abi.encodePacked(_tokenId, _symbol, _name, _reserveAmount)
        );

        require(
            checkHash == _msgHash,
            "PerformanceCard: invalid msgHash"
        );

        require(
            _isValidAdminHash(_msgHash, _signature),
            "PerformanceCard: invalid admin signature"
        );

        // Check the sender has the required sTSX balance
        _requireBalance(msgSender(), reserveToken, _reserveAmount);

        // Transfer sTSX _reserveAmount from caller account to this contract using EIP712 signature
        EIP712(address(reserveToken)).transferWithSig(
            _orderSignature,
            _reserveAmount,
            keccak256(
                abi.encodePacked(_orderId, address(reserveToken), _reserveAmount)
            ),
            _expiration,
            address(this)
        );

        // Create NFT
        // - The NFT owner is platform owner
        // - The ERC20_INITIAL_SUPPLY is for msgSender()
        //
        nftRegistry.mintToken(_tokenId, owner(), _symbol, _name);
        nftRegistry.mintBondedERC20(_tokenId, msgSender(), ERC20_INITIAL_SUPPLY, _reserveAmount);
    }

    /**
     * Swap two fractionable ERC721 tokens.
     * @param _tokenId tokenId to liquidate
     * @param _amount wei amount of liquidation in source token.
     * @param _destTokenId tokenId to puurchase.
     */
    function swap(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _destTokenId
    )
        public override gasPriceLimited
    {
        require(
            nftRegistry.getBondedERC20(_tokenId) != address(0),
            "PerformanceCard: tokenId does not exist"
        );

        require(
            nftRegistry.getBondedERC20(_destTokenId) != address(0),
            "PerformanceCard: destTokenId does not exist"
        );

        uint256 reserveAmount = nftRegistry.estimateBondedERC20Value(
            _tokenId,
            _amount
        );

        uint256 estimatedTokens = nftRegistry.estimateBondedERC20Tokens(
            _destTokenId,
            reserveAmount
        );

        // Burn selled tokens and mint buyed
        nftRegistry.burnBondedERC20(_tokenId, msgSender(), _amount, reserveAmount);
        nftRegistry.mintBondedERC20(_destTokenId, msgSender(), estimatedTokens, reserveAmount);
    }

    /**
     * Estimate Swap between two fractionable ERC721 tokens.
     * @param _tokenId tokenId to liquidate
     * @param _amount wei amount of liquidation in source token.
     * @param _destTokenId tokenId to puurchase.
     */
    function estimateSwap(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _destTokenId
    )
        public view override returns (uint expectedRate, uint slippageRate)
    {
        require(
            nftRegistry.getBondedERC20(_tokenId) != address(0),
            "PerformanceCard: tokenId does not exist"
        );

        require(
            nftRegistry.getBondedERC20(_destTokenId) != address(0),
            "PerformanceCard: destTokenId does not exist"
        );

        // get reserve amount from selling _amount of tokenId
        uint256 reserveAmount = nftRegistry.estimateBondedERC20Value(
            _tokenId,
            _amount
        );

        // Get amount of _destTokenId tokens
        uint256 estimatedTokens = nftRegistry.estimateBondedERC20Tokens(
            _destTokenId,
            reserveAmount
        );

        address bondedToken = nftRegistry.getBondedERC20(_tokenId);

        // Return the expected exchange rate and slippage in 1e18 precision
        expectedRate = estimatedTokens.mul(1e18).div(_amount);
        slippageRate = reserveAmount.mul(1e18).div(
            ERC20Manager.poolBalance(bondedToken)
        );
    }

    /**
     * Purchase of a fractionable ERC721 using sTSX
     * @param _tokenId tokenId to purchase
     * @param _paymentAmount wei payment amount in sTSX
     */
    function purchase(
        uint256 _tokenId,
        uint256 _paymentAmount,
        uint256 _expiration,
        bytes32 _orderId,
        bytes memory _orderSignature
    )
        public override gasPriceLimited
    {
        // require(
        //     nftRegistry.getBondedERC20(_tokenId) != address(0),
        //     "PerformanceCard: tokenId does not exist"
        // );

        // // Check the sender has the required sTSX balance
        // _requireBalance(msgSender(), reserveToken, _paymentAmount);

        // // Transfer sTSX amount to this contract using EIP712 signature
        // EIP712(address(reserveToken)).transferWithSig(
        //     _orderSignature,
        //     _paymentAmount,
        //     keccak256(
        //         abi.encodePacked(_orderId, address(reserveToken), _paymentAmount)
        //     ),
        //     _expiration,
        //     address(this)
        // );

        // // transfer platform cut.
        // uint256 pFee = _paymentAmount.mul(PLATFORM_CUT).div(MATH_PRECISION);
        // reserveToken.safeTransfer(owner(), pFee);

        // // Get effective amount after tx fees
        // uint256 effectiveReserveAmount = _paymentAmount.sub(pFee);

        // // The estimated amount of bonded tokens for reserve
        // uint256 estimatedTokens = nftRegistry.estimateBondedERC20Tokens(
        //     _tokenId,
        //     effectiveReserveAmount
        // );

        // // Issue fractionables to msg sender.
        // nftRegistry.mintBondedERC20(
        //     _tokenId,
        //     msgSender(),
        //     estimatedTokens,
        //     effectiveReserveAmount
        // );
    }

    /**
     * Estimate Purchase of a fractionable ERC721 using sTSX
     * @param _tokenId tokenId to purchase
     * @param _paymentAmount wei payment amount in payment token
     */
    function estimatePurchase(
        uint256 _tokenId,
        uint256 _paymentAmount
    )
        public view override returns (uint expectedRate, uint slippageRate)
    {
        require(
            nftRegistry.getBondedERC20(_tokenId) != address(0),
            "PerformanceCard: tokenId does not exist"
        );

        // Calc fees
        uint256 pFees = _paymentAmount.mul(PLATFORM_CUT).div(MATH_PRECISION);

        // Get effective amount after tx fees
        uint256 effectiveReserveAmount = _paymentAmount.sub(pFees);

        // Get estimated amount of _tokenId for effectiveReserveAmount
        uint256 estimatedTokens = nftRegistry.estimateBondedERC20Tokens(
            _tokenId,
            effectiveReserveAmount
        );

        address bondedToken = nftRegistry.getBondedERC20(_tokenId);

        // Return the expected exchange rate and slippage in 1e18 precision
        expectedRate = estimatedTokens.mul(1e18).div(_paymentAmount);
        slippageRate = effectiveReserveAmount.mul(1e18).div(
            ERC20Manager.poolBalance(bondedToken)
        );
    }

    /**
     * Liquidate a fractionable ERC721 for sTSX
     * @param _tokenId tokenId to liquidate
     * @param _liquidationAmount wei amount for liquidate
     */
    function liquidate(
        uint256 _tokenId,
        uint256 _liquidationAmount
    )
        public override gasPriceLimited
    {
        require(
            nftRegistry.getBondedERC20(_tokenId) != address(0),
            "PerformanceCard: tokenId does not exist"
        );

        // Estimate reserve for selling _tokenId
        uint256 reserveAmount = nftRegistry.estimateBondedERC20Value(
            _tokenId,
            _liquidationAmount
        );

        // Burn selled tokens.
        nftRegistry.burnBondedERC20(
            _tokenId,
            msgSender(),
            _liquidationAmount,
            reserveAmount
        );

        // Trade reserve to sTSX and send to liquidator
        reserveToken.safeTransfer(msgSender(), reserveAmount);
    }

    /**
     * Estimate Liquidation of a fractionable ERC721 for sTSX
     * @param _tokenId tokenId to liquidate
     * @param _liquidationAmount wei amount for liquidate
     */
    function estimateLiquidate(
        uint256 _tokenId,
        uint256 _liquidationAmount
    )
        public view override returns (uint expectedRate, uint slippageRate)
    {
        require(
            nftRegistry.getBondedERC20(_tokenId) != address(0),
            "PerformanceCard: tokenId does not exist"
        );

        address bondedToken = nftRegistry.getBondedERC20(_tokenId);
        uint256 reserveAmount = nftRegistry.estimateBondedERC20Value(
            _tokenId,
            _liquidationAmount
        );

        // Return the expected exchange rate and slippage in 1e18 precision
        expectedRate = _liquidationAmount.mul(1e18).div(reserveAmount);
        slippageRate = reserveAmount.mul(1e18).div(
            ERC20Manager.poolBalance(bondedToken)
        );
    }

    /**
     * @dev Check if the sender has balance and
     *  to use sender ERC20 on his belhalf
     * @param _sender - address of sender
     * @param _token - ERC20 token registry
     * @param _amount - uint256 of amount of tokens
     */
    function _requireBalance(address _sender, IERC20 _token, uint256 _amount) private view {
        require(
            _token.balanceOf(_sender) >= _amount,
            "PerformanceCard: insufficient balance"
        );
    }

    /**
     * @dev Returns message sender. If its called from a relayed call it gets
     *  the sender address from last 20 bytes msg.data
     */
    function msgSender() private view returns (address payable result) {
        if (msg.sender == address(this)) {

            bytes memory array = msg.data;
            uint256 index = msg.data.length;

            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            assembly {
                result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
            return result;
        }
        return msg.sender;
    }
}