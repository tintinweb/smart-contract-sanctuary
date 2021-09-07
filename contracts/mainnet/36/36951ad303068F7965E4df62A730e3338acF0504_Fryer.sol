/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// Dependency file: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity >=0.6.2 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: contracts/interfaces/IChainlink.sol

// pragma solidity >=0.6.5 <0.8.0;
interface IChainlink {
  function latestAnswer() external view returns (int256);
}

// Dependency file: contracts/interfaces/IFryerConfig.sol

// pragma solidity >=0.6.5 <0.8.0;

interface IFryerConfig {
    function getConfigValue(bytes32 _name) external view returns (uint256);

    function PERCENT_DENOMINATOR() external view returns (uint256);

    function ZERO_ADDRESS() external view returns (address);
}


// Dependency file: contracts/interfaces/IVaultAdapter.sol

// pragma solidity >=0.6.5 <0.8.0;

/// Interface for all Vault Adapter implementations.
interface IVaultAdapter {

  /// @dev Gets the token that the adapter accepts.
  function token() external view returns (address);

  /// @dev The total value of the assets deposited into the vault.
  function totalValue() external view returns (uint256);

  /// @dev Deposits funds into the vault.
  ///
  /// @param _amount  the amount of funds to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Attempts to withdraw funds from the wrapped vault.
  ///
  /// The amount withdrawn to the recipient may be less than the amount requested.
  ///
  /// @param _recipient the recipient of the funds.
  /// @param _amount    the amount of funds to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;
}

// Dependency file: contracts/interfaces/IOven.sol

// pragma solidity >=0.6.5 <0.8.0;




interface IOven {
    function distribute (address origin, uint256 amount) external;
}

// Dependency file: contracts/interfaces/IMintableERC20.sol

// pragma solidity >=0.6.5 <0.8.0;


interface IMintableERC20 {
  function mint(address _recipient, uint256 _amount) external;
  function burnFrom(address account, uint256 amount) external;
  function lowerHasMinted(uint256 amount)external;
}


// Dependency file: contracts/interfaces/IDetailedERC20.sol

// pragma solidity >=0.6.5 <0.8.0;

interface IDetailedERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


// Dependency file: contracts/interfaces/IERC3156FlashBorrower.sol

// pragma solidity >=0.6.0 <=0.8.0;


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


// Dependency file: contracts/interfaces/IERC3156FlashLender.sol

// pragma solidity >=0.6.0 <=0.8.0;
// import "contracts/interfaces/IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

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

// Dependency file: contracts/libraries/Upgradable.sol

// pragma solidity >=0.6.5 <0.8.0;

contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() public {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, "FORBIDDEN");
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), "INVALID_ADDRESS");
        require(_newImpl != impl, "NO_CHANGE");
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(
        address indexed _oldGovernor,
        address indexed _newGovernor
    );

    constructor() public {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, "FORBIDDEN");
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), "INVALID_ADDRESS");
        require(_newGovernor != governor, "NO_CHANGE");
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}


// Dependency file: contracts/libraries/FixedPointMath.sol

// pragma solidity >=0.6.5 <0.8.0;


library FixedPointMath {
  uint256 public constant DECIMALS = 18;
  uint256 public constant SCALAR = 10**DECIMALS;

  struct uq192x64 {
    uint256 x;
  }

  function fromU256(uint256 value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require(value == 0 || (x = value * SCALAR) / SCALAR == value);
    return uq192x64(x);
  }

  function maximumValue() internal pure returns (uq192x64 memory) {
    return uq192x64(uint256(-1));
  }

  function add(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require((x = self.x + value.x) >= self.x);
    return uq192x64(x);
  }

  function add(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    return add(self, fromU256(value));
  }

  function sub(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require((x = self.x - value.x) <= self.x);
    return uq192x64(x);
  }

  function sub(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    return sub(self, fromU256(value));
  }

  function mul(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    uint256 x;
    require(value == 0 || (x = self.x * value) / value == self.x);
    return uq192x64(x);
  }

  function div(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
    require(value != 0);
    return uq192x64(self.x / value);
  }

  function cmp(uq192x64 memory self, uq192x64 memory value) internal pure returns (int256) {
    if (self.x < value.x) {
      return -1;
    }

    if (self.x > value.x) {
      return 1;
    }

    return 0;
  }

  function decode(uq192x64 memory self) internal pure returns (uint256) {
    return self.x / SCALAR;
  }
}

