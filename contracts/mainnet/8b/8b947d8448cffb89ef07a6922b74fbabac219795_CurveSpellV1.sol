/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IBank

interface IBank {
  /// The governor adds a new bank gets added to the system.
  event AddBank(address token, address cToken);
  /// The governor sets the address of the oracle smart contract.
  event SetOracle(address oracle);
  /// The governor sets the basis point fee of the bank.
  event SetFeeBps(uint feeBps);
  /// The governor withdraw tokens from the reserve of a bank.
  event WithdrawReserve(address user, address token, uint amount);
  /// Someone borrows tokens from a bank via a spell caller.
  event Borrow(uint positionId, address caller, address token, uint amount, uint share);
  /// Someone repays tokens to a bank via a spell caller.
  event Repay(uint positionId, address caller, address token, uint amount, uint share);
  /// Someone puts tokens as collateral via a spell caller.
  event PutCollateral(uint positionId, address caller, address token, uint id, uint amount);
  /// Someone takes tokens from collateral via a spell caller.
  event TakeCollateral(uint positionId, address caller, address token, uint id, uint amount);
  /// Someone calls liquidatation on a position, paying debt and taking collateral tokens.
  event Liquidate(
    uint positionId,
    address liquidator,
    address debtToken,
    uint amount,
    uint share,
    uint bounty
  );

  /// @dev Return the current position while under execution.
  function POSITION_ID() external view returns (uint);

  /// @dev Return the current target while under execution.
  function SPELL() external view returns (address);

  /// @dev Return the current executor (the owner of the current position).
  function EXECUTOR() external view returns (address);

  /// @dev Return bank information for the given token.
  function getBankInfo(address token)
    external
    view
    returns (
      bool isListed,
      address cToken,
      uint reserve,
      uint totalDebt,
      uint totalShare
    );

  /// @dev Return position information for the given position id.
  function getPositionInfo(uint positionId)
    external
    view
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    );

  /// @dev Return the borrow balance for given positon and token without trigger interest accrual.
  function borrowBalanceStored(uint positionId, address token) external view returns (uint);

  /// @dev Trigger interest accrual and return the current borrow balance.
  function borrowBalanceCurrent(uint positionId, address token) external returns (uint);

  /// @dev Borrow tokens from the bank.
  function borrow(address token, uint amount) external;

  /// @dev Repays tokens to the bank.
  function repay(address token, uint amountCall) external;

  /// @dev Transmit user assets to the spell.
  function transmit(address token, uint amount) external;

  /// @dev Put more collateral for users.
  function putCollateral(
    address collToken,
    uint collId,
    uint amountCall
  ) external;

  /// @dev Take some collateral back.
  function takeCollateral(
    address collToken,
    uint collId,
    uint amount
  ) external;

  /// @dev Liquidate a position.
  function liquidate(
    uint positionId,
    address debtToken,
    uint amountCall
  ) external;

  function getBorrowETHValue(uint positionId) external view returns (uint);

  function accrue(address token) external;

  function nextPositionId() external view returns (uint);

  /// @dev Return current position information.
  function getCurrentPositionInfo()
    external
    view
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    );

  function support(address token) external view returns (bool);

}

// Part: ICurvePool

interface ICurvePool {
  function add_liquidity(uint[2] calldata, uint) external;

  function add_liquidity(uint[3] calldata, uint) external;

  function add_liquidity(uint[4] calldata, uint) external;

  function remove_liquidity(uint, uint[2] calldata) external;

  function remove_liquidity(uint, uint[3] calldata) external;

  function remove_liquidity(uint, uint[4] calldata) external;

  function remove_liquidity_imbalance(uint[2] calldata, uint) external;

  function remove_liquidity_imbalance(uint[3] calldata, uint) external;

  function remove_liquidity_imbalance(uint[4] calldata, uint) external;

  function remove_liquidity_one_coin(
    uint,
    int128,
    uint
  ) external;

  function get_virtual_price() external view returns (uint);
}

// Part: ICurveRegistry

interface ICurveRegistry {
  function get_n_coins(address lp) external view returns (uint, uint);

  function pool_list(uint id) external view returns (address);

  function get_coins(address pool) external view returns (address[8] memory);

