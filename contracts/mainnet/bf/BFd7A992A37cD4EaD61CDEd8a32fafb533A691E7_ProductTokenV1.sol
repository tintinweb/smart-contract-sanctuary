// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./ProductToken.sol";
import "./interface/IVNFT.sol";

/// @title ProductTokenV1
/// @notice This is version 1 of the product token implementation.
/// @dev This contract builds on top of version 0 by including transaction logics, such as buy and sell transfers
///    and exchange rate computation by including a price oracle.
contract ProductTokenV1 is ProductToken {
	using SafeMathUpgradeable for uint256;

    struct supplierInfo {
        uint256 amount;
        address wallet;
    }
    struct voucherInfo {
        address addr;
        uint256 tokenId;
    }

    supplierInfo public supplier;
    voucherInfo public voucher;
    IERC20 private high;

    function setHigh(address highAddress_) external onlyOwner {
        require(highAddress_!=address(0), "Invalid address");
        high = IERC20(highAddress_);
    }

    function buy(uint256 maxPrice_) external virtual onlyIfTradable {
        require(maxPrice_ > 0, "invalid max price");

        bool success = high.transferFrom(msg.sender, address(this), maxPrice_);
        require(success, "Purchase failed.");

        (uint256 amount,uint256 change, uint price, uint256 fee)  = _buy(maxPrice_);
        if (amount > 0) {
            if(change > 0) {
                high.transfer(msg.sender, change);
            }
            _updateSupplierFee(fee.mul(1e12).div(4e12));
        }else { // If token transaction failed
            high.transfer(msg.sender, maxPrice_);
        }
    }

    function sell(uint32 amount_) external virtual onlyIfTradable {
        require(balanceOf(msg.sender) >= amount_ || amount_ > 0, 'invalid amount');

        (uint256 price, uint256 fee )= _sellForAmount(amount_);

        bool success = high.transfer(msg.sender, price);
        _updateSupplierFee(fee.mul(1e12).div(2e12));
        require(success, "selling token failed");
    }

    function setSupplier( address wallet_) external virtual onlyOwner {
        require(wallet_!=address(0), "Address is invalid");
        supplier.wallet = wallet_;
    }

    function claimSupplier(uint256 amount_) external virtual {
        require(supplier.wallet!=address(0), "wallet is invalid");
        require(msg.sender == supplier.wallet, "The address is not allowed");
        if (amount_ <= supplier.amount){
            bool success = high.transfer(msg.sender, amount_);
            if (success) {
                supplier.amount = supplier.amount.sub(amount_);
            }
        }
    }

    function _updateSupplierFee(uint256 fee) internal virtual {
        if( fee > 0 ) {
            supplier.amount = supplier.amount.add(fee);
        }
    }

    /**
    * @dev A method that refunds the value of a product to a buyer/customer.
    *
    * @param buyer_       The wallet address of the owner whose product token is under the redemption process
    * @param value_       The market value of the token being redeemed
    *
    */
    function _refund(address buyer_, uint256 value_) internal virtual override {
        bool success = high.transfer(buyer_, value_);
        require(success, "refund token failed");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IVNFT {

    function unitsInToken(uint256 tokenId) external view returns (uint256 units);

    function approve(address to, uint256 tokenId, uint256 units) external;

    function allowance(uint256 tokenId, address spender) external view returns (uint256 allowed);

    function split(uint256 tokenId, uint256[] calldata units) external returns (uint256[] memory newTokenIds);

    function merge(uint256[] calldata tokenIds, uint256 targetTokenId) external;

    function transferFrom(address from, address to, uint256 tokenId,
        uint256 units) external returns (uint256 newTokenId);

    function safeTransferFrom(address from, address to, uint256 tokenId,
        uint256 units, bytes calldata data) external returns (uint256 newTokenId);

    function transferFrom(address from, address to, uint256 tokenId, uint256 targetTokenId,
        uint256 units) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 targetTokenId,
        uint256 units, bytes calldata data) external;

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface BancorBondingCurveV1Interface {

  function calculatePriceForNTokens(
    uint32 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint32 _amount
  )
    external
    view
    returns (
      uint256
    );

  function calculatePurchaseReturn(
    uint32 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint256 _depositAmount
  )
    external
    view
    returns (
      uint32
    );

  function calculateSaleReturn(
    uint32 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint32 _sellAmount
  )
    external
    view
    returns(
      uint256
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./interface/BancorBondingCurveV1Interface.sol";
import "./Escrow.sol";

/// @title ProductToken
/// @notice This is version 0 of the product token implementation.
/// @dev This contract lays the foundation for transaction computations, including
///   bonding curve calculations and variable management. Version 0 of this contract
///   does not implement any transaction logic.
contract ProductToken is ERC20Upgradeable, Escrow, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;

	event Buy(address indexed sender, uint32 amount, uint256 price);		// event to fire when a new token is minted
  event Sell(address indexed sender, uint32 amount, uint256 price);		// event to fire when a token has been sold back
  event Tradein(address indexed sender, uint32 amount);							// event to fire when a token is redeemed in the real world
  event Tradable(bool isTradable);

  bool private isTradable;
  uint256 public reserveBalance;      // amount of liquidity in the pool
  uint256 public tradeinReserveBalance;      // amount of liquidity in the pool
  uint32 public reserveRatio;         // computed from the exponential factor in the
  uint32 public maxTokenCount;        // max token count, determined by the supply of our physical product
  uint32 public tradeinCount;         // number of tokens burned through redeeming procedure. This will drive price up permanently
  uint32 internal supplyOffset;       // an initial value used to set an initial price. This is not included in the total supply.
  address private _manager;

  BancorBondingCurveV1Interface internal bondingCurve;

  modifier onlyIfTradable {
      require(
          isTradable,
          "unable to trade now"
      );
      _;
  }

	/**
   * @dev initializer function.
   *
   * @param _name                     the name of this token
   * @param _symbol                   the symbol of this token
   * @param _reserveRatio             the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount						the amount of token that will exist for this type.
   * @param _supplyOffset             this amount is used to determine initial price.
   * @param _baseReserve              the base amount of reserve tokens, in accordance to _supplyOffset.
   *
  */
  function initialize(string memory _name, string memory _symbol, address _bondingCurveAddress,
      uint32 _reserveRatio, uint32 _maxTokenCount, uint32 _supplyOffset, uint256 _baseReserve) public virtual initializer{
    __Ownable_init();
    __ERC20_init(_name, _symbol);
    __ProductToken_init_unchained(_bondingCurveAddress, _reserveRatio, _maxTokenCount, _supplyOffset, _baseReserve);
  }

  /**
   * @dev unchained initializer function.
   *
   * @param _reserveRatio             the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount            the amount of token that will exist for this type.
   * @param _supplyOffset             this amount is used to determine initial price.
   * @param _baseReserve              the base amount of reserve tokens, in accordance to _supplyOffset.
   *
  */
  function __ProductToken_init_unchained(address _bondingCurveAddress, uint32 _reserveRatio, uint32 _maxTokenCount, uint32 _supplyOffset, uint256 _baseReserve) internal initializer{
    require(_maxTokenCount > 0, "Invalid max token count.");
    require(_reserveRatio > 0, "Invalid reserve ratio");
    bondingCurve = BancorBondingCurveV1Interface(_bondingCurveAddress);
    reserveBalance = _baseReserve;
    tradeinReserveBalance = _baseReserve;
    supplyOffset = _supplyOffset;
    reserveRatio = _reserveRatio;
    maxTokenCount = _maxTokenCount;
  }

  function decimals() public view virtual override returns (uint8) {
      return 0;
  }

  /**
   * @dev requires function to be called from owner. sets a bonding curve implementation for this product.
   *
   * @param _address             the address of the bonding curve implementation
   *
  */
  function setBondingCurve(address _address) external virtual onlyOwner {
    require(_address!=address(0), "Invalid address");
    bondingCurve = BancorBondingCurveV1Interface(_address);
  }

  /**
   * @dev requires function to be called from owner. this enables customers to buy, sell, or redeem the product.
   *
  */
  function launch() external virtual onlyOwner {
    require(!isTradable, 'The product token is already launched');
    isTradable = true;
    emit Tradable(isTradable);
  }

  /**
   * @dev requires function to be called from owner. this prevents customers from buying, selling, or redeeming the product.
   *
  */
  function pause() external virtual onlyOwner {
    require(isTradable, 'The product token is already paused');
    isTradable = false;
    emit Tradable(isTradable);
  }

  fallback () external { }

  /**
   * @dev Function to check how many tokens of this product are currently available for purchase,
   * by taking the difference between max cap count and current token in circulation or burned.
   *
   * @return available                the number of tokens available
  */
  function getAvailability()
    public view virtual returns (uint32 available)
  {
    return maxTokenCount - uint32(totalSupply()) - tradeinCount;    // add safemath for uint32 later
  }

  /**
   * @dev Function that computes supply value for the bonding curve
   * based on current token in circulation, token offset initialized, and tokens already redeemed.
   *
   * @return supply                   supply value for bonding curve calculation.
  */
  function _getTotalSupply()
    internal view virtual returns (uint32 supply)
  {
    return uint32(totalSupply().add(uint256(tradeinCount)).add(uint256(supplyOffset)));
  }

  /**
   * @dev Function that computes current price for a token through bonding curve calculation
   * based on parameters such as total supply, reserve balance, and reserve ratio.
   *
   * @return price                   current price in reserve token (in our case, this is dai). (with 4% platform fee)
  */
  function getCurrentPrice()
  	public view virtual returns	(uint256 price)
  {
    return getPriceForN(1);
  }

  /**
   * @dev Function that computes price total for buying n token through bonding curve calculation
   * based on parameters such as total supply, reserve balance, and reserve ratio.
   *
   * @param  _amountProduct          token amount in traded token
   * @return price                   total price in reserve token (in our case, this is dai). (with 4% platform fee)
  */
  function getPriceForN(uint32 _amountProduct)
  	public view virtual returns	(uint256 price)
  {
    (uint value, uint fee) = _getPriceForN(_amountProduct);
    return value.add(fee);
  }

  function _getPriceForN(uint32 _amountProduct)
  	internal view virtual returns	(uint256, uint256) {
      uint256 price = bondingCurve.calculatePriceForNTokens(_getTotalSupply(), reserveBalance, reserveRatio, _amountProduct);
      //4% is the platform transaction fee
      uint256 fee = price.mul(4e12).div(1e14);
      return (price, fee);
    }

  function _buyReturn(uint256 _amountReserve)
    internal view virtual returns (uint32, uint)
  {
    uint value = _amountReserve.mul(1e12).div(1.04e12);
    //4% is the platform transaction fee
    uint fee = value.mul(4e12).div(1e14);
    uint32 amount = bondingCurve.calculatePurchaseReturn(_getTotalSupply(), reserveBalance, reserveRatio, value.sub(fee));
    return (amount, fee);
  }

  /**
   * @dev Function that computes number of product tokens one can buy given an amount in reserve token.
   *
   * @param  _amountReserve          purchaing amount in reserve token (dai)(with 4% platform fee)
   * @return mintAmount              number of tokens in traded token that can be purchased by given amount.
  */
  function calculateBuyReturn(uint256 _amountReserve)
    public view virtual returns (uint32 mintAmount)
  {
    (uint32 amount,) = _buyReturn(_amountReserve);
    return amount;
  }

  function _sellReturn(uint32 _amountProduct)
    internal view virtual returns (uint256, uint256)
  {
    // ppm of 98%. 2% is the platform transaction fee
    uint reimburseAmount = bondingCurve.calculateSaleReturn(_getTotalSupply(), reserveBalance, reserveRatio, _amountProduct);
    uint fee = reimburseAmount.mul(2e10).div(1e12);
    return (reimburseAmount, fee);
  }

  /**
   * @dev Function that computes selling price in reserve tokens given an amount in traded token.
   *
   * @param  _amountProduct          selling amount in product token
   * @return soldAmount              total amount that will be transferred to the seller (with 2% platform fee).
  */
  function calculateSellReturn(uint32 _amountProduct)
    public view virtual returns (uint256 soldAmount)
  {
    (uint reimburseAmount, uint fee) = _sellReturn(_amountProduct);
    return reimburseAmount.sub(fee);
  }

   /**
   * @dev calculates the return for a given conversion (in product token)
   * This function validate whether is enough to purchase token.
   * If enough, the function will deduct, and then mint one token for the user. Any extras are return as change.
   * If not enough, will return as change directly
   * then replace the _amount with the actual amount and proceed with the above logic.
   *
   * @param _deposit              reserve token deposited
   *
   * @return token                amount bought in product token
   * @return change               amount of change in reserve tokens.
   * @return price
   * @return fee
  */
  function _buy(uint256 _deposit)
    internal virtual returns (uint32, uint256, uint256, uint256)
  {
  	require(getAvailability() > 0, "Sorry, this token is sold out.");
    require(_deposit > 0, "Deposit must be non-zero.");

    (uint price, uint fee ) = _getPriceForN(1);

    if (price > _deposit) {
      return (0, _deposit, 0, 0);
    }
    _mint(msg.sender, 1);
    reserveBalance = reserveBalance.add(price);
    emit Buy(msg.sender, 1, price.add(fee));
    return (1, _deposit.sub(price).sub(fee), price, fee);
  }

   /**
   * @dev calculates the return for a given conversion (in the reserve token)
   * This function will try to compute the amount of liquidity one gets by selling _amount token,
   * then it will initiate a transfer.
   *
   * @param _amount              amount of product token wishes to be sold
   *
   * @return amount               amount sold in reserved token
   * @return fee
  */
  function _sellForAmount(uint32 _amount)
    internal virtual returns (uint256, uint256)
  {
  	require(_amount > 0, "Amount must be non-zero.");
    require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to sell.");
    // calculate amount of liquidity to reimburse
  	(uint256 reimburseAmount, uint256 fee) = _sellReturn(_amount);
 		reserveBalance = reserveBalance.sub(reimburseAmount);
    _burn(msg.sender, _amount);

    emit Sell(msg.sender, _amount, reimburseAmount);
    return (reimburseAmount.sub(fee), fee);
  }

  function calculateTradinReturn(uint32 _amount)
    public view virtual returns (uint256)
  {
  	require(_amount > 0, "invalid amount");
    uint32 supply = uint32(uint256(_amount).add(uint256(tradeinCount)).add(uint256(supplyOffset)));
  	return bondingCurve.calculateSaleReturn(supply, tradeinReserveBalance, reserveRatio, _amount);
  }


  /**
   * @dev used to update the status of redemption to "User Complete" after an escrow process has been started.
   *
   * @param buyer                 the wallet address of product buyer
   * @param id                    the id of the escrow, returned to the user after starting of redemption process
  */
  function updateUserCompleted(address buyer, uint256 id) external virtual {
    require(msg.sender == owner() || msg.sender == _manager, 'permission denied');
    require(buyer != address(0), "Invalid buyer");
    _updateUserCompleted(buyer, id);
  }

  /**
   * @dev used to update the status of redemption to "User Refunded" after an escrow process has been started.
   *
   * @param buyer                 the wallet address of product buyer
   * @param id                    the id of the escrow, returned to the user after starting of redemption process
  */
  function updateUserRefund(address buyer, uint256 id) external virtual{
    require(msg.sender == owner() || msg.sender == _manager, 'permission denied');
    require(buyer != address(0), "Invalid buyer");
    uint256 value = _updateUserRefund(buyer, id);
    require(value >0 , "Invalid value");
    _refund(buyer, value);
  }

  /**
   * @dev refund function.
   * This function returns the equivalent amount of Dai (reserve currency) to a product owner if an redemption fails
   * This is only triggered in the extremely rare cases.
   * This function is not implemented in Version 0 of Product Token
   *
   * @param _buyer       The wallet address of the owner whose product token is under the redemption process
   * @param _value       The market value of the token being redeemed
  */
  function _refund(address _buyer, uint256 _value) internal virtual {
    // override
  }

  function setManager(address addr_) external virtual onlyOwner {
    require(addr_ != address(0), 'invalid address');
    _manager = addr_;
  }

  function getManager() external view virtual returns(address) {
    return _manager;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Escrow {

  /**
     * @dev this is the enum representation of shipping status.
     * INITIAL                When an escrow has been created
     * AWAITING_PROCESSING    When an escrow has been locked and product is in transit
     * COMPLETE_USER_REFUND   When an product shipment has failed and user refund is happening
     * COMPLETE               When an shipment is delivered successfully
  */
  enum escrowState {
    INITIAL,
    AWAITING_PROCESSING,
    COMPLETE_USER_REFUND,
    COMPLETE
  }

  /**
     * @dev this is the struct class of escrow.
     * state                  The current shipping status
     * amount                 The amount of token being redeemed
     * value                  The actual reserve token being locked up
  */
  struct escrowInfo {
    escrowState state;
    uint32 amount;
    uint256 value;
  }

  mapping(address => escrowInfo[]) public escrowList;       // A list of user to escrow being saved

  event escrowStateUpdated(address, uint256, escrowInfo);   // Event that's fired when a new redeem request has been created.

  /**
     * @dev Create a new escrow and add it to the list of pending escrows.
     *
     * @param _amount        The amount of tokens being redeemed
     * @param _value         The value of the product in reserve token
     * @return               The id of the escrow created
  */
  function _addEscrow(uint32 _amount, uint256 _value) internal virtual returns (uint256){
    require(_amount > 0, 'Invalid Amount');
    escrowInfo memory info;
    info.state = escrowState.AWAITING_PROCESSING;
    info.amount = _amount;
    info.value = _value;
    escrowList[msg.sender].push(info);
    uint256 _id = escrowList[msg.sender].length -1;
    emit escrowStateUpdated(msg.sender, _id, info);
    return _id;
  }

  /**
     * @dev Update state for the redemption process to completed
     * This is triggered by our backend after shipment partner has confirmed delivery
     *
     * @param _buyer        The wallet address of the user
     * @param _id           The cached id of the escrow, retrieved from database
  */
  function _updateUserCompleted(address _buyer, uint256 _id) internal virtual {
    require(_id >=  0 || _id < escrowList[_buyer].length, "Invalid id");
    require(!isStateCompleted(escrowList[_buyer][_id].state), "already completed");

    escrowList[_buyer][_id].state = escrowState.COMPLETE;
    emit escrowStateUpdated(_buyer, _id, escrowList[_buyer][_id]);
  }

  /**
     * @dev Update state for the redemption process to refunded
     * This is triggered by our backend after shipment partner has confirmed deilvery failed
     *
     * @param _buyer        The wallet address of the user
     * @param _id           The cached id of the escrow, retrieved from database
     * @return              The amount of reserve currency in dai that needs to be refunded.
  */
  function _updateUserRefund(address _buyer, uint256 _id) internal virtual returns (uint) {
    require(_id >=  0 || _id < escrowList[_buyer].length, "Invalid id");
    require(!isStateCompleted(escrowList[_buyer][_id].state), "already completed");

    escrowList[_buyer][_id].state = escrowState.COMPLETE_USER_REFUND;
    emit escrowStateUpdated(_buyer, _id, escrowList[_buyer][_id]);
    return escrowList[_buyer][_id].value;
  }

  /**
     * @dev Helper function to check whether a escrow state is completed
     *
     * @param _state       The state to be checked
  */
  function isStateCompleted(escrowState _state) public pure virtual returns (bool) {
    return _state == escrowState.COMPLETE ||
         _state == escrowState.COMPLETE_USER_REFUND;
  }

  /**
     * @dev Return the list of all escrows created for a certain user
     *
     * @param _buyer       The address of the buyer
     * @return             A list of past escrows
  */
  function getEscrowHistory(address _buyer) external view virtual returns (escrowInfo [] memory) {
    return escrowList[_buyer];
  }

  /** 
     * @dev Get status of a particular redemption process
     *
     * @param _buyer       The address of the buyer
     * @param _id          The cached id of the escrow, retrieved from database
     * @return             The current status
  */
  function getRedeemStatus(address _buyer, uint256 _id) external view virtual returns (escrowState) {
    require(_id >=  0 || _id < escrowList[_buyer].length, "Invalid id");
    return escrowList[_buyer][_id].state;
  }

}