// Dependency file: contracts/libraries/TransferHelper.sol

// pragma solidity >=0.6.5 <0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/libraries/Vault.sol

// pragma solidity >=0.6.5 <0.8.0;

// import '/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/math/SafeMath.sol';
// import '/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import 'contracts/interfaces/IVaultAdapter.sol';
// import 'contracts/libraries/TransferHelper.sol';

/// @title Pool
///
/// @dev A library which provides the Vault data struct and associated functions.
library Vault {
	using Vault for Data;
	using Vault for List;
	using TransferHelper for address;
	using SafeMath for uint256;

	struct Data {
		IVaultAdapter adapter;
		uint256 totalDeposited;
	}

	struct List {
		Data[] elements;
	}

	/// @dev Gets the total amount of assets deposited in the vault.
	///
	/// @return the total assets.
	function totalValue(Data storage _self) internal view returns (uint256) {
		return _self.adapter.totalValue();
	}

	/// @dev Gets the token that the vault accepts.
	///
	/// @return the accepted token.
	function token(Data storage _self) internal view returns (address) {
		return _self.adapter.token();
	}

	/// @dev Deposits funds from the caller into the vault.
	///
	/// @param _amount the amount of funds to deposit.
	function deposit(Data storage _self, uint256 _amount) internal returns (uint256) {
		// Push the token that the vault accepts onto the stack to save gas.
		address _token = _self.token();
		_token.safeTransfer(address(_self.adapter), _amount);
		_self.adapter.deposit(_amount);
		_self.totalDeposited = _self.totalDeposited.add(_amount);

		return _amount;
	}

	/// @dev Withdraw deposited funds from the vault.
	///
	/// @param _recipient the account to withdraw the tokens to.
	/// @param _amount    the amount of tokens to withdraw.
	function withdraw(
		Data storage _self,
		address _recipient,
		uint256 _amount
	) internal returns (uint256, uint256) {
		(uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _amount);
		_self.totalDeposited = _self.totalDeposited.sub(_decreasedValue);
		return (_withdrawnAmount, _decreasedValue);
	}

	/// @dev Directly withdraw deposited funds from the vault.
	///
	/// @param _recipient the account to withdraw the tokens to.
	/// @param _amount    the amount of tokens to withdraw.
	function directWithdraw(
		Data storage _self,
		address _recipient,
		uint256 _amount
	) internal returns (uint256, uint256) {
		address _token = _self.token();

		uint256 _startingBalance = IERC20(_token).balanceOf(_recipient);
		uint256 _startingTotalValue = _self.totalValue();

		_self.adapter.withdraw(_recipient, _amount);

		uint256 _endingBalance = IERC20(_token).balanceOf(_recipient);
		uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

		uint256 _endingTotalValue = _self.totalValue();
		uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

		return (_withdrawnAmount, _decreasedValue);
	}

	/// @dev Withdraw all the deposited funds from the vault.
	///
	/// @param _recipient the account to withdraw the tokens to.
	function withdrawAll(Data storage _self, address _recipient) internal returns (uint256, uint256) {
		return _self.withdraw(_recipient, _self.totalDeposited);
	}

	/// @dev Harvests yield from the vault.
	///
	/// @param _recipient the account to withdraw the harvested yield to.
	function harvest(Data storage _self, address _recipient) internal returns (uint256, uint256) {
		if (_self.totalValue() <= _self.totalDeposited) {
			return (0, 0);
		}
		uint256 _withdrawAmount = _self.totalValue().sub(_self.totalDeposited);
		return _self.directWithdraw(_recipient, _withdrawAmount);
	}

	/// @dev Adds a element to the list.
	///
	/// @param _element the element to add.
	function push(List storage _self, Data memory _element) internal {
		for (uint256 i = 0; i < _self.elements.length; i++) {
			// Avoid duplicated adapter
			require(address(_element.adapter) != address(_self.elements[i].adapter), '!Repeat adapter');
		}
		_self.elements.push(_element);
	}

	/// @dev Gets a element from the list.
	///
	/// @param _index the index in the list.
	///
	/// @return the element at the specified index.
	function get(List storage _self, uint256 _index) internal view returns (Data storage) {
		return _self.elements[_index];
	}

	/// @dev Gets the last element in the list.
	///
	/// This function will revert if there are no elements in the list.
	///
	/// @return the last element in the list.
	function last(List storage _self) internal view returns (Data storage) {
		return _self.elements[_self.lastIndex()];
	}

	/// @dev Gets the index of the last element in the list.
	///
	/// This function will revert if there are no elements in the list.
	///
	/// @return the index of the last element.
	function lastIndex(List storage _self) internal view returns (uint256) {
		uint256 _length = _self.length();
		return _length.sub(1, 'Vault.List: empty');
	}

	/// @dev Gets the number of elements in the list.
	///
	/// @return the number of elements.
	function length(List storage _self) internal view returns (uint256) {
		return _self.elements.length;
	}
}