  function get_gauges(address pool) external view returns (address[10] memory, uint128[10] memory);

  function get_lp_token(address pool) external view returns (address);

  function get_pool_from_lp_token(address lp) external view returns (address);
}

// Part: IERC20Wrapper

interface IERC20Wrapper {
  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  function getUnderlyingToken(uint id) external view returns (address);

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint id) external view returns (uint);
}

// Part: IWETH

interface IWETH {
  function balanceOf(address user) external returns (uint);

  function approve(address to, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function deposit() external payable;

  function withdraw(uint) external;
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: HomoraMath

library HomoraMath {
  using SafeMath for uint;

  function divCeil(uint lhs, uint rhs) internal pure returns (uint) {
    return lhs.add(rhs).sub(1) / rhs;
  }

  function fmul(uint lhs, uint rhs) internal pure returns (uint) {
    return lhs.mul(rhs) / (2**112);
  }

  function fdiv(uint lhs, uint rhs) internal pure returns (uint) {
    return lhs.mul(2**112) / rhs;
  }

  // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
  // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
  function sqrt(uint x) internal pure returns (uint) {
    if (x == 0) return 0;
    uint xx = x;
    uint r = 1;

    if (xx >= 0x100000000000000000000000000000000) {
      xx >>= 128;
      r <<= 64;
    }

    if (xx >= 0x10000000000000000) {
      xx >>= 64;
      r <<= 32;
    }
    if (xx >= 0x100000000) {
      xx >>= 32;
      r <<= 16;
    }
    if (xx >= 0x10000) {
      xx >>= 16;
      r <<= 8;
    }
    if (xx >= 0x100) {
      xx >>= 8;
      r <<= 4;
    }
    if (xx >= 0x10) {
      xx >>= 4;
      r <<= 2;
    }
    if (xx >= 0x8) {
      r <<= 1;
    }

    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1; // Seven iterations should be enough
    uint r1 = x / r;
    return (r < r1 ? r : r1);
  }
}

// Part: OpenZeppelin/[email protected]/ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// Part: OpenZeppelin/[email protected]/IERC1155

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// Part: OpenZeppelin/[email protected]/IERC1155Receiver

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// Part: OpenZeppelin/[email protected]/Initializable

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
        return !Address.isContract(address(this));
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: Governable

contract Governable is Initializable {
  event SetGovernor(address governor);
  event SetPendingGovernor(address pendingGovernor);
  event AcceptGovernor(address governor);

  address public governor; // The current governor.
  address public pendingGovernor; // The address pending to become the governor once accepted.

  bytes32[64] _gap; // reserve space for upgrade

  modifier onlyGov() {
    require(msg.sender == governor, 'not the governor');
    _;
  }

  /// @dev Initialize using msg.sender as the first governor.
  function __Governable__init() internal initializer {
    governor = msg.sender;
    pendingGovernor = address(0);
    emit SetGovernor(msg.sender);
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
    emit SetPendingGovernor(_pendingGovernor);
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'not the pending governor');
    pendingGovernor = address(0);
    governor = msg.sender;
    emit AcceptGovernor(msg.sender);
  }
}

// Part: IWERC20

interface IWERC20 is IERC1155, IERC20Wrapper {
  /// @dev Return the underlying ERC20 balance for the user.
  function balanceOfERC20(address token, address user) external view returns (uint);

  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(address token, uint amount) external;

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(address token, uint amount) external;
}

// Part: IWLiquidityGauge

interface IWLiquidityGauge is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(
    uint pid,
    uint gid,
    uint amount
  ) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint pid);

  function crv() external returns (IERC20);

  function registry() external returns (ICurveRegistry);

  function encodeId(
    uint,
    uint,
    uint
  ) external pure returns (uint);

  function decodeId(uint id)
    external
    pure
    returns (
      uint,
      uint,
      uint
    );

  function getUnderlyingTokenFromIds(uint pid, uint gid) external view returns (address);
}

// Part: OpenZeppelin/[email protected]/ERC1155Receiver

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// Part: ERC1155NaiveReceiver