// Dependency file: contracts/libraries/ConfigNames.sol

// pragma solidity >=0.6.5 <0.8.0;

library ConfigNames {
    bytes32 public constant FRYER_LTV = bytes32("FRYER_LTV");
    bytes32 public constant FRYER_HARVEST_FEE = bytes32("FRYER_HARVEST_FEE");
    bytes32 public constant FRYER_VAULT_PERCENTAGE =
        bytes32("FRYER_VAULT_PERCENTAGE");

    bytes32 public constant FRYER_FLASH_FEE_PROPORTION =
        bytes32("FRYER_FLASH_FEE_PROPORTION");

    bytes32 public constant PRIVATE = bytes32("PRIVATE");
    bytes32 public constant STAKE = bytes32("STAKE");
}


// Dependency file: contracts/libraries/CDP.sol

// pragma solidity >=0.6.5 <0.8.0;

// import '/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/math/SafeMath.sol';
// import 'contracts/libraries/FixedPointMath.sol';
// import 'contracts/libraries/TransferHelper.sol';
// import 'contracts/libraries/ConfigNames.sol';
// import 'contracts/interfaces/IFryerConfig.sol';

library CDP {
	using CDP for Data;
	using FixedPointMath for FixedPointMath.uq192x64;
	using SafeMath for uint256;

	uint256 public constant MAXIMUM_COLLATERALIZATION_LIMIT = 4000000000000000000;

	struct Context {
		IFryerConfig fryerConfig;
		FixedPointMath.uq192x64 accumulatedYieldWeight;
	}

	struct Data {
		uint256 totalDeposited;
		uint256 totalDebt;
		uint256 totalCredit;
		uint256 lastDeposit;
		FixedPointMath.uq192x64 lastAccumulatedYieldWeight;
	}

	function update(Data storage _self, Context storage _ctx) internal {
		uint256 _earnedYield = _self.getEarnedYield(_ctx);
		if (_earnedYield > _self.totalDebt) {
			uint256 _currentTotalDebt = _self.totalDebt;
			_self.totalDebt = 0;
			_self.totalCredit = _earnedYield.sub(_currentTotalDebt);
		} else {
			_self.totalCredit = 0;
			_self.totalDebt = _self.totalDebt.sub(_earnedYield);
		}
		_self.lastAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
	}

	function checkHealth(
		Data storage _self,
		Context storage _ctx,
		string memory _msg
	) internal view {
		require(_self.isHealthy(_ctx), _msg);
	}

	function isHealthy(Data storage _self, Context storage _ctx) internal view returns (bool) {
		return collateralizationLimit(_ctx).cmp(_self.getCollateralizationRatio(_ctx)) <= 0;
	}

	function collateralizationLimit(Context storage _ctx) internal view returns (FixedPointMath.uq192x64 memory) {
		return
			FixedPointMath.uq192x64(
				MAXIMUM_COLLATERALIZATION_LIMIT.mul(_ctx.fryerConfig.getConfigValue(ConfigNames.FRYER_LTV)).div(
					_ctx.fryerConfig.PERCENT_DENOMINATOR()
				)
			);
	}

	function getUpdatedTotalDebt(Data storage _self, Context storage _ctx) internal view returns (uint256) {
		uint256 _unclaimedYield = _self.getEarnedYield(_ctx);
		if (_unclaimedYield == 0) {
			return _self.totalDebt;
		}

		uint256 _currentTotalDebt = _self.totalDebt;
		if (_unclaimedYield >= _currentTotalDebt) {
			return 0;
		}

		return _currentTotalDebt.sub(_unclaimedYield);
	}

	function getUpdatedTotalCredit(Data storage _self, Context storage _ctx) internal view returns (uint256) {
		uint256 _unclaimedYield = _self.getEarnedYield(_ctx);
		if (_unclaimedYield == 0) {
			return _self.totalCredit;
		}

		uint256 _currentTotalDebt = _self.totalDebt;
		if (_unclaimedYield <= _currentTotalDebt) {
			return 0;
		}

		return _self.totalCredit.add(_unclaimedYield.sub(_currentTotalDebt));
	}

	function getEarnedYield(Data storage _self, Context storage _ctx) internal view returns (uint256) {
		FixedPointMath.uq192x64 memory _currentAccumulatedYieldWeight = _ctx.accumulatedYieldWeight;
		FixedPointMath.uq192x64 memory _lastAccumulatedYieldWeight = _self.lastAccumulatedYieldWeight;

		if (_currentAccumulatedYieldWeight.cmp(_lastAccumulatedYieldWeight) == 0) {
			return 0;
		}

		return _currentAccumulatedYieldWeight.sub(_lastAccumulatedYieldWeight).mul(_self.totalDeposited).decode();
	}

	function getCollateralizationRatio(Data storage _self, Context storage _ctx)
		internal
		view
		returns (FixedPointMath.uq192x64 memory)
	{
		uint256 _totalDebt = _self.getUpdatedTotalDebt(_ctx);
		if (_totalDebt == 0) {
			return FixedPointMath.maximumValue();
		}
		return FixedPointMath.fromU256(_self.totalDeposited).div(_totalDebt);
	}
}


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/ERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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


// Dependency file: contracts/libraries/Convert.sol

// pragma solidity >=0.6.5 <0.8.0;

// pragma experimental ABIEncoderV2;

// import '/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/math/SafeMath.sol';

contract Convert {
	using SafeMath for uint256;

	function convertTokenAmount(
		address _fromToken,
		address _toToken,
		uint256 _fromAmount
	) public view returns (uint256 toAmount) {
		uint256 fromDecimals = uint256(ERC20(_fromToken).decimals());
		uint256 toDecimals = uint256(ERC20(_toToken).decimals());
		if (fromDecimals > toDecimals) {
			toAmount = _fromAmount.div(10**(fromDecimals.sub(toDecimals)));
		} else if (toDecimals > fromDecimals) {
			toAmount = _fromAmount.mul(10**(toDecimals.sub(fromDecimals)));
		} else {
			toAmount = _fromAmount;
		}
		return toAmount;
	}
}


// Dependency file: contracts/libraries/NoDelegateCall.sol

// pragma solidity >=0.6.5 <0.8.0;


/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() public {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// Root file: contracts/Fryer.sol

pragma solidity >=0.6.5 <0.8.0;

pragma experimental ABIEncoderV2;

// import "/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/math/Math.sol";
// import "/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/utils/Address.sol";
// import "/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/math/SafeMath.sol";
// import "/Users/sg99022ml/Desktop/chfry-protocol-internal/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "contracts/interfaces/IChainlink.sol";
// import "contracts/interfaces/IFryerConfig.sol";
// import "contracts/interfaces/IVaultAdapter.sol";
// import "contracts/interfaces/IOven.sol";
// import "contracts/interfaces/IMintableERC20.sol";
// import "contracts/interfaces/IDetailedERC20.sol";
// import "contracts/interfaces/IERC3156FlashLender.sol";
// import "contracts/interfaces/IERC3156FlashBorrower.sol";
// import "contracts/libraries/Upgradable.sol";
// import "contracts/libraries/FixedPointMath.sol";
// import "contracts/libraries/Vault.sol";
// import "contracts/libraries/CDP.sol";
// import "contracts/libraries/TransferHelper.sol";
// import "contracts/libraries/ConfigNames.sol";
// import "contracts/libraries/Convert.sol";
// import "contracts/libraries/NoDelegateCall.sol";

contract Fryer is
    ReentrancyGuard,
    UpgradableProduct,
    IERC3156FlashLender,
    Convert,
    NoDelegateCall
{
    using CDP for CDP.Data;
    using FixedPointMath for FixedPointMath.uq192x64;
    using Vault for Vault.Data;
    using Vault for Vault.List;
    using TransferHelper for address;
    using SafeMath for uint256;
    using Address for address;

    event OvenUpdated(address indexed newOven);
    event ConfigUpdated(address indexed newConfig);
    event RewardsUpdated(address indexed reward);
    event EmergencyExitUpdated(bool indexed emergencyExit);
    event ActiveVaultUpdated(address indexed adapter);
    event FundsHarvested(
        uint256 indexed harvestedAmount,
        uint256 indexed decreasedValue
    );
    event FundsFlushed(uint256 indexed depositedAmount);
    event TokensDeposited(address indexed user, uint256 indexed amount);
    event TokensWithdrawn(
        address indexed user,
        uint256 indexed amount,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );
    event TokensRepaid(
        address indexed user,
        uint256 indexed parentAmount,
        uint256 indexed childAmount
    );
    event TokensLiquidated(
        address indexed user,
        uint256 indexed amount,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );
    event FundsRecalled(
        uint256 indexed vaultId,
        uint256 withdrawnAmount,
        uint256 decreasedValue
    );
    event UseFlashloan(
        address indexed user,
        address token,
        uint256 amount,
        uint256 fee
    );

    bytes32 public constant FLASH_CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    // DAI/USDT/USDC
    address public token;

    // FiresToken
    address public friesToken;

    address public oven;

    address public rewards;

    uint256 public totalDeposited;

    uint256 public flushActivator;

    bool public initialized;

    bool public emergencyExit;

    CDP.Context private _ctx;

    mapping(address => CDP.Data) private _cdps;

    Vault.List private _vaults;

    address public _linkGasOracle;

    uint256 public pegMinimum;

    IFryerConfig public fryerConfig;

    constructor(
        address _token,
        address _friesToken,
        address _fryerConfig
    ) public {
        token = _token;
        friesToken = _friesToken;
        flushActivator = 100000 * 10**uint256(IDetailedERC20(token).decimals());
        fryerConfig = IFryerConfig(_fryerConfig);
        _ctx.fryerConfig = fryerConfig;
        _ctx.accumulatedYieldWeight = FixedPointMath.uq192x64(0);
    }

    modifier expectInitialized() {
        require(initialized, "not initialized.");
        _;
    }

    function setOven(address _oven) external requireImpl {
        require(
            _oven != fryerConfig.ZERO_ADDRESS(),
            "oven address cannot be 0x0."
        );
        oven = _oven;
        emit OvenUpdated(_oven);
    }

    function setConfig(address _config) external requireImpl {
        require(
            _config != fryerConfig.ZERO_ADDRESS(),
            "config address cannot be 0x0."
        );
        fryerConfig = IFryerConfig(_config);
        _ctx.fryerConfig = fryerConfig;
        emit ConfigUpdated(_config);
    }

    function setFlushActivator(uint256 _flushActivator) external requireImpl {
        flushActivator = _flushActivator;
    }

    function setRewards(address _rewards) external requireImpl {
        require(
            _rewards != fryerConfig.ZERO_ADDRESS(),
            "rewards address cannot be 0x0."
        );
        rewards = _rewards;
        emit RewardsUpdated(_rewards);
    }

    function setOracleAddress(address Oracle, uint256 peg)
        external
        requireImpl
    {
        _linkGasOracle = Oracle;
        pegMinimum = peg;
    }

    function setEmergencyExit(bool _emergencyExit) external requireImpl {
        emergencyExit = _emergencyExit;

        emit EmergencyExitUpdated(_emergencyExit);
    }

    function collateralizationLimit()
        external
        view
        returns (FixedPointMath.uq192x64 memory)
    {
        return CDP.collateralizationLimit(_ctx);
    }

    function initialize(address _adapter) external requireImpl {
        require(!initialized, "already initialized");
        require(
            oven != fryerConfig.ZERO_ADDRESS(),
            "cannot initialize oven address to 0x0"
        );
        require(
            rewards != fryerConfig.ZERO_ADDRESS(),
            "cannot initialize rewards address to 0x0"
        );
        _updateActiveVault(_adapter);
        initialized = true;
    }

    function migrate(address _adapter) external expectInitialized requireImpl {
        _updateActiveVault(_adapter);
    }

    function _updateActiveVault(address _adapter) internal {
        require(
            _adapter != fryerConfig.ZERO_ADDRESS(),
            "active vault address cannot be 0x0."
        );
        IVaultAdapter adapter = IVaultAdapter(_adapter);
        require(adapter.token() == token, "token mismatch.");
        _vaults.push(Vault.Data({adapter: adapter, totalDeposited: 0}));
        emit ActiveVaultUpdated(_adapter);
    }

    function harvest(uint256 _vaultId)
        external
        expectInitialized
        returns (uint256, uint256)
    {
        Vault.Data storage _vault = _vaults.get(_vaultId);

        (uint256 _harvestedAmount, uint256 _decreasedValue) =
            _vault.harvest(address(this));

        _incomeDistribution(_harvestedAmount);

        emit FundsHarvested(_harvestedAmount, _decreasedValue);

        return (_harvestedAmount, _decreasedValue);
    }

    function _incomeDistribution(uint256 amount) internal {
        if (amount > 0) {
            uint256 feeRate = fryerConfig.getConfigValue(ConfigNames.FRYER_HARVEST_FEE);
            uint256 _feeAmount =  amount.mul(feeRate).div(fryerConfig.PERCENT_DENOMINATOR());
            uint256 _distributeAmount = amount.sub(_feeAmount);

            if (totalDeposited > 0) {
                FixedPointMath.uq192x64 memory _weight =
                    FixedPointMath.fromU256(_distributeAmount).div(
                        totalDeposited
                    );
                _ctx.accumulatedYieldWeight = _ctx.accumulatedYieldWeight.add(
                    _weight
                );
            }

            if (_feeAmount > 0) {
                token.safeTransfer(rewards, _feeAmount);
            }

            if (_distributeAmount > 0) {
                _distributeToOven(_distributeAmount);
            }
        }
    }

    function recall(uint256 _vaultId, uint256 _amount)
        external
        nonReentrant
        expectInitialized
        returns (uint256, uint256)
    {
        return _recallFunds(_vaultId, _amount);
    }

    function recallAll(uint256 _vaultId)
        external
        nonReentrant
        expectInitialized
        returns (uint256, uint256)
    {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _recallFunds(_vaultId, _vault.totalDeposited);
    }

    function flush() external nonReentrant expectInitialized returns (uint256) {
        require(!emergencyExit, "emergency pause enabled");

        return flushActiveVault();
    }

    function flushActiveVault() internal returns (uint256) {
        Vault.Data storage _activeVault = _vaults.last();
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 ratio = fryerConfig.getConfigValue(ConfigNames.FRYER_VAULT_PERCENTAGE);
        uint256 pendingTotal =
            balance.add(_activeVault.totalDeposited).mul(ratio)
                .div(fryerConfig.PERCENT_DENOMINATOR());
        if (pendingTotal > _activeVault.totalDeposited) {
            uint256 _depositedAmount =
                _activeVault.deposit(
                    pendingTotal.sub(_activeVault.totalDeposited)
                );
            emit FundsFlushed(_depositedAmount);
            return _depositedAmount;
        } else {
            return 0;
        }
    }

    function deposit(uint256 _amount)
        external
        nonReentrant
        noDelegateCall
        noContractAllowed
        expectInitialized
    {
        require(!emergencyExit, "emergency pause enabled");

        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        token.safeTransferFrom(msg.sender, address(this), _amount);

        totalDeposited = totalDeposited.add(_amount);

        _cdp.totalDeposited = _cdp.totalDeposited.add(_amount);
        _cdp.lastDeposit = block.number;

        if (_amount >= flushActivator) {
            flushActiveVault();
        }

        emit TokensDeposited(msg.sender, _amount);
    }

    function withdraw(uint256 _amount)
        external
        nonReentrant
        noDelegateCall
        noContractAllowed
        expectInitialized
        returns (uint256, uint256)
    {
        CDP.Data storage _cdp = _cdps[msg.sender];
        require(block.number > _cdp.lastDeposit, "");

        _cdp.update(_ctx);

        (uint256 _withdrawnAmount, uint256 _decreasedValue) =
            _withdrawFundsTo(msg.sender, _amount);

        _cdp.totalDeposited = _cdp.totalDeposited.sub(
            _decreasedValue,
            "Exceeds withdrawable amount"
        );
        _cdp.checkHealth(
            _ctx,
            "Action blocked: unhealthy collateralization ratio"
        );
        if (_amount >= flushActivator) {
            flushActiveVault();
        }
        emit TokensWithdrawn(
            msg.sender,
            _amount,
            _withdrawnAmount,
            _decreasedValue
        );

        return (_withdrawnAmount, _decreasedValue);
    }

    function repay(uint256 _parentAmount, uint256 _childAmount)
        external
        nonReentrant
        noDelegateCall
        noContractAllowed
        onLinkCheck
        expectInitialized
    {
        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        if (_parentAmount > 0) {
            token.safeTransferFrom(msg.sender, address(this), _parentAmount);
            _distributeToOven(_parentAmount);
        }

        uint256 childAmount_ =
            convertTokenAmount(friesToken, token, _childAmount);
        // friesUsd convert USDT/DAI/USDC > 0
        if (childAmount_ > 0) {
            IMintableERC20(friesToken).burnFrom(msg.sender, _childAmount);
            IMintableERC20(friesToken).lowerHasMinted(_childAmount);
        } else {
            _childAmount = 0;
        }

        uint256 _totalAmount = _parentAmount.add(childAmount_);
        _cdp.totalDebt = _cdp.totalDebt.sub(_totalAmount);

        emit TokensRepaid(msg.sender, _parentAmount, _childAmount);
    }

    function liquidate(uint256 _amount)
        external
        nonReentrant
        noDelegateCall
        noContractAllowed
        onLinkCheck
        expectInitialized
        returns (uint256, uint256)
    {
        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        if (_amount > _cdp.totalDebt) {
            _amount = _cdp.totalDebt;
        }
        (uint256 _withdrawnAmount, uint256 _decreasedValue) =
            _withdrawFundsTo(address(this), _amount);
        _distributeToOven(_withdrawnAmount);

        _cdp.totalDeposited = _cdp.totalDeposited.sub(_decreasedValue);
        _cdp.totalDebt = _cdp.totalDebt.sub(_withdrawnAmount);
        emit TokensLiquidated(
            msg.sender,
            _amount,
            _withdrawnAmount,
            _decreasedValue
        );

        return (_withdrawnAmount, _decreasedValue);
    }

    function borrow(uint256 _amount)
        external
        nonReentrant
        noDelegateCall
        noContractAllowed
        onLinkCheck
        expectInitialized
    {
        CDP.Data storage _cdp = _cdps[msg.sender];
        _cdp.update(_ctx);

        uint256 _totalCredit = _cdp.totalCredit;

        if (_totalCredit < _amount) {
            uint256 _remainingAmount = _amount.sub(_totalCredit);
            _cdp.totalDebt = _cdp.totalDebt.add(_remainingAmount);
            _cdp.totalCredit = 0;
            _cdp.checkHealth(_ctx, "Loan-to-value ratio breached");
        } else {
            _cdp.totalCredit = _totalCredit.sub(_amount);
        }
        uint256 mint = convertTokenAmount(token, friesToken, _amount);
        IMintableERC20(friesToken).mint(msg.sender, mint);
        if (_amount >= flushActivator) {
            flushActiveVault();
        }
    }

    function vaultCount() external view returns (uint256) {
        return _vaults.length();
    }

    function getVaultAdapter(uint256 _vaultId)
        external
        view
        returns (IVaultAdapter)
    {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _vault.adapter;
    }

    function getVaultTotalDeposited(uint256 _vaultId)
        external
        view
        returns (uint256)
    {
        Vault.Data storage _vault = _vaults.get(_vaultId);
        return _vault.totalDeposited;
    }

    function getCdpTotalDeposited(address _account)
        external
        view
        returns (uint256)
    {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.totalDeposited;
    }

    function getCdpTotalDebt(address _account) external view returns (uint256) {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.getUpdatedTotalDebt(_ctx);
    }

    function getCdpTotalCredit(address _account)
        external
        view
        returns (uint256)
    {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.getUpdatedTotalCredit(_ctx);
    }

    function getCdpLastDeposit(address _account)
        external
        view
        returns (uint256)
    {
        CDP.Data storage _cdp = _cdps[_account];
        return _cdp.lastDeposit;
    }

    function _distributeToOven(uint256 amount) internal {
        token.safeApprove(oven, amount);
        IOven(oven).distribute(address(this), amount);
        uint256 mintAmount = convertTokenAmount(token, friesToken, amount);
        IMintableERC20(friesToken).lowerHasMinted(mintAmount);
    }

    modifier onLinkCheck() {
        if (pegMinimum > 0) {
            uint256 oracleAnswer =
                uint256(IChainlink(_linkGasOracle).latestAnswer());
            require(oracleAnswer > pegMinimum, "off peg limitation");
        }
        _;
    }

    modifier noContractAllowed() {
        require(
            !address(msg.sender).isContract() && msg.sender == tx.origin,
            "Sorry we do not accept contract!"
        );
        _;
    }

    function _recallFunds(uint256 _vaultId, uint256 _amount)
        internal
        returns (uint256, uint256)
    {
        require(
            emergencyExit ||
                msg.sender == impl ||
                _vaultId != _vaults.lastIndex(),
            "not an emergency, not governance, and user does not have permission to recall funds from active vault"
        );

        Vault.Data storage _vault = _vaults.get(_vaultId);
        (uint256 _withdrawnAmount, uint256 _decreasedValue) =
            _vault.withdraw(address(this), _amount);

        emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);

        return (_withdrawnAmount, _decreasedValue);
    }

    function _withdrawFundsTo(address _recipient, uint256 _amount)
        internal
        returns (uint256, uint256)
    {
        uint256 _bufferedAmount =
            Math.min(_amount, IERC20(token).balanceOf(address(this)));

        if (_recipient != address(this)) {
            token.safeTransfer(_recipient, _bufferedAmount);
        }

        uint256 _totalWithdrawn = _bufferedAmount;
        uint256 _totalDecreasedValue = _bufferedAmount;

        uint256 _remainingAmount = _amount.sub(_bufferedAmount);
        if (_remainingAmount > 0) {
            Vault.Data storage _activeVault = _vaults.last();
            (uint256 _withdrawAmount, uint256 _decreasedValue) =
                _activeVault.withdraw(_recipient, _remainingAmount);

            _totalWithdrawn = _totalWithdrawn.add(_withdrawAmount);
            _totalDecreasedValue = _totalDecreasedValue.add(_decreasedValue);
        }

        totalDeposited = totalDeposited.sub(_totalDecreasedValue);

        return (_totalWithdrawn, _totalDecreasedValue);
    }

    // flash

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token_,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(token == token_, "FlashLender: Unsupported currency");
        uint256 _fee = _flashFee(amount);
        token.safeTransfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, _fee, data) ==
                FLASH_CALLBACK_SUCCESS,
            "FlashLender: Callback failed"
        );
        token.safeTransferFrom(
            address(receiver),
            address(this),
            amount.add(_fee)
        );

        _incomeDistribution(_fee);
        emit UseFlashloan(tx.origin, token, amount, _fee);
        return true;
    }

    function flashFee(address token_, uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        require(token == token_, "FlashLender: Unsupported currency");
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        uint256 prop =
            fryerConfig.getConfigValue(ConfigNames.FRYER_FLASH_FEE_PROPORTION);
        uint256 PERCENT_DENOMINATOR = fryerConfig.PERCENT_DENOMINATOR();
        return amount.mul(prop).div(PERCENT_DENOMINATOR);
    }

    /**
     * @dev The amount of currency available to be lended.
     * @param token_ The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token_)
        external
        view
        override
        returns (uint256)
    {
        if (token == token_) {
            return IERC20(token).balanceOf(address(this));
        } else {
            return 0;
        }
    }
}