contract ERC1155NaiveReceiver is ERC1155Receiver {
  bytes32[64] __gap; // reserve space for upgrade

  function onERC1155Received(
    address, /* operator */
    address, /* from */
    uint, /* id */
    uint, /* value */
    bytes calldata /* data */
  ) external override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address, /* operator */
    address, /* from */
    uint[] calldata, /* ids */
    uint[] calldata, /* values */
    bytes calldata /* data */
  ) external override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}

// Part: BasicSpell

abstract contract BasicSpell is ERC1155NaiveReceiver {
  using SafeERC20 for IERC20;

  IBank public immutable bank;
  IWERC20 public immutable werc20;
  address public immutable weth;

  mapping(address => mapping(address => bool)) public approved; // Mapping from token to (mapping from spender to approve status)

  constructor(
    IBank _bank,
    address _werc20,
    address _weth
  ) public {
    bank = _bank;
    werc20 = IWERC20(_werc20);
    weth = _weth;
    ensureApprove(_weth, address(_bank));
    IWERC20(_werc20).setApprovalForAll(address(_bank), true);
  }

  /// @dev Ensure that the spell has approved the given spender to spend all of its tokens.
  /// @param token The token to approve.
  /// @param spender The spender to allow spending.
  /// NOTE: This is safe because spell is never built to hold fund custody.
  function ensureApprove(address token, address spender) internal {
    if (!approved[token][spender]) {
      IERC20(token).safeApprove(spender, uint(-1));
      approved[token][spender] = true;
    }
  }

  /// @dev Internal call to convert msg.value ETH to WETH inside the contract.
  function doTransmitETH() internal {
    if (msg.value > 0) {
      IWETH(weth).deposit{value: msg.value}();
    }
  }

  /// @dev Internal call to transmit tokens from the bank if amount is positive.
  /// @param token The token to perform the transmit action.
  /// @param amount The amount to transmit.
  /// @notice Do not use `amount` input argument to handle the received amount.
  function doTransmit(address token, uint amount) internal {
    if (amount > 0) {
      bank.transmit(token, amount);
    }
  }

  /// @dev Internal call to refund tokens to the current bank executor.
  /// @param token The token to perform the refund action.
  function doRefund(address token) internal {
    uint balance = IERC20(token).balanceOf(address(this));
    if (balance > 0) {
      IERC20(token).safeTransfer(bank.EXECUTOR(), balance);
    }
  }

  /// @dev Internal call to refund all WETH to the current executor as native ETH.
  function doRefundETH() internal {
    uint balance = IWETH(weth).balanceOf(address(this));
    if (balance > 0) {
      IWETH(weth).withdraw(balance);
      (bool success, ) = bank.EXECUTOR().call{value: balance}(new bytes(0));
      require(success, 'refund ETH failed');
    }
  }

  /// @dev Internal call to borrow tokens from the bank on behalf of the current executor.
  /// @param token The token to borrow from the bank.
  /// @param amount The amount to borrow.
  /// @notice Do not use `amount` input argument to handle the received amount.
  function doBorrow(address token, uint amount) internal {
    if (amount > 0) {
      bank.borrow(token, amount);
    }
  }

  /// @dev Internal call to repay tokens to the bank on behalf of the current executor.
  /// @param token The token to repay to the bank.
  /// @param amount The amount to repay.
  function doRepay(address token, uint amount) internal {
    if (amount > 0) {
      ensureApprove(token, address(bank));
      bank.repay(token, amount);
    }
  }

  /// @dev Internal call to put collateral tokens in the bank.
  /// @param token The token to put in the bank.
  /// @param amount The amount to put in the bank.
  function doPutCollateral(address token, uint amount) internal {
    if (amount > 0) {
      ensureApprove(token, address(werc20));
      werc20.mint(token, amount);
      bank.putCollateral(address(werc20), uint(token), amount);
    }
  }

  /// @dev Internal call to take collateral tokens from the bank.
  /// @param token The token to take back.
  /// @param amount The amount to take back.
  function doTakeCollateral(address token, uint amount) internal {
    if (amount > 0) {
      if (amount == uint(-1)) {
        (, , , amount) = bank.getCurrentPositionInfo();
      }
      bank.takeCollateral(address(werc20), uint(token), amount);
      werc20.burn(token, amount);
    }
  }

  /// @dev Fallback function. Can only receive ETH from WETH contract.
  receive() external payable {
    require(msg.sender == weth, 'ETH must come from WETH');
  }
}

// Part: WhitelistSpell

contract WhitelistSpell is BasicSpell, Governable {
  mapping(address => bool) public whitelistedLpTokens; // mapping from lp token to whitelist status

  constructor(
    IBank _bank,
    address _werc20,
    address _weth
  ) public BasicSpell(_bank, _werc20, _weth) {
    __Governable__init();
  }

  /// @dev Set whitelist LP token statuses for spell
  /// @param lpTokens LP tokens to set whitelist statuses
  /// @param statuses Whitelist statuses
  function setWhitelistLPTokens(address[] calldata lpTokens, bool[] calldata statuses)
    external
    onlyGov
  {
    require(lpTokens.length == statuses.length, 'lpTokens & statuses length mismatched');
    for (uint idx = 0; idx < lpTokens.length; idx++) {
      if (statuses[idx]) {
        require(bank.support(lpTokens[idx]), 'oracle not support lp token');
      }
      whitelistedLpTokens[lpTokens[idx]] = statuses[idx];
    }
  }
}

// File: CurveSpellV1.sol

contract CurveSpellV1 is WhitelistSpell {
  using SafeMath for uint;
  using HomoraMath for uint;

  ICurveRegistry public immutable registry; // Curve registry
  IWLiquidityGauge public immutable wgauge; // Wrapped liquidity gauge
  address public immutable crv; // CRV token address
  mapping(address => address[]) public ulTokens; // Mapping from LP token address -> underlying token addresses
  mapping(address => address) public poolOf; // Mapping from LP token address to -> pool address

  constructor(
    IBank _bank,
    address _werc20,
    address _weth,
    address _wgauge
  ) public WhitelistSpell(_bank, _werc20, _weth) {
    wgauge = IWLiquidityGauge(_wgauge);
    IWLiquidityGauge(_wgauge).setApprovalForAll(address(_bank), true);
    registry = IWLiquidityGauge(_wgauge).registry();
    crv = address(IWLiquidityGauge(_wgauge).crv());
  }

  /// @dev Return pool address given LP token and update pool info if not exist.
  /// @param lp LP token to find the corresponding pool.
  function getPool(address lp) public returns (address) {
    address pool = poolOf[lp];
    if (pool == address(0)) {
      require(lp != address(0), 'no lp token');
      pool = registry.get_pool_from_lp_token(lp);
      require(pool != address(0), 'no corresponding pool for lp token');
      poolOf[lp] = pool;
      (uint n, ) = registry.get_n_coins(pool);
      address[8] memory tokens = registry.get_coins(pool);
      ulTokens[lp] = new address[](n);
      for (uint i = 0; i < n; i++) {
        ulTokens[lp][i] = tokens[i];
      }
    }
    return pool;
  }

  /// @dev Ensure approval of underlying tokens to the corresponding Curve pool
  /// @param lp LP token for the pool
  /// @param n Number of pool's underlying tokens
  function ensureApproveN(address lp, uint n) public {
    require(ulTokens[lp].length == n, 'incorrect pool length');
    address pool = poolOf[lp];
    address[] memory tokens = ulTokens[lp];
    for (uint idx = 0; idx < n; idx++) {
      ensureApprove(tokens[idx], pool);
    }
  }

  /// @dev Add liquidity to Curve pool with 2 underlying tokens, with staking to Curve gauge
  /// @param lp LP token for the pool
  /// @param amtsUser Supplied underlying token amounts
  /// @param amtLPUser Supplied LP token amount
  /// @param amtsBorrow Borrow underlying token amounts
  /// @param amtLPBorrow Borrow LP token amount
  /// @param minLPMint Desired LP token amount (slippage control)
  /// @param pid Curve pool id for the pool
  /// @param gid Curve gauge id for the pool
  function addLiquidity2(
    address lp,
    uint[2] calldata amtsUser,
    uint amtLPUser,
    uint[2] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external {
    require(whitelistedLpTokens[lp], 'lp token not whitelisted');
    address pool = getPool(lp);
    require(ulTokens[lp].length == 2, 'incorrect pool length');
    require(wgauge.getUnderlyingTokenFromIds(pid, gid) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Take out collateral
    (, address collToken, uint collId, uint collSize) = bank.getCurrentPositionInfo();
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'bad pid or gid');
      require(collToken == address(wgauge), 'collateral token & wgauge mismatched');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 2 underlying tokens
    ensureApproveN(lp, 2);

    // 2. Get user input amounts
    for (uint i = 0; i < 2; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 2; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[2] memory suppliedAmts;
    for (uint i = 0; i < 2; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    if (suppliedAmts[0] > 0 || suppliedAmts[1] > 0) {
      ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);
    }

    // 5. Put collateral
    ensureApprove(lp, address(wgauge));
    {
      uint amount = IERC20(lp).balanceOf(address(this));
      uint id = wgauge.mint(pid, gid, amount);
      bank.putCollateral(address(wgauge), id, amount);
    }

    // 6. Refund
    for (uint i = 0; i < 2; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev Add liquidity to Curve pool with 3 underlying tokens, with staking to Curve gauge
  /// @param lp LP token for the pool
  /// @param amtsUser Supplied underlying token amounts
  /// @param amtLPUser Supplied LP token amount
  /// @param amtsBorrow Borrow underlying token amounts
  /// @param amtLPBorrow Borrow LP token amount
  /// @param minLPMint Desired LP token amount (slippage control)
  /// @param pid CUrve pool id for the pool
  /// @param gid Curve gauge id for the pool
  function addLiquidity3(
    address lp,
    uint[3] calldata amtsUser,
    uint amtLPUser,
    uint[3] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external {
    require(whitelistedLpTokens[lp], 'lp token not whitelisted');
    address pool = getPool(lp);
    require(ulTokens[lp].length == 3, 'incorrect pool length');
    require(wgauge.getUnderlyingTokenFromIds(pid, gid) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. take out collateral
    (, address collToken, uint collId, uint collSize) = bank.getCurrentPositionInfo();
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      require(collToken == address(wgauge), 'collateral token & wgauge mismatched');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 3 underlying tokens
    ensureApproveN(lp, 3);

    // 2. Get user input amounts
    for (uint i = 0; i < 3; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 3; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[3] memory suppliedAmts;
    for (uint i = 0; i < 3; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    if (suppliedAmts[0] > 0 || suppliedAmts[1] > 0 || suppliedAmts[2] > 0) {
      ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);
    }

    // 5. put collateral
    ensureApprove(lp, address(wgauge));
    {
      uint amount = IERC20(lp).balanceOf(address(this));
      uint id = wgauge.mint(pid, gid, amount);
      bank.putCollateral(address(wgauge), id, amount);
    }

    // 6. Refund
    for (uint i = 0; i < 3; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev Add liquidity to Curve pool with 4 underlying tokens, with staking to Curve gauge
  /// @param lp LP token for the pool
  /// @param amtsUser Supplied underlying token amounts
  /// @param amtLPUser Supplied LP token amount
  /// @param amtsBorrow Borrow underlying token amounts
  /// @param amtLPBorrow Borrow LP token amount
  /// @param minLPMint Desired LP token amount (slippage control)
  /// @param pid CUrve pool id for the pool
  /// @param gid Curve gauge id for the pool
  function addLiquidity4(
    address lp,
    uint[4] calldata amtsUser,
    uint amtLPUser,
    uint[4] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external {
    require(whitelistedLpTokens[lp], 'lp token not whitelisted');
    address pool = getPool(lp);
    require(ulTokens[lp].length == 4, 'incorrect pool length');
    require(wgauge.getUnderlyingTokenFromIds(pid, gid) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Take out collateral
    (, address collToken, uint collId, uint collSize) = bank.getCurrentPositionInfo();
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      require(collToken == address(wgauge), 'collateral token & wgauge mismatched');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 4 underlying tokens
    ensureApproveN(lp, 4);

    // 2. Get user input amounts
    for (uint i = 0; i < 4; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 4; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[4] memory suppliedAmts;
    for (uint i = 0; i < 4; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    if (suppliedAmts[0] > 0 || suppliedAmts[1] > 0 || suppliedAmts[2] > 0 || suppliedAmts[3] > 0) {
      ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);
    }

    // 5. Put collateral
    ensureApprove(lp, address(wgauge));
    {
      uint amount = IERC20(lp).balanceOf(address(this));
      uint id = wgauge.mint(pid, gid, amount);
      bank.putCollateral(address(wgauge), id, amount);
    }

    // 6. Refund
    for (uint i = 0; i < 4; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev Remove liquidity from Curve pool with 2 underlying tokens
  /// @param lp LP token for the pool
  /// @param amtLPTake Take out LP token amount (from Homora)
  /// @param amtLPWithdraw Withdraw LP token amount (back to caller)
  /// @param amtsRepay Repay underlying token amounts
  /// @param amtLPRepay Repay LP token amount
  /// @param amtsMin Desired underlying token amounts (slippage control)
  function removeLiquidity2(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[2] calldata amtsRepay,
    uint amtLPRepay,
    uint[2] calldata amtsMin
  ) external {
    require(whitelistedLpTokens[lp], 'lp token not whitelisted');
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    require(collToken == address(wgauge), 'collateral token & wgauge mismatched');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 2);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[2] memory actualAmtsRepay;
    for (uint i = 0; i < 2; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[2] memory amtsDesired;
    for (uint i = 0; i < 2; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    if (amtLPToRemove > 0) {
      uint[2] memory mins;
      ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);
    }
    // 5. Repay
    for (uint i = 0; i < 2; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 2; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev Remove liquidity from Curve pool with 3 underlying tokens
  /// @param lp LP token for the pool
  /// @param amtLPTake Take out LP token amount (from Homora)
  /// @param amtLPWithdraw Withdraw LP token amount (back to caller)
  /// @param amtsRepay Repay underlying token amounts
  /// @param amtLPRepay Repay LP token amount
  /// @param amtsMin Desired underlying token amounts (slippage control)
  function removeLiquidity3(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[3] calldata amtsRepay,
    uint amtLPRepay,
    uint[3] calldata amtsMin
  ) external {
    require(whitelistedLpTokens[lp], 'lp token not whitelisted');
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    require(collToken == address(wgauge), 'collateral token & wgauge mismatched');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 3);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[3] memory actualAmtsRepay;
    for (uint i = 0; i < 3; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[3] memory amtsDesired;
    for (uint i = 0; i < 3; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0 || amtsDesired[2] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    if (amtLPToRemove > 0) {
      uint[3] memory mins;
      ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);
    }

    // 5. Repay
    for (uint i = 0; i < 3; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 3; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev Remove liquidity from Curve pool with 4 underlying tokens
  /// @param lp LP token for the pool
  /// @param amtLPTake Take out LP token amount (from Homora)
  /// @param amtLPWithdraw Withdraw LP token amount (back to caller)
  /// @param amtsRepay Repay underlying token amounts
  /// @param amtLPRepay Repay LP token amount
  /// @param amtsMin Desired underlying token amounts (slippage control)
  function removeLiquidity4(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[4] calldata amtsRepay,
    uint amtLPRepay,
    uint[4] calldata amtsMin
  ) external {
    require(whitelistedLpTokens[lp], 'lp token not whitelisted');
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    require(collToken == address(wgauge), 'collateral token & wgauge mismatched');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 4);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[4] memory actualAmtsRepay;
    for (uint i = 0; i < 4; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[4] memory amtsDesired;
    for (uint i = 0; i < 4; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0 || amtsDesired[2] > 0 || amtsDesired[3] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    if (amtLPToRemove > 0) {
      uint[4] memory mins;
      ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);
    }

    // 5. Repay
    for (uint i = 0; i < 4; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 4; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev Harvest CRV reward tokens to in-exec position's owner
  function harvest() external {
    (, address collToken, uint collId, uint collSize) = bank.getCurrentPositionInfo();
    (uint pid, uint gid, ) = wgauge.decodeId(collId);
    address lp = wgauge.getUnderlyingToken(collId);
    require(whitelistedLpTokens[lp], 'lp token not whitelisted');
    require(collToken == address(wgauge), 'collateral token & wgauge mismatched');

    // 1. Take out collateral
    bank.takeCollateral(address(wgauge), collId, collSize);
    wgauge.burn(collId, collSize);

    // 2. Put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 3. Refund crv
    doRefund(crv);
  }
}